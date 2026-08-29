#!/usr/bin/env bash
#
# Review-recall eval: how much of a violation-laden diff does the reviewer catch?
#
# The conformance eval proves generated code follows the rules; this proves the
# REVIEW side, which is the enforcement moment for several rules nothing else
# measures. One task, two arms:
#
#   with_skill  atelier-review-me + the main atelier skill in the run dir
#   baseline    a skill-less senior-engineer review
#
# The reviewed change is built from three layers:
#   scripts/conformance-eval/fixture/   the shared repo scaffold (reused by
#                                       reference, not duplicated; documented
#                                       coupling)
#   base/                               pre-change state (adds the test that the
#                                       diff later weakens)
#   changed/                            the diff under review: 11 planted
#                                       violations (violations.json) + 2 clean
#                                       changed files (clean-files.json)
#
# The diff is materialised OUTSIDE the agent sandbox (git here, then .git
# stripped), so the agent reviews ./changes.diff plus the tree and never needs
# git. The agent is instructed to report only; its stdout is the review,
# captured to .review.txt and graded by grade.py.
#
#   bash scripts/review-eval/run.sh
#
# Env:
#   REVIEW_MODEL    model for claude -p (default: user's configured model)
#   REVIEW_TAG      suffix for the output dir (default: none)
#   REVIEW_ARMS     "with_skill baseline" (default) or a single arm
#   REVIEW_VARIANT  bun (default) or java. Java uses base-java/ + changed-java/
#                   with no shared-fixture underlay (base-java is complete), and
#                   the java manifests; grade with `grade.py --variant java`.
#
# Results land in skills/atelier-workspace/review-eval-<date>/runs* (gitignored).
# Grade afterwards:
#   python3 scripts/review-eval/grade.py <runs-dir>

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
VARIANT="${REVIEW_VARIANT:-bun}"
case "$VARIANT" in
  bun)  FIXTURE="$REPO_ROOT/scripts/conformance-eval/fixture"; BASE="$HERE/base"; CHANGED="$HERE/changed"; REPO_KIND="Bun/TypeScript" ;;
  java) FIXTURE=""; BASE="$HERE/base-java"; CHANGED="$HERE/changed-java"; REPO_KIND="Java (Maven)" ;;
  *) echo "run.sh: unknown REVIEW_VARIANT '$VARIANT' (bun|java)" >&2; exit 1 ;;
esac
OUT="$REPO_ROOT/skills/atelier-workspace/review-eval-$(date +%F)/runs${REVIEW_MODEL:+-$REVIEW_MODEL}${VARIANT:+-$VARIANT}${REVIEW_TAG:+-$REVIEW_TAG}"
ARMS="${REVIEW_ARMS:-with_skill baseline}"
mkdir -p "$OUT"

run_one() { # $1 = arm
  local arm="$1"
  local dir="$OUT/review-$arm"
  rm -rf "$dir" && mkdir -p "$dir"

  # Base state: (fixture underlay for bun) + base overlay, committed; then the
  # changed overlay on top.
  [ -n "$FIXTURE" ] && cp -r "$FIXTURE/." "$dir/"
  cp -r "$BASE/." "$dir/"
  ( cd "$dir" \
    && git init -q \
    && git config user.email 'review-eval@example.invalid' \
    && git config user.name 'review-eval' \
    && git add -A \
    && git commit -q -m 'chore: baseline before the reviewed change' \
    && cp -r "$CHANGED/." . \
    && git add -A \
    && git diff --cached > changes.diff \
    && rm -rf .git )

  local changed_files
  changed_files=$(cd "$CHANGED" && find . -type f | sed 's|^\./||' | sort | paste -sd', ' -)

  local prompt
  if [ "$arm" = "with_skill" ]; then
    mkdir -p "$dir/skills"
    cp -r "$REPO_ROOT/skills/atelier" "$REPO_ROOT/skills/atelier-review-me" "$dir/skills/"
    prompt="You are reviewing a change in the repo at $dir before it lands. This repo follows the atelier coding standard: read ./skills/atelier-review-me/SKILL.md FIRST and run its review procedure, using the hard rules in ./skills/atelier/SKILL.md (and files under ./skills/atelier/references/ where directed). The change under review is ./changes.diff (the full post-change files are in the tree; changed files: $changed_files). Report only, never edit any file. Output the findings as the review-me skill specifies: each names the file, the exact rule number it breaks, why, and the fix, grouped by severity, ending with the one-line verdict."
  else
    prompt="You are a senior engineer reviewing a change in the $REPO_KIND repo at $dir before it lands. The change under review is ./changes.diff (the full post-change files are in the tree; changed files: $changed_files). Review it for problems worth blocking or fixing before merge. Report only, never edit any file. For each finding name the file, what is wrong, and the fix, most important first."
  fi

  ( cd "$dir" && env -u CLAUDECODE claude -p "$prompt" \
      ${REVIEW_MODEL:+--model "$REVIEW_MODEL"} \
      < /dev/null > "$dir/.review.txt" 2> "$dir/.run.log" ) \
    && echo "done: review-$arm ($(wc -l < "$dir/.review.txt" | tr -d ' ') lines)" \
    || echo "FAILED: review-$arm (see $dir/.run.log)"
}

for arm in $ARMS; do
  run_one "$arm" &
done
wait
echo "all runs complete: $OUT"
