# Plan: baseline fixture top-up to three passes (2026-09-09)

Goal: `baseline-arm.json` was re-frozen during the 2.3.0 release from one pass (the release run's
baseline arm), because the 2026-09-03/04 directories behind the earlier three-pass fixture are gone.
A one-pass fixture reads each assertion as 0/1 or 1/1. Restore the three-pass grain.

Definition of done: two more baseline-arm passes over the 21 tasks (opus, tags `bl-2` and `bl-3`,
three jobs each, concurrently), none capped; `freeze-baseline.py` over the release run plus the two
new directories writes a fixture with `passes: 3` keyed to the current tasks.json;
`grade.py <release-runs> --frozen-baseline` accepts it and reads the skill arm 61/61 against the
three-pass expectation; `baseline.md` records the freeze; CHANGELOG Harness bullet; commit on the yes.

1. [x] (15:04 to 15:26, both exit 0, none capped, no errors) Launch both passes under nohup, a Monitor per log on `capped:|exit=|rror`. DoD: both logs end
       with `all runs complete` and `exit=0`, `.capped` empty in both directories.
2. [x] (passes 3, 63 runs, 138/183; sha of the current tasks.json; release run 61/61 vs 46.0/61; selftest OK) Freeze from three directories, verify the fixture (passes 3, 63 baseline runs, sha of the
       current tasks.json), grade the release run against it.
3. [x] (baseline.md section and CHANGELOG bullet; committed and pushed on the yes) Record in `baseline.md` (a "Frozen baseline arm (2026-09-09, three passes)" section with the
       per-pass unaided totals), CHANGELOG Harness bullet, plan closed. Commit
       `chore(conformance-eval): three-pass baseline fixture` on the yes.
