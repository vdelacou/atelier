# Plan: release 2.4.0 (2026-09-19), closed 2026-09-20

Goal: ship the changes since v2.3.0 as 2.4.0, the 2.3.0 shape: tier 2 on the release tree, release
notes with an "Upgrading from 2.3.0" list, the pass recorded, the annotated tag, main and the tag
pushed. Minor version with a breaking marker on the six-pack removal commit (05614a6).

Definition of done: CHANGELOG has `## [2.4.0] - 2026-09-19` with a release paragraph and the upgrade
list distilled from the Consumers notes; README names 2.4.0; `baseline.md` records the tier-2 pass
(both arms, 21 tasks, opus, scores, capped, tree under test) and the fixture stays the three-pass one
unless tasks.json changed (it did not since 2026-09-10); tag `v2.4.0` on the record commit with a
message in the v2.3.0 shape; `git ls-remote --tags origin` shows it; CI green. The owner's "release"
covers the commits, the tag and the push (the 2.3.0 precedent).

1. [x] (21:55 to 22:47, 42 sessions, exit 0, none wall-clock capped; four skill-arm sessions ended on the CLI's 60-turn cap, e7 h3 h6 h7, against none in any earlier pass; skill 58/61 as read, 59/61 once the 6.3 checks learned the test-tier scope, unaided 45/61) Tier 2: `CONFORMANCE_ARMS=both CONFORMANCE_MODEL=claude-opus-5 CONFORMANCE_JOBS=6
       CONFORMANCE_TAG=release-2.4.0`, nohup + Monitor. DoD: 42 sessions, none capped, graded.
2. [x] (3d7093a) Release notes while it runs (CHANGELOG.md, README.md). Commit `docs(release): 2.4.0 changelog
       and upgrade notes`.
3. [x] (recorded in baseline.md; seventh grader defect fixed: 6.3 absent checks in h3 and e6 exclude the test tier, selftest red-then-green; grade.py marks turn-capped sessions, selftested; fixture re-frozen from four passes, 184/244; a same-cap rerun of the four capped tasks launched 22:49 as the variance check; rerun capped three of four again, the 120-turn probe finished h6 5/5 and h7 4/4) Record the pass in `baseline.md`; if the skill arm is below full marks, stop and report before
       tagging (a grader defect is the usual cause; fix, selftest red-then-green, re-freeze from the
       workspace's three baseline directories if tasks.json changes). Commit
       `chore(conformance-eval): the 2.4.0 tier-2 pass`.
3b. [x] (recorded; first 120-turn launch 23:29 to 00:03: 24 of 42 sessions refused with "Failed to authenticate. API Error: 403" after the first 15 finished, the environmental tell; grade.py now treats a refused empty tree as a dead session, selftested; the CLI answered a one-turn probe at 00:04, second launch 00:06 to 01:08: 42 sessions, skill 61/61, unaided 45/61, no cap of either kind, no refusal; fixture re-frozen at 120 from its baseline arm, one pass) Owner's call on the 59/61 reading: rerun tier 2 at 120 turns first (both arms, `run.sh` defaults now 120 turns and 40 minutes, tag release-2.4.0-t120), re-freeze the fixture from that run's baseline arm (one pass at the new cap), record, then tag on that reading. Top-up to three passes at 120 after the tag.
4. [x] (v2.4.0 on 8bf86e5, pushed with main; released 2026-09-20 01:1x) `git tag -a v2.4.0` on the record commit; `git push origin main v2.4.0`; plan closed.
