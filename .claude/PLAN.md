# Plan: atelier six-pack (2026-09-04)

Goal: a SwarmForge pack on branch `atelier-six-packs`: six Claude Code roles that run the
atelier standard from card to verdict, installable into a project the way
`get-swarm-forge six-pack` is (this branch as the pack, swarm-forge `main` as the runtime).

Definition of done (whole task): `get-swarm-forge six-pack` composes this branch (via
`SWARMFORGE_PACKS_DIR`) into a scratch project with no missing-file error; the installer
runs end to end into a scratch project with a scratch HOME; `scripts/check-six-pack.sh`
passes and its `--selftest` proves each rule can fail; the em-dash and frontmatter gates
pass; the root README names the pack.

1. [x] Branch from main; ignore the runtime dirs. DoD: `git branch --show-current` prints it.
2. [x] Pack files: `swarm`, `swarmforge/swarmforge.conf`, `constitution.prompt`, three local
       articles. DoD: the conf parses under the launcher's rules (one master, known agent,
       unique roles without underscores, receive and propagation tokens, a prompt per role).
3. [x] Six role prompts: specifier (grill-me), coder (atelier + greenfield), cleaner,
       architect, hardener, reviewer (review-me). DoD: each carries the receive/send/done
       loop, hands off to the next role in conf order, the reviewer addresses all five.
4. [x] Installer `get-atelier-six-pack`: compose via get-swarm-forge, link the four skills,
       seed the pointer block and LESSONS header. DoD: an end-to-end run into a scratch dir.
5. [x] `scripts/check-six-pack.sh` with `--selftest`, wired into ci.yml. DoD: red on each
       planted defect, green on the pack.
6. [x] Docs: `swarmforge/README.md` (operator manual), a root README section. DoD: the role
       table matches the conf (the gate enforces it); no em dash anywhere.
7. [x] Four slices committed on the owner's yes; three LESSONS entries appended. Not pushed.

Notes: the daemon holds a handoff for Attention only when a role is literally named
`specifier` AND sits on the `master` worktree (handoffd.bb `should-hold?`), so that name
stays. The launcher injects Gherkin-tool startup lines for roles named specifier, coder,
architect, hardender, QA; the constitution overrides them. `hardener` and `reviewer` avoid
the map. `core.hooksPath` is repo-wide, so the atelier hooks run in every role worktree.

Verified 2026-09-04: gate selftest (11 planted defects red, pack green); `get-swarm-forge
six-pack` composed offline from this branch (SWARMFORGE_BASE_DIR + SWARMFORGE_PACKS_DIR);
installer end to end into a scratch project with a scratch HOME, second run idempotent;
em-dash gate on the staged diff; frontmatter 4/4; ci.yml parses with the `six-pack` job.
Not verified: `./swarm` itself (bb and tmux are not installed on this machine).
