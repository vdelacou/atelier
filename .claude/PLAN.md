# Plan: the style bans and the layer zones become lint (2026-09-08)

Goal: close the gap found on 2026-09-08. SKILL.md line 10 says the hard rules "are enforced by
ESLint and by the review bar", yet in the canonical Bun config a `class`, a custom error class, an
inline `type` import, a `try/catch` in `src/use-cases/**`, a curried arrow chain, `node:fs` in the
domain and a domain file importing infra all pass `bun run lint` (probe on eslint 10, typescript-eslint
8.68, sonarjs 4.2; only `require` and complexity 11 fail, as claimed). Same shape as rule 36: prose plus
habit, no gate. Canon 1.1 and 15.1 say the style is machine-enforced and the reverse matrix files rules
1, 7, 18, 20 as stack bindings whose enforcement is the profile's job. Decisions taken 2026-09-08 with
the owner: all seven bans in one closure; the dependency rule becomes hard rule 37 (canon 3.1 already
exists, no canon change); TypeScript now, the Java layer gate (ArchUnit) is the follow-up slice.

Definition of done (whole task): both canonical configs (`bun-typescript.md` and `nextjs-monorepo.md`)
carry the bans; SKILL.md has rule 37 and rules 1, 7, 10, 17, 18, 20 cite their lint rule the way 2, 3, 6,
13 and 35 do; every ban has a red fixture in the Bun smoke test (Next: the three universal bans) and the
doctrine's exemptions stay green there; the reverse matrix has row 37 and the forward row 3.1 reads
"gate"; tier 1 shows no miss on a rule the diff touched; CHANGELOG Unreleased names the consumer action;
CI nine jobs green on the push. No SKILL.md description edit (no trigger eval owed, no tier 2).

Facts (verified 2026-09-08):
- Probe tree: `scratchpad/lint-gap-probe` (session scratchpad). Its `eslint.config.js` spreads the
  extracted canonical config and adds the draft blocks; nine violations red with their rule number in
  the message, seven conforming files green, among them the DI factory `createLoader = (deps) =>
  async (id) =>`, an infra `try`, the commented infra `mkdirSync` helper, `node:fs` in a `*.test.ts`,
  and composition wiring that imports infra and use-cases.
