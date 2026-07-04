#!/usr/bin/env bash
#
# End-to-end smoke test of the atelier Next.js variant.
#
# Scaffolds a throwaway Next.js package from the canonical configs extracted
# straight out of references/nextjs-monorepo.md (so doc drift fails CI, not just
# a hand-copied snapshot), installs the current toolchain, and proves:
#
#   - a conforming design system (atom -> molecule -> organism, props-only),
#     a page shell wiring build-time data through a test-driven src/lib function,
#     and a static export all pass test / lint / typecheck / build
#   - the design-system lint block CATCHES the violations it exists for:
#       rule 21 — a hook, a next/* import, 'use client', an app-code import
#                 inside a component
#       rule 22 — a className / class / style attribute outside src/components/**
#
# The negative half is the point: it locks in the rules 21-22 enforcement so a
# future ESLint / Next / typescript-eslint major cannot silently disable it.
#
# Run locally: bash scripts/smoke-test-next.sh
# Requires: bun, network access for `bun install`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOC="$REPO_ROOT/skills/atelier/references/nextjs-monorepo.md"
FX="$(mktemp -d "${TMPDIR:-/tmp}/atelier-next-smoke.XXXXXX")"
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

# Print the body of the first fenced code block following a markdown heading.
extract_fence() {
  local file="$1" heading="$2"
  awk -v h="$heading" '
    index($0, h) == 1 { found = 1; next }
    found && /^```/ { if (inblock) exit; inblock = 1; next }
    inblock { print }
  ' "$file"
}

echo "== scaffold Next.js fixture ($FX) =="
mkdir -p "$FX"/{app,src/components/atoms,src/components/molecules,src/components/organisms,src/page,src/lib}
cd "$FX"

# --- canonical configs, extracted from the reference doc ---
extract_fence "$DOC" '## `tsconfig.json`'       > tsconfig.json
extract_fence "$DOC" '## `eslint.config.mjs`'   > eslint.config.mjs
extract_fence "$DOC" '## `postcss.config.mjs`'  > postcss.config.mjs
extract_fence "$DOC" '## `next.config.ts`'      > next.config.ts
grep -q 'export default eslintConfig' eslint.config.mjs || { fail "extract eslint.config.mjs"; exit 1; }
grep -q 'allowImportingTsExtensions' tsconfig.json || { fail "tsconfig missing allowImportingTsExtensions (doc drift)"; exit 1; }
grep -q "name.name='className'" eslint.config.mjs || { fail "eslint config missing the rule-22 className ban (doc drift)"; exit 1; }
pass "canonical tsconfig + eslint.config.mjs + postcss + next.config extracted from the reference"

cat > package.json <<'EOF'
{
  "name": "atelier-next-smoke-fixture",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "rimraf out && bun next build",
    "test": "bun test",
    "typecheck": "tsc --noEmit",
    "lint": "eslint --max-warnings=0"
  },
  "dependencies": { "next": "16.1.1", "react": "19.2.3", "react-dom": "19.2.3" },
  "devDependencies": {
    "@eslint/js": "^9.39.2",
    "@tailwindcss/postcss": "^4.1.18",
    "@types/bun": "^1.2.0",
    "@types/node": "^20.19.27",
    "@types/react": "^19.2.7",
    "@types/react-dom": "^19.2.3",
    "eslint": "^9.39.2",
    "eslint-config-next": "16.1.1",
    "eslint-plugin-jsx-a11y": "^6.10.2",
    "eslint-plugin-prettier": "^5.5.4",
    "eslint-plugin-react": "^7.37.5",
    "eslint-plugin-react-hooks": "^7.0.1",
    "eslint-plugin-security": "^3.0.1",
    "eslint-plugin-tailwindcss": "^4.0.2",
    "eslint-plugin-unicorn": "^61.0.2",
    "globals": "^17.0.0",
    "rimraf": "^6.1.2",
    "tailwindcss": "^4.1.18",
    "typescript": "^5.9.3",
    "typescript-eslint": "^8.51.0"
  },
  "trustedDependencies": ["sharp", "unrs-resolver"]
}
EOF

printf 'node_modules/\n.next/\nout/\n.eslintcache\nnext-env.d.ts\n' > .gitignore

cat > app/globals.css <<'EOF'
@import 'tailwindcss';

@theme {
  --color-up: oklch(0.72 0.19 145);
  --color-down: oklch(0.63 0.24 27);
  --color-flat: oklch(0.55 0.02 260);
}
EOF

cat > app/layout.tsx <<'EOF'
import type { ReactNode } from 'react';
import './globals.css';

export const metadata = { title: 'Atelier Next Smoke' };

const RootLayout = ({ children }: { readonly children: ReactNode }): ReactNode => (
  <html lang="en">
    <body>{children}</body>
  </html>
);

export default RootLayout;
EOF

cat > app/page.tsx <<'EOF'
import type { ReactNode } from 'react';
import { HomeShell } from '@/src/page/home-shell.tsx';

const Page = (): ReactNode => <HomeShell />;

export default Page;
EOF

# --- design system: props-only, styling sealed inside ---
cat > src/components/atoms/badge.tsx <<'EOF'
import type { ReactNode } from 'react';

export type Tone = 'up' | 'down' | 'flat';
export type BadgeProps = { readonly label: string; readonly tone: Tone };

const toneClass: Record<Tone, string> = {
  up: 'bg-up/15 text-up',
  down: 'bg-down/15 text-down',
  flat: 'bg-flat/15 text-flat',
};

export const Badge = ({ label, tone }: BadgeProps): ReactNode => (
  <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${toneClass[tone]}`}>{label}</span>
);
EOF

