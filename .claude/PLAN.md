# PLAN: round 4, shrink the residual gaps (all four improvements approved)

Status: IN PROGRESS. Started 2026-07-12. User selected all four next-round items.

## Goal
Shrink the two residual gaps named in the confidence discussion: (1) the LLM
instruction-following gap, via a deterministic CLAUDE.md seed in every atelier repo and
task-based conformance evals that measure rule-following in produced code; (2) the
behavioral-rules gap, via executable ripgrep guards for the mechanical slices of rules
27-30. Plus eval infrastructure hygiene so the trigger eval is a committed, rerunnable
one-liner, and upstream bug reports drafted for user sign-off.

## Definition of done (whole task)
- Greenfield and review-me adopt mode seed a short repo CLAUDE.md pointing at the standard
  (canonical block defined once); docs updated.
- New guard assets (PII channels, IO deadlines, data lifecycle, isolation-test presence)
  ship in assets/, each proven on positive+negative fixtures, wired into the discipline
  references and exercised by smoke-test.sh so they cannot rot.
- scripts/trigger-eval/ holds the patched runner, both probe fixtures, and the eval sets
  (atelier + three companions), committed; results stay gitignored. Companion sets run once.
- Conformance eval set exists (tasks + mechanical assertions), run with-skill vs without,
  graded, verdict reported.
- Upstream issue drafts (sonarjs TS7, skill-creator harness contamination) presented for
  explicit confirmation before ANY posting; nothing posted without a yes.
- All new prose em-dash-free; frontmatter valid; smoke tests green locally; commits proposed
  slice-by-slice (rule 25), push only on explicit confirmation.

## Steps
1. [x] CLAUDE.md seed: canonical block in greenfield step 6 (deterministic repo context) +
   review-me adopt step 2 seeds it in the gate-install slice.
2. [x] Guard assets written and PROVEN: 17/17 fixture cases (pii blocks query-string email,
   log interpolation, @QueryParam; deadlines blocks bare fetch/HttpClient, passes AbortSignal;
   lifecycle blocks db.delete + DROP COLUMN, exempts erasure paths + *contract* migrations,
   ignores cache.delete; isolation blocks routes without a 404 test, exempts health/public).
   Staged-diff by default, --all for audits.
3. [x] Guards wired: privacy/reliability/isolation tripwire sections, workflow.md "Discipline
   tripwires" table, SKILL.md disciplines tail, README assets list. smoke-test.sh gained a
   6-check tripwire section; full run green (31 checks). Bonus: the deadline guard caught the
   smoke fixture's own adapter (bare fetch + name in query string); fixture now models rules
   27+29 (POST body + AbortSignal.timeout).
4. [x] Eval infra committed: scripts/trigger-eval/{run_eval.py (self-contained, provenance
   header), run.sh, sets/, probe-root, probe-root-java, probe-root-empty}. Companion verdicts
   (3 runs/query, fable): review-me 12/12, grill-me 10/10, greenfield 9/10 whose one miss was
   a fixture mismatch (existing-repo negatives probed from the empty fixture); those negatives
   split into sets/atelier-greenfield-existing.json and rerun from probe-root [pending].
5. [x] Conformance evals DONE: 5 tasks x (with_skill | baseline) subagents in isolated fixture
   copies, graded by scripted greps (grade.py in the conformance workspace).
   VERDICT: with_skill 13/13 assertions, baseline 10/13. The skill closed exactly the
   discipline gaps: e1 search travelled as POST with a deadline (baseline used a GET),
   e2 removal was a deletedAt soft delete (baseline hard db.delete, the flagship rule-30
   contrast). Strong-baseline finding: claims scoping (e4), integer cents (e5), and
   idempotent bounded retries (e3) the model already does unprompted at this tier.
   Cost observation: with_skill runs ~2.5-3x tokens and 3-8x wall time (reads SKILL.md +
   references first). Follow-up idea: greenfield addendum also passed rule-24 headless
   (agents wrote PLAN.md, proposed tests in-report or wrote them; worth a look at
   transcripts later, not asserted on).
6. [x] Upstream drafts written (workspace/upstream-drafts/): sonarjs-ts7.md with exact
   crash line + interop cause + repro + fix suggestions; skill-creator-harness.md with the
   three harness findings + working fixes. NOT posted; awaiting explicit user yes and
   target repos.
7. [ ] Verify + land proposal (commits sliced, push gated on confirmation).
   Extra finding this round: greenfield over-triggered on existing-repo tooling queries
   even from the populated fixture (1/3 -> hardened the description's negative clause ->
   2/3; the residual "set up eslint" case is a single-skill-harness artifact: the main
   atelier skill is not registered in the probe to win the query. True fix = multi-skill
   probing, noted as a future harness enhancement).

## Notes / breadcrumbs
- Guard design: tripwires, not proofs; conservative patterns to respect the false-positive
  discipline; exceptions by path convention (erasure/retention for rule 30), never inline
  ignores (rule 15).
- Conformance runner: skill-creator flow with Agent-tool subagents; assertions are greps run
  by a script, not eyeballs.
- Prior rounds all landed and pushed; CI green at bbb3c26.
