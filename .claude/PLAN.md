# PLAN: optional conformance strengthenings (all four DONE, uncommitted)

Four independent strengthenings, one coherent commit each, each new gate proven to fail via the
matching smoke test. Pinned: atelier HEAD e61f754.

1. [x] Java hook split (rule 15.1): pre-commit-java -> 4 fast gates; verify + PIT to new ci-java.yml;
   java-quarkus.md + SKILL matrix reframed; smoke-test-java GREEN (fast hook + verify/PIT direct).
2. [x] 12.1 docs-check gate: assets/check-docs.sh runs the README ## Verify block; smoke-test.sh
   proves pass-and-fail; governance.md + README point at it. GREEN.
3. [x] 17.7 bundle-budget gate: assets/check-bundle-size.sh (gzipped JS vs BUDGET_KB); smoke-test-next.sh
   proves pass-and-fail on the real export; product.md + README point at it. GREEN.
4. [x] Architecture eval tasks a1-a4 (3.2/10.2/10.11/10.13/4.3) in tasks.json, rule-tagged; grader
   selftest green; 1-pass validation with_skill 8/9 vs baseline 6/9 (skill ahead on 3.2, 10.13).

Verified: all shell/YAML/JSON parse; 0 em dashes in the diff; three smoke tests green; grader selftest green.

Commit slicing (independent, cite the rule): (1) Java split, (2) docs-check, (3) bundle budget,
(4) architecture eval tasks + baseline note. LESSONS + PLAN ride with the last.

Deferred (user action): enable eval.yml by adding the ANTHROPIC_API_KEY secret; a full 3-pass re-baseline
including a1-a4. Phase 5: field scorecard on the next real repo. Open: 5.3 P6 awaiting the canon maintainer.
