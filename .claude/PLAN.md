# Plan: companion cascade for the gates landed since 2.3.0 (2026-09-26)

Goal: CLAUDE.md requires every main-skill gate change to reach the companion skills in the same
change; eight landed since v2.3.0 without that sweep (the rule 26 identity gate, the rule 27/29/30
discipline wrapper, the Next layer zones and fs ban, the Java rule 4 PMD rules and rule 20 ArchUnit
rules). The sweep found three stale echoes: adopt mode would copy CI workflows whose `--all` steps
fail a legacy tree on the first push; greenfield treats rule 26 as manual and its "prove red" list
omits the new gates; review-me has no finding for a hook or CI workflow that drops them. Grill-me
mentions no gate and needs nothing.

Definition of done: atelier-review-me adopt mode says the identity and discipline gates start in the
hook (staged lines, safe on a legacy tree) and their CI `--all` steps join at the flip-to-blocking
slice, with the `--all` audit as the adopt-mode inventory; its step 3 names a hook or CI workflow in
the diff that drops `check-identity.sh` or `check-disciplines.sh` (and the Java PMD/ArchUnit additions)
as a finding, scoped to gate files in the diff so an ordinary diff in an unconverted repo raises
nothing new; atelier-greenfield step 5 names the gate, step 8's prove-red list gains the identity
gate, the discipline wrapper, rule 4 and rule 20 in Java and the Next fs ban; descriptions untouched
(no trigger-eval); frontmatter, em dash, identity, citations green; review-eval grader selftest green
and a review-eval skill-arm pass showing no new false positives; commit on the yes.

1. [x] (review-me: step 2 gate-file finding for a dropped tripwire or rule-4/20 check, step 3 Java rules 4 and 20 and the Next zones and fs ban, step 6 the tripwires as mechanical gates, adopt step 2 hook-first with the CI --all steps held to step 6 and --all run once as the inventory; greenfield: step 3 copies the tripwires with isolation opt-in, step 5 names the gate and IDENTITY_DENYLIST, step 8 prove-red gains rules 26, 27, 4, 20 and the Next atom zone; descriptions untouched) Read both companions in full; edit.
2. [x] (fast gates green; review eval skill arm: bun 12/12 caught, 12/12 cited, 1 FP; java 9/9, 8/9, 1 FP; both FPs cite rules 11, 12, 16, untouched by the cascade, and are true on the fixture text; recorded in review-eval/baseline.md with the fixture fix as a candidate) Gates; review-eval pass (the eval that measures review-me).
3. [~] (CHANGELOG written; no LESSONS entry: the fixture finding is recorded where the eval lives; committed and pushed on the yes) CHANGELOG, LESSONS if warranted, commit on the yes.
