# PLAN: sonarjs 4.2.0 vs the branded-type doctrine (smoke-test lint:strict red)

`bash scripts/smoke-test.sh` failed `lint:strict` on a clean HEAD. Reproduced in an isolated
fixture at eslint-plugin-sonarjs 4.2.0, eslint 10.9.1, typescript-eslint 8.68.0, typescript 5.9.3.

Evidence gathered before deciding:
- The 3 errors appear ONLY under `LINT_STRICT=1`. The plain lint lane exits 0, so these are
  type-aware sonarjs rules that fire once `projectService` hands them a program.
- `sonarjs/no-useless-intersection` flags the PRIMITIVE side of every branded type: probe showed
  `string & { __brand }` flagged at the `string`, `number & { __brand }` flagged at the `number`,
  while an object-object intersection is clean. That is hard rule 12 (brand at trust boundaries),
  so it would fire in every conforming consumer repo, on every branded type.
- `sonarjs/null-dereference` flags `(v: string) => v.trim()` where `v` is non-nullable, AND
  `(v: string | undefined) => v === undefined ? 0 : v.trim()` where the narrowing makes it
  provably defined. No correct code satisfies it, and `strict: true` (tsconfig line 12, enforced
  by `bun run typecheck`) already owns the bug class.
- Option (c) was IMPOSSIBLE, not merely unattractive: sonarjs 4.1.0 does not load under eslint
  10.9.1 (`TypeError: Cannot read properties of undefined (reading 'FunctionType')` at
  S2201/rule.js). Holding sonarjs back would force pinning eslint and typescript-eslint too,
  exactly the "pin everything" the 2026-07-12 LESSONS entry rejects.
- Both rules already shipped in 4.0.3, so this is not a new-rule release; the trigger is the
  type-aware lane now reaching them.

Decision: option (a). Keep sonarjs current, disable the two rules in the canonical config with
dated reasons, next to the three sonarjs opt-outs already there.

- [x] 1. `references/bun-typescript.md`, eslint.config.js fence: both rules added to the sonarjs
      off-list, each with a dated reason naming the exact false positive.
- [x] 2. Same doc: the "three rules are turned off" bullet is now five, with the two new reasons
      and the note that pinning back is impossible.
- [x] 3. `scripts/smoke-test.sh`: informational re-probe behind `SMOKE_SONARJS_PROBE=1` using
      `eslint --rule` (verified to override flat config on eslint 10, so no env branch pollutes
      the shipped consumer config). Never touches FAILURES.
- [x] 4. `.github/workflows/canary.yml`: renamed to `toolchain-canary`, second continue-on-error
      job `sonarjs-rule-probe` runs the probe weekly. YAML parses, 2 jobs. No badge referenced the
      old workflow name.
- [x] 5. CLAUDE.md: the canary line now describes both probes, not just the typescript pin.
- [x] 6. LESSONS.md `[decision]` entry: the doctrine-vs-tool conflict, why (a) over (b) and (c),
      and the 4.1.0-does-not-load finding that killed (c).
- [x] 7. Verified: `bash scripts/smoke-test.sh` ends "smoke-test: all checks passed" (full run with
      the probe enabled). Separately confirmed in the standing repro that the patched config lints
      clean AND that the probe's forced-on run still reports all 3 errors, so the probe reports its
      still-broken branch today. `bun run scripts/validate-frontmatter.ts` 4/4. Added-lines em-dash
      grep empty.
- [ ] 8. Land: one commit, `fix(atelier): ...`, 5 files. AWAITING CONFIRM. Push a separate confirm.

Named assumption: disabling `null-dereference` loses nothing real, because the standard bans `any`
and mandates `strict: true`, so the typechecker owns this bug class; the rule only adds noise on
typed code. If that ever stops holding, the canary probe is where it resurfaces.
