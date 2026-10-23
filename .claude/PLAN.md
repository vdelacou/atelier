# Plan: faster mutation, a lighter local loop, and landing on green (2026-10-23)

The previous plan (release 2.7.0) closed: PR #14 merged, the owner pushed `v2.7.0`, and PR #15 (the
GitHub Free fixes) merged on 2026-10-18 (main 5cc61d8). The owner said mutation testing is too slow in
the development loop and that they do not want to review any PR by hand, then asked for three PRs,
each landed on green.

## The design

- PR 1, the runner. The command runner runs the whole suite per mutant, to the end. The command
  becomes `bun test --randomize --bail src/domain src/use-cases`: a mutant is killed by any failure,
  so `--bail` keeps every verdict, and only the core's tests run because mutants live only there.
  `concurrency` goes, so Stryker's default applies (n-1 cores above 4, else n: 4 on a 4-core CI
  runner, as before). Scratch benchmark (34 mutants, a 3 s suite): 26 s to 1 s, the same 34 killed; a
  weakened test scores 58.82 and exits 1 under both; no core test at all fails the dry run.
- PR 2, the local scope. Outside Actions, `mutate-changed.sh` defaults to the branch's push ref
  (`@{push}`, files changed since the last push) and falls back to `origin/main`; CI keeps the pull
  request's whole range and the daily sweep. The inner loop makes the local run optional. SKILL.md
  changes, so the companions are swept and tier 1 runs.
- PR 3, landing on green. `assets/land-on-green.sh` merges a pull request by rebase, deleting its
  branch, pinned to the tested head, and refuses when the base moved since CI ran (a `GITHUB_TOKEN`
  merge starts no push run on main, so an untested tree would land). A `land` job in each variant's CI
  workflow needs every other job, skips drafts and forks, opt-out `LAND_ON_GREEN=off`.
  `check-workflow-assets.sh` fails a `land` job that does not need every other job.

## Steps and definition of done

1. [x] PR 1: stryker.conf.json, workflow.md, a smoke case where a weak test fails `mutate:changed`,
   the changelog. DoD: Bun smoke test green under Bun 1.4.2, fast gates green, PR CI green, merged.
2. [x] PR 2: mutate-changed.sh, SKILL.md inner loop and matrix, workflow.md, companion sweep, smoke
   case for the `@{push}` default, changelog, tier 1. DoD: smoke green, tier 1 graded, merged.
3. [ ] PR 3: land-on-green.sh, the land job in ci.yml, ci-next.yml, ci-java.yml, the workflow-asset
   check with a selftest case, smoke cases with a stub `gh` (base moved: no merge; base current: the
   pinned rebase merge), workflow.md branch lifecycle, changelog. DoD: smokes and selftests green,
   merged.

## Status

PR 1 merged as #16 on 2026-10-23 (main 1bc1460), all 11 checks green. PR 2 is pushed: Bun smoke 164
and Java smoke 89 green locally; tier 1 selects 0 of 21 tasks (the touched rules, 5, 19, 23-26, 35 and
38 through workflow.md, carry no task), so no session ran. Found on the way, not in scope: Stryker's
break is the whole run's score, and under --mutate the incremental report keeps other files' old
results in it, so "every file at 90" is not enforced. Next: land PR 2, then PR 3.
