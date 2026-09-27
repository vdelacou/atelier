#!/usr/bin/env bash
#
# Weekly canary (upstream only, not a shipped asset): can Oxlint replace ESLint with every
# function kept? Run by .github/workflows/canary.yml. One line per gap; exit 0 on any valid
# reading, 1 when a control fails (then the probe is broken, not the gap).
#
# The 2026-09-27 side-by-side (oxlint 1.85.0, the Bun and Next smoke trees, every smoke fixture
# through both linters) matched ESLint on everything but the two gaps watched here:
#   1. Rule 15. Oxlint has no noInlineConfig (oxc-project/oxc#15173): `/* eslint-disable */` or
#      `/* oxlint-disable */` silently switches every ban off in its file.
#      `respectEslintDisableDirectives: false` makes the eslint-* form inert, never the oxlint-*.
#   2. JS plugins get no type information, so the sonarjs rules that need it go silent: 57 of
#      the 231 in sonarjs's recommended set (three are off already), no-alphabetical-sort among them.
# What matched: every native rule the two configs use (complexity, the mock ban and the layer
# zones, ban-ts-comment, no-warning-comments, the typescript, jsx-a11y, react with the React
# Compiler rules, nextjs and import rules), the no-restricted-syntax selector bans through the
# oxlint-plugin-eslint JS plugin, security, sonarjs (untyped), prettier and tailwind as JS plugins,
# and the typed typescript-eslint rules through --type-aware. Traps for the day both gaps close:
# @oxlint/migrate drops every per-block `ignores` (add `excludeFiles` by hand, or the layer zones
# hit the tests), drops noInlineConfig without a warning and drops no-restricted-syntax; Oxlint
# lints node_modules unless a .gitignore names it; the speed gain was small (Bun fast lane 16s to
# 9s, strict 23s to 14s, Next 15s to 15s) because the JS plugins still run in JavaScript.
#
# Each reading carries its own controls, so "open" can only mean the gap: the plain file must
# report no-console, JS plugins must load, types must flow. The gap-1 verdict is also run on a
# stand-in that is closed today (the eslint-* form under respectEslintDisableDirectives: false),
# which proves it can read closed through the real tool.
#
#   bash scripts/oxlint-parity-probe.sh     (needs bun, and Node 20.19+ or 22.12+ for Oxlint's engines)

set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/atelier-oxlint-probe.XXXXXX")"
trap 'rm -rf "${WORK:?}"' EXIT
cd "$WORK"

SUMMARY=()
say() { echo "  $1"; SUMMARY+=("$1"); }
finish() { # $1 exit status
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    { echo "### Oxlint parity probe (${VERSIONS:-versions unknown})"; printf -- '- %s\n' "${SUMMARY[@]}"; } >> "$GITHUB_STEP_SUMMARY"
  fi
  exit "$1"
}
broken() { say "BROKEN: $1"; if [ -f last.log ]; then sed 's/^/    /' last.log; fi; finish 1; }

# Unpinned on purpose: the newest Oxlint is the point. typescript stays on the canonical ^5 pin
# (eslint-plugin-sonarjs crashes under TypeScript 7; the unpinned-typescript job watches that).
echo '{ "name": "oxlint-parity-probe", "private": true, "type": "module" }' > package.json
bun add -d oxlint oxlint-tsgolint eslint-plugin-sonarjs 'typescript@^5' > last.log 2>&1 || broken "install"
version() { node -p "require('./node_modules/$1/package.json').version"; }
VERSIONS="oxlint $(version oxlint), oxlint-tsgolint $(version oxlint-tsgolint), eslint-plugin-sonarjs $(version eslint-plugin-sonarjs)"
echo "== Oxlint parity probe ($VERSIONS) =="

mkdir src
cat > tsconfig.json <<'EOF'
{ "compilerOptions": { "strict": true, "target": "ESNext", "module": "ESNext", "moduleResolution": "bundler", "noEmit": true, "skipLibCheck": true } }
EOF
cat > src/plain.ts <<'EOF'
export const shout = (s: string): void => {
  console.log(s);
};
EOF
{ echo '/* eslint-disable */'; cat src/plain.ts; } > src/eslint-directive.ts
{ echo '/* oxlint-disable */'; cat src/plain.ts; } > src/oxlint-directive.ts
cat > src/sort.ts <<'EOF'
export const sorted = (xs: readonly number[]): number[] => [...xs].sort();
EOF
cat > src/twins.ts <<'EOF'
export const first = (n: number): number => {
  const doubled = n * 2;
  const shifted = doubled + 1;
  return shifted * 3;
};
export const second = (n: number): number => {
  const doubled = n * 2;
  const shifted = doubled + 1;
  return shifted * 3;
};
EOF

