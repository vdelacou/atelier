# Atelier

A personal engineering standard for Bun/TypeScript, Next.js, and Java (Quarkus) repos, packaged as an [Agent Skill](https://github.com/anthropics/skills) for AI coding agents. Turns generic code generation into senior-engineer output that follows a consistent toolchain, TDD workflow, SOLID design, a class-free functional style (records and sealed types on the Java side), and the production disciplines a real system needs from day one: privacy, tenant isolation, reliability, observability, delivery, and validated product decisions.

## Available skills

### atelier

A single, opinionated skill covering the whole coding loop. Applies to every code task in a Bun/TypeScript, Next.js, or Java repo — writing, editing, scaffolding, testing, refactoring, reviewing, debugging.

**Use when:**

- Writing or editing TypeScript for a Bun project, or Java for a Quarkus service
- Scaffolding a new Next.js monorepo, Bun-script repo, or Java service
- Creating or modifying React UI components (Atomic Design, logic-free design system)
- Refactoring existing code to a class-free functional style
- Setting up ESLint, Prettier, TypeScript configuration (or Spotless/JaCoCo/PIT on the Java side)
- Writing or reviewing tests
- Building APIs, persistence, multi-tenant paths, or AI-model integrations to production discipline
- Discussing architecture, design patterns, or code smells
- Capturing cross-session lessons (`.claude/LESSONS.md`)

**Core commitments:**

| Area | Rule |
|------|------|
| Interaction | Terse direct prose, no em dashes, answer-first; coach-style pushback on substance, not clarifying-question spam; ask only when it changes the output and can't be inferred, then 2-4 concrete options via AskUserQuestion, one round max then assumptions named inline; confirm once before irreversible actions; next steps at wrap-up; headless runs never blocked but still never commit or weaken tests (rules 24-25) |
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
| Toolchain discipline | `bun run lint` must be 0 errors AND 0 warnings; no inline ignores of any tool ever; inner-loop checks (`bun test` + `lint` + `typecheck` + `coverage`) after every change; coverage gates 100% on `domain` + `use-cases`, 80% on `composition` + `infra` + `presenter`; Stryker mutation testing with ≥90% break threshold; no `"latest"` or `"*"` in `package.json` (use `bun add` / `bun update`); fast pre-commit hook (commit-size ≤10 files / ≤300 lines, package.json check, gitleaks `protect --staged`, staged lint, typecheck) plus a CI gate set (`.github/workflows/ci.yml`) that runs strict lint, tests, coverage, and mutation on a frozen lockfile as the required merge check |
| Security | Source-to-sink threat model, branded types at trust boundaries (`SafeUrl`, `SanitizedHtml`, `EnvVar`, `SafePath`), strict false-positive filter when reviewing |
| Commits | Conventional Commits enforced by a `commit-msg` hook (rule 23) — `type(scope)!: subject`; the Bun-script variant ships a zero-dependency validator, the Next.js variant uses `@commitlint/config-conventional`. Same grammar both ways. The agent never commits or pushes without explicit user confirmation (rule 25) |
| Identity | Contributor identity in commit metadata is normal (rule 26), never a finding or a publish blocker. File contents are the opposite: no tracked file names a person, an employer, or a client. Scrubbing a mention from pushed history is a gated `git filter-repo` rewrite plus a force-push (treating cached commits as still exposed) |
| Integration | Trunk-based development — commit to `main` in small green increments (≤10 files / ≤300 lines), no long-lived feature branches; unfinished work hides behind a flag. The pre-commit gates keep every commit releasable |
| Memory | Append-only `.claude/LESSONS.md` and `.claude/lessons.local.md` across sessions; plus a mutable `.claude/PLAN.md` (plan + per-step definition of done) so a multi-step task resumes losslessly after a context reset |
| Privacy (rules 27, 34) | Personal data never in logs, URLs, or query strings (user-typed text travels in POST bodies; opaque ids only in logs, natural identifiers redacted at the logger); user rights (see/export/correct/erase/withdraw) as routine endpoints; a data map with classifications; production data never leaves production; synthetic fixtures only |
| Isolation (rule 28) | Owner/tenant id from the verified token only, fail-closed reads, defense in depth (RLS), least-privilege runtime role, a cross-tenant 404 test on every owner-scoped endpoint, UUIDv7 ids that are never the authorization |
| Reliability (rules 29-31) | A deadline on every outbound call with bounded jittered retries and idempotency keys; explicit hot reads and keyset pagination; the transactional outbox for side effects; optimistic locking (no lost updates); soft delete + versioned expand-contract migrations; stateless scaling; load-tested latency budgets |
| Observability | SLOs as numbers with windows; correlated OpenTelemetry traces/metrics/logs; behaviour metrics split by outcome; symptom-based alerts that page only when a human must act |
| Delivery & ops | Pipeline-only deploys (canary + one-step rollback), infrastructure as code with read-only humans, ephemeral environments, managed over self-run (no SSH, automatic TLS), open-standard interfaces for portability, SBOM + signed artifacts, restore drills, blameless postmortems |
| Metrics | The four DORA metrics derived from pipeline events, flow metrics (cycle time, not story points), system metrics never per-person leaderboards, trends over snapshots, cost as a first-class metric with idle-cheap design |
| AI models (rule 32) | The model behind a capability port with a hand-written fake; pinned dated snapshots (never `latest`); model output checkpointed as untrusted input; prompt-injection fencing with server-side action authorization; eval gates in CI; per-caller spend caps on metered endpoints |
| Governance | Decision records (`[decision]` entries + an ADR tier), API docs generated from the contract, thresholds as numbers not adjectives, one honest backlog, CODEOWNERS with exactly one Accountable per area, separation of duties, audit trails, owner-verifiable done |
| Product & accessibility | Error copy naming cause + next step over stable error codes, honest flows (cancel as easy as subscribe), market-driven defaults, a visible human path, i18n catalog, semantic HTML + keyboard + token contrast + an axe gate, and validate-before-build (problem interviews, dated go/no-go, keep-or-kill on measured adoption) |

**Reference documentation included:**

- `ai.md` | the AI model as a dependency: capability port + fake, pinned snapshots, eval gates in CI, prompt-injection fencing + server-side action authorization, per-caller spend caps
- `architecture.md` — vertical slices, dependency rule, hexagonal and clean architecture, walking skeleton, inbound HTTP server archetype, client-agnostic API shape and the three model boundaries (domain/DB/wire), the frontend gateway
- `atomic-design.md` — the logic-free design system: atoms/molecules/organisms layer rules, interactivity ladder (native HTML → hoisted state → `src/lib/hooks`), injected link/image wrappers, styling seal (Tailwind invisible outside the design system), page-shell wiring, decision table
- `behavioural-examples.md` — before/after worked examples for the four Behavioural Guidelines in this repo's idiom (over-abstraction vs one function, drive-by vs surgical edit, vague vs verifiable plan), anti-pattern table
- `bun-typescript.md` — Clean Architecture Bun script repos, strict ESLint flat config (SonarJS + type-aware), Logger port + Winston adapter, bootstrap checklist, optional containerization Dockerfile
- `class-to-module.md` — translation table for classical OO patterns (value object, interface, service, strategy, factory, decorator, observer, command, entity)
- `clean-code.md` — naming priorities, object calisthenics in a class-free world, comments, formatting
- `code-smells.md` — detection catalogue and the refactorings that clean each smell
- `complexity.md` — essential vs accidental complexity, YAGNI, the lazy ladder (stop at the first rung; simplicity is not negligence; defer the build, not the seam), KISS, DRY + Rule of Three
- `delivery.md` | pipeline-only deploys with canary + one-step rollback, infrastructure as code with read-only humans, ephemeral environments, managed over self-run (no SSH, automatic TLS), open-standard portability + compose gate, SBOM + signed artifacts, restore drills, blameless postmortems
- `design-patterns.md` — full GoF catalogue rewritten as modules of arrow functions
- `governance.md` | decision records (`[decision]` + ADR tier), API docs from the contract, numbers not adjectives, one honest backlog, CODEOWNERS/RACI, separation of duties, audit trail, owner-verifiable done
- `isolation.md` | token-derived owner, RLS defense in depth, fail closed, blast radius, cross-tenant 404 tests per endpoint, UUIDv7 identifiers
- `java-quarkus.md` | the Java variant: records + sealed `Result`, ports as interfaces with hand-written fakes (no Mockito), Maven-wrapper toolchain with exact pins, Spotless, JaCoCo tiers + PIT mutation, Flyway expand-contract, Panache writes / explicit reads, authenticated-by-default resources, hard-rules translation table, bootstrap checklist
- `lessons.md` — session memory format, triggers, extraction heuristics, worked examples
- `metrics.md` | measure whether you are improving: DORA from pipeline events, flow metrics over story points, system metrics never per-person, trend over snapshot, cost as a first-class metric
- `nextjs-monorepo.md` — Next.js 16 + Tailwind v4 + i18n route groups + static export
- `object-design.md` — responsibility-driven design, stereotypes, tell-don't-ask, value objects vs entities, aggregates
- `observability.md` | SLOs as numbers, correlated OpenTelemetry traces/metrics/logs, behaviour metrics by outcome, symptom-based alerting and alert hygiene
- `privacy.md` | private by default: minimize collection, PII out of logs/URLs/query strings, user rights as routine endpoints, data map, synthetic fixtures, impact assessments
- `product.md` | the whole experience: error copy over stable codes, honest flows, market-driven defaults, human path, accessibility, and validate-before-build (interviews, cheapest demand test, dated go/no-go, keep-or-kill on adoption)
- `reliability.md` | design for failure: deadlines + jittered idempotent retries, explicit hot reads, keyset pagination, transactional outbox, optimistic locking, soft delete + expand-contract migrations, stateless scaling, load-tested budgets
- `result-type.md` — `Result<T, E>` and helpers, per-port discriminated-union errors, `StepError` aggregation, `try/catch` quarantine, fan-out batch semantics, `retryOnErr`, fakes-with-error-injection, `captureRejection` helper
- `security.md` — source-to-sink threat model, vulnerability categories for Bun/TypeScript + Next.js, branded types for trust boundaries, rented auth/crypto, the one security baseline, pre-merge checklist, adopted false-positive filter
- `solid-principles.md` — SRP, OCP, LSP, ISP, DIP expressed as typed records and function contracts
- `tdd.md` — Outside-in classicist TDD (Ian Cooper), primary-port SUT, real-domain + faked-secondary-ports rule, Red-Green-Refactor, Three Laws, triangulation
- `testing.md` — primary-port unit tests, the test-the-code-you-own principle (trust your dependencies), fakes with `errors` knob, regression + bypass + performance layers, test doubles catalogue, test builders, contract tests
- `testing-infra.md` — three patterns for infra-adapter tests (custom-fetch DI / two-constructor / sync-builder export), production-wiring smoke test, `installFetchMock`, global-swap pattern, FS chmod tricks, ordering gotchas
- `workflow.md`: four-check loop, zero-warning lint rule, no-inline-ignore discipline, per-directory coverage gates, SonarJS-at-lint-time, trunk-based development, fast pre-commit hook plus the full CI gate set, dependency CVE scanning in CI (`bun audit`), verification discipline (test the bypass, fix the class, compliance is not proof), Conventional Commits `commit-msg` hook, README consistency check

### atelier-greenfield

A companion skill for the one moment the main standard assumes has already happened: repo birth. Trigger it when starting a fresh repo or a new monorepo package ("scaffold a new Bun repo", "bootstrap a new project to the standard", "scaffold a new Java service"). It detects the variant (Bun-script, Next.js, or Java/Quarkus), follows that variant's bootstrap checklist verbatim — scaffolding the layout, copying the gate assets from the installed `atelier` skill, wiring the git hook(s), writing the build scripts — then lays a minimal green walking skeleton and proves every gate passes before stopping for you to confirm the first commit (rule 25). Greenfield only; it orchestrates the existing checklists rather than duplicating them. It is the standard's paved road: a repo born from it starts already passing every gate.

**Use when:** starting a brand-new Bun/TypeScript script repo, a new package in a Next.js monorepo, or a new Java (Quarkus) service, from zero. For an existing repo with code, the main atelier skill applies.

### atelier-grill-me

A small companion skill for stress-testing a plan or design *before* building. Trigger it with "grill me" (or when a decision needs pressure-testing): it interviews you one question at a time — each led with a recommended answer, exploring the codebase before asking — walking the decision tree until you reach shared understanding, then writes a tight decision record. Independent of the atelier standard but atelier-aware: it grills toward the simplest design and proposes durable choices as `.claude/LESSONS.md` `[decision]` entries.

**Use when:** you want to be grilled, stress-test or pressure-test a plan, or de-risk a high-stakes decision (architecture, data model, public API, migration) before writing code.

### atelier-review-me

The pre-land companion: a rule-aware conformance review of a diff against the atelier standard. Trigger it with "review me" (or to check a branch/PR against the rules before committing). It resolves the diff scope, maps each changed file to the hard rules that bind it, and reports findings that cite the exact rule number (or red flag) — applying the security false-positive filter, deferring generic correctness bugs to `/code-review` and mechanical cleanups to `/simplify`. Report-only by default; it offers to apply the fixes on request. It also runs an **adopt mode** for brownfield — scanning a whole existing repo and emitting a staged migration plan to bring it up to the standard (the counterpart to atelier-greenfield's repo birth). atelier-grill-me owns the pre-decision moment, atelier-greenfield repo-birth, atelier-review-me the pre-land moment and brownfield adoption.

**Use when:** you want a conformance checkpoint before a change lands — a rule-cited review of staged changes, a feature branch, or a PR (covering the core rules and the production disciplines, rules 27-34) — or to adopt the standard into an existing brownfield repo (adopt mode). For generic correctness bugs use `/code-review`; for reuse/simplification cleanups use `/simplify`.

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

The skill ships executable assets in [`skills/atelier/assets/`](skills/atelier/assets/) implementing the fast pre-commit hook and the full CI gate set (`ci.yml`) for the **Bun-script variant**. Next.js monorepos use `simple-git-hooks` (test + lint + commitlint) instead, see `references/nextjs-monorepo.md`; never install both hook mechanisms. For a Bun-script repo, copy the scripts and wire the hook:

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
cp $SKILL/assets/lint-staged.sh                   scripts/
cp $SKILL/assets/stryker.conf.json                ./

# The CI workflow (the authoritative gate set: full suite, coverage, mutation)
mkdir -p .github/workflows
cp $SKILL/assets/ci.yml                           .github/workflows/ci.yml

# Stryker must be a local devDependency — without it, `bunx stryker` resolves
# the deprecated npm package named "stryker" instead of @stryker-mutator/core
bun add -d @stryker-mutator/core

# Generate the initial coverage-preload.ts from your current src/ tree
bun run scripts/regenerate-coverage-preload.ts

# Test helpers (copy into src/test-helpers/)
mkdir -p src/test-helpers
cp $SKILL/assets/fetch-mock.ts          src/test-helpers/
cp $SKILL/assets/capture-rejection.ts   src/test-helpers/

# formatError is production code (every catch block in src/infra/** uses it).
# It lives in src/domain/**, so the mutation gate covers it, copy its test too.
mkdir -p src/domain/utilities
cp $SKILL/assets/format-error.ts        src/domain/utilities/
cp $SKILL/assets/format-error.test.ts   src/domain/utilities/

# Install the git hooks: fast-gate pre-commit + Conventional Commits commit-msg
cp $SKILL/assets/pre-commit             .githooks/pre-commit
cp $SKILL/assets/commit-msg             .githooks/commit-msg
chmod +x .githooks/pre-commit .githooks/commit-msg scripts/*.sh scripts/check-coverage.ts scripts/regenerate-coverage-preload.ts
git config core.hooksPath .githooks   # picks up both hooks
```

The `commit-msg` hook enforces [Conventional Commits](https://www.conventionalcommits.org) (`type(scope)!: subject`) with zero dependencies, see `references/workflow.md` (Commit message format).

Add the matching scripts to `package.json`:

```jsonc
{
  "scripts": {
    "lint":           "eslint --cache --max-warnings=0",
    "lint:staged":    "bash scripts/lint-staged.sh",
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

For a **Java (Quarkus) repo**, the equivalent install copies `assets/pre-commit-java`, `assets/ci-java.yml`, `assets/check-pom.sh`, the shared `assets/check-commit-size.sh`, and the same `assets/commit-msg`, see `references/java-quarkus.md` (§ Gates and hooks) for the copy block and the pom-side configuration (Spotless, JaCoCo tiers, PIT).

## Usage

Once installed, the agent consults `atelier` on every code task in a Bun/TypeScript, Next.js, or Java project — you do not need to mention it by name. It will:

- Refuse generated code that uses `class`, `function` declarations, `interface`, `console.*`, or `npm`/`pnpm`/`yarn` and rewrite it in the class-free style (on the Java side: refuse Mockito, `@SuppressWarnings`, version ranges, and business failures thrown as exceptions).
- Write a failing test before production code when implementing a feature.
- Promote raw domain primitives to branded types with validating factories.
- Apply the production disciplines when the change touches them: keep personal data out of logs and URLs, derive tenants from the verified token and ship the cross-tenant test, put deadlines on outbound calls, version mutable records, keep migrations additive, pin AI-model snapshots behind ports.
- Read `.claude/LESSONS.md` and `.claude/lessons.local.md` at session start and propose new entries at session end.

**Example prompts:**

- "Add a CSV export use case for the orders feature."
- "Add a pricing section with a monthly/yearly toggle to the landing page."
- "Refactor `user-service.ts` to follow SOLID principles."
- "Scaffold a new Bun script repo for a Firebase admin job."
- "Add a paginated invoices endpoint to the Quarkus service." (Java variant: keyset pagination, cross-tenant 404 test, REST Assured)
- "Review this module for code smells."
- "Wrap the `email`, `userId`, and `money` primitives as branded types."

## Repository layout

```
atelier/
├── LICENSE
├── README.md
├── .github/workflows/ci.yml       # CI: frontmatter validation + asset smoke test
├── .githooks/                     # this repo's own hooks (frontmatter check, Conventional Commits)
├── scripts/
│   ├── validate-frontmatter.ts    # frontmatter gate: name/description present + within skill limits
│   ├── smoke-test.sh              # e2e (Bun): install the assets per this README into a scratch repo, run every gate
│   ├── smoke-test-next.sh         # e2e (Next.js): scaffold a package, assert rules 21-22 enforcement
│   └── smoke-test-java.sh         # e2e (Java): scaffold from the canonical pom, run + block every gate
└── skills/
    ├── atelier/
    │   ├── SKILL.md           # Main skill instructions
    │   ├── assets/            # Copyable artefacts — install with the steps above
    │   │   ├── capture-rejection.ts            # rejection-assertion helper (SonarJS S4123)
    │   │   ├── check-commit-size.sh            # block commits over 10 files / 300 lines (gate 1; shared with the Java hook)
    │   │   ├── check-coverage.ts               # per-tier coverage gate (runs in CI)
    │   │   ├── check-data-lifecycle.sh         # rule-30 tripwire: hard deletes + destructive DDL in the staged diff
    │   │   ├── check-bundle-size.sh            # rule-17.7 bundle-weight budget (gzipped JS vs a ceiling)
    │   │   ├── check-docs.sh                    # rule-12.1 docs-check: run the README's ## Verify commands
    │   │   ├── check-io-deadlines.sh           # rule-29 tripwire: infra fetch/HttpClient without a deadline marker
    │   │   ├── check-isolation-tests.sh        # rule-28 tripwire: new route files without a nearby 404 test
    │   │   ├── check-package-json.sh           # block "latest" / "*" / dist-tag version strings (gate 2)
    │   │   ├── check-pii-channels.sh           # rule-27 tripwire: PII in query strings, log messages, @QueryParam
    │   │   ├── check-pom.sh                    # Java: block version ranges + -SNAPSHOT deps in pom.xml (rule 19)
    │   │   ├── ci.yml                          # GitHub Actions CI: the full gate set on a frozen lockfile (rules 4.6, 15.1)
    │   │   ├── commit-msg                       # git commit-msg hook: enforce Conventional Commits (rule 23, all variants)
    │   │   ├── fetch-mock.ts                   # installFetchMock for infra adapter tests
    │   │   ├── format-error.ts                 # safe catch-block formatter (SonarJS S6551)
    │   │   ├── format-error.test.ts            # its test (format-error is in the mutation scope)
    │   │   ├── java/                           # Java variant exemplars: sealed Result/Ok/Err + the Email value-record
    │   │   ├── lint-staged.sh                  # fast staged-file ESLint for the pre-commit hook
    │   │   ├── mutate-changed.sh               # Stryker mutation on files changed vs origin/main
    │   │   ├── mutate-staged.sh                # Stryker mutation on staged files (optional local; CI enforces mutation)
    │   │   ├── pre-commit                      # git pre-commit hook running the fast gates (Bun variant)
    │   │   ├── pre-commit-java                 # git pre-commit hook running the fast gates (Java variant)
    │   │   ├── ci-java.yml                     # GitHub Actions CI: the full Java gate set (verify, JaCoCo, PIT)
    │   │   ├── regenerate-coverage-preload.ts  # auto-glob src/{infra,composition,presenter} → coverage-preload.ts
    │   │   └── stryker.conf.json               # Stryker config (mutation scope, 90% break threshold)
    │   └── references/        # Supporting documentation
    │       ├── ai.md
    │       ├── architecture.md
    │       ├── atomic-design.md
    │       ├── behavioural-examples.md
    │       ├── bun-typescript.md
    │       ├── class-to-module.md
    │       ├── clean-code.md
    │       ├── code-smells.md
    │       ├── complexity.md
    │       ├── delivery.md
    │       ├── design-patterns.md
    │       ├── governance.md
    │       ├── isolation.md
    │       ├── java-quarkus.md
    │       ├── lessons.md
    │       ├── metrics.md
    │       ├── nextjs-monorepo.md
    │       ├── object-design.md
    │       ├── observability.md
    │       ├── privacy.md
    │       ├── product.md
    │       ├── reliability.md
    │       ├── result-type.md
    │       ├── security.md
    │       ├── solid-principles.md
    │       ├── tdd.md
    │       ├── testing.md
    │       ├── testing-infra.md
    │       └── workflow.md
    ├── atelier-greenfield/
    │   └── SKILL.md           # standalone greenfield-repo scaffolder (orchestrates the variant bootstrap checklists)
    ├── atelier-grill-me/
    │   └── SKILL.md           # standalone "grill me" plan stress-test skill
    └── atelier-review-me/
        └── SKILL.md           # standalone rule-aware pre-land diff-review skill
```

## Repository CI

Every push and pull request runs four GitHub Actions jobs, each guarding against the same failure mode — a toolchain major or a doc edit silently breaking what the skill ships:

- **frontmatter validator** — every `SKILL.md` opens with a valid `name`/`description` within the skill-loader limits.
- **`scripts/smoke-test.sh` (Bun variant)**: follows this README's install steps into a scratch Bun repo, extracts the canonical `tsconfig.json` / `eslint.config.js` from `references/bun-typescript.md`, installs the **current unpinned** toolchain, and proves every gate both passes on a conforming tree and blocks its target violation (the fast pre-commit hook run end-to-end, plus the CI gates run directly, Stryker included).
- **`scripts/smoke-test-next.sh` (Next.js variant)** — scaffolds a Next.js package from the canonical configs in `references/nextjs-monorepo.md`, builds a conforming design system + page shell + static export, and asserts the design-system lint block catches its target violations: rule 21 (a hook / `next/*` import / `'use client'` / app-code import inside a component) and rule 22 (a `className` / `class` / `style` attribute outside `src/components/**`).
- **`scripts/smoke-test-java.sh` (Java variant)** | scaffolds a Maven repo from the canonical `pom.xml` in `references/java-quarkus.md` plus the shipped hook assets, proves the gates pass on a conforming skeleton (spotless, `verify` with the JaCoCo tiers, PIT, a real hooked commit through `pre-commit-java`), and that each gate blocks its target violation (a version range, a `-SNAPSHOT` dependency, an oversized commit, a junk commit message, a misformatted file, a warning under `-Werror`, an untested domain class, a covered-but-unasserted mutant survivor).

A new ESLint/TypeScript/Stryker/Next/Maven-plugin major that breaks a shipped asset — or doc drift in the canonical configs — fails CI before a user hits it. Run them locally with `bash scripts/smoke-test.sh`, `bash scripts/smoke-test-next.sh`, and `bash scripts/smoke-test-java.sh`.

## Variant references

The skill covers three repo shapes and picks the right reference automatically:

- **Next.js monorepo** — Bun workspaces, Atomic Design with a logic-free design system, Tailwind v4, i18n route groups, static export. Identifiable by `packages/*` and `next.config.ts`.
- **Bun TypeScript script** — Clean Architecture (`src/{domain,use-cases,infra,presenter,composition,test-helpers}`), strict ESLint (SonarJS + type-aware), Logger port + Winston adapter. Identifiable by `"module": "src/main.ts"` in `package.json`.
- **Java (Quarkus)** | the same commitments in Java 21+ idiom: records + sealed `Result`, ports as small interfaces with hand-written fakes (no Mockito), Maven wrapper with exact pins, Spotless, JaCoCo coverage tiers, PIT mutation, Flyway expand-contract migrations, authenticated-by-default JAX-RS resources. Identifiable by `pom.xml` with `src/main/java/**`.

## Credits

Inspired by the layout of [ramziddin/solid-skills](https://github.com/ramziddin/solid-skills). The engineering substance encodes patterns from Clean Code (Robert C. Martin), Test-Driven Development (Kent Beck), Domain-Driven Design (Eric Evans), and Refactoring (Martin Fowler), adapted to a class-free Bun/TypeScript codebase (and its Java translation). The production disciplines (hard rules 27-34 and the references they point to) are the executable encoding of the eighteen pillars in *The Global Rules Every New Project Should Have* and its *Do and Don't* companion. The security reference and its false-positive filter are adapted with credit from [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review).

## Changelog

Notable changes are tracked in [CHANGELOG.md](./CHANGELOG.md); the suite is versioned as a
whole. The current release is 2.0.0 (the production-disciplines + Java-variant release).

## License

[MIT](./LICENSE)