cat > src/components/molecules/stat-card.tsx <<'EOF'
import type { ReactNode } from 'react';
import { Badge } from '../atoms/badge.tsx';
import type { Tone } from '../atoms/badge.tsx';

export type StatCardProps = { readonly title: string; readonly value: string; readonly delta: string; readonly tone: Tone };

export const StatCard = ({ title, value, delta, tone }: StatCardProps): ReactNode => (
  <article className="flex flex-col gap-1 rounded-xl border border-flat/20 p-4">
    <h3 className="text-sm text-flat">{title}</h3>
    <p className="text-2xl font-semibold tabular-nums">{value}</p>
    <Badge label={delta} tone={tone} />
  </article>
);
EOF

cat > src/components/organisms/stats-panel.tsx <<'EOF'
import type { ReactNode } from 'react';
import { StatCard } from '../molecules/stat-card.tsx';
import type { StatCardProps } from '../molecules/stat-card.tsx';

export type StatsPanelProps = { readonly heading: string; readonly stats: ReadonlyArray<StatCardProps & { readonly key: string }> };

export const StatsPanel = ({ heading, stats }: StatsPanelProps): ReactNode => (
  <section className="mx-auto flex max-w-3xl flex-col gap-4 px-6 py-12">
    <h2 className="text-lg font-bold">{heading}</h2>
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
      {stats.map((stat) => (
        <StatCard key={stat.key} title={stat.title} value={stat.value} delta={stat.delta} tone={stat.tone} />
      ))}
    </div>
  </section>
);
EOF

# --- src/lib logic: test-driven, pure ---
cat > src/lib/format-percent.ts <<'EOF'
export type Direction = 'up' | 'down' | 'flat';
export type FormattedDelta = { readonly text: string; readonly direction: Direction };

export const formatPercent = (ratio: number): FormattedDelta => {
  const rounded = Math.round(ratio * 1000) / 10;
  if (rounded > 0) return { text: `+${rounded}%`, direction: 'up' };
  if (rounded < 0) return { text: `${rounded}%`, direction: 'down' };
  return { text: '0%', direction: 'flat' };
};
EOF

cat > src/lib/format-percent.test.ts <<'EOF'
import { describe, expect, test } from 'bun:test';
import { formatPercent } from './format-percent.ts';

