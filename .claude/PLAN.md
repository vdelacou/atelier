# Plan: the Java mock ban is a gate (2026-09-08)

Goal: rule 13's Java expression says "enforce by keeping mock libraries out of the pom entirely", and
nothing enforces it: no enforcer rule, no hook check, no fixture. Close it the way the pom conventions
already work: the maven-enforcer-plugin is the build-time authority and `check-pom.sh` is its fast
pre-commit echo.

Definition of done: the canonical pom's enforcer gains `bannedDependencies` (org.mockito, org.easymock,
org.powermock, org.jmockit, quarkus-junit5-mockito, quarkus-panache-mock; enforcer 3.x walks the whole
tree, so a transitive Mockito is caught too); `check-pom.sh` gains a third check that rejects a declared
mock coordinate (fast, no network); the Java smoke test proves both red on a planted `mockito-core`
(the enforcer on its "(rule 13)" message) and the clean pom green through `verify`; java-quarkus.md,
SKILL.md's rule 13 row and the matrices name the gates; CHANGELOG Unreleased carries the consumer
action; CI green on the push. No SKILL.md description change; no tier 1 (Java only).

Facts (verified 2026-09-08, Maven 3.9.16, enforcer 3.6.3): `bannedDependencies` has no
`searchTransitives` parameter in 3.x (the probe failed on it; the 3.x rule always checks the full tree);
the rule with the six excludes is green on the canonical pom (`mvn -q validate`), red on a direct
`org.mockito:mockito-core:5.20.0` and red through `io.quarkus:quarkus-junit5-mockito:3.30.6`, whose
tree carries mockito-junit-jupiter and mockito-core ("banned via the exclude/include list"); the
smoke fixture commits its pom before the negative paths, so `git checkout -q pom.xml` restores it as the
rule 19 fixtures already do.

1. [x] (probe green/red/red; check-pom.sh green on the clean pom, red on the plant; two citations re-anchored) `java-quarkus.md`: enforcer block gains the rule (comment, message, six excludes); conventions
       bullet names `bannedDependencies` (rule 13); rules table row 13 names both gates; the
       pre-commit-java bullet's `check-pom.sh` description gains "no mock library declared"; bootstrap
       step 6 points at the enforcer. `check-pom.sh`: check 3, a `<groupId>` in the banned groups or a
       banned `<artifactId>`, message "(rule 13)"; header comment. DoD: `extract_fence` pom still
       parses (`mvn -q validate` on the probe); frontmatter; citations (java-quarkus.md lines 245, 393
       shift by the fence insertion; re-anchor, lock).
2. [x] (description byte-identical; review-me's Java mapping note already says no Mockito) SKILL.md "What applies where" row Mock ban (rule 13), Java cell names the enforcer rule and
       `check-pom.sh`; companions swept for a Java rule 13 echo. DoD: description byte-identical.
3. [x] (green locally 2026-09-08, 45 checks) `smoke-test-java.sh`: after the -SNAPSHOT case, plant `mockito-core` in `<dependencies>`;
       `expect_err` check-pom.sh; `./mvnw -q validate` must fail AND the log carry "(rule 13)"; checkout.
       Header comment. DoD: `bash scripts/smoke-test-java.sh` green locally.
4. [x] Matrices: forward row 4.5 evidence adds the fence rule line and `check-pom.sh` line, reverse row 13
       note; lock; drift green.
5. [x] (five slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Unreleased Added bullet (consumer: re-extract the enforcer block, re-copy
       `check-pom.sh`); LESSONS `[decision]` short; plan final. Commits on the yes: (a) `feat(java): the
       mock ban is a gate, enforcer bannedDependencies plus check-pom.sh`, (b) `docs(skill): the Java mock
       ban names its gates`, (c) `test(smoke): the Java mock ban proves red`, (d) `docs(matrix): the Java
       evidence for rule 13`, (e) `docs: changelog, lessons and plan for the Java mock gate`. Push on
       its own yes.

Not in scope: a source-level `@InjectMock` scan (without the dependency it does not compile); the
TypeScript side (already lint plus fixtures).
