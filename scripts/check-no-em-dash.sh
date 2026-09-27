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
# else HEAD~1..HEAD; the same resolution as the shipped commit gates. Only the push
# path falls back to HEAD~1: a base given as an argument, or a pull request's base
# that did not fetch, fails with exit 2 when it does not resolve.
set -euo pipefail

DASH=$'\xe2\x80\x94'
zero_sha=0000000000000000000000000000000000000000

# stdin: a unified diff. stdout: "path: content" for every added line carrying the dash.
# Header-aware: `+++ b/` names the file only before a file's first hunk, and inside a hunk
# every `+` line is content, a Markdown line that starts with `+` included (the old
# /^\+[^+]/ dropped it).
added_lines_with_dash() {
  awk -v d="$DASH" '
    /^diff --git / { hdr = 1; next }
    hdr && /^\+\+\+ / { f = substr($0, 7); next }
    /^@@/ { hdr = 0; next }
    !hdr && /^\+/ && index($0, d) { print f ": " substr($0, 2) }'
}

if [ "${1:-}" = "--selftest" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  gate=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
  cd "$tmp" && git init -q . && git config user.email t@e.st && git config user.name t
  printf 'clean line\n' > a.md && git add a.md
  # The staged checks run with the Actions variables unset: under a push job the gate
  # would otherwise take the range branch, find no HEAD~1 in this one-commit repo, and
  # exit 0 on the staged dash (the 2026-09-03 red main).
  staged() { env -u GITHUB_EVENT_NAME -u GITHUB_BASE_REF -u GITHUB_EVENT_BEFORE bash "$gate"; }
  staged >/dev/null || { echo "selftest FAIL: a clean stage was rejected" >&2; exit 1; }
  git commit -qm 'chore: base'
  printf 'a line %s with a dash\n' "$DASH" > b.md && git add b.md
  if staged >/dev/null 2>&1; then echo "selftest FAIL: a staged em dash was accepted" >&2; exit 1; fi
  git commit -qm 'chore: dash'
  if bash "$gate" HEAD~1 HEAD >/dev/null 2>&1; then echo "selftest FAIL: an em dash in the range was accepted" >&2; exit 1; fi
  printf 'no dash any more\n' > b.md && git add b.md && git commit -qm 'chore: fixed'
  bash "$gate" HEAD~1 HEAD >/dev/null || { echo "selftest FAIL: a range that removes the dash was rejected" >&2; exit 1; }
  # A git error is a failure, never a clean pass: `|| true` after the pipe once turned
  # an unknown head ref into "no em dash" and exit 0.
  if bash "$gate" HEAD~1 no-such-ref >/dev/null 2>&1; then echo "selftest FAIL: an unknown head ref passed" >&2; exit 1; fi
  # A base that does not resolve fails too: it once fell back to HEAD~1 and passed on a narrower
  # range than the one asked for (2026-09-28). HEAD~1..HEAD is clean here, so only the refusal
  # makes these two red: an explicit base, and a pull request's base whose fetch failed.
  if bash "$gate" no-such-base HEAD >/dev/null 2>&1; then echo "selftest FAIL: an unknown base ref passed" >&2; exit 1; fi
  if env -u GITHUB_EVENT_NAME -u GITHUB_EVENT_BEFORE GITHUB_BASE_REF=no-such-branch bash "$gate" >/dev/null 2>&1; then
    echo "selftest FAIL: an unresolvable pull request base passed" >&2; exit 1
  fi
  # A push whose before-sha is unusable (a new branch) keeps its HEAD~1 fallback.
  env -u GITHUB_BASE_REF GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$zero_sha" bash "$gate" >/dev/null \
    || { echo "selftest FAIL: a push with no usable before-sha lost its HEAD~1 fallback" >&2; exit 1; }
  # An added line whose own text starts with `+` (a Markdown bullet) is still read.
  printf '+ a plus bullet %s with a dash\n' "$DASH" > c.md && git add c.md
  if staged >/dev/null 2>&1; then echo "selftest FAIL: an em dash on a line starting with + was accepted" >&2; exit 1; fi
  git reset -q c.md
  echo "selftest OK: gate rejects a staged em dash, one in a commit range, one on a line starting with +, and an unknown ref; refuses an unknown base (explicit or a pull request's), keeps the push fallback, and accepts a clean stage and a range that removes one"
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
    # A new branch or a force-push leaves no usable before-sha: judge the pushed tip alone.
    base=HEAD~1
    git rev-parse --quiet --verify 'HEAD~1^{commit}' >/dev/null 2>&1 || { echo "check-no-em-dash: single-commit history, nothing to compare"; exit 0; }
  fi
  head=HEAD
else
  base=""; head=""
fi

if [ -z "$base" ]; then
  scope="the staged diff"
  hits=$(git diff --cached -U0 | added_lines_with_dash)
else
  # An explicit or pull-request base that does not resolve is refused, never swapped for
  # HEAD~1: a pass on a narrower range than the one asked for is a silent pass.
  if ! git rev-parse --quiet --verify "${base}^{commit}" >/dev/null 2>&1; then
    echo "check-no-em-dash: base '${base}' does not resolve to a commit; the range was not read (pass <base> [<head>], not <base>..<head>)" >&2
    exit 2
  fi
  scope="${base}..${head}"
  hits=$(git diff -U0 "$base" "$head" | added_lines_with_dash)
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
