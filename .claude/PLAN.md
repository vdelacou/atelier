# PLAN: Phase 3 behavioral eval harness (rule-tagged checker done; tasks + run pending)

Phase 3 proves produced code follows the rules. The runner (scripts/conformance-eval/run.sh,
`claude -p` per task per arm in an isolated fixture copy) and the grader (grade.py) already
existed with 10 discipline tasks (e1-e10). This session added the plan's missing "checker where
every check is tagged with the rule id it proves". Pinned: atelier HEAD 9f75574.

Done this session:
- Tagged all 28 assertions in tasks.json with their global-rules sub-concept id (11 rules:
  3.9, 4.3, 6.3, 7.1, 8.5, 10.2, 10.5, 10.9, 10.11, 10.12, 10.13).
- grade.py carries the tag and prints a BY RULE scorecard (rule -> with_skill vs baseline),
  keyed to conformance-matrix.md rows. --selftest green; a synthetic run confirms rendering.

Pending Phase 3:
- Architecture-focused tasks: the plan lists 8 (scaffold script/monorepo, use-case+port+adapter,
  TDD feature, refactor class-to-classfree, promote-to-branded-types, HTTP adapter, review-smells).
  ~4-5 fit the copy-fixture-then-edit model (use-case+port, branded-types [needs a seed file],
  HTTP adapter, TDD feature); the scaffold and review tasks need a different harness shape. Add
  the fitting ones, rule-tagged; they widen coverage into pillar 3 (boundaries) which the
  discipline tasks under-cover.
- Credible baseline DONE (commit pending): harness bug found + fixed (skill injected into the
  with_skill run dir; the nested sandbox blocked the absolute path). Valid 3x sonnet-5 replication
  (60 runs, 0 failures) gives with_skill 82/84 (97.6%) vs baseline 62/84 (73.8%), +23.8 pts,
  recorded in scripts/conformance-eval/baseline.md. Wins on the discipline rules (4.3, 10.9, 6.3,
  10.13, 10.5, 3.9); parity on 7.1/8.5/10.2/10.11/10.12. The invalid earlier runs stay gitignored.
- Architecture tasks: still optional (widen into pillar 3). Not required for the baseline to stand.

Phase 4 (CI: eval-threshold gate on skill-touching PRs + matrix drift check, scratchpad/selfcheck.py
check 2 is the seed) and Phase 5 (field scorecard) unchanged.
