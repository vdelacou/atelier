# Plan: reverse-matrix tally re-audit (2026-09-09)

Goal: `reverse-matrix.md` has a row per hard rule 1-37 but its tally still counts 36 (rule 37 is
absent from the CANON-ROW list) and two prose counts predate the last two rules (the canon at 119, "Outside
the 34"). Make the tally and the counts equal to the rows.

Definition of done: the tally lists 22 CANON-ROW (37 added), 6 STRICTER-THAN, 9 stack bindings, total
37; the canon count reads 120 (4.9 accepted 2026-09-06); "Outside the 37"; every edit in place so no
cited line moves (`check-citations.py` 233 intact, `check-matrix-drift.py` green); CHANGELOG Unreleased
bullet; commit on the owner's yes.

1. [x] (six edits, 86 lines before and after, census 22/6/9) Row census by verdict, tally and prose edits in place.
2. [x] (gates green, CHANGELOG bullet, committed and pushed on the yes) Gates: em dash, citations, matrix drift. CHANGELOG bullet. Commit `docs(reverse-matrix): tally
       counts all 37 rules` on the yes.
