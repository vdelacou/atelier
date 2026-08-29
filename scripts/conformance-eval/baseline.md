# Conformance-eval baseline

The behavioral proof for the atelier skill: does code produced WITH the skill follow the rules
that code produced WITHOUT it misses? Read the delta through a 3-pass replication, because a
single run is too noisy for a verdict (see `.claude/LESSONS.md`).

## Run

- Date: 2026-07-19
- Model (pinned): `claude-sonnet-5`
- Passes: 3, aggregated. 10 tasks (e1-e10), both arms, per pass, so 60 runs, 0 failures.
- Task set: 4 architecture tasks (a1-usecase-port, a2-branded-id, a3-http-adapter, a4-tdd-feature;
  pillar 3 boundaries, branded types, TDD) were added AFTER this baseline and are not in the totals
  below; a full re-baseline including them is pending.
- Harness: `scripts/conformance-eval/run.sh` copies the skill into each `with_skill` run dir
  (a nested `claude -p` cannot read a path outside its sandbox), graded by `grade.py`
  (diff-only, the `skills/` subtree excluded), each assertion tagged with the global-rules
  sub-concept it proves.
- Reproduce: run `CONFORMANCE_MODEL=claude-sonnet-5 CONFORMANCE_TAG=<tag> bash scripts/conformance-eval/run.sh`
  three times with distinct tags, then aggregate the three `runs-*` dirs.

## Result

| Arm | Score | |
|---|---|---|
| with_skill | 82/84 | 97.6% |
| baseline | 62/84 | 73.8% |
| **delta** | **+23.8 pts** | |

## By rule (global-rules sub-concept; summed over 3 passes)

| Rule | with_skill | baseline | Note |
|---|---|---|---|
| 3.9 The AI model is a dependency | 5/6 | 3/6 | skill ahead |
| 4.3 Have a testing philosophy | 3/3 | 0/3 | skill ahead; baseline never writes the test |
| 6.3 Keep personal data out of logs and URLs | 15/15 | 10/15 | skill ahead; baseline leaks PII in a third of runs |
| 7.1 Derive the owner from a trusted source | 6/6 | 6/6 | parity |
| 8.5 Change contracts additively | 9/9 | 9/9 | parity |
| 10.2 Errors as values | 6/6 | 6/6 | parity |
| 10.5 Do not fire and forget | 9/9 | 7/9 | skill ahead |
| 10.9 Treat data as sacred (soft delete) | 5/6 | 0/6 | skill ahead; baseline never soft-deletes |
| 10.11 Parse, don't validate | 6/6 | 6/6 | parity |
| 10.12 No lost updates | 6/6 | 6/6 | parity |
| 10.13 Every network call has a deadline | 12/12 | 9/12 | skill ahead |

The skill's wins concentrate on the disciplines a capable base model forgets unaided: writing a
regression test (4.3), soft-delete over hard delete (10.9), keeping PII out of logs and query
strings (6.3), outbound deadlines (10.13), outbox dedup (10.5), and the AI port (3.9). The two
arms are already at parity on org-from-claims (7.1), expand-contract migration (8.5),
errors-as-values (10.2), branded money (10.11), and optimistic locking (10.12): disciplines the
base model handles without help. Per-task, `with_skill` is near-perfect and stable across the
three passes while `baseline` is both lower and flakier.

## Threshold (Phase 4 gate, run locally)

The eval runs on this machine, not in CI. A skill-touching change runs one pass and calls
`grade.py <runs-dir> --min-with-skill 24 --min-delta 4`, a single-pass floor kept conservative
against this 3-pass baseline of 82/84 and +23.8:

```bash
CONFORMANCE_MODEL=claude-opus-5 CONFORMANCE_TAG=preland bash scripts/conformance-eval/run.sh
python3 scripts/conformance-eval/grade.py \
  skills/atelier-workspace/conformance-*/runs-claude-opus-5-preland --min-with-skill 24 --min-delta 4
```

There is deliberately no CI job for it. The gate spawns a nested `claude -p` per task per arm, which
on GitHub Actions means an `ANTHROPIC_API_KEY` secret and a metered bill for something the local
`claude` session already covers, so the eval is a pre-land step the author runs and reports rather
than a status check. The trade is real and worth naming: the eval now depends on the author running
it, where a CI job could not be forgotten.

The always-on cheap companion stays in CI: the `matrix-drift` gate in `ci.yml`
(`scripts/check-matrix-drift.py`), which holds the matrix to the vendored canon on every push.
Re-baseline whenever `tasks.json` or the skill changes materially; the run dirs are gitignored, this
scorecard is the committed reference.
