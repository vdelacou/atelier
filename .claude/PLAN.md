# Plan: the Next variant runs the package.json gate (2026-09-08)

Goal: `check-package-json.sh` (gate 2: rule 19 version strings, rule 5 lockfiles and scripts) runs in the
Bun-script hook and in `ci.yml`, but the Next variant never runs it: its `simple-git-hooks` pre-commit is
test plus lint, and it ships no CI workflow. Rules 5 and 19 are ungated in every Next repo built from the
skeleton. Close the hook half; the missing Next CI workflow is a separate, larger gap.

Definition of done: the root `package.json` fence's `pre-commit` runs `bash scripts/check-package-json.sh`
before test and lint; the hook paragraph and the bootstrap checklist name the asset (copy from
`assets/`, `chmod +x`); SKILL.md's Pre-commit row names it for Next; the Next smoke test copies the
asset, proves it green on the fixture and red on a planted `"latest"` dependency and a planted `node`
script, and checks the fence carries the hook line; reverse rows 5 and 19 note the Next hook; CHANGELOG
Added bullet; CI green. No description change; no tier 1.

Facts (2026-09-08): the Next fixture's `package.json` scripts (`bun next build`, `bun test`, `tsc`,
`eslint`) pass the gate; the fixture gitignores `node_modules` and the gate excludes it anyway; the
smoke test never installs `simple-git-hooks`, so the hook line is proven by extraction and grep, the
gate itself by direct calls.

1. [x] (description byte-identical, no citation shift) `nextjs-monorepo.md`: root fence `pre-commit`, the hook paragraph, a bootstrap step. SKILL.md
       Pre-commit row (Next cell). DoD: description byte-identical; frontmatter; citations (the fence
       edit adds no line; the checklist step adds one, cited lines after it re-anchored if any).
2. [x] (Next smoke green 2026-09-08) `smoke-test-next.sh`: `mkdir scripts`, copy the asset, `expect_ok` on the fixture, two `expect_err`
       with restore, the fence grep; header comment. DoD: Next smoke green locally.
3. [x] (three slices committed and pushed 2026-09-08 on the owner's yes) Reverse rows 5 and 19 notes; lock; drift. CHANGELOG bullet; LESSONS one line in the day's rule 5
       entry (the Next hook was the second variant without gate 2); plan final. Commits on the yes:
       (a) `docs(next): the package.json gate joins the simple-git-hooks pre-commit`, (b) `test(smoke): the
       Next package.json gate proves red`, (c) `docs: skill, matrices, changelog for the Next gate`. Push on
       its own yes.

Not in scope: a Next CI workflow (none is shipped today: test, lint, typecheck, build, the gate, the
commit-message re-check; its own slice); range-end pinning.
