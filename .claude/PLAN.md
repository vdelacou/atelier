# Plan: LLM-judge scoring for the conformance eval (2026-08-30)

Why: regex assertions saturate (with_skill 24/24 on the hard tier too). A judge can
separate conforming from excellent, which is what the ceiling hides.

Design decisions, each defending against a known failure mode of LLM judging:
- PAIRWISE, not absolute: no calibration drift between runs.
- BLIND: arms are relabeled A/B, order decided by a hash of the task id, so it is
  reproducible but not aligned with arm identity.
- ORDER-SWAPPED: every pair judged twice (A/B and B/A). A verdict that flips with
  position is recorded as inconsistent, not averaged into a win.
- GROUNDED: the judge reads the atelier doctrine, and must cite file plus rule for
  every claim; an uncitable verdict is discarded.
- TIE IS A REAL ANSWER: forced choice manufactures a signal that is not there.

1. [ ] scripts/conformance-eval/judge.py: build_pair_prompt, run via nested claude -p,
   parse a strict JSON verdict, unblind, aggregate (wins, ties, inconsistent).
2. [ ] --selftest, offline, no API: fixed verdict streams prove the unblinding math,
   the position-bias accounting, and that a flipped verdict scores inconsistent, not a
   win. Must fail if the unblinding is inverted (prove the gate can fail).
3. [ ] Live validation on the h1-h7 pairs already produced (hard1/hard2 run dirs), plus
   a sanity pair: a deliberately weak answer against a conforming one, which the judge
   must call correctly in BOTH orders or the instrument is not trustworthy.
4. [ ] Wire --selftest into CI beside the other grader selftests; document in baseline.md.
5. [ ] Land on confirmation only.