# lint <config json> [oxlint args and files]: one run, its unix-format output in last.log. The
# exit status is not read: 1 means findings, and a crash shows up as a missing control finding.
lint() { printf '%s\n' "$1" > cfg.json; shift; bunx oxlint -c cfg.json --format unix "$@" > last.log 2>&1 || true; }
# reported <file> <code>: the last run reported <code> on <file>.
reported() { grep -F -- "$1:" last.log | grep -qF -- "/$2]"; }

# Gap 1 verdict for an `options` object: the plain file is the control, and every directive
# file must still report no-console for the directives to count as inert.
inline_verdict() { # $1 options json, then the directive files
  local options="$1" f silenced=""; shift
  lint "{ \"options\": $options, \"rules\": { \"no-console\": \"error\" } }" src/plain.ts "$@"
  if grep -q 'unknown field' last.log; then echo "unknown"; return; fi
  reported src/plain.ts 'eslint(no-console)' || { echo "broken"; return; }
  for f in "$@"; do reported "$f" 'eslint(no-console)' || silenced="$silenced ${f#src/}"; done
  if [ -z "$silenced" ]; then echo "closed"; else echo "silenced:$silenced"; fi
}

v=$(inline_verdict '{ "respectEslintDisableDirectives": false }' src/eslint-directive.ts)
[ "$v" = "closed" ] || broken "the stand-in (eslint-disable under respectEslintDisableDirectives: false) read '$v', not closed"

v=$(inline_verdict '{ "noInlineConfig": true }' src/eslint-directive.ts src/oxlint-directive.ts)
case "$v" in
  closed) gap1=closed; say "PROBE: gap 1 closed: options.noInlineConfig makes eslint-disable and oxlint-disable inert (rule 15 holds)." ;;
  broken) broken "the plain file did not report no-console" ;;
  unknown)
    gap1=open
    # A differently named option would read open forever, so name any option this probe has not seen.
    known=' typeAware typeCheck denyWarnings maxWarnings reportUnusedDisableDirectives respectEslintDisableDirectives '
    new=""
    for o in $(sed -n 's/.*expected one of \([^"]*\).*/\1/p' last.log | grep -oE '[A-Za-z]+'); do
      case "$known" in *" $o "*) ;; *) new="$new $o" ;; esac
    done
    say "probe: gap 1 open: options.noInlineConfig is an unknown field, a disable directive still switches rules off (rule 15)."
    [ -z "$new" ] || say "PROBE: options Oxlint did not have on 2026-09-27:$new. Check by hand whether one closes gap 1."
    ;;
  *) gap1=open; say "probe: gap 1 open: options.noInlineConfig is accepted, but these directives still switch no-console off:${v#silenced:}." ;;
esac

# Gap 2: one type-aware run. twins.ts proves the JS plugin loads and reports, sort.ts's
# typescript finding proves types flow and the fixture is a real violation; the sonarjs
# finding on sort.ts is the reading.
lint '{ "jsPlugins": ["eslint-plugin-sonarjs"], "rules": { "sonarjs/no-identical-functions": "error", "sonarjs/no-alphabetical-sort": "error", "typescript/require-array-sort-compare": "error" } }' \
  --type-aware src/twins.ts src/sort.ts
reported src/twins.ts 'sonarjs(no-identical-functions)' || broken "sonarjs did not load as a JS plugin (no-identical-functions silent on twins.ts)"
reported src/sort.ts 'typescript(require-array-sort-compare)' || broken "types did not flow (require-array-sort-compare silent on sort.ts)"
if reported src/sort.ts 'sonarjs(no-alphabetical-sort)'; then
  gap2=closed; say "PROBE: gap 2 closed: a typed sonarjs rule (no-alphabetical-sort) fires through JS plugins under --type-aware."
else
  gap2=open; say "probe: gap 2 open: JS plugins still get no type information (sonarjs/no-alphabetical-sort silent under --type-aware)."
fi

if [ "$gap1" = closed ] && [ "$gap2" = closed ]; then
  say "PROBE: both gaps closed. Rerun the side-by-side (every smoke fixture through both linters, this header's traps) before switching."
fi
finish 0
