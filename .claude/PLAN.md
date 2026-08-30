# Plan: audit fix campaign (2026-08-30)

Order matters: gates land first and must fail RED on the current defects (test-first);
content fixes turn them green; citation re-anchor runs LAST because every earlier slice
shifts line numbers.

A. [x] New gates, proven red first.
   - scripts/check-workflow-assets.sh: shipped assets/ci*.yml lint; every `scripts/X`
     referenced must exist in assets/, every bare binary (gitleaks) needs an install step.
     --selftest with embedded violation fixture. DoD: selftest red-on-fixture, verify mode
     RED on current assets (gitleaks missing).
   - scripts/check-citations.py: extracts file:line citations from conformance-matrix.md
     + reverse-matrix.md, verifies against citations-lock.json (content snippet per cite);
     --lock regenerates, --selftest proves rejection. DoD: selftest red, verify RED on the
     38 rotten rows before slice G.
B. [x] Cluster 1 assets/bootstrap: gitleaks install step both ci ymls; java-quarkus.md
   copies check-commit-messages.sh; bun-typescript.md skeleton gains lint:staged + step 14
   copies lint-staged.sh/check-commit-messages.sh/ci.yml; greenfield installs CI re-check,
   variant-scopes step 8 commands, adds per-gate red proofs. DoD: check-workflow-assets
   green; smoke tests still green.
C. [x] Cluster 2 prose 8-gate legacy: bun-typescript.md strict-lint-in-hook, SKILL.md:424
   PIT-in-hook, java-quarkus.md:133/348/369, workflow.md 8-gate sentences + :686 + :357 +
   :446 + :371, asset header comments (mutate-staged.sh, regenerate-coverage-preload.ts),
   isolation.md to-response exemption. bun-audit placement = open decision for landing.
D. [x] Cluster 4 companions: review-me gate-file mapping row + rule-17 carve-out note.
   (greenfield handled in B.)
E. [x] Cluster 5 canon: one P6 row (cascade completion: 8.1 exemplar, 7.1->7.5 tag,
   15.2->15.10 + 4.7->13.5 pointers, 2.2 tag, subject->summary), owner ruling, apply,
   re-pin, drift green.
F. [x] Cluster 6 hygiene: reverse-matrix:9 count-free, README FP-filter phrase, LESSONS
   [decision] lines for 08-30 rulings, CLAUDE.md companion-sweep process line.
G. [x] Cluster 3 re-anchor: scripted fix of all stale citations to current lines, then
   check-citations.py --lock; verify green. Wire both new gates into repo ci.yml.
H. [ ] Full gate run (frontmatter, drift+selftest, both eval selftests, both new gates,
   bun smoke at minimum) then propose commit slices; land only on explicit confirmation.
