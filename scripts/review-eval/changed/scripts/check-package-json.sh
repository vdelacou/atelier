#!/usr/bin/env bash
#
# Gate: no "latest" / "*" version strings in package.json (rule 19).
#
# Widened to bare dist-tags too, and to every workspace manifest, not just the
# root one.
set -euo pipefail

manifests=$(find . -name package.json -not -path '*/node_modules/*' | sort)

violations=$(echo "$manifests" | tr '\n' '\0' | xargs -0 grep -nHE ':[[:space:]]*"(\*|latest|beta|alpha|next|canary|rc)"' || true)

if [ -n "$violations" ]; then
  echo "  forbidden version string in a package.json:" >&2
  echo "$violations" >&2
  exit 1
fi
