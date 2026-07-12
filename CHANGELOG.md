# Changelog

All notable changes to the atelier skill suite. Format follows
[Keep a Changelog](https://keepachangelog.com/); this suite versions the standard as a
whole, not any single skill.

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
