# PLAN: canon internal-consistency pass + P6 rows (DONE, uncommitted)

Both tasks the user asked for are done. Pinned: atelier HEAD 777f221.

- [x] Canon internal-consistency pass: 6 agents over 18 pillars + values (prose vs sub-concepts).
  13 pillars + values mapping consistent. 4 real issues found, 6 minor left as noted.
- [x] 4 P6 rows drafted (proposed, none applied) in docs/global-rules/proposed-revisions.md:
  - 10.3 (Do "hand-authored SQL" contradicts the canon's own 10.4 query-builder example)
  - 11.3 (prose requires anomaly alerting; sub has only fixed budget thresholds)
  - 12.7 (prose's "one working language" has no sub-concept; skill's governance.md covers it)
  - 15.5 (TLS-probe example tests only TLS 1.1 while claiming to prove >= 1.2, a bug)
- [x] Verified: drift gate green (canon unchanged this turn), 0 em dashes, LESSONS + this PLAN updated.

Change set: proposed-revisions.md (4 P6 rows + intro fix), LESSONS.md, PLAN.md. One coherent commit.

Pending the user's judgment (the 5.3 flow): accept any of the 4 rows and I apply it to the canon and
re-pin. 12.7 needs an Option A (new sub-concept, count 115 -> 116, cascades) vs Option B (fold into 12.1)
choice at acceptance. Nothing applied without acceptance. Phase 5 field test still the only external item.
