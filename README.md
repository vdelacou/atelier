# Atelier

A personal engineering standard for Bun/TypeScript repos, packaged as an [Agent Skill](https://github.com/anthropics/skills) for AI coding agents. Turns generic code generation into senior-engineer output that follows a consistent toolchain, TDD workflow, SOLID design, and class-free functional style.

## Available skills

### atelier

A single, opinionated skill covering the whole coding loop. Applies to every code task in a Bun/TypeScript repo — writing, editing, scaffolding, testing, refactoring, reviewing, debugging.

**Use when:**

- Writing or editing TypeScript for a Bun project
- Scaffolding a new Next.js monorepo or Bun-script repo
- Creating or modifying React UI components (Atomic Design, logic-free design system)
- Refactoring existing code to a class-free functional style
- Setting up ESLint, Prettier, TypeScript configuration
- Writing or reviewing tests
- Discussing architecture, design patterns, or code smells
- Capturing cross-session lessons (`.claude/LESSONS.md`)

**Core commitments:**

| Area | Rule |
|------|------|
| Toolchain | Bun only — never `npm`, `pnpm`, `yarn`, `node`, or `vite` directly |
| Language | `const` arrow functions, no `class`, no `function` declaration, no `interface`, no curried arrow chains |
| Typing | Branded types for every domain primitive; `Partial<Record<K, V>>` when the key set is open |
| Architecture | Clean Architecture: `src/{domain,use-cases,infra,presenter,composition,test-helpers}`, dependency rule inward-only |
| UI / Design system | Atomic Design: independent, logic-free design system (`src/components/{atoms,molecules,organisms}`) of stateless props-only components — no hooks, no fetching, no i18n, no `next/*` imports; state hoisted to page shells via `src/lib/hooks/`, links/images injected as `ComponentType` props. Styling sealed inside: Tailwind utilities only under `src/components/**` (tokens in `globals.css`), typed variants instead of `className` passthrough — the app layer never sees Tailwind |
| Logging | Logger is a **port** (`src/use-cases/ports/logger.ts`), Winston adapter in `src/infra/`, fake in `src/test-helpers/`. Never `console.*` |
| Tests | Outside-in classicist TDD — SUT is the primary port, domain runs real, only secondary ports are faked, never mocks |
| Test integrity | Tests are confirmation-gated (rule 24): the agent never creates, edits, deletes, skips, or weakens a test without showing you the change and getting an explicit yes — TDD stays test-first by *proposing* the Red test for approval. Prevents silently weakening a test to go green |
| Error handling | Every IO port returns `Result<T, PortError>` with a discriminated-union error; use-cases return `Result<Summary, StepError>`; `try/catch` quarantined to `infra/`, `main.ts`, and pure-domain native-API fallbacks |
| Design | SOLID expressed through typed records and arrow functions, object calisthenics |
| Complexity | YAGNI, KISS, DRY after Rule of Three, Tell-Don't-Ask, Law of Demeter |
| Toolchain discipline | `bun run lint` must be 0 errors AND 0 warnings; no inline ignores of any tool ever; inner-loop checks (`bun test` + `lint` + `typecheck` + `coverage`) after every change; coverage gates 100% on `domain` + `use-cases`, 80% on `composition` + `infra` + `presenter`; Stryker mutation testing with ≥90% break threshold; no `"latest"` or `"*"` in `package.json` (use `bun add` / `bun update`); eight-gate pre-commit hook (commit-size ≤10 files / ≤300 lines, package.json check, gitleaks `protect --staged`, tests, lint:strict, typecheck, coverage, mutate:staged) |
| Security | Source-to-sink threat model, branded types at trust boundaries (`SafeUrl`, `SanitizedHtml`, `EnvVar`, `SafePath`), strict false-positive filter when reviewing |
| Commits | Conventional Commits enforced by a `commit-msg` hook (rule 23) — `type(scope)!: subject`; the Bun-script variant ships a zero-dependency validator, the Next.js variant uses `@commitlint/config-conventional`. Same grammar both ways. The agent never commits or pushes without explicit user confirmation (rule 25) |
| Integration | Trunk-based development — commit to `main` in small green increments (≤10 files / ≤300 lines), no long-lived feature branches; unfinished work hides behind a flag. The pre-commit gates keep every commit releasable |
| Memory | Append-only `.claude/LESSONS.md` and `.claude/lessons.local.md` across sessions |

**Reference documentation included:**

- `architecture.md` — vertical slices, dependency rule, hexagonal and clean architecture, walking skeleton
- `atomic-design.md` — the logic-free design system: atoms/molecules/organisms layer rules, interactivity ladder (native HTML → hoisted state → `src/lib/hooks`), injected link/image wrappers, styling seal (Tailwind invisible outside the design system), page-shell wiring, decision table
- `behavioural-examples.md` — before/after worked examples for the four Behavioural Guidelines in this repo's idiom (over-abstraction vs one function, drive-by vs surgical edit, vague vs verifiable plan), anti-pattern table
- `bun-typescript.md` — Clean Architecture Bun script repos, strict ESLint flat config (SonarJS + type-aware), Logger port + Winston adapter, bootstrap checklist
- `class-to-module.md` — translation table for classical OO patterns (value object, interface, service, strategy, factory, decorator, observer, command, entity)
- `clean-code.md` — naming priorities, object calisthenics in a class-free world, comments, formatting
- `code-smells.md` — detection catalogue and the refactorings that clean each smell
- `complexity.md` — essential vs accidental complexity, YAGNI, the lazy ladder (stop at the first rung; simplicity is not negligence), KISS, DRY + Rule of Three
- `design-patterns.md` — full GoF catalogue rewritten as modules of arrow functions
- `lessons.md` — session memory format, triggers, extraction heuristics, worked examples
- `nextjs-monorepo.md` — Next.js 16 + Tailwind v4 + i18n route groups + static export
- `object-design.md` — responsibility-driven design, stereotypes, tell-don't-ask, value objects vs entities, aggregates
- `result-type.md` — `Result<T, E>` and helpers, per-port discriminated-union errors, `StepError` aggregation, `try/catch` quarantine, fan-out batch semantics, `retryOnErr`, fakes-with-error-injection, `captureRejection` helper
- `security.md` — source-to-sink threat model, vulnerability categories for Bun/TypeScript + Next.js, branded types for trust boundaries, pre-merge checklist, adopted false-positive filter
- `solid-principles.md` — SRP, OCP, LSP, ISP, DIP expressed as typed records and function contracts
- `tdd.md` — Outside-in classicist TDD (Ian Cooper), primary-port SUT, real-domain + faked-secondary-ports rule, Red-Green-Refactor, Three Laws, triangulation
- `testing.md` — primary-port unit tests, the test-the-code-you-own principle (trust your dependencies), fakes with `errors` knob, batch-use-case semantics, test doubles catalogue, test builders, contract tests
- `testing-infra.md` — three patterns for infra-adapter tests (custom-fetch DI / two-constructor / sync-builder export), production-wiring smoke test, `installFetchMock`, global-swap pattern, FS chmod tricks, ordering gotchas
- `workflow.md` — four-check loop, zero-warning lint rule, no-inline-ignore discipline, per-directory coverage gates, SonarJS-at-lint-time, trunk-based development, eight-gate pre-commit hook, Conventional Commits `commit-msg` hook, README consistency check

### bootstrap

A companion skill for the one moment the main standard assumes has already happened: repo birth. Trigger it when starting a fresh repo or a new monorepo package ("scaffold a new Bun repo", "bootstrap a new project to the standard"). It detects the variant, follows that variant's bootstrap checklist verbatim — scaffolding the layout, copying the gate assets from the installed `atelier` skill, wiring the git hook(s), writing the `package.json` scripts — then lays a minimal green walking skeleton and proves every gate passes before stopping for you to confirm the first commit (rule 25). Greenfield only; it orchestrates the existing checklists rather than duplicating them.

**Use when:** starting a brand-new Bun/TypeScript script repo or a new package in a Next.js monorepo, from zero. For an existing repo with code, the main atelier skill applies.

### grill-me

A small companion skill for stress-testing a plan or design *before* building. Trigger it with "grill me" (or when a decision needs pressure-testing): it interviews you one question at a time — each led with a recommended answer, exploring the codebase before asking — walking the decision tree until you reach shared understanding, then writes a tight decision record. Independent of the atelier standard but atelier-aware: it grills toward the simplest design and proposes durable choices as `.claude/LESSONS.md` `[decision]` entries.

**Use when:** you want to be grilled, stress-test or pressure-test a plan, or de-risk a high-stakes decision (architecture, data model, public API, migration) before writing code.

## Installation

### 1. Install the skill (one-time, per machine)

Use the [`skills`](https://www.npmjs.com/package/skills) CLI by Vercel Labs — it discovers `skills/atelier/SKILL.md` in this repo automatically:

```bash
npx skills add vdelacou/atelier
```

By default it installs into Claude Code's user skills directory (`~/.claude/skills/atelier`). Use `-g` for project-local install or `-a <agent>` to target another supported agent (`opencode`, `cursor`, etc.).

#### Alternative: clone and symlink (track upstream)

If you'd rather follow the repo via `git pull`:

```bash
git clone https://github.com/vdelacou/atelier.git ~/code/atelier
mkdir -p ~/.claude/skills
ln -s ~/code/atelier/skills/atelier ~/.claude/skills/atelier
```

The skill becomes available automatically the next time Claude Code starts. Verify it's loaded with `/skills` (or your client's equivalent).

### 2. Install the gate scripts (Bun-script repos)

The skill ships executable assets in [`skills/atelier/assets/`](skills/atelier/assets/) implementing the eight-gate pre-commit pipeline for the **Bun-script variant**. Next.js monorepos use `simple-git-hooks` (test + lint + commitlint) instead — see `references/nextjs-monorepo.md`; never install both hook mechanisms. For a Bun-script repo, copy the scripts and wire the hook:

```bash
SKILL=~/.claude/skills/atelier   # or wherever you cloned the skill

# Copy the gate scripts into your repo
mkdir -p scripts .githooks
cp $SKILL/assets/check-commit-size.sh             scripts/
cp $SKILL/assets/check-package-json.sh            scripts/
cp $SKILL/assets/check-coverage.ts                scripts/
cp $SKILL/assets/regenerate-coverage-preload.ts   scripts/
cp $SKILL/assets/mutate-staged.sh                 scripts/
cp $SKILL/assets/mutate-changed.sh                scripts/
cp $SKILL/assets/stryker.conf.json                ./

# Stryker must be a local devDependency — without it, `bunx stryker` resolves
# the deprecated npm package named "stryker" instead of @stryker-mutator/core
bun add -d @stryker-mutator/core

# Generate the initial coverage-preload.ts from your current src/ tree
bun run scripts/regenerate-coverage-preload.ts

# Test helpers (copy into src/test-helpers/)
mkdir -p src/test-helpers
cp $SKILL/assets/fetch-mock.ts          src/test-helpers/
cp $SKILL/assets/capture-rejection.ts   src/test-helpers/

# formatError is production code (every catch block in src/infra/** uses it)
mkdir -p src/domain/utilities
cp $SKILL/assets/format-error.ts        src/domain/utilities/

# Install the git hooks: eight-gate pre-commit + Conventional Commits commit-msg
cp $SKILL/assets/pre-commit             .githooks/pre-commit
cp $SKILL/assets/commit-msg             .githooks/commit-msg
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/*.sh scripts/check-coverage.ts scripts/regenerate-coverage-preload.ts
git config core.hooksPath .githooks   # picks up both hooks
```

The `commit-msg` hook enforces [Conventional Commits](https://www.conventionalcommits.org) (`type(scope)!: subject`) with zero dependencies — see `references/workflow.md` (Commit message format).

Add the matching scripts to `package.json`:

```jsonc
{
  "scripts": {
    "lint":           "eslint --cache",
    "lint:strict":    "LINT_STRICT=1 eslint --max-warnings=0",
    "typecheck":      "tsc --noEmit",
    "coverage":       "bun run scripts/check-coverage.ts",
    "coverage:preload":       "bun run scripts/regenerate-coverage-preload.ts",
    "coverage:preload:check": "bun run scripts/regenerate-coverage-preload.ts --check",
    "mutate":         "stryker run",
    "mutate:staged":  "bash scripts/mutate-staged.sh",
    "mutate:changed": "bash scripts/mutate-changed.sh"
  }
}
```

Optional: install `gitleaks` (`brew install gitleaks`) for the secret-scan gate. The hook degrades gracefully if it's missing.

## Usage

Once installed, the agent consults `atelier` on every code task in a Bun/TypeScript project — you do not need to mention it by name. It will:

- Refuse generated code that uses `class`, `function` declarations, `interface`, `console.*`, or `npm`/`pnpm`/`yarn` and rewrite it in the class-free style.
- Write a failing test before production code when implementing a feature.
- Promote raw domain primitives to branded types with validating factories.
- Read `.claude/LESSONS.md` and `.claude/lessons.local.md` at session start and propose new entries at session end.

**Example prompts:**

- "Add a CSV export use case for the orders feature."
- "Add a pricing section with a monthly/yearly toggle to the landing page."
- "Refactor `user-service.ts` to follow SOLID principles."
- "Scaffold a new Bun script repo for a Firebase admin job."
- "Review this module for code smells."
- "Wrap the `email`, `userId`, and `money` primitives as branded types."

## Repository layout

```
atelier/
├── LICENSE
├── README.md
└── skills/
    ├── atelier/
        ├── SKILL.md           # Main skill instructions
        ├── assets/            # Copyable artefacts — install with the steps above
        │   ├── capture-rejection.ts            # rejection-assertion helper (SonarJS S4123)
        │   ├── check-commit-size.sh            # block commits over 10 files / 300 lines (gate 1)
        │   ├── check-coverage.ts               # per-tier coverage gate (gate 7)
        │   ├── check-package-json.sh           # block "latest" / "*" / dist-tag version strings (gate 2)
        │   ├── commit-msg                       # git commit-msg hook: enforce Conventional Commits (rule 23)
        │   ├── coverage-preload.ts             # template — usually generated by regenerate-coverage-preload.ts
        │   ├── fetch-mock.ts                   # installFetchMock for infra adapter tests
        │   ├── format-error.ts                 # safe catch-block formatter (SonarJS S6551)
        │   ├── mutate-changed.sh               # Stryker mutation on files changed vs origin/main
        │   ├── mutate-staged.sh                # Stryker mutation on staged files (gate 8)
        │   ├── pre-commit                      # git pre-commit hook running 8 gates
        │   ├── regenerate-coverage-preload.ts  # auto-glob src/{infra,composition,presenter} → coverage-preload.ts
        │   └── stryker.conf.json               # Stryker config (mutation scope, 90% break threshold)
        └── references/        # Supporting documentation
            ├── architecture.md
            ├── atomic-design.md
            ├── behavioural-examples.md
            ├── bun-typescript.md
            ├── class-to-module.md
            ├── clean-code.md
            ├── code-smells.md
            ├── complexity.md
            ├── design-patterns.md
            ├── lessons.md
            ├── nextjs-monorepo.md
            ├── object-design.md
            ├── result-type.md
            ├── security.md
            ├── solid-principles.md
            ├── tdd.md
            ├── testing.md
            ├── testing-infra.md
            └── workflow.md
    ├── bootstrap/
        └── SKILL.md           # standalone greenfield repo scaffolder (orchestrates the variant bootstrap checklists)
    └── grill-me/
        └── SKILL.md           # standalone "grill me" plan stress-test skill
```

## Variant references

The skill covers two repo shapes and picks the right reference automatically:

- **Next.js monorepo** — Bun workspaces, Atomic Design with a logic-free design system, Tailwind v4, i18n route groups, static export. Identifiable by `packages/*` and `next.config.ts`.
- **Bun TypeScript script** — Clean Architecture (`src/{domain,use-cases,infra,presenter,composition,test-helpers}`), strict ESLint (SonarJS + type-aware), Logger port + Winston adapter. Identifiable by `"module": "src/main.ts"` in `package.json`.

## Credits

Inspired by the layout of [ramziddin/solid-skills](https://github.com/ramziddin/solid-skills). The engineering substance encodes patterns from Clean Code (Robert C. Martin), Test-Driven Development (Kent Beck), Domain-Driven Design (Eric Evans), and Refactoring (Martin Fowler), adapted to a class-free Bun/TypeScript codebase. The security reference and its false-positive filter are adapted with credit from [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review).

## License

[MIT](./LICENSE)
