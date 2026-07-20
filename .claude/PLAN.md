# PLAN: Atelier vs Global Rules conformance (Phases 1-4 done)

The 5-phase plan to make the atelier skill provably conform to the Global Rules canon.
Pinned: atelier HEAD 8e49556 (baseline commit); Phase 4 uncommitted below.

- Phase 1 DONE: conformance-matrix.md (115 rows), canon vendored to docs/global-rules/, sha256-pinned.
- Phase 2 DONE: two contradictions (5.3 P6 revision; 15.1+4.6 hook/CI split) + five gaps closed as
  doctrine. Matrix COVERED 111, STRICTER 3, CONTRADICTS 1 (only 5.3, P6-pending), GAP 0.
- Phase 3 DONE: rule-tagged eval checker + per-rule scorecard; harness skill-injection bug found and
  fixed; credible baseline (3x sonnet-5, 60 runs) with_skill 82/84 vs baseline 62/84, +23.8 pts,
  recorded in scripts/conformance-eval/baseline.md.
- Phase 4 DONE (this session, uncommitted): two CI gates.
  - Always-on: scripts/check-matrix-drift.py (matrix vs vendored canon: 115 rows, id+title verbatim,
    canon sha256 pins intact), wired as the matrix-drift job in ci.yml, with a fail-proving --selftest.
  - Skill PRs: grade.py --min-with-skill/--min-delta gate + .github/workflows/eval.yml (one eval pass,
    single-pass floor 24/28 and +4; needs ANTHROPIC_API_KEY, skips without it).

Pending:
- Phase 5: field scorecard on the next real repo built with the skill (P4/P5 field-test prompts).
- Optional strengthenings: architecture-focused eval tasks (widen into pillar 3); ship 12.1 docs-check
  and 17.7 bundle-budget as fixture-tested gates; split the Java pre-commit-java hook (same 15.1 shape);
  enable eval.yml by adding the ANTHROPIC_API_KEY secret.
- Open: 5.3 flips to COVERED only if the canon maintainer accepts the P6 revision
  (docs/global-rules/proposed-revisions.md).
