# PLAN: accept P6 rows 11.3 and 12.7 (DONE, uncommitted)

User's calls applied: 11.3 = softened the pillar-11 prose toward symptom/burn-rate alerting (sub
unchanged); 12.7 = new sub-concept "One working language" (Option A, count 115 -> 116, full cascade).
One coherent commit pending confirm.

- [x] 11.3: every-new-project.md pillar-11 prose reworded from "alert on anomalies rather than only
      fixed thresholds" to symptom-based/error-budget-burn alerting, matching sub 11.3 and the skill's
      observability.md. No skill change (sub + skill already burn-rate). Row stays COVERED.
- [x] 12.7: new `### 12.7 One working language` (Do/Don't + CONTRIBUTING.md example) in dos-and-donts;
      added to the "Every sub-concept" index; matrix row (COVERED, governance.md:5); tally COVERED
      112 -> 113, Total 116; work-list + ci.yml comment -> 116; check-matrix-drift.py `!= 116` and
      PER_PILLAR pillar-12 6 -> 7 (sum 116).
- [x] proposed-revisions.md: 11.3 and 12.7 marked ACCEPTED; 12.7 records Option A as landed and B declined.
- [x] Re-pinned BOTH canon hashes: dos-and-donts 37b596..910a (3423 lines), every-new-project 5b3373..2e1
      (283); header bullet now names 5.3/10.3/11.3/12.7/15.5 and which doc carries each; count now 116.
- [x] Verified: drift gate green (116 rows, per-pillar + hashes intact) + selftest green; both live hashes
      match pins; `git diff` added lines have no em dash; LESSONS + PLAN updated.

Change set: dos-and-donts.md, every-new-project.md, proposed-revisions.md, conformance-matrix.md,
check-matrix-drift.py, ci.yml, LESSONS.md, PLAN.md. One commit.

Next: confirm commit, then push. All five drafted P6 rows (5.3, 10.3, 11.3, 12.7, 15.5) are now ACCEPTED
and applied; the canon internal-consistency pass is fully resolved. Phase 5 field test remains the only
external item.
