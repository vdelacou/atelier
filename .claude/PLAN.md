# PLAN: Phase 2 resolve conformance collisions (contradictions + CI asset)

Resolve the Phase 1 work list. This session (user decision): the two contradictions plus
the interlocked CI-asset gap. The other five gaps (5.10, 7.7, 10.14, 12.1, 17.7) are a
follow-on session.

Direction of authority: rules are canon, the skill amends, UNLESS the skill exposes a rule
defect (P6 revision row instead). Every item cites its rule id in the commit. No item closes
as "both fine".

Dispositions (fixed):
- 5.3 -> P6 revision row (user decision). The skill's caret + committed lockfile + frozen-lockfile
  CI gives the determinism the canon's exact-pins mandate seeks; the canon's stated reason
  ("caret ranges resolve to unknown code on every install") is false once a lockfile is
  committed, which the canon ALSO requires. So the rule's absolute is defective, not the skill.
  Skill dependency gate UNCHANGED; record the P6 row + a LESSONS decision; annotate matrix 5.3.
- 15.1 -> amend skill (canon is right: multi-minute hooks train --no-verify; skill's own mutation
  gate is 1-3 min/file). Restructure the hook to fast gates only; relocate the slow gates to CI.
- 4.6 -> amend skill (interlocks with 15.1): ship a consumer CI workflow asset running the full
  gate set as the authoritative merge gate, giving the relocated slow gates a home.

Fix shape (15.1 + 4.6), informed by measurement (step 1):
- Hook keeps the FAST gates: commit-size, package.json, gitleaks protect --staged, staged-scoped
  lint, and typecheck if measured fast. Stated budget in the hook header (target a few seconds).
- Move to CI: full bun test, coverage, and Stryker mutation (the canon's "full suite, coverage,
  and slow scans run in CI only").
- New asset assets/ci.yml: bun install --frozen-lockfile then the full gate set (lint:strict,
  typecheck, test, coverage, mutation changed-on-PR/full-on-main, gitleaks detect, package.json,
  bun audit). This is 4.6's authoritative merge gate.
- Reframe the "eight gates" branding (27 refs across 7 files) as "the fast pre-commit gates" plus
  "the full CI gate set", preserving each gate's identity, not deleting gates.

Steps:
0. [x] Decisions (5.3 P6, scope = contradictions + CI), chapter, bun 1.3.14, ripple scoped  DONE
1. [x] Measured gate timings on a scaffolded 8-file repo: typecheck 1s, lint 2s, test/coverage <1s, mutation 4s/1 file. Split by gate NATURE (scales-with-repo goes CI), not day-1 speed (lint:strict ~25s, mutation 1-3min/file are the real-repo numbers)  DONE
2. [x] 5.3 P6 row: docs/global-rules/proposed-revisions.md + LESSONS [decision] + matrix 5.3 annotation; skill gate untouched  DONE
3. [x] 15.1+4.6: rewrote assets/pre-commit (5 fast gates + ~5s budget); added assets/ci.yml (full set, frozen lockfile) + assets/lint-staged.sh; workflow.md gate table -> hook table + CI section; lint:staged wired  DONE
4. [x] Reframed eight-gates refs across SKILL.md, workflow.md, greenfield, review-me, bun-typescript.md, nextjs-monorepo.md, commit-msg, README; em-dashes on all touched lines neutralized (diff dash count 0)  DONE
5. [x] Updated smoke-test.sh: fast hook end-to-end + CI gates (mutation, ci.yml presence/wiring) run directly  DONE (running to confirm green)
6. [x] conformance-matrix.md: 15.1 + 4.6 -> COVERED, 5.3 CONTRADICTS + P6 pointer; tally COVERED 106 / STRICTER 3 / GAP 5 / CONTRADICTS 1; self-check 9-green  DONE
7. [x] Verify: frontmatter valid (4/4); em-dash diff 0; matrix self-check 9-green; smoke-test all checks passed (fast hook end-to-end + CI gates direct, 0 failures)  DONE
8. [ ] Commit per item citing rule ids (commit1 5.3 P6; commit2 15.1+4.6 skill restructure); ask before commit (rule 25)  DoD: nothing committed without confirmation

Java pre-commit-java has the same 15.1 shape and is deferred (needs its own Java CI asset). Remaining gaps 5.10, 7.7, 10.14, 12.1, 17.7 deferred to the next session.

Pinned: atelier HEAD 8d319dd (Phase 1 committed). Canon unchanged (docs/global-rules/, sha256 as Phase 1).
Deferred to next session: gaps 5.10, 7.7, 10.14, 12.1, 17.7.
