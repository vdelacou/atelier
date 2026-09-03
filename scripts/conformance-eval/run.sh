#!/usr/bin/env bash
#
# Run conformance tasks: does code produced WITH the skill follow the rules
# that code produced WITHOUT it misses? Each task in tasks.json runs twice
# (with_skill | baseline) in an isolated copy of fixture/, executed by
# `claude -p` with edit permissions, then grade.py applies the task's
# mechanical assertions to whatever code each run produced.
#
#   bash scripts/conformance-eval/run.sh [task-id ...]   # default: all tasks
#   CONFORMANCE_SINCE=<ref> bash scripts/conformance-eval/run.sh   # tier 1: only the
#       tasks the skill diff since <ref> can affect (select-tasks.py), skill arm, 6 jobs
#
# Env:
#   CONFORMANCE_MODEL  model for claude -p (default: user's configured model)
#   CONFORMANCE_ARMS   with_skill (default: the baseline arm is frozen in baseline-arm.json,
#                      grade with --frozen-baseline), baseline, or both
#   CONFORMANCE_JOBS   parallel runs (default 4; 6 when CONFORMANCE_SINCE is set)
#   CONFORMANCE_SINCE  git ref; selects tasks from the skills/atelier/ diff since it
#   CONFORMANCE_TIMEOUT_MIN  wall-clock cap per session (default 15); a capped run is
#                      graded as produced and named in the summary
#   CONFORMANCE_MAX_TURNS    turn cap per session, passed to claude -p (default 60)
#
# Results land in skills/atelier-workspace/conformance-<date>/runs/ (gitignored).
# Grade afterwards, against the frozen baseline arm:
#   python3 scripts/conformance-eval/grade.py <runs-dir> --frozen-baseline
# Refresh the frozen arm only when tasks.json changes (prompts or assertions):
#   CONFORMANCE_ARMS=baseline bash scripts/conformance-eval/run.sh
#   python3 scripts/conformance-eval/freeze-baseline.py <runs-dir> --model <model>

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SKILL_PATH="${CONFORMANCE_SKILL_PATH:-$REPO_ROOT/skills/atelier}"
OUT="$REPO_ROOT/skills/atelier-workspace/conformance-$(date +%F)/runs${CONFORMANCE_MODEL:+-$CONFORMANCE_MODEL}${CONFORMANCE_TAG:+-$CONFORMANCE_TAG}"
SINCE="${CONFORMANCE_SINCE:-}"
JOBS="${CONFORMANCE_JOBS:-$([ -n "$SINCE" ] && echo 6 || echo 4)}"
TIMEOUT_MIN="${CONFORMANCE_TIMEOUT_MIN:-15}"
MAX_TURNS="${CONFORMANCE_MAX_TURNS:-60}"
ARMS="${CONFORMANCE_ARMS:-with_skill}"
[ "$ARMS" != "both" ] || ARMS="with_skill baseline"
mkdir -p "$OUT"
CAPPED="$OUT/.capped"
: > "$CAPPED"

