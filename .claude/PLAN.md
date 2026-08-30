# Plan: Phase 5 follow-ups 1-3 (2026-08-30)

Order: atelier gates first (2, 3), then the consumer catch-up (1) so it re-syncs onto
finished doctrine. Every gate ships red-proven (canon 15.10). Kuitto changes stop before
commit (rule 25); nothing is committed there without explicit confirmation.

2. [x] Adopt the per-commit range size check (from the field-test consumer).
   - assets/check-commit-range.sh: every commit in a pushed range vs the <=10 files /
     <=300 lines cap; the CI counterpart to the staged-diff hook gate, same shape as
     check-commit-messages.sh vs commit-msg.
   - Wire: assets/ci.yml (PR only), bootstrap copy lists (bun + java), workflow.md gate
     table. RED FIRST in smoke-test.sh: an oversized commit in the range must fail.
3. [x] Make skill staleness mechanical, not doctrinal.
   - assets/check-skill-pin.sh: compares the vendored SKILL.md against upstream, fails
     when behind; degrades gracefully offline; SKILL_PIN_UPSTREAM override for tests.
   - Home: assets/audit.yml (a vendored standard is a dependency, so it belongs with the
     other independently-changing dependency check), not a commit gate.
   - --selftest with both fixtures. Bootstrap copy list + governance.md pointer.
1. [x] Consumer catch-up in /Users/pa2bra/Documents/CODE/Kuitto (READ-WRITE, no commits):
   re-sync the vendored skills, split the 8-gate hook to the 5 fast gates with the rest in
   CI, wire the commit-message re-check, drop --pass-with-no-tests, fix 8 ADR bylines.
   Verify its gates still run. Leave a staged summary for the user to commit.
4. [x] Atelier gates green, then propose slices. Land on confirmation only.
