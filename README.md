# Atelier

**Your AI coding agent, held to a senior engineer's standard. With the gates to prove it.**

Atelier is an [Agent Skill](https://github.com/anthropics/skills) suite for Claude Code and compatible agents. Install it once and every code task in a Bun/TypeScript, Next.js, or Java (Quarkus) repo comes out test-first, cleanly layered, typed at the boundaries, private by default, and ready for production. Not because the prompt asked, but because the standard is loaded on every session and enforced by lint, hooks, and CI.

Two ways to run it: four skills inside a single agent session, or a six-agent [SwarmForge](https://github.com/unclebob/swarm-forge) pack that takes a one-paragraph card from specification to a rule-cited verdict while you approve once.

## The problem it solves

Coding agents write plausible code fast. Left to themselves they also:

- Reach for a `class`, an `interface`, a `try/catch` and a `console.log`, in whatever style the last training example used.
- Mock everything, test after the fact, and weaken a failing test to go green.
- Interpolate raw strings into SQL, shell, URLs and logs, and put an email address in a query string.
- Hard-delete rows, rename live columns, call the network without a deadline, and pin an AI model to `latest`.
- Commit, push, and rewrite your tests without asking.

Every one of those is a habit. Atelier replaces the habits with 37 hard rules, the production disciplines behind them, and a gate for each one that can be checked by a machine.

## What changes on day one

Once installed, the agent consults the standard on its own. You do not name it. Ask for a feature and you get:

- A failing test proposed first, at the primary port, with hand-written fakes and no mocks.
- Modules of `const` arrow functions and typed records. No `class`, no `function` declaration, no `interface`, no `console.*`.
- `Result<T, E>` at every IO boundary and a branded type with a validating factory for every value that crosses a trust boundary.
- Clean Architecture layers (`src/{domain,use-cases,infra,presenter,composition}`) with the dependency rule enforced by lint.
- Personal data kept out of logs and URLs, tenants derived from the verified token with the cross-tenant test shipped, deadlines on every outbound call, soft delete and additive migrations, optimistic locking, AI models behind ports with eval gates.
- Two confirmation gates: the agent never commits or pushes, and never touches an existing test, without your yes.
- A memory. It reads `.claude/LESSONS.md` at session start and proposes new entries at session end.

### Before and after

What an unaided agent writes for "fetch a user by id":

```ts
class UserService {
  async getUser(id: string) {
    try {
      const res = await fetch(`https://api.example.com/users/${id}`);
      return await res.json();
    } catch (e) {
      console.log('failed', e);
      return null;
    }
  }
}
```

The same request under atelier, before any adapter is written:

```ts
// src/domain/user-id.ts
export type UserId = string & { readonly __brand: 'UserId' };
export type UserIdError = { readonly kind: 'malformed'; readonly message: string };

export const parseUserId = (raw: string): Result<UserId, UserIdError> =>
  /^[0-9a-f-]{36}$/.test(raw) ? ok(raw as UserId) : err({ kind: 'malformed', message: 'expected a uuid' });

// src/use-cases/ports/users.ts
export type UsersError =
  | { readonly kind: 'not-found' }
  | { readonly kind: 'timeout'; readonly message: string };

