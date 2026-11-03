#!/usr/bin/env bash
#
# Block commits exceeding 10 files OR 300 lines (insertions + deletions).
#
# Why these thresholds: small commits are easier to review, revert, and
# bisect. Large commits hide bugs (one slip across 300 lines is hard to
# spot). Every commit on `main` becomes git history that the next engineer
# reads: keep each one a coherent slice.
#
# The thresholds are conservative because they force the discipline.
# Loosening them undermines the rule. Bypass with `git commit --no-verify`
# only for genuine big-bang changes (initial scaffolds, generated files);
# justify every bypass in the commit body.
#
# A file that git detects as a pure rename (R100 with -M) counts for 0 files
# and 0 lines: a mass move has nothing to review per file. A rename with an
# edit (R0xx) counts as 1 file, and its lines count as for any edit. Keep
# the counting in lockstep with check-commit-range.sh, the CI mirror.
#
# See skills/atelier/references/workflow.md (Commit size limits).

set -euo pipefail

MAX_FILES=10
MAX_LINES=300

files=$(git diff --cached -M --name-status --diff-filter=ACMR | grep -cv '^R100' || true)
lines=$(git diff --cached -M --numstat | awk '{ sum += $1 + $2 } END { print sum + 0 }')

if [ "${files:-0}" -le "$MAX_FILES" ] && [ "${lines:-0}" -le "$MAX_LINES" ]; then
  exit 0
fi

cat <<EOF >&2
  ╳ COMMIT TOO BIG
  Files staged:  ${files}  (max ${MAX_FILES}, a pure rename does not count)
  Lines staged:  ${lines} (max ${MAX_LINES}, insertions + deletions)
  Bypass: git commit --no-verify
EOF
exit 1
