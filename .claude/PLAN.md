# Plan: the citation gate scans Java citations (2026-09-08)

Goal: `scripts/check-citations.py` pins `file:line` evidence in the two matrices, but its `CITE`
pattern only knows `.md .sh .ts .yml .yaml .json .py .js` (plus the three hook names), so the
`assets/java/LayerRulesTest.java:18` evidence added to forward row 3.1 on 2026-09-08 is invisible to
it: unpinned, free to rot. Extend the pattern to the asset kinds the Java variant ships and pin the
citation.

Definition of done: the pattern accepts `.java`, `.xml` and `.properties` (the Java assets and the
files the Java reference names); the selftest proves a `.java` citation is locked and fails when its
line changes; `--lock` pins the row 3.1 asset citation (173 entries); CI green on the push. No skill
content changes.

Facts (2026-09-08): one unscanned citation exists (`assets/java/LayerRulesTest.java:18`, the
`@AnalyzeClasses` line); `resolve()` already searches `skills/atelier/` so the `assets/java/...` name
resolves; the selftest builds a temp tree with `doc.md` and a `matrix.md` source, locks, mutates, and
asserts the verdicts.

1. [x] (selftest green; the mixed copy with the old pattern fails on the .java case) `check-citations.py`: extension alternation gains `java|xml|properties`; docstring names them;
       selftest adds `Layer.java` cited as `Layer.java:2`, locked with the rest, red when line 2 changes.
       DoD: `--selftest` green and red against a copy with the old pattern (the new `.java` case is
       what fails).
2. [x] (173 locked, drift green) `python3 scripts/check-citations.py` fails on the unpinned `.java` citation, `--lock` pins it
       (173), verify green; `check-matrix-drift.py` green.
3. [x] (two slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Unreleased Harness bullet, one sentence; plan final. Commits on the yes:
       (a) `fix(check-citations): pin Java, XML and properties citations too`,
       (b) `docs: changelog and plan for the citation pattern`. Push on its own yes.

Not in scope: the Java rules-table row 36; a Java rule 13 gate.
