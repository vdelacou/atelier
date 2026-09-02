#!/usr/bin/env bash
#
# Block commits if package.json declares any version as "latest" or "*".
#
# Why: "latest" / "*" are non-deterministic, `bun install` on different
# days produces different node_modules trees. The lockfile only partially
# helps, and the literal string semantically signals "always upgrade",
# which is a silent-break footgun.
#
# Add new packages with `bun add <pkg>` (runtime) or `bun add -d <pkg>`
# (dev). Bun resolves the actual latest at install time and pins it as
# `^X.Y.Z`. To bump everything to current latest deliberately, run
# `bun update` and commit the lockfile change in the same commit.
#
# See skills/atelier/references/workflow.md (Dependency hygiene) and
# SKILL.md hard rule 19.

set -euo pipefail

# Every manifest in the repo, not just the root one: in a monorepo the
# dependencies live in apps/* and packages/*, so a root-only read passes a
# repo whose workspaces pin "latest" (found in a real consumer repo,
# 2026-08-30 field test). node_modules and .git are excluded.
manifests=$(find . -name package.json -not -path '*/node_modules/*' -not -path '*/.git/*' | sort)

if [ -z "$manifests" ]; then
  exit 0
fi

# Match a VALUE position (after the colon) equal to the bare strings
# "latest", "*", or a bare dist-tag ("beta", "alpha", "next", "canary",
# "rc"), or an npm: alias resolving to one, all non-deterministic in
# exactly the way rule 19 bans. Only the four dependency blocks are read, so
# a version-shaped value elsewhere (publishConfig.tag: "next", an engines
# field, a script) is not a finding (a false positive found 2026-09-02).
# Catches:  "any-pkg": "latest",   "x": "*",   "plugin": "beta",   "a": "npm:b@latest"
# Permits:  "x": "^1.2.3" / "~1.2.3" / ">=1.0.0" / "^4.0.0-beta.0",  "next": "16.1.1"
violations=$(echo "$manifests" | tr '\n' '\0' | xargs -0 awk '
  BEGIN { V = ":[[:space:]]*\"(\\*|latest|beta|alpha|next|canary|rc|npm:[^\"]*@(latest|\\*))\"" }
  FNR == 1 { inblock = 0 }
  {
    s = $0
    while (match(s, /"(dependencies|devDependencies|peerDependencies|optionalDependencies)"[[:space:]]*:[[:space:]]*\{/)) {
      rest = substr(s, RSTART + RLENGTH)
      close_at = index(rest, "}")
      if (close_at > 0) {                         # a one-line block: test just its body
        if (substr(rest, 1, close_at) ~ V) print FILENAME ":" FNR ":" $0
        s = substr(rest, close_at + 1); continue
      }
      inblock = 1; s = ""                         # a multi-line block opens here
    }
    if (!inblock) next
    if ($0 ~ /^[[:space:]]*\}/) { inblock = 0; next }
    if ($0 ~ V) print FILENAME ":" FNR ":" $0
  }' || true)

if [ -z "$violations" ]; then
  exit 0
fi

cat <<EOF >&2
  ╳ a package.json declares a forbidden version string ("latest", "*", or a bare dist-tag):

$(echo "$violations" | sed 's/^/      /')

  Atelier rule 19: every dependency declares a concrete version or range.
  Fix:
    - Replace each "latest" / "*" / bare dist-tag with the actual installed
      version (a pre-release pin like "^4.0.0-beta.0" is fine; bare "beta" is not).
    - For new packages, use \`bun add <pkg>\` (or \`bun add -d <pkg>\`)
      instead of hand-editing: Bun pins to ^X.Y.Z automatically.
    - To bump everything to current latest, run \`bun update\` and commit
      the lockfile change in the same commit.

  Bypass (rare): git commit --no-verify, with justification in commit body.
EOF
exit 1
