# Plan: the six-pack onto main (2026-09-04)

Goal: the SwarmForge six-pack ships on main under `packs/six-pack/`, no product branch.

Definition of done (whole task): the gate passes from the new location; outside the LESSONS
history nothing says the pack lives on a branch; CHANGELOG `Unreleased` names the pack and the
two fixes; main fast-forwards to the branch tip; the branch is deleted.

1. [x] Move `swarm`, `swarmforge/`, and the pack README under `packs/six-pack/`; the installer,
       the gate, and `.gitignore` follow. DoD: `check-six-pack.sh --selftest` and the gate green.
2. [x] Wording pass (root README, CLAUDE.md, pack README), CHANGELOG `Unreleased`, a superseding
       LESSONS decision. DoD: `grep -r atelier-six-packs` hits only LESSONS history.
3. [x] Two commits (move; wording), then `git merge --ff-only` in the main checkout and
       `git branch -d`. Executes right after the wording commit lands.

Still not exercised: `./swarm` itself (bb and tmux absent here). First live run is the next step.
