# Plan: the Java half of rule 15 (2026-09-08)

Goal: rule 15 became lint in the TypeScript variants this afternoon; the Java row still reads "No
`@SuppressWarnings`, ever" with nothing behind it. Probed on the Maven skeleton: `@SuppressWarnings`
compiles under `-Werror`, `// NOPMD` silences a complexity-11 method, `// NOSONAR` is free text.

Definition of done: three layers, each with a red fixture in the Java smoke test. (1) `pmd-ruleset.xml`
gains an XPath rule `NoSuppressWarnings` (`//Annotation[pmd-java:typeIs('java.lang.SuppressWarnings')]`),
red in `verify` on `@SuppressWarnings("unchecked")`; the rule cannot see `@SuppressWarnings("PMD")`,
which suppresses its own report (probed), so it is defence in depth, not the authority. (2) The canonical
pom sets `<suppressMarker>ATELIER-NEVER-SUPPRESS</suppressMarker>` on the PMD plugin, so a `// NOPMD`
comment is inert and the finding it hid resurfaces (probed: complexity 11 behind NOPMD green with the
default marker, red with the impossible one). (3) A new asset `check-no-suppressions.sh`, the Java rule 15
tripwire in the tripwire idiom (staged added lines in `*.java` by default, `--all` scans `src/`), rejects
`@SuppressWarnings`, `@SuppressFBWarnings`, `NOPMD`, `NOSONAR`, `CHECKSTYLE:OFF` and `noinspection`; it is
gate 3 of 5 in `pre-commit-java` and a `--all` step in `ci-java.yml`, so the bypass has nowhere to go.
Docs: java-quarkus.md row 15, the gates list, the cp block, the pom fence; SKILL.md rule 15 gains the Java
clause and "What applies where" a rule 15 row; review-me; matrices; CHANGELOG. Java smoke green locally,
CI green on the push. No SKILL.md description change; no tier 1 (Java only).

Facts (verified 2026-09-08, Maven 3.9.16, PMD 7.17.0 through maven-pmd-plugin 3.28.0, JDK 26): the XPath
rule is green on the clean skeleton and red on a method-level `@SuppressWarnings("unchecked")`; with `-q`
the console says only "has found 1 violation", the rule name is in `target/pmd.xml` (`rule="..."`), so the
fixture greps that file; `@SuppressWarnings("PMD")` on the class is green (self-suppressed); PMD prints
about 21 "Parsing failed in ParseLock ClassStub" lines on every run under JDK 26, noise that predates
this slice. No shipped Java asset or smoke fixture carries a suppression form.

1. [x] (probe: pmd:check green clean and red on unchecked; tripwire red on staged @SuppressWarnings("PMD") and NOSONAR, green clean) Assets and fence: `pmd-ruleset.xml` (rule, header comment names the hole), the pom's PMD block
       (`suppressMarker`), `check-no-suppressions.sh` (new), `pre-commit-java` gate 3 of 5, `ci-java.yml`
       step after pom sanity. DoD: the probe's `pmd:check` green clean, red on unchecked; the script red on
       a staged `@SuppressWarnings("PMD")` and `// NOSONAR`, green on the clean skeleton.
2. [x] (description byte-identical; a SKILL.md pin shifted by the new table row was caught re-locked to an empty line and re-anchored) Docs: java-quarkus.md row 15, gates bullets (pre-commit-java sequence, pmd-ruleset, the new asset),
       cp block; SKILL.md rule 15 Java clause, a "No inline ignores (rule 15)" row in What applies where;
       review-me's (15) clause gains the Java gates. DoD: description byte-identical; frontmatter;
       citations re-anchored and locked; em-dash gate.
3. [x] (green locally 2026-09-08, 51 checks; the first run aborted on a fixture calling gen_guards before its definition, block moved) `smoke-test-java.sh`: scaffold copies the asset; positive path runs the script on the clean tree;
       negative paths: unchecked annotation red in `pmd:check` with `rule="NoSuppressWarnings"` in
       `target/pmd.xml`; complexity 11 behind `// NOPMD` red (marker inert); staged
       `@SuppressWarnings("PMD")` and `// NOSONAR` red in the script; header comment. The hooked-commit
       check exercises gate 3 of 5. DoD: green locally.
4. [x] (five slices committed and pushed 2026-09-08 on the owner's yes) Matrices (forward 15.3 evidence: ruleset line, asset line; reverse row 15 Java note), lock, drift.
       CHANGELOG: the rule 15 bullet gains the Java sentence and consumer action (re-copy the ruleset,
       re-extract the PMD block, copy the tripwire, wire hook and CI). LESSONS `[decision]`. Commits on the
       yes: (a) `feat(java): rule 15 as PMD rule, inert NOPMD and a suppression tripwire`, (b) `docs(skill):
       rule 15 covers the Java variant`, (c) `test(smoke): the Java suppression forms prove red`,
       (d) `docs(matrix): the Java evidence for rule 15`, (e) `docs: changelog, lessons and plan`. Push on
       its own yes.

Not in scope: rule 5 (the next slice); Error Prone or SpotBugs (not in the toolchain).
