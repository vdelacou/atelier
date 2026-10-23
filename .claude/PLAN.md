# Plan: every file holds the mutation threshold (2026-10-23)

The previous plan closed: PRs #16, #17 and #18 merged on 2026-10-23 (main 6d6c5b9), each with all 11
checks green. Building #16's smoke case surfaced a gap, and the owner asked to fix it: Stryker's
`thresholds.break` and PIT's `mutationThreshold` judge the whole run's score, and under `--mutate`
Stryker's incremental report keeps other files' old results in it, so a file at 55.56 passed in a run
that totalled 90.00. The doctrine says every file scores 90 or more.

## The design

- Bun: `assets/check-mutation-score.ts` reads Stryker's JSON report (the json reporter goes on in
  `stryker.conf.json`) and holds each file the run mutated to `thresholds.break`, read from the report;
  a scoped file the report lacks fails by name. `mutate-changed.sh`, `mutate-staged.sh` and the
  `mutate` script end with it.
- Java: the pom asks PIT for XML; `assets/check-pit-score.py` holds every class in the report, nested
  classes folded into their outer one, to the pom's `mutationThreshold`. `pit-changed.sh` and
  `mutation-java.yml` end with it.
- Next.js has no mutation gate, so nothing changes there.

## Steps and definition of done

1. [x] Both checks with selftests; each selftest red under deliberate breaks of its check.
2. [x] Wiring, bootstrap copies, smoke cases where the run's total passes and one weak file or class
   fails by name. DoD: Bun and Java smoke green locally.
3. [x] Docs: workflow.md guarantee, java-quarkus.md, SKILL.md matrix row, changelog; tier 1 dry run.
4. [ ] Land: PR, CI green on Linux and Windows, rebase merge.

## Status

Steps 1-3 done: Bun smoke 167 and Java smoke 92 green under Bun 1.4.2, the TS check red under 5
breaks and the Python one under 4, tier 1 selects 0 of 21 tasks. Next: the PR.
