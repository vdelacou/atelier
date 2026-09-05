# Plan: the six-pack, first live run (2026-09-05)

Goal: prove the pack end to end on a real swarm and fold what it taught back into the pack.

1. [x] Prerequisites: tmux and Babashka via Homebrew, the four skills linked into `~/.claude/skills`.
2. [x] Scratch project `~/Documents/CODE/six-pack-live`, pack installed, seeds committed, `./swarm`.
3. [x] One card (invoice totals CLI) through the six roles; the spec approved in Attention; Done at 01:41.
4. [x] Independent verification on the merged main: 88 tests, lint, lint:strict, typecheck, coverage,
       mutation 100, the tool run by hand. Swarm torn down; project and worktrees kept.
5. [x] Folded back: first-start prompts in the pack README, the audit-gate hint in every role prompt,
       `lint:strict` in the pre-handoff loop, the numbers in both READMEs and the CHANGELOG, two LESSONS.
6. [x] Two commits on the owner's yes, main fast-forwarded, pushed.

Open for the standard, not the pack: `sonarjs/function-return-type` fires on `ok()`/`err()` returns
under `lint:strict`; the canonical config and the smoke fixture need the 2026-08-29 treatment.