- Draft selectors (`no-restricted-syntax`): `ClassDeclaration`, `ClassExpression` (rule 1, covers 10);
  `ImportSpecifier[importKind="type"]` (rule 7; `consistent-type-imports` alone accepts the inline
  form, verified); `VariableDeclarator[id.name!=/^create[A-Z]/] > ArrowFunctionExpression >
  ArrowFunctionExpression.body` (rule 18, the DI factory exempt by name); `TryStatement` scoped to
  `src/use-cases/**` minus tests (rule 17: domain fallback, infra and `main.ts` stay review-checked);
  `ImportDeclaration[source.value=/^(node:)?fs(\/promises)?$/]` over `src/**` minus `*.test.ts`,
  `src/test-helpers/**`, `src/infra/**` (rule 20's carve-outs are path conventions). Layer zones:
  six-pack-live's `layerZone` (`no-restricted-imports` patterns per layer, the mock ban repeated).
- The trap: ESLint replaces a rule's options per matching block, never merges, so every scoped
  `no-restricted-syntax` block spreads the shared `STYLE_BANS` list and every zone repeats `MOCK_BAN`
  (the live repo learned this with rule 13; the Next config already documents it for rule 13).
- The Bun smoke fixture itself violates rule 7 (`smoke-test.sh:127`, `import { err, ok, type Result }`)
  and its adapter is the sanctioned `createFetchGreeting` factory; `format-error.ts` (shipped, copied
  into `src/domain/utilities/`) carries a domain `try`, outside the use-cases scope. No shipped `.ts`
  asset declares a class or a curried chain (`check-coverage.ts:119` is an arrow returning a ternary).
- Next runs on the Node runtime in production, so rule 20 (`Bun.file`) does not bind there: no FS ban in
  `eslint.config.mjs`. The static layout has no `src/use-cases`, so its `TryStatement` block is inert
  until the server archetype adds one; the layer zones for that archetype are a follow-up, not this slice.
  Its base block currently sets `'no-restricted-syntax': ['off', 'ForOfStatement']`; the two scoped
  blocks (rule 21 hooks/'use client', rule 22 className) each own a list and must spread the bans.
- Echoes of the count: `assets/claude-md-pointer.md` "1-36", `README.md:17` "36 hard rules", SKILL.md
  Red flags "(1-35)" (already one behind), the "What applies where" table (rows 35 and 36 are the shape),
  `atelier-review-me/SKILL.md:40` (lists 1-4, 6, 18, 15, 35, 26 as the universal checks),
  `atelier-greenfield/SKILL.md:42` (prove green then red).
- Citations: `conformance-matrix.md` and `reverse-matrix.md` cite `file:line`; `check-citations.py`
  fails on a shift and `--lock` re-pins after a deliberate re-anchor. Forward row 3.1 cites
  `architecture.md:96; SKILL.md:91`, kind "rule". Row 1.1 cites `workflow.md:55` and gate 5.
- Tier 1: `CONFORMANCE_SINCE=8223cf8` (main before this work). The tasks whose assertions the diff can
  touch are a1, a3, h2 (10.2 and 3.2, the Result and port rules); the style bans carry no assertion, so
  the selection may be small. `CONFORMANCE_TAG=lint-gates` so the run gets its own directory.

1. [x] (verified on the probe 2026-09-08, nine red, seven green) `bun-typescript.md`: the `eslint.config.js` fence gains `MOCK_BAN`, `STYLE_BANS`, `TRY_BAN`,
       `FS_BAN` and `layerZone` as consts above `export default`, the base `**/*.ts` block uses
       `'no-restricted-syntax': ['error', ...STYLE_BANS]` and `paths: [MOCK_BAN]`, then the use-cases block
       (`STYLE_BANS, TRY_BAN, FS_BAN`), the `src/**` FS block (ignores tests, test-helpers, infra,
       use-cases), and the seven zones (domain, use-cases, presenter, infra, composition, test-helpers,
       `main.ts`), each commented in the file's voice (rule number, reference, the replace-not-merge
       trap once). After the fence, a short "Style bans and layer zones" paragraph. The File IO section
       (rule 20) names the lint and its path carve-outs. `result-type.md` quarantine section: one
       sentence, the use-cases scope is lint, the rest is review. `clean-code.md` rule 18: the selector
       and the `create[A-Z]` name exemption. `architecture.md` dependency rule: the zones are the rule as
       lint (rule 37); the grep stays as the adopt-mode audit line. DoD: `extract_fence` of the fence is
       valid (copy into the probe, `bunx eslint` reproduces nine red, seven green); frontmatter 4/4;
       `check-citations.py` shows only line shifts, then `--lock`; em-dash gate; diff within gate 1.
2. [x] (fence parses; the one shifted citation, matrix row 17.6 to nextjs-monorepo.md, re-anchored and locked) `nextjs-monorepo.md`: `STYLE_BANS` and `TRY_BAN` consts, the base block turns
       `no-restricted-syntax` on with `...STYLE_BANS`, the rule 21 and rule 22 blocks spread it before
       their own selectors, a `src/use-cases/**` block for `TRY_BAN`; the mock-ban comment gains the
       same note for `no-restricted-syntax`. DoD: frontmatter; citations; the Next smoke test's extracted
       config lints its fixture green (step 5 proves it).
3. [x] (description byte-identical, SKILL.md 199 lines, four shifted citations re-anchored and locked) SKILL.md and the cascade. Rules 1, 7, 10, 17, 18, 20 each gain a parenthetical naming the lint
       (`no-restricted-syntax` selector or block, a few words); rule 37 after 36: "Dependencies point
       inward, lint-enforced per layer." with the dependency table's substance in two sentences and the
       `references/architecture.md` cite; a "Rule 37 arrived 2026-09" note only if the 35 note's shape
       needs it (it does not: 36 has none). "What applies where" gains two rows: style bans (Bun
       `eslint.config.js` blocks, Next `eslint.config.mjs`, Java n/a: rules 1-3, 7, 18, 20 are TypeScript
       bindings, 17's Java translation stays review) and layer zones (Bun zones, Next follow-up, Java
       ArchUnit follow-up). Red flags "(1-35)" becomes "(1-37)". Reference table: `architecture.md` row
       adds "rule 37". Companions: review-me step 3 says which of its universal checks are now lint in the
       TypeScript variants (so a config missing the block is the finding) and adds 37; greenfield step 8
       adds one red proof ("a `class` in `src/domain` fails `bun run lint`"); grill-me swept, likely no
       echo. `assets/claude-md-pointer.md` and `README.md:17` count 37. DoD: SKILL.md description
       byte-identical (`git diff` shows no change in lines 1-4); frontmatter 4/4; `grep -rn "1-36"` returns
       CHANGELOG and .claude only; citations re-anchored; em-dash gate; SKILL.md stays under 200 lines.
