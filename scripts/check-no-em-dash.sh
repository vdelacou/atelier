#!/usr/bin/env bash
#
# This repo's em-dash gate: no U+2014 on an added line.
#
# The standard bans the character in everything an agent writes (SKILL.md,
# Interaction) and an agent copies the punctuation it sees, so the ban has to
# hold in the skill text itself. Until 2026-09-02 nothing checked it and
# SKILL.md alone carried 83. Only ADDED lines are read, so existing dashes do
# not block a commit that leaves them alone; touching a line means fixing it.
#
# Usage:
#   bash scripts/check-no-em-dash.sh                  the staged diff (the pre-commit hook)
#   bash scripts/check-no-em-dash.sh <base> [<head>]  the net diff of a range (CI)
#   bash scripts/check-no-em-dash.sh --selftest
#
# With no arguments under GitHub Actions the range is the PR's base branch, or
# on a push GITHUB_EVENT_BEFORE..HEAD (the workflow exports github.event.before),
# else HEAD~1..HEAD; the same resolution as the shipped commit gates.
set -euo pipefail

DASH=$'\xe2\x80\x94'
zero_sha=0000000000000000000000000000000000000000

# stdin: a unified diff. stdout: "path: content" for every added line carrying the dash.
added_lines_with_dash() {
  awk -v d="$DASH" '/^\+\+\+ b\//{f=substr($0,7)} /^\+[^+]/ && index($0, d) {print f ": " substr($0, 2)}'
}

if [ "${1:-}" = "--selftest" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  gate=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
  cd "$tmp" && git init -q . && git config user.email t@e.st && git config user.name t
  printf 'clean line\n' > a.md && git add a.md
  bash "$gate" >/dev/null || { echo "selftest FAIL: a clean stage was rejected" >&2; exit 1; }
  git commit -qm 'chore: base'
  printf 'a line %s with a dash\n' "$DASH" > b.md && git add b.md
  if bash "$gate" >/dev/null 2>&1; then echo "selftest FAIL: a staged em dash was accepted" >&2; exit 1; fi
  git commit -qm 'chore: dash'
  if bash "$gate" HEAD~1 HEAD >/dev/null 2>&1; then echo "selftest FAIL: an em dash in the range was accepted" >&2; exit 1; fi
  printf 'no dash any more\n' > b.md && git add b.md && git commit -qm 'chore: fixed'
  bash "$gate" HEAD~1 HEAD >/dev/null || { echo "selftest FAIL: a range that removes the dash was rejected" >&2; exit 1; }
  echo "selftest OK: gate rejects a staged em dash and one in a commit range, accepts a clean stage and a range that removes one"
  exit 0
fi

if [ $# -ge 1 ]; then
  base="$1"; head="${2:-HEAD}"
elif [ -n "${GITHUB_BASE_REF:-}" ]; then
  git fetch --quiet origin "$GITHUB_BASE_REF" 2>/dev/null || true
  base="origin/${GITHUB_BASE_REF}"; head=HEAD
elif [ "${GITHUB_EVENT_NAME:-}" = "push" ]; then
  before="${GITHUB_EVENT_BEFORE:-}"
  if [ -n "$before" ] && [ "$before" != "$zero_sha" ] && git rev-parse --quiet --verify "${before}^{commit}" >/dev/null 2>&1; then
    base="$before"
  else
    base=HEAD~1
  fi
  head=HEAD
else
  base=""; head=""
fi

if [ -z "$base" ]; then
  scope="the staged diff"
  hits=$(git diff --cached -U0 | added_lines_with_dash || true)
else
  if ! git rev-parse --quiet --verify "${base}^{commit}" >/dev/null 2>&1; then
    base=HEAD~1
    git rev-parse --quiet --verify 'HEAD~1^{commit}' >/dev/null 2>&1 || { echo "check-no-em-dash: single-commit history, nothing to compare"; exit 0; }
  fi
  scope="${base}..${head}"
  hits=$(git diff -U0 "$base" "$head" | added_lines_with_dash || true)
fi

if [ -z "$hits" ]; then
  echo "  ✓ no em dash on an added line (${scope})"
  exit 0
fi
{
  echo "  ╳ em dash (U+2014) on an added line (${scope}). Use a comma, a colon, parentheses, or a period:"
  echo "$hits" | sed 's/^/      /'
} >&2
exit 1
