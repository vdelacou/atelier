# Plan: rule 5 is a gate (2026-09-08)

Goal: rule 5, "Bun only, never npm, pnpm, yarn, node or vite directly", has no gate of any kind: a tracked
`package-lock.json` or a `scripts` entry that calls `node` passes every hook and CI step. Queued this
afternoon behind rule 15; the natural home is gate 2, `check-package-json.sh`, which already walks every
manifest in the repo and runs in the fast hook and in `ci.yml`.

Definition of done: `check-package-json.sh` reports three kinds of finding (the existing rule 19 version
strings; a non-bun lockfile tracked or staged anywhere: `package-lock.json`, `npm-shrinkwrap.json`,
`yarn.lock`, `pnpm-lock.yaml`; a `scripts` entry whose command, or a segment after `&&`, `||`, `;` or
`|`, starts with `node`, `npm`, `npx`, `pnpm`, `yarn` or `vite`, an env prefix like `LINT_STRICT=1`
allowed), all in one run, exit 1 on any; `bunx vite` and `bun run node-thing` stay green (the rule says
"directly"); the Bun smoke test proves a lockfile, a `node` script, a `vite` script and an env-prefixed
`npx` red and the fixture's own scripts green; SKILL.md rule 5, workflow.md's gate table and the asset
header name the checks; reverse row 5 and forward row 1.1 updated; CHANGELOG bullet; CI green. No
SKILL.md description change; no tier 1 (no conformance task carries rule 5).

Facts (2026-09-08): the asset exits 0 early when the version check is clean, so the new checks need the
structure changed to collect-then-report; the fixture's `package.json` is committed in the scaffold
commit and the rule 19 cases restore it with `git checkout -q package.json` (verify at lines 462-515);
the Next variant does not run `check-package-json.sh` at all (its hook is `simple-git-hooks`: test,
lint, commitlint), so rules 19 and 5 are ungated there, a separate follow-up.

1. [x] (probe matrix 11 of 11 as designed) `check-package-json.sh`: restructure into three collectors and one report; header documents the
       rule 5 checks. Probe in a scratch git repo: clean skeleton green; `package-lock.json` staged red;
       `"dev": "node src/main.ts"` red; `"build": "vite build"` red; `"x": "LINT_STRICT=1 npx eslint"`
       red; `"y": "bun run node-fetch"` and `"z": "bunx vite build"` green; a `yarn.lock` in a workspace
       dir red. DoD: the probe matrix; `bash -n`.
2. [x] (first run red on node_modules/uri-js/yarn.lock, the fixture does not ignore node_modules; the gate now excludes node_modules; rerun green 2026-09-08) `smoke-test.sh`: after the rule 19 cases, the four red fixtures and one green (`bunx vite`), each
       restoring the manifest. DoD: Bun smoke green locally.
3. [x] (three slices committed and pushed 2026-09-08 on the owner's yes) Docs: SKILL.md rule 5 names gate 2; workflow.md gate row 2 and the sentence at line 377; reverse
       row 5, forward row 1.1 evidence; citations re-anchored and locked; CHANGELOG Added bullet (consumer:
       re-copy `check-package-json.sh`); LESSONS short `[decision]`; plan final. Commits on the yes:
       (a) `feat(gates): rule 5 in check-package-json.sh, no foreign lockfile, no node or npm in scripts`,
       (b) `test(smoke): the rule 5 forms prove red`, (c) `docs: skill, workflow, matrices, changelog for
       the rule 5 gate`. Push on its own yes.

Not in scope: the Next variant's missing package.json gate (follow-up); the blank citation pins.
