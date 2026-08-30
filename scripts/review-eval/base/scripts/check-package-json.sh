#!/usr/bin/env bash
#
# Gate: no "latest" / "*" version strings in package.json (rule 19).
set -euo pipefail

violations=$(grep -nE ':[[:space:]]*"(\*|latest)"' package.json || true)

if [ -n "$violations" ]; then
  echo "  forbidden version string in package.json:" >&2
  echo "$violations" >&2
  exit 1
fi
