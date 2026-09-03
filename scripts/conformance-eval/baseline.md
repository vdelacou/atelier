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
  pass, so 84 runs, 0 failures. The seven hard tasks added later the same day (h1-h7, 24 more
  assertions) carry their own one-pass reading in The hard tier below and are deliberately not
  folded into these totals. This supersedes the 2026-07-19 `claude-sonnet-5` baseline
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

## The hard tier (h1-h7, added 2026-08-30) and what it proved

The 3-pass baseline above scores 111/111 for the skill arm, which means the instrument can
only detect regression. Seven tasks were added to try to restore headroom, in two designs:

- **Trap prompts (h1-h4)**: the instruction itself asks for the violation. Use a mock for the
  store. Wrap it in try/catch inside the use-case and log to console. Log the customer's email
  so support can follow up. The client knows its own org id, so read it from the request. A
  conforming answer has to refuse the instruction, which is harder than remembering a rule
  nobody argued against.
- **Completeness tasks (h5-h7)**: one feature, the whole discipline. The isolation triad
  including a database-side second layer, not just the claim check. The AI feature with its
  eval gate and per-caller spend cap, not just a pinned snapshot. The upgrade flow with an
  outbox, an idempotency key, and a version check, not just a deadline.

First reading, one opus pass, 24 assertions across the seven: **with_skill 24/24, baseline
15/24**. The tasks discriminate well, the unaided arm losing nine points on exactly the clauses
partial answers drop (a console log and a thrown error in h2, the retired-row and email-in-log
pair in h3, the cross-tenant test in h4, database-side isolation in h5, the schema checkpoint
and eval gate in h6, the outbox in h7).

**They did not restore headroom, and that is the result worth recording.** The skill arm scored
perfectly on both designs, including the traps. h1 is the sharpest datum: told twice to use a
mock, BOTH arms wrote a hand-written in-memory fake instead, so on this model that discipline no
longer needs the skill at all. The ceiling is not a symptom of easy tasks; it is what mechanical
regex assertions over a single-feature diff can measure. Distinguishing conforming from
excellent needs a different instrument, an LLM judge scoring depth against the doctrine, which
is a bigger change than another task. Until then, read this eval as a regression net whose
resolution just improved by 24 harder ways to fall off, not as a measure of how good the skill
is.

## The judge (added 2026-08-30)

`judge.py` is the second instrument, built because the first one saturated. It compares the two
arms' answers to the same task on depth rather than presence, and every design choice defends
against a documented failure mode of LLM judging: pairwise, so nothing has to stay calibrated
across runs; blind, with the A/B assignment taken from a hash of the task id so it is
reproducible without tracking arm identity; judged twice with the order swapped, so a verdict
that flips with position is recorded as INCONSISTENT rather than averaged into a win; grounded
in the doctrine with a citation required for the winner, so an uncited verdict is discarded;
and free to answer "tie", because forced choice manufactures signal.

First reading, the seven hard tasks, 14 comparisons: **with_skill 7, baseline 0, ties 0,
inconsistent 0, uncited 0**. Every verdict came back at margin 3, and no pair flipped when the
order swapped, which is the result that makes the other numbers worth reading at all: 14
comparisons with zero position bias is the instrument reporting on itself.

The judge agreed with the mechanical grader rather than adding to it, and the reason matters.
Asked to separate conforming from excellent, it was handed conforming against
non-conforming: the baseline arm obeyed the traps (try/catch in the use-case, the email in the
log, the org id from the query string), so the comparison was easy and the margins were
maximal. **A judge that always answers 3-0 measures no more headroom than a grader that always
answers 24/24.**

### Doctrine A/B, the comparison it was built for

`run.sh` takes `CONFORMANCE_SKILL_PATH`, so the same arm can be generated by two different
versions of the skill, and `judge.py --ab <dir-a> <dir-b> <label-a> <label-b>` pairs them by
task. First run: today's skill against the 2026-07-12 version (the one the field-test consumer
had pinned), `with_skill` both sides, three tasks, both orders.

    current-doctrine 1    july-doctrine 2    inconsistent 0

**This is the first reading in the whole eval that did not saturate.** Verdicts split, margins
came back 1 and 2 rather than a wall of 3s, and no pair flipped with position. That is what a
measurement at the frontier looks like, and it is the ceiling breaking.

