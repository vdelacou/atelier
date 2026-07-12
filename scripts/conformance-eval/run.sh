#!/usr/bin/env bash
#
# Run conformance tasks: does code produced WITH the skill follow the rules
# that code produced WITHOUT it misses? Each task in tasks.json runs twice
# (with_skill | baseline) in an isolated copy of fixture/, executed by
# `claude -p` with edit permissions, then grade.py applies the task's
# mechanical assertions to whatever code each run produced.
#
#   bash scripts/conformance-eval/run.sh [task-id ...]   # default: all tasks
#
# Env:
#   CONFORMANCE_MODEL  model for claude -p (default: user's configured model)
#   CONFORMANCE_ARMS   "with_skill baseline" (default) or a single arm
#   CONFORMANCE_JOBS   parallel runs (default 4)
#
# Results land in skills/atelier-workspace/conformance-<date>/runs/ (gitignored).
# Grade afterwards:
#   python3 scripts/conformance-eval/grade.py

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
SKILL_PATH="$REPO_ROOT/skills/atelier"
OUT="$REPO_ROOT/skills/atelier-workspace/conformance-$(date +%F)/runs"
JOBS="${CONFORMANCE_JOBS:-4}"
ARMS="${CONFORMANCE_ARMS:-with_skill baseline}"
mkdir -p "$OUT"

# bash-3.2-safe (macOS): no mapfile, no wait -n
TASK_IDS=()
while IFS= read -r line; do TASK_IDS+=("$line"); done < <(python3 -c "
import json, sys
tasks = json.load(open('$HERE/tasks.json'))
wanted = sys.argv[1:]
for t in tasks:
    if not wanted or t['id'] in wanted:
        print(t['id'])
" "$@")

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
  local task
  task=$(task_prompt "$id")
  local prompt
  if [ "$arm" = "with_skill" ]; then
    prompt="You are executing a coding task in the repo at $dir. This repo follows the coding standard defined by the skill at $SKILL_PATH: read that skill's SKILL.md FIRST and follow it exactly, consulting files under its references/ directory where the SKILL.md directs you to. Then implement the task. Work only inside the repo directory named above. Do not run git. Do not install packages. Task: $task When done, reply with only the list of files you created or changed, one relative path per line."
  else
    prompt="You are a senior engineer executing a coding task in the repo at $dir. It is a small Bun/TypeScript repo. Implement the task well, using your own judgment. Work only inside the repo directory named above. Do not run git. Do not install packages. Task: $task When done, reply with only the list of files you created or changed, one relative path per line."
  fi
  ( cd "$dir" && env -u CLAUDECODE claude -p "$prompt" \
      --permission-mode acceptEdits \
      ${CONFORMANCE_MODEL:+--model "$CONFORMANCE_MODEL"} \
      < /dev/null > "$dir/.result.txt" 2> "$dir/.run.log" ) \
    && echo "done: $id-$arm" || echo "FAILED: $id-$arm (see $dir/.run.log)"
}

for id in "${TASK_IDS[@]}"; do
  for arm in $ARMS; do
    run_one "$id" "$arm" &
    while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do sleep 2; done
  done
done
wait
echo "all runs complete: $OUT"
