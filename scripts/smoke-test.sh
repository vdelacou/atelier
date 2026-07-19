#!/usr/bin/env bash
#
# End-to-end smoke test of the atelier skill's shipped assets.
#
# Scaffolds a throwaway Bun repo by following README.md's install steps
# verbatim, extracts the canonical tsconfig.json and eslint.config.js from
# references/bun-typescript.md (so doc drift fails CI, not just asset drift),
# installs the current toolchain UNPINNED (so a new ESLint/TS/Stryker major
# that breaks an asset is caught here first), then proves:
#
#   - every gate passes on a conforming tree (the fast pre-commit hook run
#     end-to-end, plus the CI gates run directly, Stryker included)
#   - every gate FAILS on the violation it exists to block (untested infra
#     file, stale preload, oversized commit, "latest" version, junk commit
#     message)
#
# Run locally: bash scripts/smoke-test.sh
# Run in CI:   .github/workflows/ci.yml
#
# Requires: bun, git, network access for `bun add`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPO_ROOT/skills/atelier"
DOC="$SKILL/references/bun-typescript.md"
FX="$(mktemp -d "${TMPDIR:-/tmp}/atelier-smoke.XXXXXX")"
LOG="$FX/.step.log"
FAILURES=0

cleanup() { rm -rf "$FX"; }
trap cleanup EXIT