4. [x] (171 citations locked, drift green, 120 rows) Matrices. `reverse-matrix.md`: row 37 (CANON-ROW, 3.1, "Added 2026-09-08: the dependency table as
       ESLint zones per layer, the mock ban repeated in each"), rows 1, 7, 18, 20 notes gain "lint since
       2026-09-08", header "1-35" becomes "1-37" where it counts rows. `conformance-matrix.md`: row 3.1
       evidence adds the `bun-typescript.md` zone lines and the SKILL.md rule 37 line, kind "gate"; row
       1.1 note mentions the style bans. DoD: `python3 scripts/check-matrix-drift.py` green (120 rows,
       pins intact: no canon edit); `python3 scripts/check-citations.py --lock` then a clean verify.
5. [x] (Bun 85 checks, Next 18 checks green 2026-09-08; first Bun run red on a prettier warning in the DI-factory fixture, reformatted) Gates prove red. `smoke-test.sh`: fix the fixture's inline type import first (a real rule 7 hit the
       new gate would otherwise turn into a false fixture failure), then after the rule 35 block one
       negative path per ban, each a one-file write, `expect_err "... (rule N)" bun run lint`, `rm`:
       `class` in `src/domain`, `import { type X }`, `try` in `src/use-cases/`, a curried export in
       `src/domain`, `node:fs` in `src/domain`, `src/domain` importing `../infra/fetch-greeting.ts`
       (rule 37), plus `expect_ok` for a `createX` factory in `src/use-cases/` and `node:fs` in a
       `*.test.ts` (the exemptions, so a tightened selector cannot pass silently). `smoke-test-next.sh`:
       `class`, curried and inline type import in `src/lib`, `expect_err` each. DoD: `bash
       scripts/smoke-test.sh` and `bash scripts/smoke-test-next.sh` green locally (minutes each; never
       edit scripts/ or skills/ while one runs); the Java smoke test untouched.
6. [x] (h2 3/3, a1 2/2, a3 3/3, 8/8 vs frozen 4.0/8, no capped or dead session; the CONFORMANCE_SINCE dry run over-selected 21 of 21: the Red flags line now reads "(1-37)" and select-tasks.py reads a range as every rule in it; killed after 35 s, partial runs dir removed, rerun with explicit ids h2-trap-catch a1-usecase-port a3-http-adapter, the only task whose hard_rules the diff touched being h2 for rule 17) Tier 1: `CONFORMANCE_SINCE=8223cf8 CONFORMANCE_MODEL=claude-opus-5 CONFORMANCE_TAG=lint-gates
       bash scripts/conformance-eval/run.sh` detached (nohup, no setsid, a Monitor on the log), graded
       `python3 scripts/conformance-eval/grade.py <runs-dir> --frozen-baseline`. DoD: no miss on a rule
       the diff touched; a miss elsewhere rerun twice before it is called anything; tasks.json unchanged,
       no re-freeze.
7. [x] (six slices committed 2026-09-08 on the owner's yes, push on its own yes the same day) CHANGELOG Unreleased (2.3.0): Added, hard rule 37 and the seven bans as lint, consumer action
       (re-extract `eslint.config.js` / `eslint.config.mjs`, expect reds on inline type imports and hidden
       classes, re-copy the pointer block for 1-37). LESSONS `[decision]` (the gap, the probe, the
       replace-not-merge trap, the fixture that violated rule 7 for months). This plan's final state; the
       previous plan's step 7 flip rides along. Commits, each waiting for the yes, gate-1 sized:
       (a) `docs(references): the style bans and layer zones as lint`, (b) `docs(references): the Next
       config carries the style bans`, (c) `docs(skill): rule 37 and the lint citations` with companions,
       pointer block and README, (d) `docs(matrix): row 37 and the re-anchored citations`, (e) `test(smoke):
       the seven bans prove red`, (f) `docs: changelog, lessons and plan for rule 37`. Push once after (f),
       waiting for its own yes; CI nine jobs green.

Not in scope: the Java layer gate (ArchUnit test in the skeleton plus its smoke fixture, the next slice);
Next server-archetype zones; any SKILL.md description edit; lint for `main.ts` "exactly one catch" or the
domain fallback (review-checked, stated in the rule text); rule 5 (Bun only) and the size caps.