describe('formatting a growth ratio for display', () => {
  test('a positive ratio reads as an up delta with a plus sign', () => {
    expect(formatPercent(0.125)).toEqual({ text: '+12.5%', direction: 'up' });
  });
  test('a negative ratio keeps its sign and reads as down', () => {
    expect(formatPercent(-0.031)).toEqual({ text: '-3.1%', direction: 'down' });
  });
  test('a flat ratio reads as zero', () => {
    expect(formatPercent(0)).toEqual({ text: '0%', direction: 'flat' });
  });
});
EOF

# --- page shell: owns data, no styling ---
cat > src/page/home-shell.tsx <<'EOF'
import type { ReactNode } from 'react';
import { StatsPanel } from '@/src/components/organisms/stats-panel.tsx';
import { formatPercent } from '@/src/lib/format-percent.ts';

const RAW_STATS = [
  { key: 'revenue', title: 'Revenue', value: '€1.28M', ratio: 0.125 },
  { key: 'churn', title: 'Churn', value: '2.1%', ratio: -0.031 },
  { key: 'nps', title: 'NPS', value: '52', ratio: 0 },
] as const;

export const HomeShell = (): ReactNode => {
  const stats = RAW_STATS.map((raw) => {
    const delta = formatPercent(raw.ratio);
    return { key: raw.key, title: raw.title, value: raw.value, delta: delta.text, tone: delta.direction };
  });
  return (
    <main>
      <StatsPanel heading="This quarter" stats={stats} />
    </main>
  );
};
EOF

echo "== install current Next.js toolchain =="
expect_ok "bun install" bun install

echo "== positive path: a conforming package passes every gate =="
expect_ok "bun test (src/lib TDD gate)" bun test
expect_ok "eslint (design system + shell clean)" bun run lint
expect_ok "tsc --noEmit" bun run typecheck
expect_ok "next build (static export)" env NODE_ENV=production bun run build

echo "== negative path: rule 21 — the design-system block rejects app knowledge in a component =="
cat > src/components/atoms/bad-widget.tsx <<'EOF'
'use client';
import { useState } from 'react';
import Link from 'next/link';
import type { ReactNode } from 'react';
import { formatPercent } from '../../lib/format-percent.ts';

export const BadWidget = (): ReactNode => {
  const [open, setOpen] = useState(false);
  const delta = formatPercent(0.1);
  return <Link href="/" onClick={() => setOpen(!open)}>{delta.text} {open ? 'x' : 'o'}</Link>;
};
EOF
rule21_hits=$(bunx eslint src/components/atoms/bad-widget.tsx 2>&1 | grep -c 'hard rule 21' || true)
[ "${rule21_hits:-0}" -ge 4 ] && pass "rule 21 caught (${rule21_hits} findings: hook, next import, use client, app-code import)" \
  || { echo "expected >=4 'hard rule 21' findings, got ${rule21_hits:-0}"; fail "rule 21 enforcement"; }
rm src/components/atoms/bad-widget.tsx

echo "== negative path: rule 22 — a class/style attribute outside the design system is rejected =="
cat > app/_bad.tsx <<'EOF'
import type { ReactNode } from 'react';
const Bad = (): ReactNode => <div className="flex bg-red-500 p-8" style={{ color: 'red' }}>x</div>;
export default Bad;
EOF
rule22_hits=$(bunx eslint app/_bad.tsx 2>&1 | grep -c 'hard rule 22' || true)
[ "${rule22_hits:-0}" -ge 2 ] && pass "rule 22 caught (${rule22_hits} findings: className, style outside src/components/**)" \
  || { echo "expected >=2 'hard rule 22' findings, got ${rule22_hits:-0}"; fail "rule 22 enforcement"; }
rm app/_bad.tsx

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "next-smoke-test: $FAILURES check(s) FAILED"
  exit 1
fi
echo "next-smoke-test: all checks passed"