export type Users = {
  readonly find: (id: UserId) => Promise<Result<User, UsersError>>;
};
```

The fetch lives in one infra adapter behind that port, with `AbortSignal.timeout` on the call and the `Logger` port instead of `console`. The test drives the use-case through a hand-written in-memory `Users` fake. The failing test came first, and the agent asked before writing it.

## Proof, not promises

Every claim above is measured. The harnesses and their scorecards live in this repo.

| Measurement | With atelier | Without |
|---|---|---|
| Conformance eval, 37 assertions over 3 passes, Claude Opus ([baseline](scripts/conformance-eval/baseline.md)) | 111/111 | 86/111 |
| Hard tier, 7 production-discipline tasks, 24 assertions | 24/24 | 15/24 |
| Review eval, TypeScript, 11 planted violations over 3 passes ([baseline](scripts/review-eval/baseline.md)) | 33/33 caught | 23/33 caught |
| Review eval, TypeScript, findings that cite the rule | 33/33 | 0/33 |
| Review eval, Java, 9 planted violations over 3 passes | 27/27 caught | 15/27 caught |
| False positives on clean files, both languages | 0 | 0 |

The gap is widest where it matters most. Soft delete over hard delete was satisfied by the unaided arm in none of its runs, in either eval. Depending on a port rather than an implementation: one run in six.

The six-pack's first live run, an empty repository and a small CLI card on 2026-09-05: one hour fifty-six from card to Done, one approval, zero clarifications, 35 commits by six roles, 88 tests, coverage 100 on every tier, mutation score 100, a verdict of conformant with one Low finding fixed by the reviewer.

The standard itself is audited: 120 of 120 canon sub-concepts covered in [`conformance-matrix.md`](conformance-matrix.md), 233 file-and-line citations pinned to their content, and nine CI jobs that prove every shipped gate both passes on a conforming tree and blocks its target violation on the current, unpinned toolchain.

## Start with one agent

Three steps, once per machine and once per repo.

**1. Install the skills.** The [`skills`](https://www.npmjs.com/package/skills) CLI by Vercel Labs discovers every skill in this repo:

```bash
bunx skills add vdelacou/atelier
```

`npx skills add vdelacou/atelier` works the same. The default target is Claude Code's user skills directory (`~/.claude/skills/atelier`); `-g` installs project-local, `-a <agent>` targets another supported agent (`opencode`, `cursor`, and more).

**2. Point your repo at the standard.** Skill triggering is probabilistic. A pointer block at the top of your repo's `CLAUDE.md` is deterministic, so every session loads the standard whatever you type:

```bash
SKILL=~/.claude/skills/atelier
printf '# CLAUDE.md\n\n' > CLAUDE.md
cat "$SKILL/assets/claude-md-pointer.md" >> CLAUDE.md
```

**3. Ask for work.** In plain language, no skill names:

- "Add a CSV export use case for the orders feature."
- "Add a pricing section with a monthly/yearly toggle to the landing page."
- "Add a paginated invoices endpoint to the Quarkus service."
- "Wrap the `email`, `userId`, and `money` primitives as branded types."
- "Review this module for code smells."

The gates are the agent's job. For a new repo, say "scaffold a new Bun repo" (or a Next.js package, or a Java service) and `atelier-greenfield` lays the layout, copies the gate scripts, wires the hooks and proves every gate green before the first commit. For an existing repo, say "adopt the standard into this repo" and `atelier-review-me` scans it and hands you a staged plan whose first slice installs the gates without tripping them on the legacy tree. Prefer to do it by hand? The copy block is [below](#install-the-gates-by-hand).

## Or hand the loop to six agents

Write a card. Six Claude Code agents take it from a grilled specification to a rule-cited conformance verdict. You decide once, at the spec.

```text
New Task -> specifier -> Attention -> coder -> cleaner -> architect -> hardener -> reviewer -> Done
```

| Role | What it does | Skill |
|---|---|---|
| specifier | Grills the card one question at a time, writes `docs/specs/<card>.md`: scenarios, disciplines, decisions, ADRs | atelier-grill-me |
| coder | Makes the scenarios pass test-first; on an empty tree, scaffolds the variant green from the first commit | atelier, atelier-greenfield |
| cleaner | The refactor step: names, the clean-code numbers, complexity at most 10, duplication at the third occurrence | atelier |
| architect | Layers, dependency direction, ports as function types, branded value objects, boundary lint with fixtures | atelier |
| hardener | Mutation at 90 or above, test seams, the discipline tripwires, the security lens, a red fixture for every gate | atelier |
| reviewer | The rule-cited verdict in `docs/reviews/<card>.md`, the lessons appended, the card closed | atelier-review-me |

Each role runs in its own git worktree and exchanges committed work through SwarmForge's durable handoffs. The hooks run in every worktree, no test older than the card is touched, and no role ever pushes.

### Install the pack

Prerequisites on the machine that runs the swarm: `zsh`, `git`, `tmux`, Babashka (`bb`), the `claude` CLI signed in, and the variant's toolchain (Bun, or JDK 21 with the Maven wrapper for Java). `gitleaks` on PATH serves the hooks' secret gate; the hook degrades without it and says so.

Run the installer from the project that will receive the pack, an existing repo or an empty directory the first card turns into one:

```bash
git clone https://github.com/vdelacou/atelier.git ~/code/atelier
cd ~/code/my-project
~/code/atelier/get-atelier-six-pack
```

It writes the `swarm` launcher and the `swarmforge/` runtime, the pointer block at the top of `CLAUDE.md`, an empty `.claude/LESSONS.md`, and the runtime's ignore rules. It symlinks the four skills into `~/.claude/skills` unless they are already there (`--skip-skills` leaves that directory alone, `--copy-skills` copies instead). It commits nothing. You do:

```bash
git add CLAUDE.md .claude/LESSONS.md .gitignore swarm swarmforge
git commit -m "chore(swarm): install the atelier six-pack"
./swarm
```

### Your first card

1. `./swarm` starts the six roles, the handoff daemon and the dashboard, then opens `http://127.0.0.1:<port>`. On a first start Claude Code asks two questions in every pane, whether to trust the folder and whether to accept bypass-permissions mode: six panes, twelve answers, from the dashboard's pane view.
2. **New Task**: write the card as intent, not as a design. The first run's card in full:

   > Bun script CLI that reads a CSV of invoices and prints the total amount per customer as a table. The CSV columns are customer name, customer email, invoice id, amount in EUR cents. The file holds personal data (names, emails). Single user, no tenants, no network, no database. Scope: parse the file, sum per customer, print the table; nothing else. Start with the walking skeleton.

