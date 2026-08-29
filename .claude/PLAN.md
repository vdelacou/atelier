# PLAN: harden the mutation gate assets (untracked scope, loud base failure, ref refresh, --force)

Four verified traps in `skills/atelier/assets/mutate-changed.sh` (untouched since 13d62a8,
2026-07-04): (1) untracked files are invisible to the three ACMR diffs, so a brand-new domain
file passes unmutated with exit 0; (2) an unknown BASE ref dies inside the command substitution,
the `|| true` eats it, and the run goes green having measured nothing; (3) a stale `origin/main`
widens scope and misreads as unpushed work; (4) `rm -f reports/stryker-incremental.json`
hardcodes a path that `stryker.conf.json` owns via `incrementalFile`, and destroys the cache
before the run. Same `rm -f` also in `mutate-staged.sh`. Consumer-repo sync (the "five drifted
assets") is OUT OF SCOPE, that repo is not mounted here.

- [x] 1. `assets/mutate-changed.sh`: fetch guard (only when BASE is `origin/*`, opt-out
      `MUTATE_NO_FETCH=1`); `git rev-parse --verify` or exit 1; resolved-base print (short SHA,
      relative date, ahead count); `git ls-files --others --exclude-standard` unioned into scope;
      `bunx stryker run --force` replaces the `rm -f`.
      DONE: `bash -n` clean; smoke test proves unknown BASE exits 1 and an untracked
      `src/domain/*.ts` enters scope; no em dash in added lines.
- [x] 2. `assets/mutate-staged.sh`: `rm -f` becomes `--force` (comment rewritten, em dashes
      dropped). No untracked union, staged-only IS the gate-8 contract. `bash -n` clean.
- [x] 3. `--force` verified against the real installed Stryker: both `mutate:staged` and the new
      `mutate:changed` smoke runs pass, and an unknown option would have failed them.
- [x] 4. `scripts/smoke-test.sh`: three new checks after the ci.yml greps. All three green:
      "fails loudly when the base ref does not resolve" (expect_err, fixture has no remote),
      "scores an untracked new domain file" (BASE=HEAD after committing src/domain, so the new
      `eligibility.ts` is the only in-scope file), "prints the resolved base and pulls the
      untracked file into scope" (greps the base line and "testing 1 file(s)").
- [x] 5. `references/workflow.md` (Mutation testing): the mutate:changed bullet now says
      untracked files are in scope, plus a guarantees block (untracked, loud base failure,
      refresh + print, --force freshness, greenfield pre-remote case) and the un-encodable rule
      (fetch before reading origin/main-relative output as push scope; confirm with
      `git log --oneline origin/main..HEAD`).
- [x] 6. LESSONS.md `[gotcha]` entry: all four traps, why `--force` over `rm`, why untracked is
      changed-only, and the deliberate greenfield exit-1 behaviour change.
- [ ] 7. Land: one commit, `fix(atelier): ...`, 6 files. AWAITING CONFIRM. Push is a separate
      confirm.

Verification: `bash scripts/smoke-test.sh` runs 3 new checks, all ok. The run reports 1 FAILED,
`lint:strict (type-aware)`, which is PRE-EXISTING and unrelated: a clean `git worktree` of HEAD
(17a6e78, none of this change) fails identically. Cause is the deliberate unpinned-toolchain
canary firing: eslint-plugin-sonarjs 4.2.0 (2026-07-14) flags the fixture's own canonical
branded type (`sonarjs/no-useless-intersection` on `string & { readonly __brand }`) and
`sonarjs/null-dereference` in greeting.ts and fetch-greeting.test.ts. Separate task, listed as a
next step, NOT fixed here (out of scope). Also green: `bun run scripts/validate-frontmatter.ts`
(4/4), added-lines em-dash grep empty.

Named assumptions: a repo with no `origin/main` (greenfield pre-push) now exits 1 loudly instead
of silently passing, handled in docs not special-cased in the script; auto-refresh covers only
the `origin` remote.
