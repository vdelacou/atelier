# Plan: multi-generation doctrine A/B (2026-08-30)

Question the last reading left open: was current 1 / july 2 a doctrine difference or
generator noise? One generation per side cannot tell. Three can start to.

Design: same two doctrines (current skill vs 2026-07-12), same arm (with_skill), the two
tasks whose verdicts split (h5-isolation-full, h7-reliability-full), 3 independent
generations per side. Judge pairs generation i against generation i, both orders, blind.
9 outcomes per task-side pairing at most; read the DISTRIBUTION, not a single verdict.

Honest bar set before the run, so the result cannot be rationalised after it:
- A doctrine claim needs the same winner in most pairs AND low inconsistency.
- A split across generations means the generator's variance dominates the doctrine
  difference on these tasks, which is a real finding and gets recorded as one.
- Either way the sample is 2 tasks; this bounds noise, it does not settle doctrine.

1. [ ] Generate 3x per side (12 runs total, sequential per side).
2. [ ] Judge g1-vs-g1, g2-vs-g2, g3-vs-g3 (6 pairs, 12 comparisons).
3. [ ] Aggregate; report distribution and inconsistency rate; record in baseline.md.
4. [ ] Land on confirmation.
