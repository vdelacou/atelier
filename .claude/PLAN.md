# Plan: sonarjs/function-return-type vs the Result helpers (2026-09-05)

Goal: a consumer that returns through `ok()`/`err()` (the idiom `references/result-type.md`
teaches) passes `lint:strict` on the canonical Bun config, and the skill repo's own gates prove
it: green with the rule off, red under the canary probe, so the rule cannot come back unnoticed.

Definition of done (whole task): `bash scripts/smoke-test.sh` green with a helper-returning
function in the fixture; `SMOKE_SONARJS_PROBE=1 bash scripts/smoke-test.sh` reports the rule
as still firing (the probe's own red); `check-citations.py`, the em-dash gate, and frontmatter
green; CHANGELOG Unreleased carries the fix; nothing in SKILL.md changes.

Facts (verified 2026-09-05): the rule fires on `return ok(x)` / `return err(e)` because the
helpers are typed `Result<T, never>` and `Result<never, E>` (result-type.md:16-17); the smoke
fixture's `createFetchGreeting` (smoke-test.sh:148) returns object literals under one union
annotation, which the rule accepts, so the existing gate is green by accident. The Next config
carries no sonarjs block, so only the Bun variant changes. Reproduction on any consumer tree:
`LINT_STRICT=1 bunx eslint --rule 'sonarjs/function-return-type: error' --max-warnings=0 src`.

1. [x] Prove red first. The fixture has no `result.ts` (its `GreetingResult` union is declared
       inline, smoke-test.sh:145), so add `src/domain/result.ts` with the `Result` type and the
       `ok`/`err` helpers exactly as result-type.md:16-17 writes them, then one domain function
       that returns through them (one guard returning `err`, one success returning `ok`) with
       its test in the mutation scope; run the smoke test once WITHOUT the config change. DoD:
       `lint:strict` fails on exactly that function with `sonarjs/function-return-type`, the
       coverage and mutation gates still pass (the new function is fully asserted), and the
       failure line is pasted into the commit body.
2. [x] The canonical config. In `references/bun-typescript.md`, the SonarJS override block
       (around line 227, after `null-dereference`): `'sonarjs/function-return-type': 'off'` with
       a dated comment in the 2026-08-29 shape (what fires, why no correct code satisfies it
       under hard rule 16, what already owns the bug class: `strict: true` plus rule 6's explicit
       return types, and that the canary re-probes it). DoD: `extract_fence` still finds the
       fence; `bash scripts/smoke-test.sh` green; the fixture from step 1 lints clean.
3. [x] The canary probe. Add the rule to the `--rule` JSON the `SMOKE_SONARJS_PROBE=1` branch
       passes (smoke-test.sh:221) and to the comment above it; update the `PROBE:` wording if it
       names "both" rules. DoD: `SMOKE_SONARJS_PROBE=1 bash scripts/smoke-test.sh` prints the
       probe verdict naming three rules, and the step-1 function is among the reported hits.
4. [x] `canary.yml`: the job comment says "both disabled rules"; make it "the disabled rules"
       and name three. DoD: the workflow parses (`ruby -ryaml` or `python3 -c yaml`).
5. [x] The doctrine text that points at the block: `references/workflow.md` (Zero warnings /
       project-level disabling) and LESSONS 2026-08-29 name two rules re-probed weekly; add the
       third where a sentence counts them, and append a LESSONS `[decision]` (do not edit the
       old entry). DoD: `grep -rn 'two disabled\|both disabled' skills scripts .github
       CLAUDE.md README.md` returns nothing stale. CLAUDE.md and README.md both say "the two
       disabled sonarjs rules" for the canary: update both.
6. [x] Citations. `citations-lock.json` cites nothing in bun-typescript.md (checked), so the
       inserted lines shift no pinned line; still run `python3 scripts/check-citations.py`. DoD:
       160 citations intact, no `--lock` needed.
7. [x] (selected 7 of 21, mechanically: workflow.md maps to rules 19-26 and the config comment names rules 6 and 16; skill arm 19/19 vs frozen baseline 12.5/19, runs-claude-opus-5 of 2026-09-05) Conformance tier 1 dry run: `python3 scripts/conformance-eval/select-tasks.py --since
       main`. DoD: if it selects tasks, run the skill arm (`CONFORMANCE_SINCE=main
       CONFORMANCE_MODEL=claude-opus-5 bash scripts/conformance-eval/run.sh`) and grade against
       the frozen baseline; if it selects none (a config comment and a fixture change carry no
       doctrine), record that in the commit body and skip.
8. [x] CHANGELOG Unreleased, Fixed: one entry naming the rule, the trigger (helper returns), why
       the smoke test missed it, and the consumer action (re-extract `eslint.config.js`).
9. [ ] Commits, gate-1 sized, references before the text that cites them: (a) `test(smoke): a
       helper-returning function in the fixture` (red, step 1), (b) `fix(bun-typescript):
       sonarjs/function-return-type off, re-probed by the canary` (steps 2-4), (c) `docs: the
       third re-probed rule` (steps 5, 6, 8). Each proposed, each waits for the yes (rule 25).

Not in scope: the consumer project `~/Documents/CODE/six-pack-live` already carries the rule
off (the cleaner's ecf1517); a re-extract there is the owner's call. The Java variant has no
SonarJS. The pack's role prompts change nothing; the standard changes, and the swarm reads it.
