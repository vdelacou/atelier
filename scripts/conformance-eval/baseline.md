# Conformance-eval baseline

The behavioral proof for the atelier skill: does code produced WITH the skill follow the rules
that code produced WITHOUT it misses? Read the delta through a 3-pass replication, because a
single run is too noisy for a verdict (see `.claude/LESSONS.md`).

## Run

- Date: 2026-08-30
- Model (pinned): `claude-opus-5`
- Passes: 3, aggregated. 14 tasks (e1-e10 plus the four architecture tasks a1-a4), both arms, per
  pass, so 84 runs, 0 failures. This supersedes the 2026-07-19 `claude-sonnet-5` baseline
  (with_skill 82/84 = 97.6%, baseline 62/84 = 73.8%, delta +23.8), which predated a1-a4 and is
  kept here only as the prior reading.
- Assertions: 37 per pass. Two were corrected in this re-baseline after all three passes showed
  them measuring the wrong thing (see Corrected checks below), so scores before and after that fix
  are not comparable.
- Harness: `scripts/conformance-eval/run.sh` copies the skill into each `with_skill` run dir
  (a nested `claude -p` cannot read a path outside its sandbox), graded by `grade.py`
  (diff-only, the `skills/` subtree excluded), each assertion tagged with the global-rules
  sub-concept it proves.
- Reproduce: run `CONFORMANCE_MODEL=claude-opus-5 CONFORMANCE_TAG=<tag> bash scripts/conformance-eval/run.sh`
  three times with distinct tags, then aggregate the three `runs-*` dirs.

## Result

| Arm | Score | |
|---|---|---|
| with_skill | 111/111 | 100% |
| baseline | 84/111 | 75.7% |
| **delta** | **+24.3 pts** | |

Per pass, `with_skill` was 37/37 three times out of three; `baseline` ran 27, 28, 29.

## By rule (global-rules sub-concept; summed over 3 passes)

| Rule | with_skill | baseline | Note |
|---|---|---|---|
| 3.2 Depend on interfaces, not implementations | 6/6 | 2/6 | skill ahead; baseline puts the adapter in front of no port |
| 3.9 The AI model is a dependency | 6/6 | 1/6 | skill ahead; baseline ships an unpinned model |
| 4.3 Have a testing philosophy | 6/6 | 3/6 | skill ahead; baseline writes the test half the time |
| 6.3 Keep personal data out of logs and URLs | 15/15 | 12/15 | skill ahead |
| 7.1 Derive the owner from a trusted source | 6/6 | 6/6 | parity |
| 8.5 Change contracts additively | 9/9 | 6/9 | skill ahead; baseline renames a live column in place |
| 10.2 Errors as values | 12/12 | 12/12 | parity |
| 10.5 Do not fire and forget | 9/9 | 9/9 | parity |
| 10.9 Treat data as sacred (soft delete) | 6/6 | 0/6 | skill ahead; baseline never soft-deletes |
| 10.11 Parse, don't validate | 15/15 | 12/15 | skill ahead |
| 10.12 No lost updates | 6/6 | 6/6 | parity |
| 10.13 Every network call has a deadline | 15/15 | 15/15 | parity |

## Corrected checks (2026-08-30)

Two assertions failed every pass in a way that proved they measured the wrong thing, and were
replaced. Anyone comparing against an older scorecard should know the instrument moved.

- `e10-llm` asserted the absence of the word "latest". The skill-guided arm pins dated snapshots
  (`prov-summarize-2026-06-11`), validates the configured model against that allowlist, returns
  `{ok: false, kind: 'unpinned-model'}` otherwise, and writes a test feeding `prov-summarize-latest`
  to prove the rejection. The check failed it for that test, while the baseline arm passed by never
  considering aliases and shipping an unpinned `prov-summary-9`. The check rewarded the weaker arm.
  It now requires a dated snapshot, present-mode, which is what rule 3.9 actually asks for.
- `a3-http-adapter` demanded the literal string "fake" in an outbound HTTP adapter. Hard rule 13
  mandates the custom-fetch seam for exactly this case and bans mocks, so a conforming answer can
  never contain that word: both arms failed it in all three passes, which proves nothing. It now
  asserts the port itself (`ports/|\bPort\b`, chosen so it cannot match "export"): the skill arm
  imports `../use-cases/ports/billing.ts`, the baseline arm has no ports directory.

The skill's wins concentrate on the disciplines a capable base model forgets unaided: soft-delete
over hard delete (10.9, 6/6 vs 0/6), the pinned AI port (3.9, 6/6 vs 1/6), depending on a port
rather than an implementation (3.2, 6/6 vs 2/6), writing a regression test (4.3), expand-contract
migration (8.5), branded types (10.11), and keeping PII out of logs and query strings (6.3). The
two arms are at parity on org-from-claims (7.1), errors-as-values (10.2), outbox dedup (10.5),
optimistic locking (10.12), and outbound deadlines (10.13): disciplines opus handles without help,
and two of those (10.5, 10.13) were skill-ahead on sonnet, so the base model has closed ground.
Per-task, `with_skill` was perfect and identical across all three passes while `baseline` moved
between 27 and 29, both lower and flakier.

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
