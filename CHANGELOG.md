# Changelog

All notable changes to the atelier skill suite. Format follows
[Keep a Changelog](https://keepachangelog.com/); this suite versions the standard as a
whole, not any single skill.

## [Unreleased]

### Harness

- Conformance eval: 4.8 and 7.5 assert shape, not vocabulary (an eval set with a bar in any
  `.ts`/`.json` file; a forged-owner scenario or a 404), pinned by the grader selftest; a tier-1 mode,
  `CONFORMANCE_SINCE=<ref>`, runs only the tasks the skill diff can affect (`select-tasks.py`,
  selftested in CI), skill arm, six jobs.

### Added
- **Hard rule 35, cyclomatic complexity at most 10 per function**, lint-enforced in every
  variant: ESLint `complexity: ['error', 10]` in both TypeScript configs, PMD
  `CyclomaticComplexity` (`methodReportLevel` 11) bound to `verify` in the Java pom with the
  ruleset shipped as `assets/java/pmd-ruleset.xml`. Each smoke test plants a complexity-11
  function and sees the gate red, and a complexity-10 one green. The size caps and this cap
  are complementary: the cap counts the one-line chain of `&&`/`??`/ternaries the size caps
  never see. `sonarjs/cognitive-complexity` stays off; one metric.
- An em-dash gate for the skill repo itself (`scripts/check-no-em-dash.sh`, hook and CI).

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
