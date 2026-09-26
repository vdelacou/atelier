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

## Fixture update, 2026-08-30 (12 violations, 3 clean files)

Two cases were planted after the day's doctrine changes gave atelier-review-me findings that
nothing measured. Both were validated in a single opus pass, reported separately from the
3-pass numbers below, which predate them:

- **v-gate-nofixture** (canon 15.10): `scripts/check-package-json.sh` widened on two axes with
  no violation fixture proving either can fail. The skill arm caught it and cited it; the
  baseline reviewer read the widening as an improvement and said nothing.
- **`src/domain/settings.ts`**, a new CLEAN file: a `try/catch` around `JSON.parse` in pure
  domain code returning a `Result`, which rule 17 sanctions explicitly. It exists to measure a
  false positive, not a catch. The skill arm cleared it by name and verified the carve-out
  rather than taking the file's own docstring on faith.

One-pass reading with the new fixtures: with_skill 12/12 caught, 12/12 rule-cited, 0 false
positives; baseline 10/12 caught, 0/12 cited, 0 false positives (it missed v-interface and
v-harddelete, the same two it has never caught).

That pass also cost two grader bugs, both fixed selftest-first (see Grader integrity):
the run initially scored a false positive against the skill arm for the exoneration sentence
that cleared `settings.ts` while citing rule 17, and scored the gate finding uncited because
the reviewer named the doctrine (`SKILL.md:433`, "every gate proves it can fail") instead of
the canon id. Both were the instrument being wrong about a correct review.

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

The 2026-08-30 fixture pass cost two more, same discipline, both of them the grader misreading
a correct review:

- **An exoneration that cites a rule is still an exoneration.** Clearing `settings.ts` reads
  "the try/catch is the pure-domain carve-out rule 17 names explicitly", so the sentence carries
  the clean file and a rule token, and the FP lens called it an accusation. It now checks for
  clearing words (conformant, clean, exempt, carve-out, holds) and, so the fix cannot swallow a
  real finding, treats a negated one ("not conformant with rule 17") as an accusation again.
