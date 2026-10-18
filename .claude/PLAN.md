# Plan: TypeScript 7 beside the 6.0 API, and Next.js 16.4.2 (2026-10-18)

The previous plan (the eval preflight) closed with PR #9 merged; what the rule 38 plan left still waits
on the owner: `check-host.py --apply` here and in panda-social-cli, and the delete of the remote
`main-f7v4vj`. The owner's change request of 2026-10-18 (an uploaded document, tested on a copy of main
at 6cc240e) asks for TypeScript 7 as the `tsc` binary while ESLint keeps every rule.

## The design

- TypeScript 7.0 has no JavaScript API: typescript-eslint 8.71.2 refuses it (peer range
  `>=4.8.4 <6.1.0`) and eslint-plugin-sonarjs 4.2.2 crashes in `ts-api-utils`. So both stacks install
  two aliases: `typescript` is `npm:@typescript/typescript6@^6.0.2` (the 6.0 API the lint plugins
  `require`, binary `tsc6`), and `@typescript/native` is `npm:typescript@^7.0.2` (binary `tsc`, which
  the `typecheck` script, the hooks and CI run). `check-package-json.sh` already permits an `npm:`
  alias with a caret range.
- Next.js: the template moves to `next` and `eslint-config-next` 16.4.2, and the tsconfig sets
  `"types": ["bun"]`, which TypeScript 6 and 7 need to find `bun:test` (TS2307 otherwise, in `tsc` and
  in `next build`). `next build` type-checks with `tsc6`.
- The weekly `unpinned-typescript` canary keeps `SMOKE_TS_SPEC=typescript`, which now installs
  TypeScript 7 as `typescript`: it stays red until typescript-eslint and sonarjs load TypeScript 7.1,
  and green then means the aliases can go.

## Steps and definition of done

1. [x] Bun stack: `bun-typescript.md` (the TypeScript bullet, the template, the load-bearing clause),
   `smoke-test.sh` (install line and comment), `oxlint-parity-probe.sh` (spec and comment),
   `canary.yml` (comment 1 and the last step). DoD: `bash scripts/smoke-test.sh` passes every check
   with `.bin/tsc` reporting TypeScript 7. Done: 154 of 154 under Bun 1.4.2. Under the container's
   Bun 1.3.14 it went red (32 checks): 1.3.14 resolves `@typescript/typescript6`'s own
   `@typescript/old` dependency to the wrapper, so `require('typescript')` is `{}`; 1.4.0 to 1.4.2
   resolve it right, and a 1.3-written `bun.lock` stays broken until its `@typescript/old` line goes.
   The Runtime line now asks for Bun 1.4.
2. [x] Next.js stack: `nextjs-monorepo.md` (template versions and aliases, tsconfig `types`, the two
   notes) and `smoke-test-next.sh` (the package.json it writes). DoD: `bash scripts/smoke-test-next.sh`
   passes every check. Done: 55 of 55 under Bun 1.4.2.
3. [x] The text that names the old pin: `CLAUDE.md`, `docs/upstream/sonarjs-ts7.md` (status note),
   a `.claude/LESSONS.md` entry and a CHANGELOG entry with an upgrade line. DoD: the fast gates green
   (frontmatter, em dash, citations re-anchored, matrix drift, workflow assets), no em dash added.
   Done: all green; nine citations moved by one or two lines and were re-anchored.
4. [x] The request's untested items that are cheap here: the Oxlint parity probe with the new spec,
   and the canary's run (`SMOKE_TS_SPEC=typescript`). DoD: the probe reads both gaps; the canary run
   goes red at typescript-eslint's refusal, the signal the job relies on. Done: the probe reads both
   gaps open on Oxlint 1.88.0; the canary run goes red at lint (32 checks), where sonarjs crashes in
   `ts-api-utils` before typescript-eslint's own refusal is reached.
5. [ ] Land on the owner's yes (given 2026-10-18: commit, push, PR, merge on green): four commits under
   gate 1, push, PR #12, CI green on Linux and Windows, rebase merge. Tier 1 skipped by the owner: the
   selector picked 4 tasks only through the Bun reference's rule-20 row and two version numbers read as
   canon ids (5.9, 7.1).

## Status

Steps 1-4 done 2026-10-18. Next: step 5. After it, the owner's second request: rule 26 blocks only in
a public repository and warns in a private one, declared by `.github/visibility` and checked in CI
against the host's own answer.
