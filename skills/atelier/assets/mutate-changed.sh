#!/usr/bin/env bash
#
# Run Stryker mutation testing on the files that changed, plus any uncommitted
# edits and untracked files: the mutation step of the CI gate (assets/ci.yml,
# every pull request and push) and the iteration-time check. The full sweep
# is never a commit gate; assets/mutation.yml runs it once a day.
#
# The base ref: BASE= wins; under GitHub Actions the range is the pull
# request's base branch or, on a push, github.event.before..HEAD (ci.yml
# exports it as GITHUB_EVENT_BEFORE; the zero SHA of a new branch and an
# unresolvable SHA fall back to HEAD~1), the same resolution as the commit
# gates. Without it a push to main has HEAD == origin/main and the run would
# test nothing. Elsewhere the default is origin/main. Skip the ref refresh
# with MUTATE_NO_FETCH=1 (offline, or when BASE is deliberately stale):
#
#   BASE=HEAD~3 bun run mutate:changed
#
# A repo with no `origin/main` yet (greenfield, before the first push) must set
# BASE to a local ref; an unknown base fails loudly rather than passing empty.
#
# See skills/atelier/references/workflow.md (Mutation testing).

set -euo pipefail

zero_sha=0000000000000000000000000000000000000000
if [ -n "${BASE:-}" ]; then
  :
elif [ -n "${GITHUB_BASE_REF:-}" ]; then
  BASE="origin/${GITHUB_BASE_REF}"
elif [ "${GITHUB_EVENT_NAME:-}" = "push" ]; then
  before="${GITHUB_EVENT_BEFORE:-}"
  if [ -n "$before" ] && [ "$before" != "$zero_sha" ] && git rev-parse --quiet --verify "${before}^{commit}" >/dev/null 2>&1; then
    BASE="$before"
  else
    BASE=HEAD~1
  fi
else
  BASE=origin/main
fi

# `origin/*` is a LOCAL cache of the remote, moved only by a fetch. Against a
# stale ref, `$BASE...HEAD` still holds commits pushed long ago: the mutation
# set widens by files nobody touched, and the same list reads as "unpushed
# work". Refresh it, but never fail the run on a network error.
if [ -z "${MUTATE_NO_FETCH:-}" ] && [ "${BASE#origin/}" != "$BASE" ]; then
  git fetch --quiet origin "${BASE#origin/}" || true
fi

# An unknown BASE makes every diff below fail, and the `|| true` on the
# pipeline turns that into "no files changed" plus exit 0: a green run that
# mutated nothing. Fail loudly instead.
if ! git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
  echo "mutate:changed: base ref '$BASE' does not exist (fetch it, or set BASE=)" >&2
  exit 1
fi

echo "mutate:changed: base ${BASE} $(git rev-parse --short "$BASE")" \
     "($(git log -1 --format=%cr "$BASE")), HEAD +$(git rev-list --count "$BASE"..HEAD)"

# Files that differ from BASE, plus uncommitted and staged edits, plus
# untracked files, intersected with the mutation scope. Untracked matters: a
# brand-new source file appears in NO diff, so without it a new domain or
# use-case file is never mutated and the run still exits 0.
files=$( {
  git diff --name-only --diff-filter=ACMR "$BASE"...HEAD
  git diff --name-only --diff-filter=ACMR HEAD
  git diff --cached --name-only --diff-filter=ACMR
  git ls-files --others --exclude-standard
} | sort -u \
  | grep -E '^src/(domain|use-cases)/' \
  | grep -E '\.ts$' \
  | grep -vE '\.test\.ts$' \
  | grep -vE '/ports/' \
  || true)

if [ -z "$files" ]; then
  echo "mutate:changed: no files in mutation scope changed since ${BASE}"
  exit 0
fi

count=$(echo "$files" | wc -l | tr -d ' ')
echo "mutate:changed: testing ${count} file(s)"

# Stryker's --mutate takes ONE comma-separated value; repeated flags
# overwrite each other (the CLI keeps only the last one), so join the list.
mutate_arg=$(echo "$files" | paste -sd, -)

# --force rather than deleting the incremental file: the cache keys on source
# hashes, so a test-only change (a stronger assertion, same source) replays
# stale verdicts. --force ignores cached statuses and rebuilds the file, and
# unlike `rm -f reports/stryker-incremental.json` it does not hardcode a path
# that `stryker.conf.json` owns via `incrementalFile`.
bunx stryker run --force --mutate "$mutate_arg"