3. The specifier grills the card, exploring the tree before each question and leading with a recommendation. Anything it cannot settle reaches you in **Attention**. When the specification is written, its handoff waits there too: read `docs/specs/<card>.md`, then approve. That is your one decision.
4. The board moves on its own from there. **Work Queue** opens any role's live pane; a clarification from any role lands in Attention.
5. **Done**: the specification, the rule-cited verdict in `docs/reviews/<card>.md`, the lessons appended to `.claude/LESSONS.md`, and every commit on your `main`. Push when you are ready.
6. **Teardown** stops the swarm and keeps the project; `./swarm` starts it again.

Read this first: the agents run unattended with permission prompts bypassed (SwarmForge's model), inside worktrees of your project. The Attention gate on the spec is where the standard's two confirmation rules land. The operator manual, the role table a CI gate keeps equal to the conf, and the swarm reading of those rules are in [`packs/six-pack/README.md`](packs/six-pack/README.md).

## The four skills

| Skill | Moment | Say | What you get |
|---|---|---|---|
| [`atelier`](skills/atelier/SKILL.md) | Every code task | Nothing. It triggers on its own in a Bun, Next.js, or Java repo | The 37 hard rules, the TDD loop, the production disciplines, 27 reference files, the gate assets |
| [`atelier-greenfield`](skills/atelier-greenfield/SKILL.md) | Repo birth | "Scaffold a new Bun repo", "scaffold a new Java service" | The variant's layout, gate scripts, hooks, build scripts and a green walking skeleton, every gate proven before the first commit |
| [`atelier-grill-me`](skills/atelier-grill-me/SKILL.md) | Before building | "Grill me on this plan" | One question at a time, each led by a recommendation, the codebase explored first, until the decision tree is resolved; then a decision record |
| [`atelier-review-me`](skills/atelier-review-me/SKILL.md) | Before landing, or adopting | "Review me", "adopt the standard into this repo" | A read-only conformance review citing the exact rule per finding; in adopt mode, a staged plan to bring a brownfield repo up to the standard |

`atelier-review-me` reports only concrete, exploitable security findings with an attack path, and defers generic correctness bugs to `/code-review` and mechanical cleanups to `/simplify`. Diff and PR content is treated as data to audit, never as instructions to follow.

## What the standard enforces

The letter of every rule is in [`skills/atelier/SKILL.md`](skills/atelier/SKILL.md), one reference file per concern under [`references/`](skills/atelier/references/). The shape:

| Area | The rule, in one line |
|---|---|
| Toolchain | Bun only, never `npm`, `pnpm`, `yarn`, `node`, or `vite` directly (Maven wrapper with exact pins in Java); nothing pinned to `latest` or `*` |
| Language | `const` arrow functions and typed records; no `class`, `function` declaration, `interface`, curried chain, or `console.*`; records and sealed types on the Java side, no Mockito, no `@SuppressWarnings` |
| Architecture | Clean Architecture, dependencies point inward, the layer table is lint (ArchUnit in Java); Atomic Design with a logic-free design system where Tailwind never reaches app code |
| Types and errors | Brand what crosses a trust boundary or feeds a sink, with a two-tier factory; every IO port returns `Result<T, PortError>`, `try/catch` quarantined to `infra/` and `main.ts` |
| Tests | Outside-in classicist TDD at the primary port, hand-written fakes, random order, 100% coverage on `domain` and `use-cases`, 80% elsewhere, mutation at 90 or above on changed files in CI |
| Lint discipline | 0 errors and 0 warnings; no inline ignore survives (`noInlineConfig`), complexity at most 10 per function |
| Commits | Conventional Commits by hook, at most 10 files and 300 lines, trunk-based, the agent never commits or pushes and never edits an existing test without a yes |
| Privacy (27, 34) | Personal data never in logs, URLs, or query strings; user rights as routine endpoints; synthetic fixtures only |
| Isolation (28) | Owner from the verified token only, fail-closed reads, RLS, a cross-tenant 404 test on every owner-scoped endpoint |
| Reliability (29-31) | A deadline on every outbound call, bounded jittered retries with idempotency keys, the transactional outbox, optimistic locking, soft delete, expand-contract migrations |
| AI models (32) | The model behind a port with a hand-written fake, pinned dated snapshots, output treated as untrusted, prompt-injection fencing, eval gates in CI, per-caller spend caps |
| Security (33) | Source-to-sink threat model, auth and crypto rented, review reports only concrete exploitable findings |
| Operations | SLOs as numbers, correlated OpenTelemetry, symptom-based alerts; pipeline-only deploys with canary and one-step rollback, IaC, SBOM and signed artifacts, restore drills |
| Product | Error copy naming cause and next step, honest flows, accessibility with an axe gate, validate before build |
| Memory | Append-only `.claude/LESSONS.md` across sessions, a live `.claude/PLAN.md` so a multi-step task survives a context reset |

Rules are non-negotiable by design: when a request would violate one, the agent rewrites to comply and says so in one sentence.

## Three stacks, one standard

The skill detects the variant and reads the matching reference:

- **Bun TypeScript script**: Clean Architecture, strict ESLint (SonarJS, type-aware, the style bans and layer zones), Logger port with a Winston adapter. Detected by `"module": "src/main.ts"` in `package.json`.
- **Next.js monorepo**: Bun workspaces, Atomic Design with a logic-free design system, Tailwind v4, i18n route groups, static export, a bundle-size budget. Detected by `packages/*` and `next.config.ts`.
- **Java (Quarkus)**: records and a sealed `Result`, ports as small interfaces with hand-written fakes, Maven wrapper with exact pins, Spotless, JaCoCo tiers, PIT mutation, Flyway expand-contract, ArchUnit layer rules, authenticated-by-default resources. Detected by `pom.xml` with `src/main/java/**`.

## Install the gates by hand

The skill ships every gate as a copyable asset in [`skills/atelier/assets/`](skills/atelier/assets/): the fast pre-commit hook, the Conventional Commits hook, the tripwires, and the full CI gate set. `atelier-greenfield` and adopt mode install them for you; this is the manual path for a **Bun-script repo**, and it is the block the Bun smoke test replays in CI.

<details>
<summary>Copy block, Bun-script variant</summary>

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
cp $SKILL/assets/check-docs.sh                    scripts/
cp $SKILL/assets/stryker.conf.json                ./

# CI re-runs the commit-message and commit-size gates over the pushed range
# (ci.yml calls both), because --no-verify exists
cp $SKILL/assets/check-commit-messages.sh         scripts/
cp $SKILL/assets/check-commit-range.sh            scripts/

# The CI workflow (the authoritative gate set: full suite, coverage, mutation on
# the changed files) and the daily full mutation sweep (never a commit gate)
mkdir -p .github/workflows
cp $SKILL/assets/ci.yml                           .github/workflows/ci.yml
cp $SKILL/assets/mutation.yml                     .github/workflows/mutation.yml

# The CVE watchdog: a daily schedule plus dependency-scoped PR runs, not a
# gate on unrelated commits. Add assets/check-skill-pin.sh to scripts/ only
# if the repo vendors or pins the skill; audit.yml runs it in tree mode
cp $SKILL/assets/audit.yml                        .github/workflows/audit.yml

# Stryker must be a local devDependency: without it, `bunx stryker` resolves
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

The `commit-msg` hook enforces [Conventional Commits](https://www.conventionalcommits.org) (`type(scope)!: subject`) with zero dependencies. Optional: `brew install gitleaks` for the secret-scan gate; the hook degrades gracefully without it.

</details>

For a **Next.js monorepo**, the hook is `simple-git-hooks` (`references/nextjs-monorepo.md`, Root `package.json`) and the CI workflow is `assets/ci-next.yml` with `check-commit-range.sh`, `check-package-json.sh` and `check-bundle-size.sh`; never install both hook mechanisms. For a **Java (Quarkus) repo**, copy `assets/pre-commit-java`, `assets/ci-java.yml`, `assets/mutation-java.yml`, `assets/audit-java.yml`, `assets/check-pom.sh`, `assets/pit-changed.sh`, `assets/java/pmd-ruleset.xml`, `assets/java/LayerRulesTest.java`, the shared commit scripts and the same `assets/commit-msg`; the copy block and the pom-side configuration are in `references/java-quarkus.md` (Gates and hooks).

## Carry the standard in the repo, not only in the skill

Skill triggering depends on a prompt matching a description, and smaller model tiers under-invoke. The pointer block at the top of a consumer's `CLAUDE.md` loads on every session regardless. Treat the block as the primary distribution mechanism and skill triggering as the fallback. The canonical text is [`assets/claude-md-pointer.md`](skills/atelier/assets/claude-md-pointer.md): copy it, never retype it, so an upstream wording change propagates by re-copy. `atelier-greenfield` seeds it at repo birth and adopt mode seeds it in the first migration slice.

A vendored or pinned skill is a dependency. It goes stale silently while every gate stays green; the [field test](field-test.md) found a consumer running doctrine 49 days behind. Re-check the pin on your dependency-scan cadence and re-sync doctrine and gates together.

## Working on this repository

This repo is the standard, not an application. What binds work here is in [`CLAUDE.md`](CLAUDE.md): never an em dash, frontmatter within the loader limits, plan-first, small Conventional Commits, and every new gate ships with a fixture that proves it can fail.

<details>
<summary>Repository layout</summary>

```text
atelier/
├── README.md
├── CHANGELOG.md                   # the suite's changelog; the standard is versioned as a whole
├── CLAUDE.md                      # authoring and process rules for work in this repo
├── field-test.md                  # the skill scored against a real consumer repo
├── conformance-matrix.md          # one row per canon sub-concept, verdict + file:line evidence
├── reverse-matrix.md              # one row per hard rule, does the canon carry it
├── citations-lock.json            # content pin for every file:line the matrices cite
├── docs/global-rules/             # the vendored canon the matrices audit against
├── docs/upstream/                 # notes on the upstream tooling this repo leans on
├── .github/workflows/ci.yml       # nine jobs on every push (below)
├── .github/workflows/canary.yml   # weekly probe of the two toolchain concessions
├── .githooks/                     # this repo's own hooks: em-dash gate, frontmatter check, Conventional Commits
├── get-atelier-six-pack           # six-pack installer: compose the pack, link the skills, seed the pointer
├── packs/six-pack/                # the SwarmForge pack: launcher stub, conf, constitution, six role prompts, operator README
├── scripts/
│   ├── validate-frontmatter.ts    # frontmatter gate
│   ├── check-no-em-dash.sh        # no em dash on an added line (hook + CI)
│   ├── check-citations.py         # file:line evidence pinned to content (--reanchor, --lock)
│   ├── check-matrix-drift.py      # conformance-matrix.md true to the vendored canon
│   ├── check-workflow-assets.sh   # shipped workflows parse and are self-sufficient
│   ├── check-six-pack.sh          # the pack parses, the prompts close the loop, the README table matches the conf
│   ├── smoke-test.sh              # e2e (Bun): replay the copy block above, run and block every gate
│   ├── smoke-test-next.sh         # e2e (Next.js): scaffold a package, prove the design-system lint block
│   ├── smoke-test-java.sh         # e2e (Java): scaffold from the canonical pom, run and block every gate
│   ├── trigger-eval/              # does the skill load on the queries it should, and not on the others
│   ├── conformance-eval/          # does produced code follow the rules, with-skill vs a frozen baseline, plus the judge
│   └── review-eval/               # does atelier-review-me catch planted violations, recall + citation + false positives
└── skills/
    ├── atelier/
    │   ├── SKILL.md               # the 37 hard rules, the TDD loop, the disciplines, the workflow
    │   ├── assets/                # copyable gates: hooks, tripwires, CI workflows, test helpers, Java exemplars
    │   └── references/            # 27 files, one per concern: architecture, testing, result-type, security, privacy, ...
    ├── atelier-greenfield/SKILL.md
    ├── atelier-grill-me/SKILL.md
    └── atelier-review-me/SKILL.md
```

</details>

<details>
<summary>Repository CI, nine jobs on every push</summary>

- **frontmatter**: every `SKILL.md` opens with a valid `name` and `description` within the skill-loader limits.
- **em dash**: no em dash on an added line; the selftest runs first so the gate is seen red before it judges the range.
- **grader selftests**: the conformance grader, the tier-1 task selector, the judge and the review grader each prove they can fail. Four grader defects have been found so far, every one punishing the better review.
- **matrix drift**: the matrices stay true to the vendored canon, every cited line keeps its content, the shipped workflows parse and stay self-sufficient.
- **six-pack**: the pack parses under the launcher's rules, every role prompt closes the handoff loop, the operator README's role table equals the conf.
- **smoke test, Bun**: replays the copy block into a scratch repo on the current unpinned toolchain and proves every gate both passes on a conforming tree and blocks its target violation, the style bans and layer zones included.
- **smoke test, Next.js**: scaffolds a package from the canonical configs and proves the design-system lint block catches a hook, a `next/*` import or app code inside a component, and a `className` outside `src/components/**`.
- **smoke test, Java**: scaffolds from the canonical `pom.xml` and proves Spotless, the JaCoCo tiers, PIT, the enforcer's mock ban, the ArchUnit layer rules and the hooks each pass and each block their violation.

A new ESLint, TypeScript, Stryker, Next or Maven-plugin major that breaks a shipped asset fails CI here before a user hits it. Run them locally with `bash scripts/smoke-test.sh`, `bash scripts/smoke-test-next.sh`, and `bash scripts/smoke-test-java.sh`; the fast checks are `bun run scripts/validate-frontmatter.ts` and `python3 scripts/check-citations.py`.

</details>

## Credits

Inspired by the layout of [ramziddin/solid-skills](https://github.com/ramziddin/solid-skills). The engineering substance encodes patterns from Clean Code (Robert C. Martin), Test-Driven Development (Kent Beck), Domain-Driven Design (Eric Evans), and Refactoring (Martin Fowler), adapted to a class-free Bun/TypeScript codebase and its Java translation. The production disciplines (hard rules 27-34 and their references) are the executable encoding of the eighteen pillars in *The Global Rules Every New Project Should Have* and its *Do and Don't* companion. The security reference and its false-positive filter are adapted with credit from [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review).

## Changelog

Notable changes are in [CHANGELOG.md](./CHANGELOG.md); the suite is versioned as a whole. The current release is 2.2.0.

## License

[MIT](./LICENSE)
