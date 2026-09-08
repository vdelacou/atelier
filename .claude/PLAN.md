# Plan: a blank line is not evidence (2026-09-08)

Goal: `check-citations.py` pins the first line of every `file:line` citation in the matrices and fails
when its content changes, but it accepts an empty snippet: three citations (`observability.md:21-22`,
`product.md:47-48`, `product.md:51-52`) have pinned a blank line since the lock was created on
2026-08-30 (their ranges start on the blank line after a heading), and twice today a shifted pin was
re-locked to a blank line before the lock diff caught it. A gate that pins nothing is a gate that lies
(canon 15.10).

Definition of done: `run_verify` fails a citation whose target line is blank ("cites a blank line, not
evidence"); `run_lock` refuses to pin one; the selftest proves both on a temp tree and fails against
the old script; the three rows cite the paragraph lines (22, 48, 52) instead of the blanks; lock and
verify green with zero empty snippets; CHANGELOG Harness bullet; CI green.

Facts (2026-09-08): no lock in history ever held a non-empty snippet for the three keys (the ranges
were born on the blank line); the rows' notes quote the paragraphs at observability.md:22 ("Logs,
metrics, and traces join up only when they share a trace id"), product.md:48 ("Automation removes
friction") and product.md:52 ("Every user-facing string lives in a catalog"); only the start of a
range is pinned (the `N-M` end is not), which is why a heading drift left the start on a blank.

1. [x] (selftest green, the mixed copy fails the new case, the tree reported the three blanks) `check-citations.py`: blank snippet is a FAIL in verify and a refusal in lock; selftest case
       (a matrix citing a blank line: verify 1, lock 1). DoD: selftest green; the mixed copy with the old
       verify fails the new case; `check-citations.py` on the tree reports the three blanks.
2. [x] (zero empty snippets) Re-anchor the three rows to 22, 48, 52; lock (zero empty snippets); verify; drift green.
3. [x] (two slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Harness bullet; LESSONS `[gotcha]` short; plan final. Commits on the yes:
       (a) `fix(check-citations): a blank line is not evidence`, (b) `docs: changelog, lessons and plan for
       the blank-pin fix`. Push on its own yes.

Not in scope: pinning the end line of a range (a wider lock; worth its own decision); the Next
variant's missing package.json gate.
