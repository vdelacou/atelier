# CLAUDE.md

This repo IS the atelier coding standard, packaged as an Agent Skill suite. It is not a
Bun/Java application, so the hard rules 1-37 are the *product*, not constraints on this
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
- `skills/atelier-{greenfield,review-me,grill-me,distill}/` are the companion skills.
- `scripts/` holds the CI harnesses: three `smoke-test*.sh` (Bun/Next/Java, each proving the
  gates pass AND block their target violation), `trigger-eval/` (does the skill load; suite
  mode measures which skill wins a query), `conformance-eval/` (does produced code follow the
  rules, with-skill vs baseline), `review-eval/` (does atelier-review-me catch planted
  violations in a diff, recall + rule-citation + false-positives vs a skill-less reviewer).

## Verify commands
- `bun run scripts/validate-frontmatter.ts` (fast; the CI frontmatter gate).
- `python3 scripts/check-citations.py` (fast; file-line evidence vs citations-lock.json; after an
  edit shifts cited lines, `--reanchor` moves every pinned citation, both ends of a range, to the line
  that now holds its snippet and re-locks, refusing an ambiguous or vanished one; `--lock` alone only
  when the pinned content itself changed on purpose) and `bash scripts/check-workflow-assets.sh`
  (shipped CI workflows parse and are self-sufficient); both take `--selftest`.
- `bash scripts/smoke-test.sh` / `smoke-test-next.sh` / `smoke-test-java.sh` (the CI e2e gates;
  Java needs JDK 21+ and mvn; each takes minutes on first run for dependency downloads).
- `bash scripts/trigger-eval/run.sh <set> <skill-dir> [fixture] [runs]` after any SKILL.md
  description edit (a description is a triggering contract).
- `python3 scripts/review-eval/grade.py --selftest` (fast; the CI review-grader gate). The full
  eval: `bash scripts/review-eval/run.sh`, then grade the printed runs dir.
- `python3 scripts/conformance-eval/select-tasks.py --selftest` (fast; the CI gate for the tier-1
  selection). Three tiers (baseline.md, Tiers): tier 0 is the CI selftests; tier 1 after any doctrine
  edit is `CONFORMANCE_SINCE=<ref> CONFORMANCE_MODEL=claude-opus-5 bash scripts/conformance-eval/run.sh`
  (only the tasks the skill diff can affect, skill arm, then `grade.py <runs-dir> --frozen-baseline`);
  tier 2, the full matrix with `CONFORMANCE_ARMS=both`, only on a description change or before a
  release. Sessions are capped (`CONFORMANCE_TIMEOUT_MIN`, default 40; `CONFORMANCE_MAX_TURNS`,
  default 120) and each run dir keeps the session's stream-json transcript (`.transcript.jsonl`);
  the scorecard prints `turns=N` per session and flags a turn cap.
- Grade against the frozen baseline arm: `python3 scripts/conformance-eval/grade.py <runs-dir>
  --frozen-baseline`. The fixture (`baseline-arm.json`) is keyed to the prompts and assertions; after
  a tasks.json change, `CONFORMANCE_ARMS=baseline bash scripts/conformance-eval/run.sh` then
  `python3 scripts/conformance-eval/freeze-baseline.py <runs-dir> --model <model>`.
- `python3 scripts/conformance-eval/judge.py --selftest` (fast; the CI judge-harness gate).
  The judging itself is local and paired: `JUDGE_MODEL=claude-opus-5 python3
  scripts/conformance-eval/judge.py <runs-dir>` over run dirs the conformance eval produced.
- CI (`.github/workflows/ci.yml`) runs eight jobs on every push (frontmatter, the em-dash and
  identity gates, the three smoke tests, the two grader selftests, matrix drift with the citation,
  workflow-asset and staleness selftests); `canary.yml` weekly-probes
  the two deliberate toolchain concessions (whether the typescript pin can lift, and whether the
  three disabled sonarjs rules can go back on).

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
  atelier-review-me, atelier-grill-me, and atelier-distill for stale echoes in the same change; the 2026-08-30
  audit found every companion gap was a missed cascade.
- **Every new gate proves it can fail**: ship a fixture violation case alongside it, and wire
  it into the matching smoke test so a toolchain major cannot silently disable it.
- **Read `.claude/LESSONS.md` at session start**: it holds the eval-harness, trigger-eval and
  toolchain lessons that cost real time to find (the gate-writing ones live in the next section);
  `.claude/lessons.archive.md` holds the history the compaction pass retired (grep it, never read
  it at session start).

## Writing a gate
A rule that is only a table row and a habit is not a rule; the gate that fails is what makes it
one. The method of every gap closed since 2026-09-06, and the proofs that were green for the wrong
reason:
- **Probe before doctrine.** Take the enforcement claim (the SKILL.md table of what applies where,
  a rule's "lint-enforced", a reference's "the check is") and run it on the real toolchain in a
  scratch tree, one violation per rule, the smoke fixture trees included (their one-word git names
  shaped rule 26's gate). A tool's rule with the right name can fire on nothing (PMD's
  `AvoidPrintStackTrace`), ArchUnit fails an empty layer unless `withOptionalLayers(true)`, and for
  toolchain behaviour the smoke test outranks the docs.
- **The closure**: a canon sub-concept if missing, a hard rule if missing, the gate in its family's
  shape (staged lines in the hook, `--all` in CI, copied by every variant's checklist, which
  `check-workflow-assets.sh` enforces), a red fixture per variant proven through the hook, then
  tier 1. A gate that is inert where its concern is absent is on by default; opt-in needs the
  doctrine to say who opts out and why.
- **A red fixture proves the gate only when** it greps the rule's own tag (a formatting slip also
  exits non-zero), plants the route real code takes (the transitive `quarkus-junit5-mockito`, not
  only `mockito-core`), uses the idiom the reference teaches (returns through `ok()`, not
  literals), lives inside every later block that replaces the rule's options (ESLint keeps only the
  last matching block's), and cleans up exactly what it created. Walk the old gates through each
  new red-fixture helper: the mock ban had never been seen red.
- **Logic traps**: an empty string equals nothing (a blank pin passed); a grepped token appears in
  prose about the rule (`-SNAPSHOT` in the enforcer's own message); human-readable output carries
  defaults on failure (key on the exit status, not openssl's `Protocol` line); a `git diff` scope
  ignores untracked files, and `|| true` after a failing first command turns an error into a pass;
  a check that reads a sample must name it; a leak has more than one constructor
  (`new URLSearchParams({ email })`); a ban on a tool's own suppression cannot live in that tool
  (`@SuppressWarnings("PMD")` silences the PMD rule that flags it, hence `check-no-suppressions.sh`).
