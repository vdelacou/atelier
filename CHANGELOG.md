# Changelog

All notable changes to the atelier skill suite. Format follows
[Keep a Changelog](https://keepachangelog.com/); this suite versions the standard as a
whole, not any single skill.

## [Unreleased]

## [2.3.0] - 2026-09-09

The enforcement release: hard rules 36 (tests run in random order) and 37 (the dependency rule
as lint), the style rules, the no-inline-ignore rule, the Java mock ban and the Bun-only rule
turned from prose into gates, the Next variant's first CI workflow, the citation
gate pinning both ends of a range with a re-anchor mode, and the README rewritten as a pitch.

### Upgrading from 2.2.0

- Re-extract `eslint.config.js` (Bun) or `eslint.config.mjs` (Next) from its reference. It carries
  the style bans (rules 1, 7, 10, 18), the use-case `try/catch` ban (17), the domain `fs` ban (20,
  Bun only), the layer zones (37, Bun only), `noInlineConfig` with the `@ts-` and other-tool
  suppression bans (15), and the mock-ban message tagged with its rule. Then `bun run lint`: expect
  reds on inline `type` specifiers, hidden classes, curried helpers, a `try/catch` in a use-case, a
  cross-layer import, and every suppression comment in the tree, each to refactor or to turn into a
  project-level severity change with a reason.
- Change the `test` script to `bun test --randomize` and re-copy `ci.yml` and `stryker.conf.json`
  (rule 36). A red run prints `--seed=<n>`; the seed replays the order.
- Re-copy `check-package-json.sh` (rule 5: a foreign lockfile or a `node`/`npm`/`npx`/`pnpm`/`yarn`/
  `vite` script entry now fails gate 2). On Next, add it to the `simple-git-hooks` pre-commit line
  before test and lint, then `bun run prepare`.
- On Next, copy `assets/ci-next.yml` to `.github/workflows/ci.yml` with `check-commit-range.sh`,
  `check-package-json.sh` and `check-bundle-size.sh`, and make it the required status check.
- On Java: add `src/test/resources/junit-platform.properties` with the random orderers (36); add
  the `archunit-junit5` test dependency and copy `assets/java/LayerRulesTest.java` into
  `src/test/java/<pkg>/architecture/`, renaming its package and root (37); re-extract the enforcer
  block of the canonical pom and re-copy `check-pom.sh` (13); copy `check-no-suppressions.sh` into
  `scripts/`, re-copy `pre-commit-java`, `ci-java.yml` and `pmd-ruleset.xml`, and re-extract the
  PMD block of the canonical pom (15).
- Re-copy `assets/claude-md-pointer.md` into your `CLAUDE.md`: the block names hard rules 1-37.
- The manual gate install left the README; each variant's bootstrap checklist in its reference
  carries it. No action unless you linked to the README section.

### Added
- **Hard rule 36 and canon 4.9: tests run in random order, no test depends on another.**
  `bun test --randomize` is the `test` script in the Bun and Next.js skeletons, the CI step in
  `assets/ci.yml` and Stryker's command runner; a red run prints `--seed=<n>` and the seed replays
  the order. Java carries `src/test/resources/junit-platform.properties` with the random method
  and class orderers. `references/testing.md` gains the section (what the rule forbids, what it
  asks for), the smells row names the shuffle, and the three smoke tests prove the gate can fail
  with an order-dependent pair (green in declaration order, red under a seed). The canon gains
  sub-concept 4.9 under pillar 4 (count 120), accepted 2026-09-06. Consumers: change the `test`
  script, re-copy `ci.yml` and `stryker.conf.json`, add the properties file in Java, and re-copy
  the pointer block (rules 1-37).
- **Hard rule 37 and the style rules as lint: a `class`, an inline `type` specifier, a `try/catch` in a
  use-case, a curried arrow chain, `node:fs` in the domain and a domain file importing infra now fail
  `bun run lint`.** Found 2026-09-08: SKILL.md said the hard rules were enforced by ESLint, and the
  canonical config caught only rules 2, 3, 6, 13 and 35 of the style set. The `eslint.config.js` of
  `references/bun-typescript.md` gains `STYLE_BANS` (rules 1 and 10, 7, 18; the `create[A-Z]` DI factory
  exempt), `TRY_BAN` under `src/use-cases/**` (17), `FS_BAN` over `src/**` outside tests,
  `src/test-helpers/**` and `src/infra/**` (20), and one `layerZone` per layer under `src/` (rule 37, the
  dependency table of `references/architecture.md` as `no-restricted-imports`, tests excepted). The Next
  `eslint.config.mjs` carries `STYLE_BANS` and `TRY_BAN`; no `fs` ban there (Node runtime) and no zones
  yet. Rules 1, 7, 10, 17, 18, 20 cite their lint rule in SKILL.md; the Bun smoke test proves each ban red
  with its rule number in the message and the exemptions green, the Next smoke test the three universal
  bans. Java gets the same rule as a shipped test: `assets/java/LayerRulesTest.java` (ArchUnit 1.5.0,
  `archunit-junit5` in the canonical pom, test scope) runs the layered architecture over `domain`,
  `usecases`, `infra`, `api`, `composition` plus two framework bans in every `mvn test`, so `verify` and
  CI carry it; the Java smoke test proves a domain class importing a use-case red. Consumers: re-extract
  `eslint.config.js` or `eslint.config.mjs` from the reference, run `bun run lint` and expect reds on
  inline `type` specifiers (the standard's own smoke fixture carried one) and on any hidden class or
  curried helper; on Java add the `archunit-junit5` dependency, copy `LayerRulesTest.java` into
  `src/test/java/<pkg>/architecture/` and rename its package and root; then re-copy the pointer block
  (rules 1-37).
- **Rule 13 in Java is a gate.** The canonical pom's enforcer gains `bannedDependencies` for `org.mockito`,
  `org.easymock`, `org.powermock`, `org.jmockit`, `quarkus-junit5-mockito` and `quarkus-panache-mock`
  (enforcer 3.x walks the whole tree, so a Mockito arriving through another artifact is caught too), and
  `check-pom.sh` rejects a declared mock coordinate in the fast hook. The Java smoke test proves both red
  on a planted `mockito-core`. Consumers: re-extract the enforcer block of the canonical pom and re-copy
  `check-pom.sh`.
- **Rule 15 is lint: no inline ignore survives.** Probed 2026-09-08, five of seven suppression forms passed
  the canonical config and a file-level `/* eslint-disable */` switched off every other ban. Both TypeScript
  configs gain `linterOptions.noInlineConfig: true` (every ESLint directive comment is inert and reported,
  so `--max-warnings=0` fails on the comment and the hidden violation surfaces beside it),
  `@typescript-eslint/ban-ts-comment` on every `@ts-` form (a described `@ts-expect-error` included) and
  core `no-warning-comments` on the markers other tools read (`prettier-ignore`, `stryker disable`,
  `nosonar`, `sonar-ignore`, `snyk-ignore`, `deepcode ignore`, `biome-ignore`, `oxlint-disable`, the `c8`,
  `v8` and `istanbul` coverage ignores). The Bun smoke test proves eight forms red on their own messages,
  the Next smoke test three. Consumers: re-extract `eslint.config.js` or `eslint.config.mjs`; every
  suppression comment in the tree becomes a finding to refactor or to turn into a project-level severity
  change with a reason. Java gets three layers: `assets/check-no-suppressions.sh` (new; staged Java lines in
  the fast hook as gate 3 of 5, `--all` over the tree in CI) rejects `@SuppressWarnings`,
  `@SuppressFBWarnings`, `NOPMD`, `NOSONAR`, `CHECKSTYLE:OFF` and `noinspection` as text; the
  `NoSuppressWarnings` XPath rule in `pmd-ruleset.xml` flags the annotation in `verify` (defence in depth,
  since `@SuppressWarnings("PMD")` suppresses its own report); the canonical pom's `suppressMarker` is an
  impossible token, so a `// NOPMD` comment is inert and the finding it hid resurfaces. Consumers on Java:
  copy `check-no-suppressions.sh` into `scripts/`, re-copy `pre-commit-java`, `ci-java.yml` and
  `pmd-ruleset.xml`, re-extract the PMD block of the canonical pom.
- **Rule 5 is a gate.** `check-package-json.sh` (gate 2 of the fast hook, re-run in CI) also rejects a
  foreign lockfile tracked or staged anywhere (`package-lock.json`, `npm-shrinkwrap.json`, `yarn.lock`,
  `pnpm-lock.yaml`) and a `scripts` entry that calls `node`, `npm`, `npx`, `pnpm`, `yarn` or `vite`
  directly, an env prefix and a segment after `&&` included; `bunx vite` passes, the rule says directly.
  Until 2026-09-08 a tracked npm lockfile passed every hook. Consumers: re-copy `check-package-json.sh`.
- **The Next variant runs gate 2.** The root `package.json` skeleton's `simple-git-hooks` pre-commit calls
  `bash scripts/check-package-json.sh` before test and lint, and the bootstrap checklist copies the asset;
  until 2026-09-08 no Next repo built from the skeleton ran the package.json gate at all, so rules 5 and 19
  were unenforced there. The Next smoke test proves `"latest"` and a `node` script red. Consumers on Next:
  copy `check-package-json.sh` into `scripts/`, add it to the hook line, `bun run prepare`.
- **The Next variant ships a CI workflow.** `assets/ci-next.yml`, the authoritative gate set beside `ci.yml`
  and `ci-java.yml`: commit messages over the pushed range through commitlint (the hook's grammar), the
  commit-size range gate, gate 2, gitleaks over the full history, then test, lint, typecheck and build for
  every workspace on a frozen lockfile, and the bundle budget on each `packages/*/out`. Until 2026-09-08 a
  Next repo built from the skeleton had hooks only, so `--no-verify` had nothing behind it. The
  workflow-asset gate lints it against the Next reference. Consumers on Next: copy it to
  `.github/workflows/ci.yml` with `check-commit-range.sh`, `check-package-json.sh` and
  `check-bundle-size.sh`, then make it the required status check.

### Changed
- The README is rewritten from scratch as a pitch, no section carried over: why agents need a
  standard, the three things the suite delivers (a standard, enforcement, proof), a before-and-after
  snippet, three steps to start, the six-pack as a team with its install and first card, the stack
  table, the four skills by moment, the rules at a glance, the canon (what the Global Rules are, the
  two-way audit of the matrices, the drift and citation gates), the measured scorecards (conformance
  and review evals, the first six-pack run, the CI counts), a short FAQ, a contributor pointer and
  the lineage.
- The six-pack section of the README and the pack manual say how the pieces fit (SwarmForge supplies
  the runtime from its `main`, this repo the pack, the project receives both under `swarmforge/` and
  runs there) and how to update (skills by pulling the linked clone, runtime and pack by re-running
  the installer after a Teardown, which replaces them wholesale and commits nothing). The README also
  names what the installer seeds exactly: the pointer block, the LESSONS header, `tmp/` in
  `.gitignore`. The manual gate install is no longer in the README; each variant's bootstrap
  checklist in its reference carries it, and `smoke-test.sh`'s header names that checklist as the
  block it replays.
- The Bun config's mock-ban message (`MOCK_BAN`, hard rule 13) ends with the rule number like the Next
  one, and both smoke tests now prove the ban red, which no fixture had done since it shipped: a `mock`
  import in a test file (the base block) and in a scoped production file (a Bun layer zone, a Next
  design-system component), the second because ESLint replaces a rule's options per block and a zone
  that dropped the copy would go quiet. Consumers: re-extract `eslint.config.js` if you want the tag in
  the message; the ban itself is unchanged.

### Harness
- `tasks.json`, h4 7.1 (absent mode): the check no longer matches a method call such as
  `query.byOrg(orgId)`. It matched the skill arm's query-builder call in the 2.3.0 tier-2 pass and
  read a conforming tree 60/61: the fifth grader defect, and like the four before it the one
  punishing the better code. The grader selftest pins a property read red and the call green. The
  frozen baseline arm is re-frozen from that pass's own 21 baseline runs (one pass, 45/61), since
  the three-pass run directories behind the 2.1.0 fixture are gone from the workspace.
- `select-tasks.py` (tier 1): a rule range from 1 over at least half the set is the count of the rules
  and selects nothing; the rule ceiling is read from the SKILL.md hard-rules section instead of a
  constant stuck at 35 (an explicit "rule 36" used to select nothing); within a hunk only the
  references that differ between removed and added text count. The 2026-09-08 lint-gates diff selects
  5 of 21 tasks instead of 21; each fix has a selftest case that fails without it.
- `check-citations.py` scans `.java`, `.xml` and `.properties` citations too; the `LayerRulesTest.java:18`
  evidence in matrix row 3.1 had sat unpinned for a day. The selftest now drifts a cited `.java` line.
- `check-citations.py` fails a citation whose target line is blank and refuses to lock one; three range
  citations had pinned the blank line after a heading since the lock was created, and twice on 2026-09-08 a
  shifted pin was re-locked onto a blank before the lock diff caught it. The three rows now cite the
  paragraph they quote.
- `check-workflow-assets.sh` parses every shipped workflow (python3 with PyYAML, else ruby) before grepping
  it; the first `ci-next.yml` draft did not parse and only a hand check caught it. A parser that says no
  fails the gate, a machine with no parser prints a note, and the selftest rejects the colon-space fixture.
- `check-citations.py` pins both ends of a `file:N-M` range citation. Only the start was pinned, so range
  ends rotted unseen: the preview found two ranges ending on a blank line and three inverted (end before
  start) after starts had been re-anchored without their ends. The five are repaired from the target
  text and the lock grows from 183 to 233 entries.
- `check-citations.py --reanchor`: after an edit shifts cited lines, every pinned citation moves to the
  unique line that now holds its snippet, both ends of a range, in both matrices, and the lock is rewritten;
  a snippet that is gone or appears twice is reported and left for a human, nothing locked. Replaces the
  hand scripts that did this eight times on 2026-09-08 and never moved a range's end.

## [2.2.0] - 2026-09-06

The six-pack release: the standard as a team of six (the SwarmForge pack, its installer and its
CI gate, the first live run measured), the README rebuilt around the value and two quick starts,
the third sonarjs rule turned off and re-probed weekly, and the two redirect stubs removed.

### Upgrading from 2.1.0

- Re-extract `eslint.config.js` from `references/bun-typescript.md`: `sonarjs/function-return-type`
  is off, with its reason beside the two 2026-08-29 switches.
- Re-copy `assets/claude-md-pointer.md` into your `CLAUDE.md`: the block names hard rules 1-35.
- If your repo was installed from the 2.1.0 README's Bun block, copy the three assets it skipped:
  `check-commit-messages.sh` and `check-commit-range.sh` into `scripts/` (the shipped `ci.yml`
  calls both) and `audit.yml` into `.github/workflows/`.
- `references/tdd.md` and `references/class-to-module.md` are gone; re-point any pinned path at
  `references/testing.md` and `references/design-patterns.md`.
- Optional: the six-pack. From a clone of this repository, `get-atelier-six-pack` composes the
  pack into your project; the README's "Start here with the six-pack" walks the first card.

### Added
- **The atelier six-pack** (`packs/six-pack/`, `get-atelier-six-pack`): the four skills as a
  [SwarmForge](https://github.com/unclebob/swarm-forge) pack of six Claude Code roles
  (specifier, coder, cleaner, architect, hardener, reviewer) that take an operator's card from
  a grilled specification to a rule-cited verdict, each in its own git worktree. The
  constitution makes the standard the engineering law and turns off SwarmForge's Gherkin and
  CRAP/DRY tooling; the local articles read rules 24 and 25 for a board (the Attention approval
  of the spec is the yes; no role pushes; a test older than the card is frozen).
  `scripts/check-six-pack.sh` is its CI gate (the launcher's parse rules, the handoff chain
  closing in conf order, the README role table equal to the conf), with a selftest that plants
  eleven defects. First live run 2026-09-05 on an empty repository with a small CLI card:
  card to Done in 1h56, one Attention approval, zero clarifications, 35 commits, 88 tests,
  coverage 100 on every tier, mutation 100, verdict conformant with one Low finding fixed by
  the reviewer; the run's three costs (the first-start prompts, the audit-gate detour, the
  `lint:strict` gap) are folded into the pack.

### Removed
- `references/tdd.md` and `references/class-to-module.md`, the redirect stubs 2.1.0 kept for one
  release. Their content lives in `references/testing.md` and `references/design-patterns.md`;
  re-point any pinned path.

### Fixed
- `sonarjs/function-return-type` is off in the canonical Bun `eslint.config.js`
  (`references/bun-typescript.md`), dated 2026-09-05 against sonarjs 4.2.0. It fires on every
  function that returns through the `ok()`/`err()` helpers, because `Result<T, never>` and
  `Result<never, E>` are two return types to it, so `lint:strict` was red on every conforming
  consumer while this repo's smoke fixture stayed green by returning union literals under one
  annotation. The fixture now returns through the helpers, and the weekly canary re-probes
  three rules instead of two. Consumers: re-extract `eslint.config.js` from the reference.
- `assets/claude-md-pointer.md` said hard rules 1-34; rule 35 landed in 2.1.0.
- The README's Bun install block never copied `check-commit-messages.sh` and
  `check-commit-range.sh`, both called by the shipped `ci.yml`, nor `audit.yml`; its symlink
  alternative linked one skill of four; the Java line named five of the variant's eleven
  assets; the layout tree omitted nine assets and four root files; the CI job count said eight.

## [2.1.0] - 2026-09-03

The measured-standard release: the 2026-09-02 audit's findings closed (five doctrine
contradictions, two gate holes, the em-dash ban made a gate, SKILL.md cut from 570 to 194 lines
without losing a noun the evals assert), hard rule 35 (cyclomatic complexity), an eval harness
that measures a doctrine edit in minutes instead of hours, the mutation cadence moved off the
merge path, and eight canon revisions accepted, including the profiles appendix with every
stack number the sub-concepts used to state.

### Upgrading from 2.0.0

- Re-copy the shipped workflows: `ci.yml` and `ci-java.yml` now export `GITHUB_EVENT_BEFORE`
  (the commit gates and the mutation step were vacuous on a push to main without it) and run
  mutation on the changed files only; `audit.yml` and `audit-java.yml` run the skill-pin gate
  in tree mode against `SKILL_PIN_UPSTREAM`. New: `mutation.yml` / `mutation-java.yml` (the
  daily full sweep) and `pit-changed.sh` (Java, next to `mutate-changed.sh`).
- Re-copy every `check-*.sh` you carry; six of them changed behaviour (see Fixed).
- ESLint configs gain `complexity: ['error', 10]` (rule 35); the Java pom gains
  `maven-pmd-plugin` with `assets/java/pmd-ruleset.xml` and the `pitest.targetClasses` property
  the narrowed PIT run overrides. Re-extract both from their references.
- `references/tdd.md` and `references/class-to-module.md` are redirect stubs in this release
  (their content lives in `testing.md` and `design-patterns.md`); they are removed in 2.2.0.
- Rule 32 asks for an eval artifact (a case set, a `--min-score` runner, the CI job), no longer a
  sentence; rule 12 governs the value-object section; boundary factories return `Result`
  (`parseX`), constructors assert (`x()`); Money is integer cents everywhere.

### Harness

- Conformance eval: 4.8 and 7.5 assert shape, not vocabulary (an eval set with a bar in any
  `.ts`/`.json` file; a forged-owner scenario or a 404), pinned by the grader selftest; a tier-1 mode,
  `CONFORMANCE_SINCE=<ref>`, runs only the tasks the skill diff can affect (`select-tasks.py`,
  selftested in CI), skill arm, six jobs; the baseline arm is a frozen fixture (`baseline-arm.json`,
  keyed to the prompts and assertions, `grade.py --frozen-baseline`, `freeze-baseline.py`), so a
  skill edit no longer re-runs the arm that never reads the skill; every session is capped
  (`CONFORMANCE_TIMEOUT_MIN`, graded as produced) and each task's scorecard line prints as it lands;
  the three-tier contract is in baseline.md.

### Added
- **Hard rule 35, cyclomatic complexity at most 10 per function**, lint-enforced in every
  variant: ESLint `complexity: ['error', 10]` in both TypeScript configs, PMD
  `CyclomaticComplexity` (`methodReportLevel` 11) bound to `verify` in the Java pom with the
  ruleset shipped as `assets/java/pmd-ruleset.xml`. Each smoke test plants a complexity-11
  function and sees the gate red, and a complexity-10 one green. The size caps and this cap
  are complementary: the cap counts the one-line chain of `&&`/`??`/ternaries the size caps
  never see. `sonarjs/cognitive-complexity` stays off; one metric.
- An em-dash gate for the skill repo itself (`scripts/check-no-em-dash.sh`, hook and CI).

### Changed
- Mutation testing cadence: CI mutates the changed files only, on every pull request and
  push (`mutate:changed` resolves the pushed range from `github.event.before` like the commit
  gates; Java gets `pit-changed.sh`, which narrows PIT through the pom's new
  `pitest.targetClasses` property). The full sweep is a daily scheduled workflow
  (`assets/mutation.yml`, `assets/mutation-java.yml`, `workflow_dispatch` on demand), never a
  commit gate. Consumers copy the two new workflows and the script; the pom fence changed.
- Rule 32's eval gate is an artifact, not a sentence: a labeled case set under
  `evals/<capability>/`, a runner that exits non-zero below `--min-score` wired as the `evals`
  package script, and the CI job that runs it on prompt, pin, or schema changes. `ai.md` shows
  the three files and a minimal runner; the after-change checklist, the review-me discipline
  scan, and the red-flag list name the same shape. Found by the h6 conformance task, which
  the skill arm missed in four runs of five by describing the eval in a comment.

### Fixed
- `check-commit-messages.sh` and `check-commit-range.sh` checked an empty range on a push to
  main (HEAD is origin/main there), so the CI half of rule 23 was decorative on the
  trunk-based workflow; both now walk `github.event.before..HEAD`, which the shipped
  workflows export.
- `check-io-deadlines.sh` never matched `globalThis.fetch(`, the idiom the doctrine
  prescribes, and accepted the word `timeout` in a comment as the deadline; it now checks
  per call for `AbortSignal.timeout(`/`signal:` within eight lines, comments stripped.
- `check-data-lifecycle.sh` exempted a hard delete on the strength of a `// retention`
  comment and knew only DROP COLUMN and RENAME COLUMN; exemptions are path-anchored and the
  DDL pattern covers DROP TABLE, RENAME TO, TRUNCATE, ALTER COLUMN TYPE.
- `check-pii-channels.sh` read a logger call on one line only and four literal names; it
  joins a call with up to three following lines and matches thirteen identifiers with any
  casing or prefix.
- `check-package-json.sh` blocked a manifest for a `publishConfig.tag` and passed an
  `npm:pkg@latest` alias; it reads the four dependency blocks only.
- `check-isolation-tests.sh` passed a route when any test in the directory contained `404`;
  the test must be named for the route and assert 404 inside a test block.
- `check-skill-pin.sh` compared SKILL.md alone from the shipped workflow; it now compares the
  whole vendored tree against a cloned upstream (`SKILL_PIN_UPSTREAM`), with its selftest in
  CI and the smoke test.
- `check-coverage.ts` had a function of complexity 14; refactored under the new cap without
  a behaviour change.

## [2.0.0] - 2026-07-12

The production-disciplines release: the suite becomes the executable encoding of all
eighteen pillars of *The Global Rules Every New Project Should Have*, gains a Java variant,
and grows measurement and enforcement harnesses.

### Added
- **Production disciplines (hard rules 27-34)**: privacy (no PII in logs/URLs/query strings),
  tenant isolation (token-derived, fail-closed, cross-tenant test per endpoint), IO deadlines
  with bounded idempotent retries, additive/reversible data changes (soft delete + expand-
  contract migrations), optimistic locking, AI models behind ports with pinned snapshots and
  eval gates, rented auth/crypto, and synthetic-only test data.
- **Nine discipline references**: `privacy`, `isolation`, `reliability`, `observability`,
  `delivery`, `metrics`, `ai`, `governance`, `product` (accessibility + validate-before-build).
- **Java (Quarkus) variant**: `references/java-quarkus.md` (records + sealed `Result`, ports
  with hand-written fakes, no Mockito, Maven-wrapper toolchain, Spotless, JaCoCo tiers, PIT),
  shipped domain assets (`assets/java/`), a canonical pom, and the `smoke-test-java.sh` CI gate.
- **Discipline tripwires**: staged-diff guard assets for rules 27-30 (`check-pii-channels`,
  `check-io-deadlines`, `check-data-lifecycle`, `check-isolation-tests`), exercised by the
  Bun smoke test.
- **Accessibility gate (rule 17.6)**: `eslint-plugin-jsx-a11y` error-level on the design system,
  proven by the Next smoke test.
- **Measurement harnesses**: `scripts/trigger-eval/` (does the skill load; suite mode measures
  which skill wins a query) and `scripts/conformance-eval/` (does produced code follow the
  rules, with-skill vs baseline). Verdicts: trigger 32/34, routing 13/13, conformance 24/25
  vs 22/25 baseline.
- **CLAUDE.md seed** written at repo birth (greenfield) and adoption (review-me), so the
  standard rides in deterministic repo context.
- **CI**: `smoke-test-java` job; a weekly `canary` probing whether the TypeScript pin can lift.

### Changed
- The main skill description now covers three variants (Bun, Next.js, Java) and names the
  production disciplines; rule 24 gains an unattended carve-out (new tests may be written
  headless; existing tests stay gated).

### Fixed
- Pinned `typescript@^5` in the Bun smoke test: `eslint-plugin-sonarjs` crashes under
  TypeScript 7 (tracked; a weekly canary signals when the pin can lift).
- `check-pom.sh` matched `-SNAPSHOT` in enforcer prose; the trigger-eval runner false-zeroed
  under parallel probes (shared command dir) and explore-first models.

## [1.x] - before 2026-07-11

The original standard: strict TDD (primary-port SUT, hand-written fakes, no mocks), Clean
Architecture, `Result<T, E>` at IO boundaries, branded types, a Bun-only toolchain, Atomic
Design with a sealed design system, the eight-gate pre-commit hook and coverage/mutation
tiers, and the companion skills (greenfield, grill-me, review-me). See the git history before
`docs(atelier): update the README and plan for the disciplines and the Java variant`.
