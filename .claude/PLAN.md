# Plan: unicorn recommended, the review fixture follow-up, then 2.5.0 (2026-09-27)

The owner's go (2026-09-27): enable eslint-plugin-unicorn's recommended rules (both TS variants
registered the plugin with no rule on), do the open pre-release items, then release 2.5.0 with its
full conformance run. Landings on the owner's yes; the backup deletion gets its own question.

## Steps and definition of done

1. [x] Probe unicorn recommended on the real toolchain before any doctrine edit: the Bun and Next
   smoke trees (conforming code and every shipped asset they copy) and every TypeScript example in
   the references, one list of the rules that fire on conforming code. DoD: the list, each rule with
   its hits and a verdict (comply by fixing the asset or example, or off with a dated reason where
   the rule contradicts the standard, the sonarjs precedent).
2. [x] Apply: `configs.recommended` in both reference configs with the justified overrides, the
   notes, the assets and examples fixed, a red fixture per variant in the smoke tests (the rule's own
   tag, a file where only unicorn fires), the companion sweep, citations re-anchored. DoD: both smoke
   tests green with the new fixtures seen red; frontmatter, citations, matrix drift, em-dash gates.
3. [x] Review fixture follow-up: `settings.ts` and `MemberId` get a consumer, `Refund.java` a typed
   error and no single-use constant, so the clean files are clean on every rule. DoD: grader
   selftest green; a three-pass rerun, both arms, both variants, recorded in the review baseline.md
   and the README row.
4. [x] skills.sh: re-check the atelier-distill audits (and the other four). DoD: the levels recorded.
5. [ ] Release 2.5.0: the changelog block and upgrade notes, the tier-2 run (both arms, the full
   matrix), baseline.md and the README conformance rows (measured before isolation until now), the
   annotated tag, push on the owner's yes, the plan and memory refreshed.

## Status
Steps 1, 2 and 4 done 2026-09-27; unicorn landing approved (commit and push); the backup deleted on the
owner's yes. Unicorn: probed on 61 (the Next pin) and 76 (315 rules on); off with reasons: three that
fight prettier, no-null, the abbreviation rule under both names, prefer-ternary, no-array-reduce,
consistent-boolean-name, prefer-number-coercion, prefer-global-number-constants; no-useless-undefined
narrowed; the test seams scoped. About 60 examples and 4 assets brought in line; both smoke tests green
with `unicorn/throw-new-error` red; citations re-anchored (21 moved, 235 intact). skills.sh:
atelier-distill audited 2026-09-26 12:32 (Safe, Pass, Low); atelier still shows the 08:22 audit from
before the check-docs.sh fix (Socket Medium) until the providers re-audit.
Step 3 running: fixture changed (a use-case, a port and StepError consume settings.ts; Refund.java
types its error; CancelMembership takes a MemberId); re-measure driver3 launched 15:19 (three passes
per variant, both arms, REVIEW_TAG=fx-r1..3), log in the scratchpad remeasure/lanes3.log.
Bun r1 and r2: skill 12/12 caught and cited, no false positive, after the thirteenth grader defect
(a bold heading ending in `.**` read as one sentence with the next line; fixed, selftest red first;
yesterday's isolated passes regrade to one skill false positive per variant, not two). Guideline-level
findings remain true on two other clean files: notifier.ts has no implementation or caller
(guideline 2), shipping.ts's constant extraction is unrelated (guideline 3); next fixture slice.
Step 5 tier 2 launched 15:24 (driver4, CONFORMANCE_TAG=t2-2.5.0, both arms, three jobs). Harness bug
seen: with both arms, run.sh's incremental scorecard prints the other arm too, and an arm still
running reads 0 (its tree lands at copy-back); fix after the run (filter to the landed arm).
Done 2026-09-27 17:40. Step 3: three passes per variant, both arms, isolated, on the new fixture: Bun
skill 36/36 caught and cited, unaided 22/36 and 1/36; Java 27/27 and 27/27, unaided 20/27 and 1/27; no
rule claim against a clean file on either arm. Grader defects 13 to 16 fixed, each red first (the bold
heading split, a numbered heading as one finding, node:fs evidence wanting node:fs named, a call
argument is not a citation); the 2026-09-26 isolated reading regrades to one skill false positive per
variant and Bun unaided 23/36. Step 5: tier 2 15:24 to 17:18, 42 sessions, none capped or refused: skill
61/61 (60/61 before the 10.11 correction, the seventeenth defect: a branded parseThreadSummary read as
no checkpoint), unaided 35/61; production-discipline tier 24/24 against 8/24. Fixture re-frozen from
four isolated passes, 143/244. run.sh's incremental scorecard prints the landed arm only. Records in
both baseline.md files, the README rows (all isolated now) and the 2.5.0 block. Landed and pushed on the
owner's yes (four commits); the v2.5.0 tag waits for a later yes (the owner chose to tag later); next fixture slice (notifier and shipping carry
guideline findings); the Oxlint canary's first run on Monday.

