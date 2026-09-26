# Plan: review-eval fixtures clean on every rule (2026-09-26)

Goal: the post-cascade review eval scored one false positive per variant on files the eval treats as
clean, and both findings were true on the fixture's text: `changed/src/domain/settings.ts` is new
production code with no test (rule 11) and casts parsed JSON unchecked (rule 12); `changed-java/.../
MemberId.java` returns `Result<MemberId, String>` where the shipped `Email` exemplar uses a typed
error (rule 16). A clean file must be clean on every rule, not only the one it was planted for.

Definition of done: `settings.ts` keeps its rule-17 carve-out and its embedded claim (the injection-
resistance probe) and gains a shape check with a typed `malformed-shape` error; `settings.test.ts`
lands beside it in the changed tree and joins `clean-files.json`; `MemberId` returns a typed error in
the `Email` exemplar's shape, its test and every caller follow; no planted violation's evidence moves
(violations.json and violations-java.json untouched); the grader selftest green; the full eval rerun,
both arms, both variants, three passes each (the recorded shape); `review-eval/baseline.md` records
the new fixture version and numbers; CHANGELOG Harness bullet; commit on the yes.

1. [x] (settings.ts: parseJson keeps the rule-17 catch and its embedded claim, isStringRecord adds the shape check, typed malformed-shape error; settings.test.ts, 4 scenarios, green under bun against the fixture's result.ts, joins clean-files.json; MemberId: nested enum Error as in the Email exemplar, MemberIdTest follows, compiles; no caller of parse elsewhere; violations manifests untouched; diff 13 files) Read the fixtures, manifests, grader and harness; edit the two files, add the test.
2. [x] (grader selftest green; the smoke pass is folded into the full run below) Selftest; one skill-arm smoke pass per variant to confirm the two FPs are gone.
3. [x] (all six passes graded with both grader fixes: skill Bun 36/36 caught and cited, 2 FP; Java 27/27, 27/27, 1 FP; unaided Bun 31/36, 0/36, 1 FP; Java 24/27, 2/27, 0 FP; ninth grader defect, plural citations, fixed with a selftest seen red; recorded; two commits pushed on the yes. Earlier: launched two chains, bun and java, three passes each, both arms; tags fxclean-r1..r3. Pass 1: Bun skill 12/12, 12/12, the one FP a grader defect (the eighth: a sentence reporting settings.ts's embedded rule-17 claim, verdict in the next sentence), fixed with selftests red under the old logic, regrade 0 FP; Java skill 9/9, 8/9, 1 FP on MemberId.parse(null), a reviewer overreach java-quarkus.md settles (null rejected at the HTTP edge), no asset change) Full rerun (12 sessions), grade, record, commit on the yes.
