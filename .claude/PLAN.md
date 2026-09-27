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
3. [ ] Review fixture follow-up: `settings.ts` and `MemberId` get a consumer, `Refund.java` a typed
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
