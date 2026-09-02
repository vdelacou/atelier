# CLAUDE.md

This repo IS the atelier coding standard, packaged as an Agent Skill suite. It is not a
Bun/Java application, so the hard rules 1-34 are the *product*, not constraints on this
tree. What binds work HERE is the authoring and process discipline below.

## Authoring conventions
- **Never use em dashes** in anything you write: prose, code comments, commit messages,
  skill text, LESSONS/PLAN entries. The reference files predate this rule; do not imitate
  their punctuation. The gate is `bash scripts/check-no-em-dash.sh`: the pre-commit hook runs
  it on the staged diff, CI over the pushed range, and `--selftest` proves it can fail.
- **YAML frontmatter descriptions carry no `: ` (colon-space)** and no unescaped `:` mid-line;
  it breaks the single-line YAML parse. Rephrase (a comma, a dash with spaces, parentheses).
  The frontmatter validator catches it: `bun run scripts/validate-frontmatter.ts`.
- **Skill descriptions max 1024 chars** (the loader limit; the validator enforces it). The
  main `atelier` description runs near the ceiling, so trimming is needed to add anything.
- Terse, direct prose; lead with the outcome; match the surrounding file's idiom.

## Structure
- `skills/atelier/` is the main skill: `SKILL.md` (hard rules + workflow) plus `references/`
  (the doctrine, one file per concern) and `assets/` (copyable gate scripts + Java exemplars).
- `skills/atelier-{greenfield,review-me,grill-me}/` are the companion skills.
- `scripts/` holds the CI harnesses: three `smoke-test*.sh` (Bun/Next/Java, each proving the
  gates pass AND block their target violation), `trigger-eval/` (does the skill load; suite
  mode measures which skill wins a query), `conformance-eval/` (does produced code follow the
  rules, with-skill vs baseline), `review-eval/` (does atelier-review-me catch planted
  violations in a diff, recall + rule-citation + false-positives vs a skill-less reviewer).

## Verify commands
- `bun run scripts/validate-frontmatter.ts` (fast; the CI frontmatter gate).
- `python3 scripts/check-citations.py` (fast; file-line evidence vs citations-lock.json; after
  a deliberate re-anchor, `--lock`) and `bash scripts/check-workflow-assets.sh` (shipped CI
  workflows self-sufficient); both take `--selftest`.
- `bash scripts/smoke-test.sh` / `smoke-test-next.sh` / `smoke-test-java.sh` (the CI e2e gates;
  Java needs JDK 21+ and mvn; each takes minutes on first run for dependency downloads).
- `bash scripts/trigger-eval/run.sh <set> <skill-dir> [fixture] [runs]` after any SKILL.md
  description edit (a description is a triggering contract).
- `python3 scripts/review-eval/grade.py --selftest` (fast; the CI review-grader gate). The full
  eval: `bash scripts/review-eval/run.sh`, then grade the printed runs dir.
- `python3 scripts/conformance-eval/judge.py --selftest` (fast; the CI judge-harness gate).
  The judging itself is local and paired: `JUDGE_MODEL=claude-opus-5 python3
  scripts/conformance-eval/judge.py <runs-dir>` over run dirs the conformance eval produced.
- CI (`.github/workflows/ci.yml`) runs eight jobs on every push (frontmatter, the em-dash gate,
  the three smoke tests, the two grader selftests, matrix drift with the citation, workflow-asset
  and staleness selftests); `canary.yml` weekly-probes
  the two deliberate toolchain concessions (whether the typescript pin can lift, and whether the
  two disabled sonarjs rules can go back on).

## Process
- **Plan-first**: before multi-step work, write the plan and a per-step definition of done to
  `.claude/PLAN.md`; keep it live; overwrite it when the next task begins. It is the resume
  contract, distinct from the append-only `.claude/LESSONS.md`.
- **Commit slicing**: small, coherent commits (the standard's own gate 1 spirit: <=10 files /
  <=300 lines), Conventional Commits, references before the SKILL.md that cites them.
- **Never commit or push without explicit confirmation** (rules 25). Commit and push are
  separate decisions; ask per landing. Eval results stay gitignored (`skills/*-workspace/`);
  harnesses and sets are committed.
- **Main-skill doctrine changes cascade to companions**: when `skills/atelier/SKILL.md` gains
  or changes doctrine (a rule summary, a gate, a workflow step), sweep atelier-greenfield,
  atelier-review-me, and atelier-grill-me for stale echoes in the same change; the 2026-08-30
  audit found every companion gap was a missed cascade.
- **Every new gate proves it can fail**: ship a fixture violation case alongside it, and wire
  it into the matching smoke test so a toolchain major cannot silently disable it.
- **Read `.claude/LESSONS.md` at session start**: it holds the toolchain gotchas (TypeScript 7
  vs sonarjs, PIT history, the eval-harness pitfalls) that cost real time to find.
