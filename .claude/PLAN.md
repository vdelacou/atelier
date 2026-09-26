# Plan: guideline citations in review-me (2026-09-26)

Goal: two of the three skill-arm false positives in the clean-fixture rerun cited "rule 3" and
"rule 2" for SKILL.md's behavioural guidelines 3 (surgical changes) and 2 (simplicity). The
guidelines and the hard rules both number from 1, and review-me says only "the exact rule number",
so a guideline finding reads as a false hard-rule claim (rule 3 is the `interface` ban).

Definition of done: review-me's Output section says to cite a hard rule as `rule N` and a behavioural
guideline as `guideline N`, with the collision named; the description untouched (no trigger eval);
fast gates green; the review eval's skill arm rerun, three passes per variant, graded; the record
shows whether the guideline false positives are gone and nothing regressed (recall, citation); the
unaided arm is not rerun (it never reads review-me); CHANGELOG and baseline.md; commit on the yes.

1. [x] (one sentence in Output; description untouched; frontmatter, citations, em dash, identity green) Edit review-me; gates.
2. [x] (Bun 36/36 caught, 36/36 cited, 0 FP; Java 27/27, 27/27, 0 FP, after the tenth grader defect, the hyphenated doctrine phrase, fixed in violations.json with a selftest on the shipped manifest seen red) Skill arm, three passes per variant (six sessions); grade.
3. [x] (recorded; three commits pushed on the yes) Record, commit on the yes.