# bash-3.2-safe (macOS): no mapfile, no wait -n
TASK_IDS=()
if [ -n "$SINCE" ]; then
  [ $# -eq 0 ] || { echo "run.sh: CONFORMANCE_SINCE and explicit task ids are exclusive" >&2; exit 2; }
  while IFS= read -r line; do TASK_IDS+=("$line"); done < <(python3 "$HERE/select-tasks.py" --since "$SINCE")
  if [ "${#TASK_IDS[@]}" -eq 0 ]; then
    echo "no task maps to the skills/atelier/ diff since $SINCE; nothing to run (tier 2 is the full pass, by hand)"
    exit 0
  fi
  echo "tier 1 since $SINCE: ${TASK_IDS[*]} (arms: $ARMS, jobs: $JOBS)"
else
  while IFS= read -r line; do TASK_IDS+=("$line"); done < <(python3 -c "
import json, sys
tasks = json.load(open('$HERE/tasks.json'))
wanted = sys.argv[1:]
for t in tasks:
    if not wanted or t['id'] in wanted:
        print(t['id'])
" "$@")
fi

task_prompt() { # $1 = task id
  python3 -c "
import json, sys
tasks = json.load(open('$HERE/tasks.json'))
print(next(t['prompt'] for t in tasks if t['id'] == sys.argv[1]))
" "$1"
}

run_one() { # $1 = task id, $2 = arm
  local id="$1" arm="$2"
  local dir="$OUT/$id-$arm"
  rm -rf "$dir" && mkdir -p "$dir" && cp -r "$HERE/fixture/." "$dir/"
  # with_skill: copy the skill INTO the run dir. A nested `claude -p` sandboxes
  # file reads to its own working directory, so an absolute path to the skill
  # OUTSIDE the run dir cannot be read, and a with_skill run would then execute
  # skill-less (measuring baseline vs baseline). grade.py excludes the skills/
  # subtree, so these injected files are never counted as the agent's output.
  if [ "$arm" = "with_skill" ]; then
    mkdir -p "$dir/skills" && cp -r "$SKILL_PATH" "$dir/skills/"
  fi
  local task
  task=$(task_prompt "$id")
  local prompt
  if [ "$arm" = "with_skill" ]; then
    prompt="You are executing a coding task in the repo at $dir. This repo follows the coding standard defined by the atelier skill, copied into this repo at ./skills/atelier. Read ./skills/atelier/SKILL.md FIRST and follow it exactly, consulting files under ./skills/atelier/references/ where the SKILL.md directs you to. Then implement the task. Work only inside the repo directory named above; the ./skills/atelier tree is read-only reference, so do not edit it or count it as your output. Do not run git. Do not install packages. Task: $task When done, reply with only the list of files you created or changed, one relative path per line."
  else
    prompt="You are a senior engineer executing a coding task in the repo at $dir. It is a small Bun/TypeScript repo. Implement the task well, using your own judgment. Work only inside the repo directory named above. Do not run git. Do not install packages. Task: $task When done, reply with only the list of files you created or changed, one relative path per line."
  fi
  # Wall-clock cap, portable (macOS ships no `timeout`): the session runs in the
  # background with a sleeping watchdog; whichever finishes first kills the other.
  # A capped run keeps whatever it produced and is graded like any other, so a
  # wandering session costs one slot for TIMEOUT_MIN minutes, never the batch.
  ( cd "$dir" && env -u CLAUDECODE claude -p "$prompt" \
      --permission-mode acceptEdits \
      ${MAX_TURNS:+--max-turns "$MAX_TURNS"} \
      ${CONFORMANCE_MODEL:+--model "$CONFORMANCE_MODEL"} \
      < /dev/null > "$dir/.result.txt" 2> "$dir/.run.log" ) &
  local session=$!
  ( sleep $((TIMEOUT_MIN * 60)) && kill "$session" 2>/dev/null && echo "$id-$arm" >> "$CAPPED" ) &
  local watchdog=$!
  local status=0
  wait "$session" || status=$?
  kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null || true
  if grep -qx "$id-$arm" "$CAPPED"; then
    echo "capped: $id-$arm after ${TIMEOUT_MIN} min (graded as produced)"
  elif [ "$status" -eq 0 ]; then
    echo "done: $id-$arm"
  else
    echo "FAILED: $id-$arm (see $dir/.run.log)"
  fi
  # Incremental grading: the scorecard line for this task, as soon as it lands.
  python3 "$HERE/grade.py" "$OUT" --task "$id" 2>/dev/null | grep -E "^  (with_skill|baseline) " | sed "s/^/  [$id] /" || true
}

for id in "${TASK_IDS[@]}"; do
  for arm in $ARMS; do
    run_one "$id" "$arm" &
    while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do sleep 2; done
  done
done
wait
if [ -s "$CAPPED" ]; then
  echo "capped at ${TIMEOUT_MIN} min: $(tr '\n' ' ' < "$CAPPED")"
fi
echo "all runs complete: $OUT"
