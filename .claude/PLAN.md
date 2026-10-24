# Plan: release 2.8.0 (2026-10-24)

The previous plan closed: PR #19 (every file holds the mutation threshold) merged on 2026-10-23 (main
0243e5a). The owner pushed `v2.7.1` on the 2.7.0 release commit (2659e70), its GitHub Release with
empty notes, and chose to keep it; the `v2.7.0` tag was never pushed. They asked for the 2.8.0 release
PR and chose tier 2 first.

Since 2.7.0: #15 (the GitHub Free host check, the first push), #16 (the bailing, core-only runner),
#17 (the local run since the last push), #18 (landing on green), #19 (the per-file and per-class
mutation gates). No skill description changed.

## Steps and definition of done

1. [x] Tier 2: both arms, 21 tasks, `claude-opus-5`, three jobs, Bun 1.4.2 first on PATH, detached.
   DoD: 42 sessions finish (capped ones named); `grade.py` both arms and `--frozen-baseline`; every
   skill-arm miss read by hand.
2. [x] Record it: a "Tier 2 for the 2.8.0 release" section in baseline.md, the README row, the
   changelog summary's sentence. DoD: fast gates green.
3. [x] The release commit: `[Unreleased]` becomes `[2.8.0] - 2026-10-24` with a summary and upgrade
   notes, a `[2.7.1]` entry, the README's current release line. DoD: fast gates green, no em dash.
4. [ ] Land: PR, CI green, rebase merge; the owner tags `v2.8.0` on the release commit.

## Status

Tier 2 ran 14:31 to 16:30 UTC: skill 61/61 (24/24 on the discipline tier), unaided 38/61 (10/24)
against the frozen 36.2/61 and 8.8/24, no session capped, no skill-arm miss, turn medians 50 and 16.
Recorded in baseline.md, the README row and the changelog summary; fast gates green. Next: the release
PR, then the owner tags `v2.8.0` on the `docs(release)` commit as it lands on main.