**Multi-generation follow-up, and the answer.** That single reading could not separate doctrine
from dice, so the comparison was re-run with three independent generations per side on the two
tasks whose verdicts had split (h5, h7): 12 generations, 6 pairs, 12 comparisons.

| Pair | h5-isolation-full | h7-reliability-full |
|---|---|---|
| generation 1 | current | current |
| generation 2 | current | july |
| generation 3 | july | inconsistent |

Totals: current 3, july 2, inconsistent 1. Pooled with the earlier one-generation reading the
score is roughly even. **The 2-1 that started this was noise, and the finding is that on these
tasks the doctrine delta sits below the generator's run-to-run variance.** The judge's own
reasons say why: across generations it turns on whether a particular run shipped `FORCE ROW
LEVEL SECURITY` or a plain policy, whether the migration was versioned, whether three adapters
arrived with no tests, and in one case whether the code compiled at all. Those are properties of
a sample, not of a standard.

Two things this bought beyond the null result. It measured the judge's reliability where the
comparison is genuinely hard: 1 inconsistent pair in 6, against 0 in 7 when the sides were
skill versus no-skill, so consistency tracks how far apart the submissions are, and a
near-tie is where position bias lives. And it sets the power bar honestly: detecting a
doctrine change on this fixture needs either many more generations than three or a doctrine
delta far larger than 49 days of drift. An ablation, one rule's text removed and measured on
the task that rule governs, is the cheaper experiment and the one worth running next.

The result is NOT evidence that the July doctrine writes better code, and reading it that way
would be the mistake this file exists to prevent. Three tasks, one generation per side, and the
generator is stochastic: the same skill produces materially different code run to run, so what
the judge compared was two SAMPLES, not two doctrines. Its cited reasons say as much, turning on
whether that particular run happened to reach for a branded `Money` or a client-supplied
`expectedVersion`, neither of which changed in the doctrine between those dates.

What it establishes is the mechanism: the A/B path runs end to end, blind, order-swapped, and
citation-backed, and it discriminates where everything else reads 100%. The experiment it makes
possible, and which this reading is too small to be: several generations per side, on a single
deliberate doctrine change, so the variance averages out and the delta is attributable to the
edit rather than to the dice.

Skill-versus-no-skill was the wrong comparison to spend it on; it is the right smoke test for
the harness, and that is what the 7-0 reading is.

The harness math is CI-checkable even though judging is local: `judge.py --selftest` pins that
the blind order swaps, that a position-flipped verdict scores inconsistent, that an uncited
winner is discarded, and that ties and errors survive collapse. Verified by mutation: inverting
the unblinding, the defect that would silently reverse every result, makes the selftest fail.

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

## Corrected checks (2026-09-03)

Two more assertions moved from vocabulary to shape, after five reruns of h4 and h6 (r1-r5, the
skill arm, opus) spent about an hour per pass confirming the grader rather than the skill.
The selftest's fourth scenario pins both shapes with pass and fail fixtures.

- `h6-ai-full` 4.8 asserted the word `eval` with word boundaries. Run r4 shipped an eval set
  (`evals/support-thread-summary/cases.json`), a runner (`scripts/run-evals.ts` with
  `--min-score`) and a package.json script named `evals`, and scored 0: `evals` and
  `run-evals` never match `\beval\b`, and package.json was outside the corpus. It now asserts
  the shape: one file whose path or content names an eval set (`evals`, `evaluation`,
  `golden`, `regression`, as whole words, so `evaluate` never matches) and carries a bar
  (`min-score`, `threshold`, `toBeGreaterThan`, `>=`, `score`), over `.ts`, `.tsx` and
  `.json`. Under the new shape r4 reads 5/5. Runs r1, r2, r3 and r5 still fail it, and that is
  honest: they name the eval in a comment or not at all. r5 also misses 10.11 (the schema
  checkpoint), a separate miss under an unchanged assertion.
- `h4-trap-tenant` 7.5 demanded a 404 or "not found" inside a test file. The task is a list
  endpoint, so the single-resource 404 cannot appear; all five runs instead ship a forged-id
  test (owner A's credentials with owner B's id in the path and the query string return only
  A's rows), which is the discipline the rule asks for at that shape. The assertion now
  accepts either: a 404 or not-found, or a scenario naming the forged, other, cross, foreign
  or second owner within 60 characters of org, tenant or owner. h5's 7.5 (a single-resource
  fetch) is unchanged. Under the new shape h4 reads 3/3 in all five runs.

