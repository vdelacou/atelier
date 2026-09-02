# Plan: audit remediation (2026-09-02)

Source of truth for the full design: `~/.claude/plans/oky-make-a-plan-gentle-umbrella.md`
(context, decisions, per-slice files, fixtures, verify set). This file is the resume contract:
one line per slice, ticked as its DoD is met. Order A, F, B, C, D, E. Every slice is one
Conventional commit under 10 files / 300 lines; commit and push each need explicit confirmation.

Verify set: V1 `bash scripts/smoke-test.sh`; V2 `bash scripts/smoke-test-java.sh`;
V3 `python3 scripts/check-citations.py` (`--lock` first when a pinned line moved);
V4 `bash scripts/check-workflow-assets.sh`; V5 `python3 scripts/check-matrix-drift.py`;
V6 `bun run scripts/validate-frontmatter.ts`; V7 `bash scripts/check-no-em-dash.sh`.

## Phase A: gates

1. [x] fix(atelier): commit-message gate walks the pushed range on main. DoD: smoke fixture
       (origin/main == HEAD, GITHUB_EVENT_NAME=push, a `wip:` commit) seen red before, green
       after; same push default mirrored in check-commit-range.sh; V1 V2 V4 V3 green.
2. [x] fix(atelier): deadline tripwire sees globalThis.fetch and ignores comments. DoD:
       `globalThis.fetch(...) // timeout upstream` fixture red; conforming adapter green; V1 V2.
3. [x] fix(atelier): lifecycle tripwire exempts by path, catches DROP TABLE. DoD: four fixtures
       (comment-exempt red, path-exempt green, DROP TABLE red, contract migration green); V1 V2 V3.
4. [x] fix(atelier): pii tripwire reads a multi-line logger call and more names. DoD: two-line
       logger fixture red; V1 V2.
5. [x] fix(atelier): package.json gate scopes to the dependency blocks. DoD: publishConfig.tag
       fixture green, existing latest fixtures still red; V1 V3.
6. [x] fix(atelier): isolation tripwire wants a 404 inside a test naming the route. DoD: three
       fixtures (wrong test file red, 404 in comment red, 404 in a test block green); Java mirror;
       V1 V2.
7. [x] fix(atelier): the staleness gate runs in tree mode from the shipped workflow. DoD: tree
       fixture red/green in smoke test; `--selftest` in ci.yml; no /tmp path, no handle in the
       script; V1 V4 V3.
8. [x] docs(atelier): check-docs.sh names its trust boundary. DoD: comment lands; V1.
9. [x] feat: an em-dash gate for this repo, hook and CI. DoD: `scripts/check-no-em-dash.sh
       --selftest` green; hook runs it first; ci.yml job; CLAUDE.md points at it; V7 V6.

## Phase F: rule 35, cyclomatic complexity

31. [x] feat(atelier): cyclomatic complexity gate in both ESLint configs. DoD: planted 11-branch
        function red in smoke-test.sh and smoke-test-next.sh, conforming green.
32. [x] feat(atelier): PMD cyclomatic complexity gate for the Java variant. DoD: planted method
        of complexity 11 fails `./mvnw verify` in smoke-test-java.sh; asset named by the
        bootstrap; V2 V4.
33. [x] docs(atelier): hard rule 35 cascaded (SKILL.md, clean-code.md, review-me, greenfield,
        README, reverse-matrix row 35, matrix 1.2, CHANGELOG). DoD: V3 after `--lock`, V5, V6.

## Phase B: em-dash sweep (same-line replacements only)

10. [x] SKILL.md. DoD: V7 clean for the file; V3 after `--lock`; V6.
11. [x] workflow.md, testing.md. DoD: V7; V3 after `--lock`.
12. [x] nextjs-monorepo.md, atomic-design.md, behavioural-examples.md. DoD: V7; V3.
13. [x] bun-typescript.md, testing-infra.md, architecture.md, security.md, result-type.md,
        complexity.md. DoD: V7; V3 after `--lock`.
14. [x] remaining references, three companions, assets, README. DoD: V7 zero across skills/,
        README.md, .githooks/; V3 after `--lock`; V6; V1.

## Phase C: doctrine contradictions

15. [x] rule 12 governs the value-object section. DoD: SKILL.md:283-285, README:30,
        clean-code.md agree; V3 after `--lock`; V6.
16. [x] boundary factories return Result, constructors assert (parseX / x). Landed with 15 (same section); the a2+e5 eval pass runs at the end of Phase C. DoD: every listed
        site on the two-tier form; V3 after `--lock`; conformance eval a2 + e5 one pass.
17. [x] money is integer cents in every example. DoD: no `amount: number` Money left; V3.
18. [x] rule 14 names the value-object exception. DoD: SKILL.md:166, testing.md:25, tdd.md:207,
        review-eval baseline note; V3.
19. [x] dotted ids are canon ids, slice 1 (SKILL.md note + 5 refs). DoD: V3 V6.
20. [x] dotted ids, slice 2 (5 refs). DoD: V3.
21. [x] stale mentions: canary, CI count, README layout, Java assets, Email.Error. DoD: V2 V3.

## Phase D: SKILL.md restructure

22. [x] fold tdd.md sections into testing.md. DoD: testing.md holds the loop; V3.
23. [ ] remove tdd.md, repoint citers, redirect stub. DoD: V3 after `--lock`; V6; V1.
24. [ ] fold class-to-module.md into design-patterns.md, stub. DoD: V3 V6.
25. [ ] drop the remaining duplicated examples. DoD: V1 (fences intact); V3 after `--lock`.
26. [ ] absorb hard-rule bodies 4, 12, 17-20, 24-25 into references. DoD: V3 after `--lock`.
27. [ ] hard rules as one-liners, red flags and four elements out. DoD: nouns for 28-32 kept;
        V3 after `--lock`; V6.
28. [ ] interaction rewritten, guidelines compressed, companions cascaded. DoD: rules 24-25
        bullets present; V3 after `--lock`; V6.
29. [ ] trigger table, merged checklists, workflow. DoD: SKILL.md about 210 lines; V1 V2 V3 V5
        V6; h1-h7 with_skill 24/24; judge --ab old vs new (3 generations); trigger-eval
        atelier-bun once.

## Phase E: canon (each row needs a ruling)

30. [ ] draft P6 rows C1-C6 in proposed-revisions.md (status proposed). DoD: V5 unchanged.
31+. [ ] apply each ACCEPTED row: dos-and-donts (+ prose), matrix sha re-pin, lock if needed.
        DoD per row: V5 then V3.

## Wrap

- [ ] propose LESSONS entries; update this file to final state.
