# Conformance-eval baseline

The behavioral proof for the atelier skill: does code produced WITH the skill follow the rules
that code produced WITHOUT it misses? Read the delta through a 3-pass replication, because a
single run is too noisy for a verdict (see `.claude/LESSONS.md`).

## Run

- Date: 2026-08-30, re-run late the same day against the doctrine that landed during it (the
  gate-proving paragraph, "a bug is a missing test", the corrected rule 29 and mutation-testing
  lines). The morning reading from the same date is kept below as the prior scorecard.
- Model (pinned): `claude-opus-5`
- Passes: 3, aggregated. 14 tasks (e1-e10 plus the four architecture tasks a1-a4), both arms, per
  pass, so 84 runs, 0 failures. This supersedes the 2026-07-19 `claude-sonnet-5` baseline
  (with_skill 82/84 = 97.6%, baseline 62/84 = 73.8%, delta +23.8), which predated a1-a4 and is
  kept here only as the prior reading.
- Assertions: 37 per pass. Two were corrected in this re-baseline after all three passes showed
  them measuring the wrong thing (see Corrected checks below), so scores before and after that fix
  are not comparable.
- Grader hardened 2026-08-30, same day, selftest-first: comments are stripped before matching
  (prose about a discipline is not its implementation) and file paths join the matchable corpus
  (a `003_contract_*.sql` filename IS the contract-step evidence). The numbers below are from the
  hardened grader; with_skill was unchanged by it, baseline lost 3 comment-credited points.
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
| baseline | 86/111 | 77.5% |
| **delta** | **+22.5 pts** | |

Per pass, `with_skill` was 37/37 three times out of three; `baseline` ran 29, 29, 28.

Against the morning reading of the same day (111/111 vs 81/111, +27.0, baseline 27/26/28), the
skill arm did not move and could not: it has now been 37/37 in six consecutive passes. The whole
change is the unaided arm gaining five points, four of them on 3.9 (it pinned a dated model
snapshot in four runs of six, against one of six that morning) and the rest single points on 3.2
and 4.3. Same model, same assertions, same grader, so read it as run-to-run variance in a noisy
arm rather than a base model that improved between breakfast and dinner; the honest summary is
that the gap is somewhere in the low-to-mid twenties, not that it moved 4.5 points in a day.

**The instrument is at its ceiling on one side.** A perfect skill arm can only measure
regression from here, never improvement, so a doctrine change that makes the skill better is
invisible to this scorecard. Adding harder tasks is the fix; until then, treat 37/37 as "no
regression" rather than as evidence the day's changes helped.

## By rule (global-rules sub-concept; summed over 3 passes)

| Rule | with_skill | baseline | Note |
|---|---|---|---|
| 3.2 Depend on interfaces, not implementations | 6/6 | 1/6 | skill ahead; baseline builds the port once in six |
| 3.9 The AI model is a dependency | 6/6 | 4/6 | skill ahead, and the arm that moved most this re-run |
| 4.3 Have a testing philosophy | 6/6 | 4/6 | skill ahead; baseline writes the test two runs in three |
| 6.3 Keep personal data out of logs and URLs | 15/15 | 12/15 | skill ahead |
| 7.1 Derive the owner from a trusted source | 6/6 | 6/6 | parity |
| 8.5 Change contracts additively | 9/9 | 6/9 | skill ahead; baseline renames a live column in place |
| 10.2 Errors as values | 12/12 | 12/12 | parity |
| 10.5 Do not fire and forget | 9/9 | 9/9 | parity |
| 10.9 Treat data as sacred (soft delete) | 6/6 | 0/6 | skill ahead; baseline never soft-deletes, in any pass of either reading |
| 10.11 Parse, don't validate | 15/15 | 11/15 | skill ahead |
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
over hard delete (10.9, 6/6 vs 0/6, the one rule the unaided arm has never once satisfied across
either reading), depending on a port rather than an implementation (3.2, 6/6 vs 1/6),
expand-contract migration (8.5), branded types (10.11), keeping PII out of logs and query strings
(6.3), writing a regression test (4.3), and the pinned AI port (3.9). The
two arms are at parity on org-from-claims (7.1), errors-as-values (10.2), outbox dedup (10.5),
optimistic locking (10.12), and outbound deadlines (10.13): disciplines opus handles without help,
and two of those (10.5, 10.13) were skill-ahead on sonnet, so the base model has closed ground.
The 10.13 parity is measured at the frontier the doctrine actually mandates: e3 asserts the full
rule-29 triad (deadline, idempotency-keyed retry, bounded, no while(true)) because payments retry;
a3 and e1 assert only the deadline because rule 29 mandates retries be bounded and jittered WHERE
PRESENT, not that every read call retry. No a3 run in either arm adds retry, conformantly.
Per-task, `with_skill` was perfect and identical across all three passes while `baseline` moved
between 28 and 29 in this reading and between 26 and 28 in the morning's: lower and flakier in
both, which is the shape of the claim worth making.

## Threshold (Phase 4 gate, run locally)

The eval runs on this machine, not in CI. A skill-touching change runs one pass and calls
`grade.py <runs-dir> --min-with-skill 24 --min-delta 4`, a single-pass floor kept deliberately
conservative: this 3-pass baseline runs 37/37 per pass with a per-pass delta of 8 or 9, so the
floor sits far below the observed range and fires only on a real regression, not on the unaided
arm's noise:

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
