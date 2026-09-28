#!/usr/bin/env bash
#
# Smoke helper: the shipped .gitattributes (assets/gitattributes) keeps a checkout LF under
# Git for Windows' system-wide core.autocrlf=true. Each smoke test calls it on the
# .gitattributes its fixture copied, as its variant's bootstrap checklist says.
#
# It clones a two-file repo twice under a planted system and global config that sets
# core.autocrlf=true. Without the file the checkout must be CRLF: the red case, so a git that
# ignores GIT_CONFIG_SYSTEM (older than 2.32) cannot pass this vacuously. With it, a
# TypeScript file must be LF and a Windows batch file CRLF.
#
#   bash scripts/smoke-eol-checkout.sh <path-to-.gitattributes>
set -euo pipefail

attrs="${1:?usage: smoke-eol-checkout.sh <path-to-.gitattributes>}"
[ -f "$attrs" ] || { echo "smoke-eol-checkout: no $attrs" >&2; exit 1; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf '[core]\n\tautocrlf = true\n' > "$work/autocrlf.gitconfig"

# $1: with | without the .gitattributes. Leaves the checkout in $work/$1-clone.
checkout() {
  local repo="$work/$1"
  mkdir -p "$repo"
  printf 'export const a = 1;\n' > "$repo/a.ts"
  printf '@echo off\n' > "$repo/b.cmd"
  if [ "$1" = with ]; then cp "$attrs" "$repo/.gitattributes"; fi
  git -C "$repo" init -q
  git -C "$repo" add -A
  git -C "$repo" -c user.name=smoke -c user.email=smoke@example.invalid commit -qm fixture
  GIT_CONFIG_SYSTEM="$work/autocrlf.gitconfig" GIT_CONFIG_GLOBAL="$work/autocrlf.gitconfig" \
    git clone -q "file://$repo" "$work/$1-clone"
}
crs() { tr -cd '\r' < "$1" | wc -c | tr -d ' '; }

checkout without
checkout with
if [ "$(crs "$work/without-clone/a.ts")" -eq 0 ]; then
  echo "smoke-eol-checkout: without .gitattributes the checkout was LF, so the planted core.autocrlf=true did not take; this run proves nothing" >&2
  exit 1
fi
if [ "$(crs "$work/with-clone/a.ts")" -ne 0 ]; then
  echo "smoke-eol-checkout: with $attrs a TypeScript file still checked out CRLF" >&2
  exit 1
fi
if [ "$(crs "$work/with-clone/b.cmd")" -eq 0 ]; then
  echo "smoke-eol-checkout: with $attrs a .cmd file checked out LF; cmd.exe wants CRLF" >&2
  exit 1
fi
echo "smoke-eol-checkout: CRLF without the file; with it, LF text and a CRLF batch file"
