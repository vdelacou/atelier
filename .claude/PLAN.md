# Plan: release 2.4.0 (2026-09-19)

Goal: ship the changes since v2.3.0 as 2.4.0, the 2.3.0 shape: tier 2 on the release tree, release
notes with an "Upgrading from 2.3.0" list, the pass recorded, the annotated tag, main and the tag
pushed. Minor version with a breaking marker on the six-pack removal commit (05614a6).

Definition of done: CHANGELOG has `## [2.4.0] - 2026-09-19` with a release paragraph and the upgrade
list distilled from the Consumers notes; README names 2.4.0; `baseline.md` records the tier-2 pass
(both arms, 21 tasks, opus, scores, capped, tree under test) and the fixture stays the three-pass one
unless tasks.json changed (it did not since 2026-09-10); tag `v2.4.0` on the record commit with a
message in the v2.3.0 shape; `git ls-remote --tags origin` shows it; CI green. The owner's "release"
covers the commits, the tag and the push (the 2.3.0 precedent).

1. [~] (launched 21:55, six sessions live) Tier 2: `CONFORMANCE_ARMS=both CONFORMANCE_MODEL=claude-opus-5 CONFORMANCE_JOBS=6
       CONFORMANCE_TAG=release-2.4.0`, nohup + Monitor. DoD: 42 sessions, none capped, graded.
2. [~] (written; commit next) Release notes while it runs (CHANGELOG.md, README.md). Commit `docs(release): 2.4.0 changelog
       and upgrade notes`.
3. [ ] Record the pass in `baseline.md`; if the skill arm is below full marks, stop and report before
       tagging (a grader defect is the usual cause; fix, selftest red-then-green, re-freeze from the
       workspace's three baseline directories if tasks.json changes). Commit
       `chore(conformance-eval): the 2.4.0 tier-2 pass`.
4. [ ] `git tag -a v2.4.0` on the record commit; `git push origin main v2.4.0`; plan closed.
