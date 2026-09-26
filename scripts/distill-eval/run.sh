#!/usr/bin/env bash
#
# Distill eval: does a compaction pass keep every live lesson, account for every entry,
# and leave everything outside the memory layers alone?
#
# One task, two arms, on scripts/distill-eval/fixture/ (a small Bun repo whose
# .claude/LESSONS.md plants every verdict; planted.json names what each entry should
# become):
#
#   with_skill  atelier-distill and the main atelier skill installed at project level
#               (.claude/skills/), the prompt pointing at the skill
#   baseline    the same request, no skill
#
# Both arms get the owner's own request, headless and pre-approved. Each session runs in a
# scratch folder outside this repo, copied back into its run dir when it ends: started inside
# the tree, a session loads this repo's CLAUDE.md and project memory by directory walk-up.
# The user setting source is off, so skills installed under ~/.claude/skills stay out of both
# arms, and the user's settings file is passed back (the output style the other evals run
# with). The fixture is committed in the session folder first: the pass reads
# `git show HEAD:` for its ledger, and the grader checks that no commit followed.
#
# A headless session may not write under .claude/, the journal's home: acceptEdits and
# every allow rule tried on 2026-09-26 were refused, and the first six sessions left the
# journal untouched. Both arms are therefore told to write what they would change under
# .claude/ into ./out/ under the same name, and grade.py reads out/ as the journal layer.
# Only the output path is artificial; the pass's decisions are the ones measured.
#
#   bash scripts/distill-eval/run.sh
#
# Env:
#   DISTILL_MODEL        model for claude -p (default: the user's configured model)
#   DISTILL_TAG          suffix for the output dir (default: none)
#   DISTILL_ARMS         "with_skill baseline" (default) or one arm
#   DISTILL_PASSES       passes per arm (default 3)
#   DISTILL_MAX_TURNS    turn cap per session (default 80)
#   DISTILL_TIMEOUT_MIN  wall-clock cap per session (default 30)
#
# Results land in skills/atelier-workspace/distill-eval-<date>/runs* (gitignored).
# Grade afterwards:
#   python3 scripts/distill-eval/grade.py <runs-dir>

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$REPO_ROOT/skills/atelier-workspace/distill-eval-$(date +%F)/runs${DISTILL_MODEL:+-$DISTILL_MODEL}${DISTILL_TAG:+-$DISTILL_TAG}"
ARMS="${DISTILL_ARMS:-with_skill baseline}"
PASSES="${DISTILL_PASSES:-3}"
MAX_TURNS="${DISTILL_MAX_TURNS:-80}"
TIMEOUT_MIN="${DISTILL_TIMEOUT_MIN:-30}"
mkdir -p "$OUT"
SESSION_ROOT="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/atelier-distill.XXXXXX")" && pwd -P)"
trap 'rm -rf "${SESSION_ROOT:?}"' EXIT
ISOLATE=(--setting-sources project,local)
[ ! -f "$HOME/.claude/settings.json" ] || ISOLATE+=(--settings "$HOME/.claude/settings.json")

REQUEST="Clean up this repo's agent memory, .claude/LESSONS.md and CLAUDE.md: delete what is not needed and organize it better."
HEADLESS="You are running unattended and the owner has pre-approved every change you propose: apply them all, then reply with a short summary of what you did. Do not commit, and do not ask questions. This harness cannot write under .claude/: write each file you would create or change there to ./out/ under the same name instead (./out/LESSONS.md, ./out/lessons.archive.md), leave .claude/ as it is, and edit CLAUDE.md in place."

run_one() { # $1 = arm, $2 = pass
  local arm="$1" n="$2"
  local dir="$OUT/$arm-$n" sdir="$SESSION_ROOT/$arm-$n"
  rm -rf "$dir" "${sdir:?}" && mkdir -p "$dir" "$sdir"
  cp -R "$HERE/fixture/." "$sdir/"
  ( cd "$sdir" \
    && git init -q \
    && git config user.email 'distill-eval@example.invalid' \
    && git config user.name 'distill-eval' \
    && git add -A \
    && git commit -q -m 'chore: fixture' )
  local prompt
  if [ "$arm" = "with_skill" ]; then
    # Installed after the fixture commit, so the skills are untracked and never graded.
    mkdir -p "$sdir/.claude/skills"
    cp -R "$REPO_ROOT/skills/atelier" "$REPO_ROOT/skills/atelier-distill" "$sdir/.claude/skills/"
    prompt="$REQUEST Use the atelier-distill skill: read ./.claude/skills/atelier-distill/SKILL.md first and follow it; the doctrine it applies is ./.claude/skills/atelier/references/lessons.md. $HEADLESS"
  else
    prompt="$REQUEST $HEADLESS"
  fi
  # Wall-clock cap, portable (macOS ships no `timeout`), in the conformance runner's shape.
  ( cd "$sdir" && env -u CLAUDECODE claude -p "$prompt" \
      --permission-mode acceptEdits \
      "${ISOLATE[@]}" \
      --allowedTools "Bash(git show:*),Bash(git diff:*),Bash(git log:*),Bash(git status:*),Bash(wc:*),Bash(ls:*)" \
      --max-turns "$MAX_TURNS" \
      ${DISTILL_MODEL:+--model "$DISTILL_MODEL"} \
      --output-format stream-json --verbose \
      < /dev/null > "$dir/.transcript.jsonl" 2> "$dir/.run.log" ) &
  local session=$!
  ( sleep $((TIMEOUT_MIN * 60)) && kill "$session" 2>/dev/null && echo "capped" > "$dir/.capped" ) &
  local watchdog=$!
  local status=0
  wait "$session" 2>/dev/null || status=$?
  kill "$watchdog" 2>/dev/null; wait "$watchdog" 2>/dev/null || true
  cp -R "$sdir/." "$dir/" && rm -rf "${sdir:?}"  # the tree the grader reads, .git included
  if [ -f "$dir/.capped" ]; then
    echo "capped: $arm-$n after ${TIMEOUT_MIN} min (graded as produced)"
  elif [ "$status" -eq 0 ]; then
    echo "done: $arm-$n"
  else
    echo "FAILED: $arm-$n (exit $status, see $dir/.run.log)"
  fi
}

for arm in $ARMS; do
  for n in $(seq 1 "$PASSES"); do
    run_one "$arm" "$n" &
  done
done
wait
echo "all runs complete: $OUT"