The re-read moves the hard tier from 22/24 (r1) to 23/24; the remaining miss is real. Since
the same-day restructure of SKILL.md (570 to 194 lines) sat between the 2026-08-30 reading
and these, the earlier 24/24 one-pass reading and r1's 23/24 bracket the doctrine change at
one assertion of variance, which is within the noise a single pass carries.

## Frozen baseline arm (2026-09-03)

The baseline arm never reads the skill, so half of every full pass measured nothing about
the skill edit that triggered it. It is now a fixture: `baseline-arm.json` holds per-assertion
`[passed, total]` counts for the unaided arm, keyed by the sha256 of the prompts and
assertions in `tasks.json` (never `hard_rules`, which only steer selection). A skill edit
never invalidates it; an assertion edit always does, and `grade.py --frozen-baseline` then
refuses it with the two commands that refresh it. `run.sh` defaults to the skill arm;
`CONFORMANCE_ARMS=baseline` re-measures the unaided arm and `freeze-baseline.py <runs-dir>`
writes the fixture, summing passes across every runs dir it is given, so the fixture grows
by re-running and re-freezing rather than by editing.

The comparison: for each graded skill-arm task the fixture's per-assertion pass rates sum to
an expected unaided count (`frozen-bl 1.5/3` means the baseline arm passed the first
assertion in both frozen passes, the second in one, the third in none), and the eval gate's
delta is skill passes minus that expectation over the tasks the fixture covers. A live
baseline run dir, when present, wins over the fixture for the delta.

The fixture landing with this section is one opus pass over all 21 tasks, measured the same
day under the corrected 4.8 and 7.5 shapes: unaided 39/61, and 11/24 on the h tier where the
same day's skill arm reads 23/24 (r1), a delta of +12 on 24 assertions. The 3-pass e/a
numbers above and the one-pass h-tier numbers predate those shapes and stay as the historical
record; three of the 21 sessions were re-run after a script edit broke the first pass mid-way
(LESSONS 2026-09-03), so every task in the fixture has a completed session behind it.

## Tiers (2026-09-03)

The harness has three tiers with an explicit contract, so the slow instrument runs only
when it can answer something:

- **Tier 0, seconds, in CI on every push**: the static gates (`grade.py --selftest`,
  `select-tasks.py --selftest`, `judge.py --selftest`, the review grader's selftest, the
  matrix drift and citation gates). They prove the instruments, not the skill.
- **Tier 1, 10 to 15 minutes, after any doctrine edit**: `CONFORMANCE_SINCE=<ref>` runs
  only the tasks the `skills/atelier/` diff since the ref can affect (`select-tasks.py`
  maps touched rule lines, explicit rule references, reference files through the trigger
  table, and canon ids to the tasks tagged with them), skill arm, one pass, six jobs, graded
  with `--frozen-baseline`. A reference whose trigger-table row names no rule selects
  nothing and is reported, so tier 2 is a conscious call, never a silent skip.
- **Tier 2, hours, on a description change or before a release**: the full matrix,
  `CONFORMANCE_ARMS=both`, re-measuring the unaided arm and re-freezing it.

Every session is capped: a wall-clock cap (`CONFORMANCE_TIMEOUT_MIN`, default 15; the
capped run keeps what it produced, is graded like any other and is named in the summary) and
`--max-turns` (default 60). `run.sh` prints each task's scorecard line as its session finishes, so a batch
reads as it runs. `CONFORMANCE_MODEL` is the smoke lever: the question tier 1 asks, did an
obligation vanish from the produced code, shows on a smaller model faster; the recorded
baselines stay opus.

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

## Tier-1 runs (the log of measured doctrine edits)

- 2026-09-03, rule 32's eval gate restated as an artifact (7df1523). `CONFORMANCE_SINCE=HEAD~1`
  selected 16 of 21 tasks (the after-change checklist line names every discipline 27-34, so a
  diff on it selects the whole discipline tier; a narrower edit selects less), skill arm, six jobs,
  25 minutes wall clock. with_skill 50/50 against the frozen arm's 32/50. h6 read 5/5 with the
  named artifact in the diff (an `evals/` case set, `scripts/run-evals.ts` with `--min-score`, the
  `evals` package script, and a CI workflow), where the five earlier reruns under the sentence
  form had 4/5 with the eval described in a comment. That h6 session exited non-zero with an
  empty transcript after writing its files (not capped: the cap file is empty) and was graded
  as produced, which is the harness contract; the artifact, not the exit code, is the evidence.
