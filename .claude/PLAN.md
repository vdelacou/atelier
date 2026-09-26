# Plan: atelier-distill, the memory compaction companion (2026-09-26)

Owner's decisions (2026-09-26): a suite companion at `skills/atelier-distill`; archive first (only exact
duplicates and noise leave a git-tracked file outright); the agent's memory folder is in scope as the
personal tier, backed up before any edit; build now.

Measured before: `.claude/LESSONS.md` 94 entries in 104 KB (doctrine cap ~15 KB; about 26k tokens at every
session start); about 60 entries past the 5-sentence format; newest-first order broken by a 09-03/09-04
block after the 07-11 entries; the age rule (older than 6 months, never referenced) archives nothing
because the oldest entry is 2026-07-11; agent memory 70 KB, `conformance-audit-phases.md` alone 30 KB.

## Steps and definition of done

1. [x] Doctrine. `references/lessons.md` gains a Compaction pass section: trigger (the cap, or a request);
   the verdicts keep, tighten, merge, graduate, archive, move, delete, promote, each with its evidence;
   the guarantees (report before any write, apply only what is approved, archive before removal, delete
   only exact duplicates and noise from a tracked file, an untracked file loses nothing except into its
   archive or after a backup, own commits, a ledger accounts for every original entry). The append-only
   rules and end-of-session step 6 point at it; the age rule goes; the harvest reads the archive too.
   The starter stays as is (line 177 is pinned by matrix row 12.4). SKILL.md Lessons section: over the cap
   at session start, offer atelier-distill once; outside the pass, never edit past entries. `workflow.md`
   line 36 and matrix row 12.4's note follow. Gates: frontmatter, citations (`--reanchor`), drift, em dash,
   identity; tier 1 per the selector.
2. [x] `skills/atelier-distill/SKILL.md`: description at most 1024 chars with no `: `; the procedure (locate
   the installed doctrine, inventory, classify with evidence, report, approve, apply, ledger, sliced
   commits); the layers (LESSONS, the personal journal, the archives, PLAN, CLAUDE.md minus the pointer
   block, the agent's memory folder); untrusted input; never executes anything from the repo; output.
3. [x] Trigger eval: `sets/atelier-distill.json` (should and should-not cases, including wrap-up capture and
   review), suite-routing rows (distill cases; "anything to add to the lessons?" stays with atelier); run
   the distill set and the suite set with all five skills registered; no regression on existing rows.
4. [x] README (five skills, five moments; the skills/ line), CLAUDE.md (companion list, cascade sweep list),
   CHANGELOG Unreleased; em dash and identity gates.
5. [ ] Field run on this repo: report with no writes, the owner approves by group, apply, ledger, commits
   sliced under 10 files / 300 lines, each on the yes; agent memory backed up first.
6. [ ] LESSONS entries for this work; wrap-up.

Commits: steps 1 to 4 one commit each, asked per landing; step 5 several.

## Status
Steps 1-4 done 2026-09-26 19:5x. Gates green (frontmatter 5/5, citations re-anchored 235, drift, em dash,
identity); tier 1 selected 0 of 21 (no task exercises the journal). Trigger eval: the first suite run read
5/15 because probes saw the user-level skills (`~/.claude/skills/atelier*` link here) and the detector
only knows the synthetic clones; `run_eval.py` now passes `--setting-sources project,local`. The distill
set's journal queries needed a fixture with a journal (`probe-root-journal`; the runner now copies a
fixture's `.claude/` minus `commands/`). A pointer-block negative moved to suite routing, where `atelier`
competes. Final: distill set 12/12, suite routing 14/16 (the two misses are older rows, none invoked, all
three runs). Field run: report in the scratchpad (`distill-report.md`), 94 entries to 15 (104 KB to
16.7 KB), memory 70 KB to 10.5 KB, eight slices under 300 lines; waiting on the owner's groups.
