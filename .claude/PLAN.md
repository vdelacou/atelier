# Plan: rule 15 is lint, no inline ignore survives (2026-09-08)

Goal: SKILL.md rule 15 says "no inline ignores, ever" and cites workflow.md, which describes a
discipline. Probed on the canonical Bun config: `/* eslint-disable */`, `// eslint-disable-next-line`,
`// @ts-expect-error: reason`, `// prettier-ignore`, `// NOSONAR`, `// Stryker disable next-line all`
and `/* c8 ignore next */` all pass `bun run lint`; only `@ts-ignore` is caught. A file-level disable
switches off every ban landed this morning. Decisions 2026-09-08 with the owner: TypeScript now, the
Java half (PMD XPath for `@SuppressWarnings`, `suppressMarker`, a hook grep for NOPMD and NOSONAR) is
the next slice; rule 5 (Bun only, no gate) is queued after it.

Definition of done: both canonical configs carry `linterOptions.noInlineConfig: true` (directives inert
and each one reported, so `--max-warnings=0` fails and the hidden violation surfaces),
`@typescript-eslint/ban-ts-comment` banning `@ts-expect-error`, `@ts-ignore` and `@ts-nocheck`, and core
`no-warning-comments` on the other tools' markers (`prettier-ignore`, `stryker disable`, `nosonar`,
`biome-ignore`, `oxlint-disable`, `c8 ignore`, `v8 ignore`, `istanbul ignore`, anywhere in a comment);
SKILL.md rule 15 and workflow.md name the mechanism; the Bun smoke test proves eight forms red on their
own messages and the Next smoke test three; matrices, citations and CHANGELOG updated; CI green on the
push. No SKILL.md description change; no tier 1 (no conformance task carries rule 15).

Facts (verified 2026-09-08 on the probe, eslint 10, typescript-eslint 8.68): the three additions make
all eight forms red with the intended message (the directive report reads "has no effect because you
have 'noInlineConfig'"), the seven conforming probe files stay green, and a plain TODO comment is
rejected by the existing `sonarjs/todo-tag`, not by the new terms. No plugin is needed. Cited lines that
shift: bun-typescript.md 127, 152, 217 (the block lands before them), nextjs-monorepo.md 329, 565, 644,
workflow.md 159 onward if the section gains lines; all re-anchored by snippet and locked.

1. [x] (fences verified on the probe, eight red and seven green; 14 shifted citations re-anchored and locked) `bun-typescript.md`: a `linterOptions` object after `securityPlugin.configs.recommended` and the
       two rules in the base `**/*.ts` block after the style bans, commented in the file's voice; a
       "Notes on the config" bullet. `nextjs-monorepo.md`: the same object after its security block and
       the two rules in the return-type block. `workflow.md`, Zero warnings; no inline ignores: a paragraph
       naming the three mechanisms and the markers list. DoD: extracted fences parse on the probe (eight
       red, seven green); frontmatter 4/4; citations re-anchored and locked; em-dash gate.
2. [x] (description byte-identical) SKILL.md rule 15 cites the lint (`noInlineConfig`, `ban-ts-comment`, `no-warning-comments`);
       review-me's "(15)" gains "lint since 2.3.0, a config without `noInlineConfig` is the finding";
       greenfield's prove-red step plants a disable directive. DoD: description byte-identical.
3. [x] (Bun 95 checks, Next 23 checks green 2026-09-08) `smoke-test.sh`: eight `ban_red` cases after the rule 13 ones (file disable with a class, next-line
       with console, ts-expect-error, ts-ignore, prettier-ignore, Stryker, NOSONAR, c8), tags from the
       messages; `smoke-test-next.sh`: next-line, ts-expect-error, prettier-ignore. DoD: both green locally.
4. [x] Matrices: forward row 15.3 kind stays gate, evidence adds the `linterOptions` line and the
       `ban-ts-comment` line, note "lint since 2026-09-08"; reverse row 15 note. Lock; drift green.
5. [x] (five slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Unreleased Added bullet (consumer: re-extract the config; expect reds on every
       suppression comment in the tree, each one a refactor or a project-level severity change); LESSONS
       `[decision]`; plan final. Commits on the yes: (a) `docs(references): no inline ignore survives
       the lint`, (b) `docs(skill): rule 15 cites its lint`, (c) `test(smoke): the inline-ignore forms
       prove red`, (d) `docs(matrix): the lint evidence for rule 15`, (e) `docs: changelog, lessons and
       plan for rule 15`. Push on its own yes.

Not in scope: the Java half (next slice); rule 5 (the slice after); `sonarjs/todo-tag` (already on).
