# Plan: conformance harness revamp (2026-09-03)

Owner ruling 2026-09-03: harness only, no field runner. Context: a conformance run is one
full `claude -p` coding session (opus, 6 to 11 min, no cap); the routine matrix is 21 tasks x
2 arms x 3 passes, hours at 4 jobs; the baseline arm never reads the skill. The 2026-09-03
reruns (r1-r5, h4/h6) spent about an hour per pass confirming two grader artifacts: 4.8 is the
word `eval` with boundaries (r4 shipped `evals/` + `scripts/run-evals.ts --min-score` and
scored 0) and 7.5 wants a 404 in a test on a list endpoint (all five runs ship a forged-id
test, none can 404). Shrink the harness, do not rebuild it. No new instrument beyond the
selection mode; the judge, the review eval and the trigger eval are untouched.

Standing rules: every grader change ships a red fixture in `grade.py --selftest`; commits
Conventional, <=10 files / <=300 lines; commit each slice once green (standing approval from
the previous task, push stays a separate ask); no em dashes; baseline.md gets a dated note for
every assertion change (its existing idiom).

## Slice 1: structural assertions for 4.8 and 7.5 (grader shapes, red first)

- [x] tasks.json h6 4.8: one file whose path or content names an eval set
      (`\b(evals?|evaluations?|golden|regression)\b`, so `evaluate` never matches) AND carries
      a threshold token (`min.?score|threshold|toBeGreaterThan|>=|score`), globs `.ts .tsx
      .json` so a package.json script counts.
- [x] tasks.json h4 7.5: a test file with a 404 / not-found assertion OR a scenario name that
      states the cross-owner attempt (`(forg|another|other|cross|foreign|second)` within 60
      chars of `org|tenant|owner`), the list-endpoint shape.
- [x] grade.py selftest, fourth scenario: synthetic run dirs prove each new shape passes on
      the artifact (an `evals` script with `--min-score`; a forged-org test name; a 404 test)
      and fails on the trap (a file saying `evaluate ... score` with no eval set; `evals`
      with no threshold; a same-owner-only test).
- [x] baseline.md dated note: what changed and why, with the r1-r5 re-read under the new
      shapes (expected: h4 3/3 in all five, h6 5/5 in r4 only; r2 h6 stays 4/5, a real miss).
- DoD: `python3 scripts/conformance-eval/grade.py --selftest` green and red when a shape is
  reverted (prove by hand once); regrade r1-r5 and record; commit.

## Slice 2: diff-targeted selection (`--since <ref>`)

- [ ] `run.sh --since <ref>` (or `CONFORMANCE_SINCE`): diff `skills/atelier/**` against the
      ref, collect touched hard-rule numbers (a `NN.` line in SKILL.md, the reference's rule
      list from the trigger table) and canon ids, map to tasks whose assertions cite those
      rules (tasks.json is rule-tagged; add a `hard_rules` list per task where the mapping is
      not derivable), run only those, skill arm only, one pass, JOBS 6 default.
- [ ] `--dry-run` prints the selection; selftest: a synthetic diff touching rule 28 selects
      h4, h5 and nothing else.
- DoD: dry-run on this branch's SKILL.md diff selects the h tier only; selftest green; the
  README/CLAUDE.md verify lines name the new mode.

## Slice 3: freeze the baseline arm

- [ ] baseline arm results become a committed fixture (`scripts/conformance-eval/
      baseline-arm.json`: per task/assertion pass counts, tasks.json sha256, model, date).
- [ ] grade.py `--frozen-baseline` reads it for the delta instead of baseline run dirs; a
      tasks.json hash mismatch is an error naming the re-run command.
- [ ] run.sh default arms become `with_skill`; `CONFORMANCE_ARMS=both` re-runs the baseline.
- DoD: grading a skill-only runs dir prints a delta against the frozen arm; hash-mismatch
  selftest red; baseline.md documents the freeze.

## Slice 4: caps and tiers

- [ ] run.sh: `--max-turns` (default 60) and a wall-clock `timeout` per session (default 15
      min) around `claude -p`; a capped run is graded as produced, and the summary names it.
- [ ] incremental grading: `run.sh` prints each run's scorecard line as it finishes.
- [ ] `CONFORMANCE_MODEL` documented as the smoke lever (sonnet for tier 1, opus for tier 2).
- [ ] baseline.md and CLAUDE.md: the tier contract (tier 0 static gates in CI; tier 1
      `--since` skill arm one pass after any doctrine edit; tier 2 full matrix both arms on a
      description change or before a release).
- DoD: a run with `--max-turns 1` finishes under a minute and grades; docs name the tiers.

## Wrap

- [ ] LESSONS entries (vocabulary assertions, the frozen arm, the selection mode); this file
      to final state; final report.
