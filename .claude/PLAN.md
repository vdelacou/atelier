# Plan: rule 37 layer zones in the Next variant (2026-09-09)

Goal: SKILL.md's matrix row for rule 37 says the Next variant is a "follow-up for the server
archetype", so a Next package built from the canonical `eslint.config.mjs` has no lint on its
dependency direction: an atom may import an organism, a domain file may import infra. Give the Next
config the zones the Bun config has, in the two shapes the variant needs.

Definition of done: `references/nextjs-monorepo.md`'s `eslint.config.mjs` carries a `layerZone` helper
and zones for `src/components/atoms` (never molecules, organisms), `src/components/molecules` (never
organisms) and the server archetype's `src/{domain,use-cases,infra,presenter,composition,test-helpers}`
as in Bun, each zone spreading the mock ban and, for the design-system zones, the rule-21 bans (a zone
replaces the design-system block's `no-restricted-imports` for its files); the Next smoke test proves
three fixtures red with "hard rule 37" in the message (atom importing a molecule, molecule importing an
organism, domain importing infra), seen red BEFORE the config change and green after, with the existing
rule-21 and rule-13 atom fixtures proving the copies survived; SKILL.md rule 37 and the matrix row name
the Next zones; `conformance-matrix.md` row 3.1 cites the Next config line; citations re-anchored and
locked; CHANGELOG Unreleased bullet; LESSONS decision; tier 1 dry-run, run if it selects; commit on the yes.

1. [x] (14:46 run: exactly three FAILs, each "expected non-zero exit", exit 1) Smoke fixtures (three
       `ban_red` cases) and the red run with the unchanged config.
2. [x] (patched 14:48, fence parses, eight zones; green run 14:48 to 14:51, all 34 checks passed, the
       three new ones and the rule-21 and rule-13 atom fixtures included) The config: `MOCK_BAN`, `DESIGN_SYSTEM_BANS` hoisted, `layerZone(layer, forbidden, extraPatterns)`,
       the zones after the rule-21 block; the green run, every check green, three new passes.
3. [x] (SKILL.md 79 and 130 in place; matrix 3.1 cites nextjs-monorepo.md:234; reanchor moved three,
       lock 234; drift, frontmatter, workflow-asset gates green) Doctrine and evidence: SKILL.md rule 37 tail and the matrix row (in place, one line each), the note
       after the Next fence, matrix row 3.1, `check-citations.py --reanchor` then `--lock`, drift gate.
4. [x] (CHANGELOG and LESSONS written; committed and pushed on the yes; tier 1 selected a3-http-adapter and h1-trap-mock from rules 13,
       21, 37: skill 6/6 against the frozen 4.0/6, none capped, 14:51 to 14:58)
       CHANGELOG, LESSONS, tier 1 dry run (`select-tasks.py --since HEAD`), run if it selects. Commit
       `feat(next): rule 37 layer zones in eslint.config.mjs` on the yes.
