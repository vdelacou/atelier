# Atelier

**Senior-engineer output from your coding agent. Enforced, not requested.**

Atelier is a coding standard packaged as an [Agent Skill](https://github.com/anthropics/skills) suite. Install it once and every code task your agent takes in a Bun/TypeScript, Next.js, or Java (Quarkus) repo comes out test-first, cleanly layered, typed at the boundaries, private by default and production-ready. The agent does not need to be told. The standard loads on every session, and lint, git hooks and CI hold the line when prose alone would not.

It runs two ways. Four skills inside your normal agent session, or a six-agent [SwarmForge](https://github.com/unclebob/swarm-forge) pack that turns a one-paragraph card into specified, tested, hardened, reviewed code on your `main` while you approve once.

## Why a standard for agents

Coding agents are fast and fluent. They are also inconsistent in exactly the ways that cost you later.

Ask three times for the same feature and you get three styles: a class here, a bare function there, an interface nobody needed. Tests arrive after the code, if at all, and a failing one gets loosened until it passes. Errors are thrown across layers, caught nowhere useful and logged with the customer's email in the message. Rows get hard-deleted, columns get renamed in place, network calls run with no deadline, and the AI model is pinned to `latest`. Then the agent commits, and sometimes pushes, without asking.

None of that is a model failing. It is the absence of a standard the agent can be held to. Atelier is that standard, written for agents, with a machine check behind each rule.

## What you get

**A standard.** 37 hard rules and the production disciplines behind them, in one `SKILL.md` and 27 reference files, one per concern: architecture, testing, error handling, security, privacy, tenant isolation, reliability, observability, delivery, AI models as dependencies, product and accessibility. Every rule says what it forbids, what it asks for instead, and where the long form lives.

**Enforcement.** The rules that can be lint are lint: the style bans, the layer dependency table, the no-inline-ignore rule, complexity at most 10. The rest are hooks, tripwires and CI: a fast pre-commit that caps commit size, blocks unpinned dependencies and secrets, lints the staged files and typechecks; a `commit-msg` hook for Conventional Commits; tripwires for personal data in logs and URLs, network calls without a deadline, routes without a cross-tenant test, hard deletes; CI that runs the full suite, per-tier coverage and mutation on the changed files as the merge gate. All of it ships as copyable assets.

**Proof.** Two evals measure the skill against an unaided agent on the same tasks. Three smoke tests replay the install on the current unpinned toolchain and prove every gate both passes and blocks its target violation. A conformance matrix pins the doctrine to a written 120-point canon with file-and-line citations that CI keeps honest ([the canon](#built-on-a-written-canon)). The numbers are [below](#how-we-know-it-works).

## See the difference

Ask an unaided agent to fetch a user by id and you get some version of this:

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

Under atelier the same request starts here, before any adapter exists:

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

The id is validated once, at the boundary, and carries its proof as a type. The port returns a `Result` with an error you can match on. The `fetch` lands in one infra adapter behind that port, with `AbortSignal.timeout` on the call and the `Logger` port instead of `console`. The use-case is tested through a hand-written in-memory `Users` fake, and the failing test was proposed to you before it was written.

## Get started in three steps

**Install the skills, once per machine.** The [`skills`](https://www.npmjs.com/package/skills) CLI by Vercel Labs finds all four in this repo:

```bash
bunx skills add vdelacou/atelier
```

`npx` works the same. The default target is Claude Code's user skills directory, `~/.claude/skills/`. Pass `-g` for a project-local install, or `-a <agent>` for `opencode`, `cursor` and the other agents the CLI supports.

**Point the repo at the standard, once per repo.** Skill triggering depends on your prompt matching a description. A pointer block at the top of `CLAUDE.md` is loaded on every session whatever you type, so it is the primary mechanism and triggering is the fallback:

```bash
SKILL=~/.claude/skills/atelier
printf '# CLAUDE.md\n\n' > CLAUDE.md
cat "$SKILL/assets/claude-md-pointer.md" >> CLAUDE.md
```

Copy the block rather than retyping it. When the wording changes upstream, a re-copy propagates it.

**Ask for work, in your own words.** No skill names, no reminders about tests or style:

- "Add a use case that archives an order and emits the event."
- "Build the pricing page with a monthly and yearly toggle."
- "Expose invoices as a paginated endpoint on the Quarkus service."
- "This module has grown. Refactor it."
- "Turn the raw `email` and `tenantId` strings into proper types."

The gates are the agent's job, not yours. Say "scaffold a new Bun repo" (or a Next.js package, or a Java service) on an empty directory and `atelier-greenfield` lays the layout, copies the gate assets, wires the hooks and proves every gate green before the first commit. Say "adopt the standard into this repo" on an existing codebase and `atelier-review-me` scans it and returns a staged plan whose first slice installs the gates without tripping them on legacy code. The manual path, for each variant, is the bootstrap checklist at the end of its reference: [`bun-typescript.md`](skills/atelier/references/bun-typescript.md), [`nextjs-monorepo.md`](skills/atelier/references/nextjs-monorepo.md), [`java-quarkus.md`](skills/atelier/references/java-quarkus.md).

## Scale it to six agents

The six-pack is the same standard run as a team. You write a card. Six Claude Code agents, each in its own git worktree, hand committed work down a pipeline and back, and you make one decision: approving the specification.

```text
New Task -> specifier -> Attention -> coder -> cleaner -> architect -> hardener -> reviewer -> Done
```

- **specifier** grills your card one question at a time, exploring the tree before each and leading with a recommendation, then writes `docs/specs/<card>.md`: scenarios, the disciplines the card triggers, decisions and ADRs. Runs `atelier-grill-me`.
- **coder** makes the scenarios pass test-first under `atelier`. On an empty tree it scaffolds the variant green from the first commit with `atelier-greenfield`.
- **cleaner** takes the refactor step: names in domain language, the clean-code numbers, complexity at most 10, duplication extracted at the third occurrence.
- **architect** owns structure: layers and dependency direction, ports as function types, branded value objects, and the lint rules that pin each boundary with a fixture that proves they fire.
- **hardener** proves the tests bite: mutation at 90 or above, a test seam on every adapter, the discipline tripwires, the security lens, a red fixture for every gate the card added.
- **reviewer** runs `atelier-review-me` over the whole diff, cites a rule number for every finding, fixes the narrow ones, writes `docs/reviews/<card>.md`, appends the lessons and closes the card.

The hooks run in every worktree. No test older than the card is touched. No role ever pushes.

### Install it

You need `zsh`, `git`, `tmux`, Babashka (`bb`), a signed-in `claude` CLI and the variant's toolchain (Bun, or JDK 21 with the Maven wrapper). `gitleaks` on PATH feeds the secret gate; the hook says so and continues without it.

Run the installer from the project that receives the pack, an existing repo or an empty directory:

```bash
git clone https://github.com/vdelacou/atelier.git ~/code/atelier
cd ~/code/my-project
~/code/atelier/get-atelier-six-pack
```

It writes the `swarm` launcher and the `swarmforge/` runtime, seeds the pointer block in `CLAUDE.md`, an empty `.claude/LESSONS.md` and the runtime's ignore rules, and links the four skills into `~/.claude/skills` unless they are already there (`--skip-skills` and `--copy-skills` change that). It commits nothing. Commit the seeded files yourself, then start:

```bash
git add CLAUDE.md .claude/LESSONS.md .gitignore swarm swarmforge
git commit -m "chore(swarm): install the atelier six-pack"
./swarm
```

### Run a card

`./swarm` brings up the six roles, the handoff daemon and a local dashboard, and opens it. The first start asks Claude Code's two questions in every pane, trust the folder and accept bypass-permissions mode: six panes, twelve answers, from the dashboard's pane view.

Write the card under **New Task** as intent, not design. The card that ran first:

> Bun script CLI that reads a CSV of invoices and prints the total amount per customer as a table. The CSV columns are customer name, customer email, invoice id, amount in EUR cents. The file holds personal data (names, emails). Single user, no tenants, no network, no database. Scope: parse the file, sum per customer, print the table; nothing else. Start with the walking skeleton.

Anything the specifier cannot settle from the tree reaches you in **Attention**. When the spec is written, its handoff waits there too: read it, approve it. From that point the board moves on its own; **Work Queue** opens any role's live pane. **Done** means the spec, the rule-cited verdict, the appended lessons and every commit are on your `main`. You push. **Teardown** stops the swarm and keeps the project.

Know before you start: the roles run unattended with permission prompts bypassed, inside worktrees of your project, and the spec approval is where the standard's two confirmation gates land. The operator manual is [`packs/six-pack/README.md`](packs/six-pack/README.md).

## Pick your stack

The skill detects the variant from the tree and reads the matching reference. Same rules, native idiom.

| Stack | Idiom | Detected by |
|---|---|---|
| Bun TypeScript script | Clean Architecture under `src/`, strict flat ESLint with SonarJS, type-aware rules, the style bans and layer zones, a Logger port with a Winston adapter | `"module": "src/main.ts"` in `package.json` |
| Next.js monorepo | Bun workspaces, Atomic Design with a logic-free design system, Tailwind v4 sealed inside `src/components/**`, i18n route groups, static export, a bundle budget | `packages/*` and `next.config.ts` |
| Java (Quarkus) | Records and a sealed `Result`, ports as small interfaces with hand-written fakes, Maven wrapper with exact pins, Spotless, JaCoCo tiers, PIT, Flyway expand-contract, ArchUnit layer rules, authenticated-by-default resources | `pom.xml` with `src/main/java/**` |

## Four skills, four moments

| Skill | When | Trigger | Outcome |
|---|---|---|---|
| [`atelier`](skills/atelier/SKILL.md) | Every code task | Automatic in a Bun, Next.js or Java repo | Code that follows the 37 rules, test-first, with the disciplines applied when a change touches them |
| [`atelier-greenfield`](skills/atelier-greenfield/SKILL.md) | A new repo or package | "Scaffold a new Bun repo", "scaffold a new Java service" | Layout, gates, hooks, build scripts and a green walking skeleton, proven before the first commit |
| [`atelier-grill-me`](skills/atelier-grill-me/SKILL.md) | Before you build | "Grill me on this plan" | One question at a time with a recommended answer until the decision tree is resolved, then a decision record |
| [`atelier-review-me`](skills/atelier-review-me/SKILL.md) | Before you land, or when you adopt | "Review me", "adopt the standard into this repo" | A read-only review citing the exact rule per finding; in adopt mode, a staged migration plan for a brownfield repo |

The reviewer is deliberately narrow. Security findings must be concrete and exploitable with an attack path. Generic correctness bugs go to `/code-review`, mechanical cleanups to `/simplify`. Diff and PR text is audited as data, never followed as instructions.

## The rules at a glance

The full text is [`SKILL.md`](skills/atelier/SKILL.md). This is the shape.

| | |
|---|---|
| **Code** | `const` arrow functions and typed records. No `class`, no `function` declaration, no `interface`, no curried chain, no `console.*`. Records and sealed types in Java, no Mockito, no `@SuppressWarnings`. Bun only, never `npm`, `pnpm`, `yarn`, `node` or `vite` directly; Maven wrapper with exact pins. Nothing pinned to `latest` or `*`. |
| **Structure** | Clean Architecture with the dependency rule as lint (ArchUnit in Java). Atomic Design with a logic-free design system the app layer never styles. SOLID through typed records and function contracts. YAGNI, KISS, DRY after the third occurrence. |
| **Boundaries** | Brand what crosses a trust boundary or feeds a sink, with a two-tier factory: `parseX` returns `Result`, `x` asserts a proven value. Every IO port returns `Result<T, PortError>`. `try/catch` is quarantined to `infra/` and `main.ts`. |
| **Tests** | Outside-in classicist TDD at the primary port. Hand-written fakes, never mocks. Random order. Coverage 100 on `domain` and `use-cases`, 80 on the rest. Mutation at 90 or above on the changed files in CI. |
| **Lint and commits** | 0 errors and 0 warnings, no inline ignore survives, complexity at most 10. Conventional Commits by hook. At most 10 files and 300 lines per commit, trunk-based. |
| **Two gates** | The agent never commits or pushes without your yes. It never creates, edits, deletes or weakens a test without showing you the change first; TDD stays test-first by proposing the red test. |
| **Privacy** | Personal data never in logs, URLs or query strings. User rights as routine endpoints. Production data never leaves production; fixtures are synthetic. |
| **Isolation** | Owner and tenant from the verified token only, fail-closed reads, row-level security, a cross-tenant 404 test on every owner-scoped endpoint. |
| **Reliability** | A deadline on every outbound call. Bounded jittered retries with idempotency keys. The transactional outbox. Optimistic locking. Soft delete and expand-contract migrations. |
| **AI models** | The model behind a port with a hand-written fake. Pinned dated snapshots. Output treated as untrusted. Prompt-injection fencing. Eval gates in CI. Per-caller spend caps. |
| **Operations** | SLOs as numbers, correlated OpenTelemetry, symptom-based alerts. Pipeline-only deploys with canary and one-step rollback, infrastructure as code, SBOM and signed artifacts, restore drills. |
| **Product** | Error copy that names the cause and the next step. Honest flows. Semantic HTML, keyboard, contrast and an axe gate. Validate before you build. |
| **Memory** | An append-only `.claude/LESSONS.md` the agent reads at session start and extends at session end, and a live `.claude/PLAN.md` so a long task survives a context reset. |

Rules are non-negotiable by design. When a request would break one, the agent rewrites to comply and tells you in one sentence what it substituted.

## Built on a written canon

Atelier is not a list of preferences. It is the executable form of a written canon, [*The Global Rules Every New Project Should Have*](docs/global-rules/global-rules-every-new-project.md): eighteen pillars, from consistency and clean boundaries through security, privacy, isolation, delivery, observability and ownership to validating before you build, expanded into 120 sub-concepts with a [Do and Don't](docs/global-rules/global-rules-dos-and-donts.md) for each, and vendored in this repo under `docs/global-rules/`. The canon states the obligation and stays stack-agnostic. Atelier is its [profile](docs/global-rules/global-rules-profiles.md) for Bun, Next.js and Java: it fixes which tool meets each obligation and at what threshold.

The two are audited against each other, in both directions. The forward matrix, [`conformance-matrix.md`](conformance-matrix.md), gives every one of the 120 sub-concepts a row and a verdict with file-and-line evidence: 118 covered, 2 where the skill is stricter than the canon, none missing, none contradicted. The reverse matrix, [`reverse-matrix.md`](reverse-matrix.md), takes each hard rule back to the canon: most sit on a canon row, some exceed it, and the nine that fix a language or toolchain choice are stack bindings the canon leaves to a profile on purpose. When the two collide, the canon wins and the skill amends. When the skill exposes a defect in the canon, the fix is a [proposed revision](docs/global-rules/proposed-revisions.md), and the accepted ones have changed the canon.

CI keeps this honest. A drift gate hashes the vendored canon and refuses a matrix whose count or titles no longer match it. The 233 citations the matrices make are pinned to the content of the line they cite, so an edit that moves a cited line fails the build until the citation is re-anchored.

## How we know it works

Both evals run the same tasks with and without the skill on Claude Opus and grade mechanically. The scorecards are checked in.

| Measurement | With atelier | Without |
|---|---|---|
| Conformance, 37 assertions over 3 passes ([scorecard](scripts/conformance-eval/baseline.md)) | 111/111 | 86/111 |
| Conformance, the 7-task production-discipline tier | 24/24 | 15/24 |
| Review, TypeScript, 11 planted violations over 3 passes ([scorecard](scripts/review-eval/baseline.md)) | 33/33 caught | 23/33 caught |
| Review, TypeScript, findings that cite the rule | 33/33 | 0/33 |
| Review, Java, 9 planted violations over 3 passes | 27/27 caught | 15/27 caught |
| Review, false positives on clean files | 0 | 0 |

The gap is widest on the rules that hurt most in production. The unaided agent never once preferred soft delete to a hard `DELETE`, in either eval, and built against a port rather than an implementation in one run of six.

The six-pack's first live run, on 2026-09-05 from an empty repository with the card quoted above: one hour fifty-six from card to Done, one approval, zero clarifications, 35 commits by six roles, 88 tests, coverage 100 on every tier, mutation score 100, and a verdict of conformant with one Low finding the reviewer fixed itself.

Nine CI jobs run on every push to this repo: the canon drift and citation gates, the grader selftests, the six-pack gate, and three smoke tests that replay the install on the current unpinned toolchain and prove each shipped gate green on a conforming tree and red on its target violation. A new ESLint, TypeScript, Stryker, Next or Maven-plugin major that breaks an asset fails here before it reaches you. A [field test](field-test.md) on a real consumer repo found the defects the evals could not, and each became a fix.

## Questions you will have

**Do I have to invoke it?** No. In a Bun, Next.js or Java repo the main skill triggers on any code task, and the pointer block in `CLAUDE.md` loads it on every session regardless. The three companions answer to plain phrases: "scaffold", "grill me", "review me".

**Does it work outside Claude Code?** The skills CLI installs into `opencode`, `cursor` and the other agents it supports with `-a <agent>`. Paste the same pointer block into whatever context file your agent reads.

**I have an existing codebase.** Say "adopt the standard into this repo". Adopt mode scans the tree and hands you a staged plan; the first slice installs the gates without tripping them on legacy code, later slices migrate by area.

**Can I switch a rule off?** Not from inside the skill: the rules are the product, and the agent explains each substitution it makes. The suite is MIT, so fork it and edit `SKILL.md`; the smoke tests and the frontmatter validator will tell you what you broke.

**Will it commit or change my tests on its own?** No. Commit and push each wait for an explicit yes, and so does any change to an existing test. Headless runs create new tests only and report everything else.

**What if I vendor the skill and it goes stale?** A pinned skill is a dependency, and it goes stale silently while every gate stays green. The shipped `audit.yml` runs a staleness check on your dependency-scan cadence, and the pointer block reminds the agent to re-sync doctrine and gates together.

## Inside this repository

This repo is the standard, not an application. `skills/` holds the four skills, with the main one's `assets/` (hooks, tripwires, CI workflows, test helpers, Java exemplars) and `references/` (the 27 doctrine files). `packs/six-pack/` is the SwarmForge pack and `get-atelier-six-pack` its installer. `scripts/` holds the harnesses: the three smoke tests, the trigger, conformance and review evals, and the gates that keep the matrices, citations, workflows and pack honest. `docs/global-rules/` is the vendored canon the matrices audit against.

Working here means [`CLAUDE.md`](CLAUDE.md): never an em dash, frontmatter within the loader limits, a plan before multi-step work, small Conventional Commits, and a fixture that proves every new gate can fail. The fast checks:

```bash
bun run scripts/validate-frontmatter.ts
python3 scripts/check-citations.py
bash scripts/check-six-pack.sh
```

The slow ones are `bash scripts/smoke-test.sh`, `smoke-test-next.sh` and `smoke-test-java.sh`; the Java one needs JDK 21+ and Maven.

## Lineage

The engineering substance comes from Clean Code and Clean Architecture (Robert C. Martin), Test-Driven Development (Kent Beck), Domain-Driven Design (Eric Evans) and Refactoring (Martin Fowler), translated to a class-free Bun/TypeScript idiom and back into Java 21. The production disciplines, rules 27 to 34 and their references, are the executable form of the eighteen pillars in *The Global Rules Every New Project Should Have* and its *Do and Don't* companion. The security reference and its false-positive filter adapt [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review), with credit. The repository layout follows [ramziddin/solid-skills](https://github.com/ramziddin/solid-skills).

## Versioning and license

The suite is versioned as a whole in [CHANGELOG.md](./CHANGELOG.md). The current release is 2.2.0. [MIT](./LICENSE).
