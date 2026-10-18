# Plan: release 2.7.0 (2026-10-18)

The previous plan (rule 26's public-blocks, private-warns split) closed with PR #13 rebase-merged on
2026-10-18 (main 3d2c4e3), all 11 checks green on Linux and Windows. The owner asked to tag a new
version and chose: 2.7.0, tier 2 before the tag, and the usual landing (a release PR, merge on green,
an annotated tag on main).

Since v2.6.1: 66 commits, hard rule 38 (the branch lifecycle), the reply gate, the eval preflight, the
Windows coverage fix, TypeScript 7 beside the 6.0 API with Next.js 16.4.2, and rule 26's visibility
split. No skill description changed, so the trigger eval is not due.

## The design

- Tier 2 per the contract (baseline.md, Tiers): the full matrix, both arms, 21 tasks, `claude-opus-5`
  (the frozen fixture's model), 120 turns and 40 minutes per session, three jobs as in 2.6.0, with Bun
  1.4.2 first on PATH so the TypeScript aliases install. Run detached, since a background tool call
  ends at two hours and a worker restart can drop it; the runner has no resume, so a lost session is
  rerun by its task id and arm into the same runs dir.
- The re-freeze is not possible here: freeze-baseline.py sums passes by re-grading their runs dirs,
  and the five earlier passes' dirs are not in this container (the workspace is gitignored). The
  fixture stays at five passes; this pass's unaided arm is reported beside it.
- The release commit, `docs(release): 2.7.0 changelog, upgrade notes and README`: `[Unreleased]`
  becomes `[2.7.0] - <date>` with a summary, a new empty `[Unreleased]` above it, the README's current
  release line, and the README rows that read tier 2.

## Steps and definition of done

1. [ ] Tier 2. DoD: the preflight answers; 42 sessions finish (capped ones named); `grade.py` on both
   arms and `--frozen-baseline` on the skill arm; every miss read by hand, with extra samples of a miss
   as 2.6.0 did for h5, so variance is told from a regression.
2. [ ] Record it: a "Tier 2 for the 2.7.0 release" section in baseline.md, and the README rows that
   read it. DoD: fast gates green.
3. [ ] The release commit. DoD: fast gates green, no em dash.
4. [ ] Land on the owner's yes (given 2026-10-18): a PR, CI green on Linux and Windows, rebase merge,
   an annotated `v2.7.0` on main pushed, then this plan closed.

## Status

Started 2026-10-18. Next: step 1, the preflight.