pass() { echo "  ok:   $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

expect_ok() {
  local desc="$1"; shift
  if "$@" >"$LOG" 2>&1; then pass "$desc"; else cat "$LOG"; fail "$desc"; fi
}

expect_err() {
  local desc="$1"; shift
  if "$@" >"$LOG" 2>&1; then cat "$LOG"; fail "$desc (expected non-zero exit)"; else pass "$desc"; fi
}

# Print the body of the first fenced code block that follows a markdown heading.
extract_fence() {
  local file="$1" heading="$2"
  awk -v h="$heading" '
    index($0, h) == 1 { found = 1; next }
    found && /^```/ { if (inblock) exit; inblock = 1; next }
    inblock { print }
  ' "$file"
}

echo "== scaffold fixture ($FX) =="
mkdir -p "$FX"/{scripts,.githooks,src/domain/utilities,src/test-helpers,src/infra}
cd "$FX"
git init -q

# --- README install steps, verbatim ---
cp "$SKILL/assets/check-commit-size.sh" "$SKILL/assets/check-package-json.sh" \
   "$SKILL/assets/check-coverage.ts" "$SKILL/assets/regenerate-coverage-preload.ts" \
   "$SKILL/assets/mutate-staged.sh" "$SKILL/assets/mutate-changed.sh" \
   "$SKILL/assets/lint-staged.sh" scripts/
cp "$SKILL/assets/fetch-mock.ts" "$SKILL/assets/capture-rejection.ts" src/test-helpers/
cp "$SKILL/assets/format-error.ts" "$SKILL/assets/format-error.test.ts" src/domain/utilities/
cp "$SKILL/assets/pre-commit" "$SKILL/assets/commit-msg" .githooks/
mkdir -p .github/workflows
cp "$SKILL/assets/ci.yml" .github/workflows/ci.yml
cp "$SKILL/assets/stryker.conf.json" ./
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/*.sh scripts/check-coverage.ts scripts/regenerate-coverage-preload.ts
git config core.hooksPath .githooks

# --- canonical configs, extracted from the reference doc ---
extract_fence "$DOC" '## `tsconfig.json`' > tsconfig.json
extract_fence "$DOC" '## `eslint.config.js`' > eslint.config.js
[ -s tsconfig.json ] || { fail "extract tsconfig.json from bun-typescript.md"; exit 1; }
grep -q 'export default' eslint.config.js || { fail "extract eslint.config.js from bun-typescript.md"; exit 1; }
pass "canonical tsconfig + eslint config extracted from references/bun-typescript.md"

cat > package.json <<'EOF'
{
  "name": "atelier-smoke-fixture",
  "module": "src/main.ts",
  "type": "module",
  "scripts": {
    "lint": "eslint --cache --max-warnings=0",
    "lint:staged": "bash scripts/lint-staged.sh",
    "lint:strict": "LINT_STRICT=1 eslint --max-warnings=0",
    "typecheck": "tsc --noEmit",
    "coverage": "bun run scripts/check-coverage.ts",
    "coverage:preload": "bun run scripts/regenerate-coverage-preload.ts",
    "coverage:preload:check": "bun run scripts/regenerate-coverage-preload.ts --check",
    "mutate": "stryker run",
    "mutate:staged": "bash scripts/mutate-staged.sh",
    "mutate:changed": "bash scripts/mutate-changed.sh"
  }
}
EOF

cat > bunfig.toml <<'EOF'
[test]
coverage = true
coverageSkipTestFiles = true
coverageReporter = ["text"]
EOF

# --- minimal atelier-style source: branded domain + fetch adapter, fully tested ---
cat > src/domain/greeting.ts <<'EOF'
export type Name = string & { readonly __brand: 'Name' };

export const name = (value: string): Name => {
  if (value.trim().length === 0) throw new Error('invalid Name');
  return value as Name;
};

export const greet = (n: Name): string => `Hello, ${n}!`;
EOF

cat > src/domain/greeting.test.ts <<'EOF'
import { expect, test } from 'bun:test';
import { captureRejection } from '../test-helpers/capture-rejection.ts';
import { greet, name } from './greeting.ts';

test('when a visitor gives their name, they are greeted by it', () => {
  expect(greet(name('Ada'))).toBe('Hello, Ada!');
});

test('an empty name is rejected at the trust boundary', async () => {
  expect(() => name(' ')).toThrow('invalid Name');
  const err = await captureRejection(Promise.reject(new Error('invalid Name')));
  expect(err.message).toBe('invalid Name');
});
// formatError is exercised by its own shipped test (format-error.test.ts,
// copied into src/domain/utilities/ alongside format-error.ts above).
EOF

cat > src/infra/fetch-greeting.ts <<'EOF'
import { formatError } from '../domain/utilities/format-error.ts';

export type GreetingResult = { readonly ok: true; readonly text: string } | { readonly ok: false; readonly error: string };
export type FetchGreeting = (visitor: string) => Promise<GreetingResult>;

export const createFetchGreeting = (baseUrl: string): FetchGreeting => async (visitor) => {
  try {
    // user-typed text travels in the body (rule 27); every call carries a deadline (rule 29)
    const response = await fetch(`${baseUrl}/greet`, {
      method: 'POST',
      body: JSON.stringify({ visitor }),
      signal: AbortSignal.timeout(2_000),
    });
    if (!response.ok) return { ok: false, error: `http ${response.status}` };
    return { ok: true, text: await response.text() };
  } catch (e) {
    return { ok: false, error: formatError(e) };
  }
};
EOF

cat > src/infra/fetch-greeting.test.ts <<'EOF'
import { afterEach, expect, test } from 'bun:test';
import { installFetchMock } from '../test-helpers/fetch-mock.ts';
import { createFetchGreeting } from './fetch-greeting.ts';

let mock: ReturnType<typeof installFetchMock> | undefined;
afterEach(() => mock?.restore());

test('when the greeting service responds, the adapter returns its text', async () => {
  mock = installFetchMock([{ match: (url) => url.includes('/greet'), respond: () => new Response('Hello, Ada!') }]);
  expect(await createFetchGreeting('https://svc.test')('Ada')).toEqual({ ok: true, text: 'Hello, Ada!' });
  expect(mock.calls).toHaveLength(1);
});

test('when the service answers 500, the adapter reports the status', async () => {
  mock = installFetchMock([{ match: () => true, respond: () => new Response('', { status: 500 }) }]);
  expect(await createFetchGreeting('https://svc.test')('Ada')).toEqual({ ok: false, error: 'http 500' });
});

test('when the connection dies, the adapter translates the throw', async () => {
  mock = installFetchMock([{ match: () => true, respond: () => { throw new Error('ECONNREFUSED'); } }]);
  expect(await createFetchGreeting('https://svc.test')('Ada')).toEqual({ ok: false, error: 'ECONNREFUSED' });
});
EOF

echo "== install current toolchain (unpinned — new majors are the point) =="
# typescript is the one deliberate exception to unpinned: the canonical skeleton
# pins "typescript": "^5.0.0", and eslint-plugin-sonarjs (<= 4.1.0) crashes at
# rule load under TypeScript 7 (reads ts.SyntaxKind at module scope; TS 7's
# module shape breaks the CJS default-export interop). Caught by this test on
# 2026-07-12. Lift the pin when sonarjs supports TS 7. The weekly canary
# workflow overrides SMOKE_TS_SPEC=typescript to probe whether it can be lifted.
expect_ok "bun add -d toolchain" bun add -d eslint @eslint/js globals typescript-eslint \
  eslint-plugin-security eslint-plugin-sonarjs eslint-plugin-unicorn eslint-plugin-prettier \
  prettier "${SMOKE_TS_SPEC:-typescript@^5}" @types/bun @stryker-mutator/core

# The four fixture-authored files above are test scaffolding, not shipped assets —
# normalise THEIR formatting only, so a formatting regression in a shipped asset
# still fails the lint step below.
bunx eslint --fix src/domain/greeting.ts src/domain/greeting.test.ts \
  src/infra/fetch-greeting.ts src/infra/fetch-greeting.test.ts >/dev/null 2>&1 || true

echo "== positive path: every gate green on a conforming tree =="
expect_ok "regenerate coverage preload" bun run scripts/regenerate-coverage-preload.ts
expect_ok "preload --check in sync" bun run scripts/regenerate-coverage-preload.ts --check
expect_ok "bun test" bun test
expect_ok "lint (fast)" bun run lint
expect_ok "lint:strict (type-aware)" bun run lint:strict
expect_ok "typecheck" bun run typecheck
expect_ok "coverage gate" bun run coverage

echo "== negative paths: each gate blocks the violation it exists for =="
cat > src/infra/orphan.ts <<'EOF'
export const orphan = (n: number): number => n * 2;
EOF
bun run scripts/regenerate-coverage-preload.ts >/dev/null
expect_err "coverage gate rejects untested infra file" bun run coverage
rm src/infra/orphan.ts
bun run scripts/regenerate-coverage-preload.ts >/dev/null

echo '// stale' >> scripts/coverage-preload.ts
expect_err "preload --check rejects stale preload" bun run scripts/regenerate-coverage-preload.ts --check
bun run scripts/regenerate-coverage-preload.ts >/dev/null

git add -A
expect_err "commit-size gate rejects oversized stage" bash scripts/check-commit-size.sh
git reset -q
git add package.json bunfig.toml
expect_ok "commit-size gate accepts small stage" bash scripts/check-commit-size.sh
git reset -q

expect_ok "package.json gate accepts pinned deps" bash scripts/check-package-json.sh
python3 - <<'EOF'
import json
p = json.load(open('package.json'))
p['dependencies'] = {'left-pad': 'latest'}
json.dump(p, open('package.json', 'w'), indent=2)
EOF
expect_err "package.json gate rejects \"latest\"" bash scripts/check-package-json.sh
python3 - <<'EOF'
import json
p = json.load(open('package.json'))
del p['dependencies']
json.dump(p, open('package.json', 'w'), indent=2)
EOF

check_msg() { printf '%s\n' "$1" > .msg; bash .githooks/commit-msg .msg; }
expect_ok  "commit-msg accepts feat(scope)!: subject" check_msg "feat(auth)!: rotate refresh tokens"
expect_ok  "commit-msg accepts plain fix:" check_msg "fix: guard empty cart"
expect_ok  "commit-msg exempts merge commits" check_msg "Merge branch 'main' into feature"
expect_ok  "commit-msg exempts revert commits" check_msg "Revert \"feat: x\""
expect_err "commit-msg rejects junk" check_msg "updated stuff"
expect_err "commit-msg rejects unlisted type" check_msg "wip: half done"
expect_err "commit-msg rejects capitalised type" check_msg "Feat: x"
expect_err "commit-msg rejects trailing period" check_msg "feat: add thing."
expect_err "commit-msg rejects >100-char header" check_msg "feat: $(printf 'x%.0s' $(seq 1 120))"
rm -f .msg

echo "== discipline tripwires (rules 27-30, staged-diff guards) =="
cp "$SKILL/assets/check-pii-channels.sh" "$SKILL/assets/check-io-deadlines.sh" \
   "$SKILL/assets/check-data-lifecycle.sh" "$SKILL/assets/check-isolation-tests.sh" scripts/
chmod +x scripts/check-pii-channels.sh scripts/check-io-deadlines.sh scripts/check-data-lifecycle.sh scripts/check-isolation-tests.sh
mkdir -p src/use-cases

printf 'export const s = async (u: { email: string }) => fetch(`/search?email=${u.email}`);\n' > src/use-cases/leak.ts
git add src/use-cases/leak.ts
expect_err "pii guard blocks an email in a query string" bash scripts/check-pii-channels.sh
git reset -q && rm src/use-cases/leak.ts

printf 'export const s = async (u: { email: string }) => fetch(`/search?${new URLSearchParams({ email: u.email })}`);\n' > src/use-cases/leak-params.ts
git add src/use-cases/leak-params.ts
expect_err "pii guard blocks email built into a query via URLSearchParams" bash scripts/check-pii-channels.sh
git reset -q && rm src/use-cases/leak-params.ts

printf 'export const s = async (u: { email: string }) => fetch("/search", { method: "POST", body: JSON.stringify({ email: u.email }) });\n' > src/use-cases/post-body.ts
git add src/use-cases/post-body.ts
expect_ok "pii guard passes email carried in a POST body" bash scripts/check-pii-channels.sh
git reset -q && rm src/use-cases/post-body.ts

printf 'export const f = (): Promise<Response> => fetch("https://svc.test/x");\n' > src/infra/no-deadline.ts
git add src/infra/no-deadline.ts
expect_err "deadline guard blocks fetch without a deadline marker" bash scripts/check-io-deadlines.sh
git reset -q && rm src/infra/no-deadline.ts
git add src/infra/fetch-greeting.ts
expect_ok "deadline guard passes the conforming adapter" bash scripts/check-io-deadlines.sh
git reset -q

printf 'export const rm = async (id: string): Promise<void> => { await db.delete(orders); };\n' > src/use-cases/hard-delete.ts
git add src/use-cases/hard-delete.ts
expect_err "lifecycle guard blocks a hard delete" bash scripts/check-data-lifecycle.sh
git reset -q && rm src/use-cases/hard-delete.ts

mkdir -p src/infra/http
printf 'export const route = (orgId: string): string => orgId;\n' > src/infra/http/invoices.ts
git add src/infra/http/invoices.ts
expect_err "isolation guard blocks a route without a 404 test" bash scripts/check-isolation-tests.sh
printf 'import { test, expect } from "bun:test";\ntest("cross-tenant read is not_found", () => { expect(404).toBe(404); });\n' > src/infra/http/invoices.test.ts
git add src/infra/http/invoices.test.ts
expect_ok "isolation guard passes once the 404 test is staged" bash scripts/check-isolation-tests.sh
git reset -q && rm -rf src/infra/http

echo "== fast pre-commit hook end-to-end (the 5 fast gates: size, package.json, gitleaks, lint:staged, typecheck) =="
git add package.json src/domain/greeting.ts src/domain/greeting.test.ts
expect_ok "fast pre-commit hook end-to-end" bash .githooks/pre-commit

echo "== CI-only gates run directly (the full suite, coverage, and mutation are CI's job, not the hook's) =="
expect_ok "mutation gate (Stryker on the staged domain file)" bun run mutate:staged
expect_ok "ci.yml asset is present" test -f .github/workflows/ci.yml
expect_ok "ci.yml wires the package.json gate" grep -q "check-package-json.sh" .github/workflows/ci.yml
expect_ok "ci.yml runs the full suite, coverage, and mutation" bash -c 'grep -q "bun test" .github/workflows/ci.yml && grep -q "bun run coverage" .github/workflows/ci.yml && grep -q "mutate" .github/workflows/ci.yml'

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "smoke-test: $FAILURES check(s) FAILED"
  exit 1
fi
echo "smoke-test: all checks passed"
