# Plan: check-citations.py --reanchor (2026-09-09)

Goal: after any insertion in a cited file, the pinned citations shift and `--lock` re-pins whatever now
sits at the old line, blank included, so yesterday every shift was repaired by an ad-hoc script that
found the pinned snippet's new line and rewrote the matrix, eight times, and never moved a range's end.
Give the gate that mode.

Definition of done: `python3 scripts/check-citations.py --reanchor` finds, for every lock entry whose
line no longer holds its snippet, the unique line that does, rewrites every citation token in both
matrices consistently (start, end, and `/extra` lines each mapped independently), re-locks, and prints
the moves; a snippet that is gone or appears more than once is reported and left for a human, exit 1,
no lock written; on an unshifted tree it prints "nothing to re-anchor" and exits 0; the selftest proves
the happy path (a citation and a range shifted by an inserted line, verify red before, green after) and
both refusals; CLAUDE.md's verify line names the mode; CHANGELOG Harness bullet; CI green.

Facts (2026-09-09): lock keys are `target:line` with `target` the ROOT-relative path `resolve()` returns
and the snippet the stripped 72-char prefix; both ends of a range are separate keys since yesterday, so
mapping keys independently moves a range as two points; `CITE.sub` over each source with a per-match
rebuild keeps everything outside the token untouched.

1. [x] (selftest green; nothing to re-anchor on the tree; rehearsal on a scratch copy moved 17 SKILL.md citations and nothing else) `run_reanchor()`, dispatch, docstring, selftest cases. DoD: selftest green; `--reanchor` on the
       current tree says nothing to re-anchor; verify still 233 intact.
2. [x] (two slices committed and pushed 2026-09-09 on the owner's yes) CLAUDE.md verify line; CHANGELOG bullet; LESSONS one line; plan final. Commits on the yes:
       (a) `feat(check-citations): --reanchor moves shifted citations by snippet`, (b) `docs: CLAUDE.md,
       changelog, lessons and plan for --reanchor`. Push on its own yes.