- **A finding can have more than one correct citation.** The gate-proving rule is canon 15.10
  and the skill's own doctrine line; the reviewer cited `SKILL.md:433, every gate proves it can
  fail`, which the integer-only matcher could not see. A violation's `rule` may now be a list of
  alternates, any one of which counts, alongside the integer hard rules and dotted canon ids.

The pattern across all four: every grader defect found so far punished the better review, never
the worse one, because a baseline reviewer says less and gives the instrument less to misread.

## Java variant (added 2026-08-30, same day; fixture v4)

Same protocol, `REVIEW_VARIANT=java`: a self-contained Maven fixture (`base-java/`, the sealed
`Result` trio from `assets/java`, a `Refund` record with its three-scenario JUnit test, an
`Orders` port) and a 9-violation diff (`changed-java/`, `violations-java.json`): Mockito in a
test (13), `@SuppressWarnings` (15), `System.out.println` (4), a bespoke business exception
thrown from a use case (10), a `[5.0,)` version range in the pom (19), the existing test's
expected value silently changed (24), an email in a log line (27), `HttpClient` with no
timeout (29), a hard SQL `DELETE` (30). Numbers below are fixture v4, three passes on
`claude-opus-5`, both arms, 6 runs, 0 failures.

| Metric | with_skill | baseline |
|---|---|---|
| caught | 27/27 (100%) | 15/27 (55.6%) |
| rule-cited | 26/27 | 1/27 |
| false positives on clean files | 0 | 0 |

Per pass, with_skill caught 9/9 three times out of three; baseline ran 6, 2, 7, wider variance
than any other measurement in this file (the 2/9 pass is a real run, not a harness fault, and
is why single-pass review verdicts are worthless). jv-harddelete was missed by baseline in all
three passes, jv-weakened and jv-mockito in two; earlier fixture rounds (v1-v3, 9 baseline
runs total) show the same shape: the hard delete was caught unaided in NONE of the twelve
baseline runs across all fixture versions. The one rule-cited gap in with_skill (v4r1) was a
citation landing outside the finding's paragraph, a formatting wobble, not a recall miss.

## The sentinel iterations (v1 to v4), kept for what they proved

The false-positive lens needs clean files a strict reviewer has nothing to say about, and
finding them took four rounds, because the with_skill reviewer kept issuing CORRECT findings
against my candidates while the baseline arm never noticed any of them:

- v1: the new `Notifier` port used `Result<Void, String>` and raw params; the review demanded
  the doctrine's sealed per-port error union and branded ids (rules 12, 16). Right. Hardened.
- v2: hardened `MemberId` shipped without a test; flagged under rule 11 with the note that the
  file was "otherwise exactly the rule 12 exemplar". Right. `MemberIdTest` added.
- v3: `MemberId` duplicated its regex and recompiled per call, an ergonomics nit inherited
  from the shipped `Email.java` exemplar itself, which the finding thereby exposed (fixed
  upstream in the asset and its doc fence, verified by the java smoke test); and the diff
  shipped the port with no implementation while `CrmSync` declared a same-named incompatible
  method, incoherence the review caught across files. Both right.
- v4: `MemberIdTest` flagged under rule 14 in all three passes, correctly: the standard runs
  value objects real inside primary-port tests, and the reviews noted the base `RefundTest`
  precedent honestly rather than blaming the diff.

Read together, v2 and v4 asked for opposite things of the same file, and the doctrine, not
the reviewer, was the ambiguity: rule 14 said the SUT is never a value object while
testing.md allowed a few direct tests for one with non-trivial logic. Settled 2026-09-03 in
both files: the exception exists, stays rare, and a regex-shaped id such as `MemberId` does
not qualify, so v4 was the correct finding and v2's rule 11 demand was the misfire (the right
question was which port test exercises `MemberId`). No grader or sentinel change followed;
`MemberIdTest` is not in `violations-java.json`.

Final sentinel set: `Refund.java` (a conforming edit, unflagged in all 12 with_skill runs) and
`MemberId.java` (exemplar-shaped, unflagged once its test existed and its pattern was hoisted).
`Notifier` and `MemberIdTest` remain in the diff, deliberately unlisted: reviewable, not
sentinels. The design rule this bought: a sentinel must be a file the doctrine has nothing to
say about, which in practice means conforming edits to existing files and exemplar-shaped
records, never a new unwired port and never a new standalone value-object test. The planted
TS-inversion trap (a Java `interface` flagged as illegal) never fired in any of the 24 runs.

## After the companion cascade (2026-09-26)

One pass per variant, skill arm, opus, after `atelier-review-me` gained the 2.4.0 gate findings
(a hook or workflow dropping a tripwire, a Java ruleset or `LayerRulesTest` dropping the rule-4 or
rule-20 checks, the Next zones and fs ban) and adopt mode the hook-first order for the tripwires.

| Variant | Caught | Rule-cited | False positives |
|---|---|---|---|
| Bun | 12/12 | 12/12 | 1 (`settings.ts`) |
| Java | 9/9 | 8/9 | 1 (`MemberId.java`) |

Recall is full and no finding touched the edited gate text: the review named no clean file for a
missing hook or workflow, which is what scoping the new findings to gate files in the diff was for.
The two false positives cite rules the cascade did not change, and both are true on the fixture's
text. `settings.ts` is new production code with no test (rule 11) and casts parsed JSON unchecked,
`JSON.parse(raw) as Record<string, string>` (rule 12); the file was planted to test rule 17's
carve-out and the review cleared that part explicitly. `MemberId.parse` returns `Result<MemberId,
String>`, a string error where the shipped `Email` exemplar uses a typed enum (rule 16's error
shape). Neither was raised in the recorded passes, so this pass is the stricter reviewer, the same
direction as every grader defect so far. Candidate fixture fixes, not made here: give `settings.ts`
a test and a shape check, and `MemberId` a typed error, so the clean files are clean on every rule
and not only on the one they were planted for; that changes the fixture and needs both arms rerun.

## Clean fixtures, clean on every rule (2026-09-26)

The two false positives of the post-cascade pass were true on the fixture's text, so the clean files
were not clean. Fixed: `changed/src/domain/settings.ts` keeps its rule-17 carve-out and the embedded
claim (the untrusted-input probe) and gains a shape check with a typed `malformed-shape` error, and
`settings.test.ts` (four scenarios, green under bun) lands beside it and joins `clean-files.json`;
`changed-java/.../MemberId.java` returns the nested `Error` enum of the shipped `Email` exemplar and
its test follows (compiled against JUnit). No planted violation moved; the diff is 13 files.

Three passes per variant, both arms, opus, graded with the two grader fixes below:

| Variant | Arm | Caught | Rule-cited | False positives |
|---|---|---|---|---|
| Bun | skill | 36/36 | 36/36 | 2 |
| Bun | unaided | 31/36 | 0/36 | 1 |
| Java | skill | 27/27 | 27/27 | 1 |
| Java | unaided | 24/27 | 2/27 | 0 |

Two grader defects surfaced in the rerun, the eighth and ninth, and like the seven before them both
punished the better review. The first: a sentence reporting what a clean file claims about itself
("the doc comment at settings.ts:9-13 asserts its own rule 17 compliance"), which review-me tells the
reviewer to write before verifying the claim, read as an accusation because the verdict sat in the
next sentence; a sentence with a claim verb and no accusation verb is now a report. The second: a
plural citation ("breaks rules 3 and 1") cited neither rule, which left three Bun findings and two
Java findings uncited. Both have selftest cases, each seen red with its fix reverted.

The three remaining skill-arm false positives are real in the eval's terms and are not fixture or
grader defects. Two (Bun pass 3) cite "rule 3" and "rule 2" for SKILL.md's behavioural guidelines 3
(surgical changes: the drive-by constant extraction in `shipping.ts`) and 2 (simplicity: the
`Notifier` port nothing implements); the guidelines and the hard rules share the numbers 1 to 5 and
review-me gives no citation form for a guideline, so a guideline finding reads as a false hard-rule
claim. That is a review-me doctrine gap, the next slice. One (Java pass 1) says `MemberId.parse(null)`
throwing breaks rule 12; `java-quarkus.md` rejects null at the HTTP edge (`@NotNull` on wire DTOs) and
keeps shape in the record, so this is a reviewer overreach the doctrine already settles. The unaided
arm's one false positive calls the settings comment a rule argument, an opinion the standard does not
hold.
