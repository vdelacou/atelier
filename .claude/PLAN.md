# Plan: the Next variant ships a CI workflow (2026-09-08)

Goal: the Bun-script and Java variants ship `ci.yml` and `ci-java.yml`, the authoritative gate set that a
bypassed hook cannot skip; the Next variant ships none, so a Next repo built from the skeleton has hooks
only. Ship `assets/ci-next.yml` in the same shape, wire it into the doc, the skill table, the README, the
workflow-asset gate and the Next smoke test.

Definition of done: `assets/ci-next.yml` runs, on push to main and pull requests, on a frozen lockfile:
commit messages over the pushed range through commitlint (the hook's own grammar, so one grammar per
variant, canon 1.3), `check-commit-range.sh`, `check-package-json.sh`, gitleaks over the full history
(installed first), then `bun run --filter '*' test | lint | typecheck | build` and the bundle budget
over every `packages/*/out`. `check-workflow-assets.sh` lints it (new `ci-next.yml` case mapped to
`nextjs-monorepo.md`) and passes; nextjs-monorepo.md gains a CI section and the bootstrap copies the
workflow and the three scripts; SKILL.md's Pre-commit row names it for Next; README names it beside the
other two; the Next smoke test copies it into `.github/workflows/ci.yml` and greps the gates it must
carry; matrices cite it (15.1); CHANGELOG bullet; CI green. No description change; no tier 1.

Facts (2026-09-08): `check-commit-messages.sh` delegates to `.githooks/commit-msg`, which the Next
variant does not install (its hook is commitlint through simple-git-hooks), so the re-check uses
`bunx --yes commitlint --from <base> --to HEAD` with the same range logic (PR base ref, else
`github.event.before`, else `HEAD~1`); `check-workflow-assets.sh` maps a workflow to its bootstrap doc
by file name and requires `assets/<script>` to appear in that doc; `check-bundle-size.sh` takes one
output directory, so the workflow loops over `packages/*/out`; the smoke fixture is a single package,
so the workflow is proven by extraction, the asset gate and greps, not by running Actions.

1. [x] `assets/ci-next.yml`; `check-workflow-assets.sh` case `ci-next.yml` (`BOOTSTRAP_REF_NEXT`).
       DoD: `bash scripts/check-workflow-assets.sh` green after step 2; yaml parses.
2. [x] `nextjs-monorepo.md`: a "CI" section after `commitlint.config.cjs` (what runs, copy lines for the
       workflow and `assets/check-commit-range.sh`, `assets/check-package-json.sh`,
       `assets/check-bundle-size.sh`, required status check, `BUDGET_KB`); bootstrap step 5 copies them.
       SKILL.md Pre-commit row Next cell adds "(full set in `ci-next.yml`)". README line 290 sentence
       and the assets tree gain `ci-next.yml`. DoD: description byte-identical; frontmatter; citations
       re-anchored (nextjs-monorepo.md lines after the new section) and locked; em-dash gate.
3. [x] (Next smoke green 2026-09-08; the first asset draft did not parse, fixed before the run that counts) `smoke-test-next.sh`: copy the asset to `.github/workflows/ci.yml`, grep for the package.json gate,
       commitlint, the frozen lockfile, the bundle budget and `check-commit-range.sh`; header comment.
       DoD: Next smoke green locally.
4. [x] (four slices committed and pushed 2026-09-08 on the owner's yes) Forward row 15.1 evidence adds `assets/ci-next.yml`; lock; drift. CHANGELOG Added bullet; LESSONS
       one sentence; plan final. Commits on the yes: (a) `feat(next): ci-next.yml, the authoritative gate
       set for the Next variant`, (b) `docs(next): the CI section, bootstrap, skill row and README`,
       (c) `test(smoke): the Next workflow carries its gates`, (d) `docs: matrices, changelog and lessons
       for the Next CI`. Push on its own yes.

Not in scope: coverage and mutation for Next (the matrix says no); range-end pinning.
