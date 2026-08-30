# Plan: 10.3 prose repair + full prose-vs-sub drift sweep (2026-08-30)

The 10.3 P6 revision (ACCEPTED 2026-07-20) widened sub 10.3 to admit a typed query builder
and cascaded to references/reliability.md, but missed the pillar-10 prose bullet at
every-new-project.md:164, which still mandates hand-written reads. Same drift class the 11.3
row exists to catch. User decided: record as a repair row (not a new P6 row, the substance was
already ruled), and sweep the other 17 pillars for the same class before landing, so one hash
re-pin covers everything found.

Drift class hunted: a pillar prose bullet that says something NARROWER, WIDER, or CONTRADICTORY
to the sub-concept Do/Don't that governs it. Not hunted: prose that merely paraphrases loosely,
or omits a sub entirely (that is the 12.7 class, a different finding, recorded separately if seen).

1. [x] Sweep pillars 1-6. DoD: every prose bullet read against its subs' Do/Don't; findings listed
       with line numbers, or "none" recorded per pillar.
2. [x] Sweep pillars 7-12 (10.3 already known). DoD: same.
3. [x] Sweep pillars 13-18. DoD: same.
4. [x] Write the repair row into docs/global-rules/proposed-revisions.md: one row, numbered items,
       each naming the prose line, the governing sub, and the fix. DoD: row states the defect class
       and the cascade cost; status ACCEPTED only after the user rules on the list.
5. [x] Apply the accepted edits to global-rules-every-new-project.md (and dos-and-donts.md if any
       finding lands there). DoD: each edit is the minimum wording change that removes the divergence.
6. [x] Re-pin. DoD: conformance-matrix.md:30 carries the new every-new-project sha256 (and :29 the
       dos-and-donts one if it changed); `python3 scripts/check-matrix-drift.py` and
       `python3 scripts/check-citations.py` both green.
7. [ ] Land on explicit confirmation. Commit and push are separate asks.

Sweep result: one contradiction (10.3's prose leg), repaired. Three prose-only obligations
with no sub-concept (17.7 bundle budget, 18.3 practice-build exemption, 4.4 PR-scoped
mutation runs) are the 12.7 class, recorded in the repair row and awaiting a ruling on
whether each becomes a P6 row. Ruled 2026-08-30: 17.7's bundle budget becomes canon (a clause
on the existing Do/Don't, no count change, matrix 17.7 evidence re-anchored to product.md:86
and the shipped gate, dos-and-donts re-pinned, citations re-locked at 162). 18.3's exemption
and 4.4's PR-scoped mutation runs stay prose-only by decision.
Gates green: drift, citations, workflow-assets, frontmatter.
