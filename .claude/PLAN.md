# Plan: the review fixture's guideline findings, the canary's first run, the audit re-check (2026-09-27)

The owner's go (2026-09-27, "2 do it, then 3 and then 4") on the 2.5.0 wrap-up's next steps. The
v2.5.0 tag still waits for its own yes.

## Steps and definition of done

1. [x] Review fixture: the clean files carry no guideline finding either. `notifier.ts` (and the Java
   `Notifier.java`, in neither manifest) had no implementation or caller (guideline 2); `shipping.ts`
   extracted a constant unrelated to the change (guideline 3). DoD: the fixture change, the grader
   selftest green, a three-pass rerun per variant, both arms, read before recorded, in the review
   baseline.md, the README rows and the CHANGELOG (Unreleased).
2. [x] The Oxlint canary's first run, dispatched by hand: the oxlint-parity-probe job reads both gaps
   on Linux with its controls passing. DoD: the run's job log and summary read, recorded.
3. [x] skills.sh: re-check the atelier audit (Gen, Socket, Snyk). DoD: the dates and levels recorded.

## Status
Step 1: notifier.ts, Notifier.java and the shipping.ts edit leave the changed overlay (the runner
overlays changed/ on base/, so shipping.ts is unchanged now; the planted shipping.test.ts stays);
clean-files.json keeps the six settings-slice files. Re-measure driver5 launched 20:09 (REVIEW_TAG
fx2-r1..3). Bun r1: skill 12/12 cited, unaided 7/12, after grader defects 18 and 19 (a basename matched
inside a longer name, settings.ts in load-settings.ts; "exemption" not read as clearing), each red first;
the recorded readings do not move under them.
Step 2: canary run 36317998313 (workflow_dispatch, 12:08Z): oxlint-parity-probe green in 10s on Node
22.23.2, both gaps open (oxlint 1.85.0, oxlint-tsgolint 7.0.2003, sonarjs 4.2.1), no control failed.
unpinned-typescript red as expected: ESLint crashes loading sonarjs under TypeScript 7, now through
ts-api-utils (sonarjs rule S6759 reading `Intrinsic` of an undefined enum). sonarjs-rule-probe green.
Step 3: the atelier audits unchanged (2026-09-26 08:22, hash c7fcff0f...: Gen Safe, Socket Medium on
the old check-docs.sh, Snyk Low); the providers re-audit on their own schedule.
Step 1 done 20:46: Bun skill 36/36 caught and cited, unaided 21/36 and 2/36; Java 27/27 and 27/27,
unaided 23/27 and 4/27; no rule claim against a clean file. Grader defects 18 to 21 (basename inside a
longer name; exemption, accurate and praise as clearing), each red first; no earlier reading moves.
Left: a minor style note on MemberId.java (Pattern written out twice), no rule claimed. Commits and the
push wait for the owner's yes; the v2.5.0 tag stays untouched (2.5.0 was cut before this change).
Follow-up 2026-09-27 (owner: "2 and 3"): MemberId.java imports java.util.regex.Pattern (the reviewer's
premise was half wrong: the shipped Email.java exemplar writes it out twice too); Java re-measure
fx3-r1..3, both arms; then the skills.sh re-check. The two uncommitted landings wait for the yes.

