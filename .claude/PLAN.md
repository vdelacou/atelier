# Plan: the Email.java exemplar imports Pattern (2026-09-27)

The owner's go ("2 do it"): the shipped `assets/java/Email.java` wrote `java.util.regex.Pattern` out
twice, while `references/java-quarkus.md` shows the same exemplar with a bare `Pattern`, and the review
fixture's `MemberId.java` now imports it. The v2.5.0 tag still waits for its own yes.

## Steps and definition of done

1. [x] `Email.java` imports `java.util.regex.Pattern`. DoD: the Java smoke test green (it compiles the
   exemplar, tests it and runs the gates over it); citations and the em-dash gate on the diff; the
   tier-1 selector's dry run on the change named.
2. [x] CHANGELOG (Unreleased); commit and push on the owner's yes.

## Status
Done 2026-09-27: Java smoke test green (58 checks, none failed), citations 235 intact, tier-1 selector 0 of 21 tasks. Committed and pushed on the owner's yes given in advance.
