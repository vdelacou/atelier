# Plan: the Java layer gate, rule 37 in the Quarkus variant (2026-09-08)

Goal: the follow-up slice decided on 2026-09-08 when rule 37 landed for TypeScript. `java-quarkus.md`
states the dependency table and offers a grep nobody runs; SKILL.md's "What applies where" says the
Java side is review-checked until the ArchUnit gate lands. Land it: the dependency rule as a shipped
ArchUnit test that runs in every `mvn test`, so `verify` and CI carry it, with a red fixture in the
Java smoke test.

Definition of done (whole task): `assets/java/LayerRulesTest.java` ships, formatted as Spotless wants
it; the canonical pom carries `archunit-junit5` (test scope, a pinned property); `java-quarkus.md`
names the test where it names the dependency rule, in the rules table, the gates list, the bootstrap;
SKILL.md rule 37 and the table row cover Java; the Java smoke test copies the asset, asserts the three
rules ran green inside `verify`, and proves a domain class importing a use-case red on the
"Architecture Violation" message; matrices and citations updated; CHANGELOG extends the rule 37 entry;
Java smoke test green locally, CI nine jobs green on the push. No SKILL.md description edit; no tier 1
owed (no conformance task exercises Java, and the TypeScript doctrine is unchanged apart from one
clause in the rule 37 sentence).

Facts (verified 2026-09-08 on JDK 26.0.2, Maven 3.9.16, ArchUnit 1.5.0, the current Maven Central
release of 2026-08-04):
- Probe `scratchpad/archunit-probe`, scaffolded from the Java smoke skeleton (lines 69-239 of
  `smoke-test-java.sh`) plus the pom patch and the test: `spotless:apply` then `spotless:check` green;
  `verify` green with the three ArchUnit rules reported by Surefire (`Tests run: 3, Failures: 0` in
  `LayerRulesTest.txt`, 1.1 s); a domain class importing `RegisterUser` red on `mvn test` with
  "Architecture Violation"; a use-case importing an infra class red the same way; the PIT goal green
  with the ArchUnit engine on the test classpath (its tests cover no mutant, so PIT never reruns them).
- The rules: `layeredArchitecture().consideringOnlyDependenciesInLayers().withOptionalLayers(true)`
  over `domain`, `usecases`, `infra`, `api`, `composition` (domain accessed by the other four,
  usecases by infra, api and composition, infra and api by composition only, composition by none);
  `domain` depends on no `jakarta..`, `io.quarkus..`, `org.hibernate..`, `org.jboss..` class;
  `usecases` on none of `jakarta.ws.rs..`, `jakarta.persistence..`, `io.quarkus..`, `org.hibernate..`
  (so `@ApplicationScoped` on a use-case stays tolerated, as the paragraph already says).
  `ImportOption.DoNotIncludeTests` keeps the fakes out. Optional layers because a walking skeleton
  has no infra, api or composition class yet.
- Surefire's JUnit Platform provider runs ArchUnit's engine next to Jupiter without configuration;
  the random orderers in `junit-platform.properties` are Jupiter-only and leave it alone.
- Citations into `java-quarkus.md`: lines 19 and 382 (row 4.9 cites the properties file line);
  the pom insertions sit above 382, so it shifts and is re-anchored, then `--lock`.
- Smoke fixture packages: `com.example.app.{domain,usecases,usecases.ports}`, tests mirror them; the
  asset already declares `package com.example.app.architecture` and analyses `com.example.app`.

1. [x] (formatted by the probe's `spotless:apply`) `assets/java/LayerRulesTest.java`.
2. [x] (pom fence carries archunit, one citation re-anchored) `java-quarkus.md`: `<archunit.version>1.5.0</archunit.version>` in the properties and the
       `archunit-junit5` test dependency after JUnit; the test tree line; the dependency-rule paragraph
       says the check is the shipped test and keeps the grep as the adopt-mode audit; rules table row 37;
       gates list bullet for the asset; bootstrap step 3 copies it (rename package and analysed root),
       step 9 plants the red. DoD: `extract_fence` still yields the pom with `archunit`; frontmatter 4/4;
       the shifted citation re-anchored and locked; em-dash gate.
3. [x] (description byte-identical) SKILL.md rule 37 gains the Java clause and the "Layer zones" row's Java cell names the asset;
       review-me step 3 names the missing test or dependency as the Java finding; greenfield step 8 plants
       a domain class importing a use-case on Java. DoD: description byte-identical; frontmatter; citations.
4. [x] (green locally 2026-09-08, both rule 37 checks pass) `smoke-test-java.sh`: the scaffold copies the asset into `src/test/java/com/example/app/architecture/`;
       after `verify`, assert the Surefire report of `LayerRulesTest` reads three passes; negative path 6a
       plants `domain/Leaky.java` importing `RegisterUser`, requires `mvn test` to fail AND the log to carry
       "Architecture Violation", removes it; header comment lists it. DoD: `bash scripts/smoke-test-java.sh`
       green locally (minutes; never edit scripts/ or skills/ during the run).
5. [x] Matrices: reverse row 37 note adds the Java half; forward row 3.1 evidence adds the
       `java-quarkus.md` paragraph line and `assets/java/LayerRulesTest.java:18`; lock; drift green.
6. [x] (five slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Unreleased: the rule 37 bullet gains the Java sentence and consumer action (add the
       dependency, copy the test, rename); LESSONS `[decision]`, short; plan final. Commits, gate-1 sized,
       each waiting for the yes: (a) `feat(java): the dependency rule as a shipped ArchUnit test` (asset +
       java-quarkus.md), (b) `docs(skill): rule 37 covers the Java variant` (SKILL.md + companions),
       (c) `test(smoke): the Java layer gate proves red`, (d) `docs(matrix): the Java evidence for rule 37`,
       (e) `docs: changelog, lessons and plan for the Java layer gate`. Push on its own yes.

Not in scope: the `usecases.ports` sub-layer as its own ArchUnit layer (the table treats ports as part
of use-cases); a framework-ban red fixture (the smoke pom has no `jakarta` dependency to import); the
Next server-archetype zones; the rule 13 mock-ban red fixture; the `select-tasks.py` range fix.
