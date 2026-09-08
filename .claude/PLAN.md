# Plan: the citation lock pins both ends of a range (2026-09-08)

Goal: `check-citations.py` pins the start line of every `file:N-M` citation and nothing else, so the end
of a range is free to rot; the preview found 56 ranges, two ending on a blank line (`SKILL.md:52-169`,
`workflow.md:62-82`) and three inverted, end before start (`testing.md:184-127`, `security.md:227-217`,
`testing.md:649-531`), all invisible to the gate today. Pin the end too, and repair the five.

Definition of done: `collect()` yields the end line of a range as a pinned target beside the start;
the selftest proves a drifted end line fails; the five broken ranges are re-anchored to the lines their
row means (checked against the target text, not guessed); `--lock` pins every end with no blank
snippet; verify green; drift green; CHANGELOG Harness bullet; CI green. The lock grows by about 56
entries, which is the accepted cost: a range guards a section, and a section has two ends.

Facts (2026-09-08): the re-anchoring done by hand today rewrote `file:N` starts and never the `-M` ends,
which is how three ranges inverted; `SKILL.md:52-169` (row 10.2) spans rule 16 to a blank line before
the workflow steps and means rules 16 and 17 (lines 52-53); `workflow.md:62-82` (row 15.3) ends on the
blank before the section's last paragraph at 83.

1. [x] (selftest green; the mixed copy with the old collect fails the new case) `check-citations.py`: pin the range end; docstring; selftest (`doc.md:1-3`, drift line 3, fail).
       DoD: selftest green, the mixed copy with the old collect fails the new case.
2. [x] (52 end pins added, 233 locked, zero blank, drift green) Repair the five ranges in `conformance-matrix.md` from the target text; verify reports only the
       new end pins as unlocked; lock; verify; zero blank snippets; drift green.
3. [x] (two slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Harness bullet; LESSONS short `[gotcha]`; plan final. Commits on the yes: (a) `fix(check-
       citations): pin both ends of a range citation`, (b) `docs: changelog, lessons and plan for range
       ends`. Push on its own yes.

Not in scope: a `--reanchor` helper that moves starts and ends by snippet (today's hand scripts did it
eight times; a real candidate for the next harness slice).
