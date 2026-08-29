# Plan: P6 rows 15.10 and 10.2 (canon improvement from the reverse audit)

Two proposals distilled from the stricter-than deltas and the repo's own gate discipline.
Loop: draft rows -> owner ruling -> apply cascade per accepted row -> re-pin -> gates -> land.

1. [x] Draft P6 rows in docs/global-rules/proposed-revisions.md, status PROPOSED.
   - 15.10 Prove the gate can fail (new sub-concept; source: repo smoke-test discipline).
   - 10.2 catch-at-the-boundary strengthening (source: hard rule 17 delta).
   - DoD: rows match file idiom, cite canon line refs, name full cascade incl. the
     skill amendment 15.10 forces (doctrine today binds only the skill repo, not consumers).
2. [x] Owner ruling via AskUserQuestion, one round, per row.
3. [x] Apply cascade for each ACCEPTED row:
   - 15.10: canon section after 15.9 + index :76 + pillar-15 bullet in every-new-project.md;
     count 118->119; drift checker TOTAL + PER_PILLAR pillar 15 9->10; forward matrix row
     15.10; skill doctrine sentence (SKILL.md gates section and/or references/governance.md)
     so the row is COVERED honestly; reverse-matrix "Outside the 34" note; re-pin both hashes.
   - 10.2: Do/Don't at dos-and-donts :1983-1984; pillar-10 bullet every-new-project.md:163;
     forward matrix 10.2 evidence adds rule 17; reverse matrix row 17 STRICTER->CANON-ROW,
     tally 20/5/9; no count change; re-pin.
   - DoD: check-matrix-drift.py green, validate-frontmatter green, no em dashes in diff.
4. [ ] Land on explicit confirmation only; commit slices: canon+P6, matrices+drift, skill text.
