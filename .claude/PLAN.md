# Plan: mutation cadence, changed files per run, full sweep daily (2026-09-03)

Owner's ruling (2026-09-03): CI never runs the full mutation sweep on a commit; it mutates the
changed files only, on pull requests and on pushes to main alike. The full sweep runs once a day
on a schedule, outside the merge gate. Both variants.

## Design

- Bun: `mutate:changed` resolves its base the way the commit gates do (a PR: `origin/<base>`;
  a push: `GITHUB_EVENT_BEFORE`, zero SHA or unresolvable falls back to `HEAD~1`; elsewhere
  `origin/main`, `BASE=` still overrides), so `assets/ci.yml` runs it on every event. Without
  that, a push to main has HEAD == origin/main and the step passes over nothing (the hole the
  commit gates had until 2026-09-02). New `assets/mutation.yml`: daily cron plus
  `workflow_dispatch`, frozen install, `bun run mutate`. A red scheduled run is the signal, the
  audit.yml pattern; it is not a required check.
- Java: new `assets/pit-changed.sh` (the mirror of mutate-changed.sh: same base resolution,
  untracked files in scope, fails loudly on an unknown base, exits 0 with a message when no
  class under `domain`/`usecases` changed) runs PIT with `-Dpitest.targetClasses=<fqcn,...>`;
  the canonical pom reads `<targetClasses>${pitest.targetClasses}</targetClasses>` with the two
  package globs as the property default, so the CLI can narrow it. `assets/ci-java.yml` runs the
  script; new `assets/mutation-java.yml` runs the full `mutationCoverage` daily.
- Doctrine: the cadence is a profile value (canon 4.4 keeps the KPI; the profiles appendix row
  carries "changed files per run, full sweep daily"). The canon's 4.4 example comment says
  "main runs the full sweep": a P6 row proposes the scheduled sweep instead, applied on the
  owner's ruling.

Assumptions, named: cron `0 3 * * *` UTC for both sweeps; the scheduled workflow does not
upload reports (one fewer action to pin; add `actions/upload-artifact` per repo if wanted);
`pitest.targetClasses` is a comma-separated property (PIT documents the CLI form, the smoke test
proves the narrowed run).

## Standing rules

Commits at most 10 files / 300 lines, Conventional, each gate change with its red fixture in
the matching smoke test, companions swept in the doctrine slice, citations re-anchored per
slice. Commit under the standing approval; push on an explicit ask. Verify set: V1
`smoke-test.sh`, V2 `smoke-test-java.sh`, V3 `check-citations.py`, V4
`check-workflow-assets.sh`, V5 `check-matrix-drift.py`, V6 `validate-frontmatter.ts`, V7
`check-no-em-dash.sh`.

## Slices

1. [x] feat(atelier): mutate:changed resolves the CI range; ci.yml runs it on every event (fd9e653,
       merged with slice 2 so the prose never cites an asset that does not exist yet).
       Files: assets/mutate-changed.sh, assets/ci.yml, scripts/smoke-test.sh, workflow.md
       (CI paragraph, the three-scopes list, the guarantees list), assets/mutate-staged.sh header.
       Red fixture: in the smoke fixture, commit a domain change, then
       `GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE=$(git rev-parse HEAD~1) bun run mutate:changed`
       must test that one file (today: exits 1 on the missing origin/main).
       DoD: V1 green with the new case seen red before the script change; V3; V7.
2. [x] feat(atelier): the daily full mutation sweep, `assets/mutation.yml` (in fd9e653).
       Files: assets/mutation.yml, scripts/check-workflow-assets.sh (the loop and the bootstrap
       case learn `mutation*.yml`), bun-typescript.md bootstrap step 14, README copy block,
       scripts/smoke-test.sh (asset present, scheduled, runs `bun run mutate`; ci.yml no longer
       runs the full sweep), workflow.md (Mutation testing section names the sweep).
       DoD: V4 (with its selftest), V1, V3.
3. [x] feat(atelier): PIT on changed classes in CI, full sweep daily (Java). V2 first run: every PIT
       case green, two asset checks failed on a quoting slip (unexported $SKILL inside bash -c),
       fixed, second run all green.
       Files: assets/pit-changed.sh, assets/ci-java.yml, assets/mutation-java.yml,
       java-quarkus.md (pom fence property + targetClasses, PIT bullet, gates list, CI paragraph,
       bootstrap copy lines), scripts/smoke-test-java.sh (narrowed run on one changed class,
       unknown base fails loudly, no change exits 0, workflow assets present).
       DoD: V2 green with the narrowed case seen red before the pom change; V4; V3.
4. [x] docs(atelier): the cadence everywhere else. SKILL.md matrix row 116 and checklist 180,
       README commitments row 39, profiles appendix row 4.4, matrix notes 4.4/4.6/15.1, workflow.md
       summary lines 631 and 667, review-me/greenfield if they echo the cadence, CHANGELOG.
       DoD: V3 (`--lock` after re-anchor), V5, V6, V7.
5. [x] docs(canon): P6 row for the 4.4 example comment (scheduled full sweep), status proposed (drafted;
       applied on the owner's ruling with the hash re-pin. DoD: V5.
6. [ ] tier 1: `CONFORMANCE_SINCE=<pre-slice-1 ref> CONFORMANCE_MODEL=claude-opus-5 bash
       scripts/conformance-eval/run.sh`, graded `--frozen-baseline`; report. LESSONS entry if a
       gotcha surfaces; this file to final state.
