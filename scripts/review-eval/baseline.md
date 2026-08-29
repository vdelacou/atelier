# Review-eval baseline

The behavioral proof for the review side: how much of a violation-laden diff does
atelier-review-me catch that a skill-less senior-engineer review misses? The conformance eval
measures generation; this measures the enforcement moment. Read through a 3-pass replication,
single runs are too noisy for a verdict (`.claude/LESSONS.md`).

## Run

- Date: 2026-08-30
- Model (pinned): `claude-opus-5`
- Passes: 3, both arms per pass, so 6 review runs, 0 failures.
- The reviewed change: 11 planted violations (`violations.json`) and 2 clean changed files
  (`clean-files.json`) layered on the shared conformance fixture; `run.sh` materialises the
  diff outside the agent sandbox and the agent reviews `changes.diff` plus the tree, report-only.
- Grading (`grade.py`, selftest in CI): **caught** is arm-neutral (file basename + evidence
  regex in one paragraph, no rule number required, so the baseline arm can score); **rule-cited**
  additionally requires the rule number in that paragraph; **false positive** is a rule asserted
  against a clean file within one sentence.
- Reproduce: `REVIEW_MODEL=claude-opus-5 REVIEW_TAG=<tag> bash scripts/review-eval/run.sh`
  three times with distinct tags, then grade each printed runs dir.

## Result (summed over 3 passes)

| Metric | with_skill | baseline |
|---|---|---|
| caught | 33/33 (100%) | 23/33 (69.7%) |
| rule-cited | 33/33 | 0/33 |
| false positives on clean files | 0 | 0 |

Per pass, with_skill caught 11/11 three times out of three; baseline ran 7, 8, 8.

## What the baseline reviewer misses

| Violation | baseline caught | Note |
|---|---|---|
| v-interface (rule 3) | 0/3 | never flagged; `interface` reads as idiomatic TS without the standard |
| v-harddelete (rule 30) | 0/3 | never flagged; a working hard delete looks finished |
| v-class (rule 1) | 2/3 | |
| v-mock (rule 13) | 2/3 | |
| v-nodefs (rule 20) | 2/3 | |
| v-weakened (rule 24) | 2/3 | the silently changed expected value slips one pass in three |
| console, try/catch, latest, PII in URL, no deadline | 3/3 | caught without the skill |

The pattern mirrors the conformance eval: the generic reviewer finds what looks like a bug
(console noise, a missing timeout, PII in a URL) and misses what looks like working code that
merely breaks doctrine (interface, hard delete, a weakened test). Those are exactly the
violations only a rule-aware review catches, and rule-cited 33 vs 0 is the difference between
a finding the author can act on ("rule 30, soft delete") and prose they must interpret.

## Grader integrity

One grader defect was caught by this baseline run and fixed test-first, the selftest gaining
the failing case (red) before the matcher changed (green): a paragraph that names a clean file
only to exonerate it ("nothing in shipping.ts changed", "shipping.ts is exempt") was counted as
a false positive, which inflated the with_skill FP count to 1 in two passes; sentence-granularity
matching fixed it. A second hazard, a line reference like `orders-db.ts:30` counting as a rule-30
citation, was designed out up front. Both cases are pinned in `grade.py --selftest`, which CI
runs (`review-eval grader selftest`).

## Java variant (added 2026-08-30, same day)

Same protocol, `REVIEW_VARIANT=java`: a self-contained Maven fixture (`base-java/`, the sealed
`Result` trio from `assets/java`, a `Refund` record with its three-scenario JUnit test, an
`Orders` port) and a 9-violation diff (`changed-java/`, `violations-java.json`): Mockito in a
test (13), `@SuppressWarnings` (15), `System.out.println` (4), a bespoke business exception
thrown from a use case (10), a `[5.0,)` version range in the pom (19), the existing test's
expected value silently changed (24), an email in a log line (27), `HttpClient` with no
timeout (29), a hard SQL `DELETE` (30). Three passes on `claude-opus-5`, both arms, 6 runs,
0 failures.

| Metric | with_skill | baseline |
|---|---|---|
| caught | 27/27 (100%) | 19/27 (70.4%) |
| rule-cited | 27/27 | 1/27 |
| false positives on clean files | 0 | 0 |

Per pass, with_skill caught 9/9 three times out of three; baseline ran 5, 7, 7. The baseline
misses rhyme with the Bun run: jv-harddelete 0/3 (a working hard delete looks finished),
jv-weakened 1/3 (the silently changed expectation slips past), and once each the PII log line,
the missing timeout, and the exception-instead-of-Err. What it does catch unaided: Mockito,
`@SuppressWarnings`, `System.out`, the version range, the generic reviewer's home turf.

Two design notes, recorded for honesty. The TS-inversion trap did not fire: a new port
`interface` was planted as a clean file expecting a TS-minded reviewer to flag it (rule 3
inverts in Java), and neither arm did in any pass. And that same file was then reclassified
OUT of the clean list: the with_skill review accused it under rules 12 and 16 (raw `String`
params, `Result<Void, String>` instead of a sealed error union), a defensible strict reading
of the standard's own text, so it is not the indisputable sentinel a false-positive lens
needs. The clean list for Java is the conforming `Refund` edit alone; the reclassification
removed the only FP in the six runs, and it was charged against the fixture design, not the
review.

