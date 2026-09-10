#!/usr/bin/env bash
#
# Rule 26 tripwire: identity lives in commit metadata, never in file contents.
#
# Checks the STAGED ADDED LINES (like gitleaks protect --staged), so it blocks
# a mention entering history without flooding a brownfield tree. `--all` scans
# every tracked text file instead (CI, and the adopt-mode audit).
#
# What it looks for, case-insensitively, as whole words:
#   - the committer's full name, in both orders (git config user.name)
#   - the committer's email (git config user.email)
#   - under --all, every author and committer name and email in the history
#   - every entry of IDENTITY_DENYLIST (newline- or comma-separated: employer
#     and client names). An environment variable, never a tracked file, since a
#     tracked denylist would itself name what the rule forbids.
# A one-word git name is a handle, which rule 26 permits, and is skipped; so is
# a GitHub noreply address (<handle>@users.noreply.github.com). CODEOWNERS and
# .mailmap are exempt: rule 26 names them as the two places a person belongs.
# A lone first name stays a review duty: a one-word match would flag "will"
# and "grace" in prose.
#
# This is a tripwire, not a proof. A hit is a hard stop; the fix is a neutral
# handle, never an inline suppression (rule 15).
#
#   bash scripts/check-identity.sh          # staged added lines (the hook)
#   bash scripts/check-identity.sh --all    # every tracked text file (CI, adopt audit)

set -euo pipefail

MODE="${1:-staged}"

# The identity set: one string per line, trimmed, at least four characters.
# Git names count only with a space in them (a one-word name is a handle);
# emails count unless they are GitHub noreply handles; denylist entries always.
identities() {
  {
    { git config user.name 2>/dev/null || true; } | awk '/ /'
    git config user.email 2>/dev/null || true
    if [ "$MODE" = "--all" ]; then
      { git log --format='%an%n%cn' 2>/dev/null || true; } | awk '/ /'
      git log --format='%ae%n%ce' 2>/dev/null || true
    fi
    printf '%s\n' "${IDENTITY_DENYLIST:-}" | tr ',' '\n'
  } | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v -i '@users\.noreply\.github\.com$' \
    | awk 'length($0) >= 4' | sort -u
}

# A multi-word name in both orders: "First Last" and "Last First".
patterns() {
  identities | while IFS= read -r id; do
    printf '%s\n' "$id"
    case "$id" in
      *" "*) printf '%s %s\n' "${id#* }" "${id%% *}" ;;
    esac
  done | sort -u
}

# One stream of `path: content` (staged) or `path:N:content` (--all) lines,
# CODEOWNERS and .mailmap dropped, binaries skipped.
lines() {
  if [ "$MODE" = "--all" ]; then
    git ls-files -z | xargs -0 grep -I -H -n '' 2>/dev/null \
      | awk -F: '$1 !~ /(^|\/)(CODEOWNERS|\.mailmap)$/' || true
  else
    git diff --cached -U0 --diff-filter=ACMR \
      | awk '/^\+\+\+ b\//{f=substr($0,7)} /^\+[^+]/{print f": "substr($0,2)}' \
      | awk -F': ' '$1 !~ /(^|\/)(CODEOWNERS|\.mailmap)$/' || true
  fi
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
patterns > "$tmp"
if [ ! -s "$tmp" ]; then
  echo "check-identity: no identity to look for (git config user.name/user.email unset and IDENTITY_DENYLIST empty)" >&2
  exit 0
fi

hits="$(lines | grep -F -i -w -f "$tmp" || true)"
if [ -n "$hits" ]; then
  echo "check-identity: a person, employer, or client is named in file contents (hard rule 26):" >&2
  printf '%s\n' "$hits" | sed 's/^/  /' >&2
  echo "  fix: a neutral handle in file contents; CODEOWNERS and .mailmap are where a person belongs (references/workflow.md, Commit identity)" >&2
  exit 1
fi
echo "check-identity: ok ($MODE)"
