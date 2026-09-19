# Plan: remove the six-pack (2026-09-19)

Goal: the owner asked to remove everything about the six-pack. The pack (`packs/six-pack/`), its
installer (`get-atelier-six-pack`), its CI gate (`scripts/check-six-pack.sh` and the `six-pack` job)
and every current-state mention leave the repo. History stays: the CHANGELOG entries for 2.2.0 and
the Unreleased notes that mention the pack, and the LESSONS entries, are the record of what shipped
and are not rewritten (append-only journal; Keep a Changelog).

Definition of done: `git ls-files` shows no `packs/`, no installer, no `check-six-pack.sh`; `ci.yml`
has eight jobs and the README and CLAUDE.md counts say eight; `.gitignore` carries no swarm-forge
block; README has no six-pack section, no SwarmForge mention in the intro, the first-run paragraph
gone from the proof section, the CI sentence, the layout paragraph and the fast-checks block updated;
CLAUDE.md's Structure and CI bullets updated; the reverse matrix's one mention rephrased; a CHANGELOG
`### Removed` bullet under Unreleased; a LESSONS `[decision]`; every fast gate green; `git grep -i
"six-pack\|swarm"` hits only CHANGELOG and LESSONS; commit on the yes.

1. [x] `git rm` the pack, the installer, the gate; drop the CI job and the gitignore block.
2. [x] README, CLAUDE.md, reverse matrix edits.
3. [x] (gates green, census clean, committed and pushed on the yes) CHANGELOG Removed bullet, LESSONS decision, gates, census, commit `chore!: remove the
       six-pack` on the yes.
