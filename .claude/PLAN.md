# Plan: gap hunt, rules 4 and 20 gated in Java and Next (2026-09-19)

Findings: rule 4 (no console, no System.out) has no machine check in Java; rule 20 (file IO at the
edges) has none in Next or Java. The Bun config has FS_BAN; the Java PMD ruleset carries rules 35 and
15 only; LayerRulesTest carries the layers and two framework bans. Owner chose one closure for both.

Definition of done: `pmd-ruleset.xml` gains `SystemPrintln` and `AvoidPrintStackTrace` (rule 4);
`LayerRulesTest.java` gains a rule that domain and use-case classes depend on nothing in `java.io..`
and `java.nio.file..` (rule 20); the Next config's `domain` and `use-cases` zones carry an fs import
ban (rule 20, server sub-variant; the design-system and lib layers untouched, Node runtime); each
proven red first on the toolchain (PMD in a scratch Maven tree, ArchUnit in the Java smoke, ESLint in
the Next smoke), then red fixtures in the Java smoke (System.out in a domain class red on
pmd:check with the rule name in target/pmd.xml; a domain class importing java.nio.file red on mvn
test with "Architecture Violation") and the Next smoke (a domain file importing node:fs red on lint
with "hard rule 20"); SKILL.md rules 4 and 20 name the gates, the Logger and style-bans rows updated;
java-quarkus.md rows 4 and 20 and the two asset bullets; nextjs-monorepo.md's zone note; matrix rows
cited and re-anchored; CHANGELOG, LESSONS; tier 1; commit on the yes.

1. [x] (scratch Maven tree: SystemPrintln red on System.out and System.err, PMD's AvoidPrintStackTrace silent on both forms so an XPath rule of ours ships instead, red; ArchUnit rules red on java.nio.file and java.io.File in domain, green in infra, five tests) Probe: PMD rules red on System.out and e.printStackTrace, green on the skeleton; ArchUnit
       rule red on a domain java.nio.file import, green on the skeleton (infra may import it); the
       Next zone red on node:fs in src/domain, green on src/lib.
2. [x] (Java suite green, both new gates red on their fixtures with the rule names; Next RED run with the reference stashed failed exactly the new fixture, GREEN run all checks passed, src/lib still free to import fs) Assets and configs edited; smoke fixtures; the smoke runs.
3. [~] (doctrine, 235 citations re-anchored, CHANGELOG, LESSONS; tier 1 e6 + h2 skill 5/5 vs frozen 2.0/5, none capped; three commits pushed on the yes) Doctrine, matrix, citations, CHANGELOG, LESSONS, tier 1, commits on the yes.
