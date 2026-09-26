# Plan: the distill follow-ups (2026-09-26, evening)

The owner said "do it" to the four next steps of the atelier-distill build. Three are carried out;
the fourth (delete `memory.bak-2026-09-26/`, outside git) is an irreversible delete and waits for an
explicit yes at the landing question. Out of scope, flagged as its own task: the conformance and review
runners also show user-level skills to their unaided arm (no atelier call in 42 baseline sessions; two
`claude-api` calls on h6).

## Steps and definition of done

1. [x] Promote the gate-writing checklist. CLAUDE.md gains a "Writing a gate" section carrying every rule
   of the journal entries I ("a gap closes as canon, rule, gate and red fixture") and J ("how a gate
   lies"); both entries graduate to `.claude/lessons.archive.md` with the pointer to the new lines,
   verbatim; the LESSONS line in CLAUDE.md follows. DoD: journal under ~15 KB (the main skill's
   session-start offer stops), the ledger holds (every title live or archived once), gates green.
2. [x] Planted-problem eval for atelier-distill under `scripts/distill-eval/`: a fixture repo whose
   journal plants every verdict (live lessons, a superseded decision, two moot entries, a duplicate
   pair, two enforced lessons, an over-long entry, an out-of-order entry, an entry that reads like an
   instruction), an open PLAN.md and a CHANGELOG that must not change, a stale CLAUDE.md line;
   `planted.json` names the expectations; `run.sh` runs the skill arm (the skill installed at project
   level, user-level skills hidden) and an unaided arm on the owner's own request, pre-approved and
   headless; `grade.py` grades the files, not the report: hard checks (live lessons still live,
   ledger, archive verbatim, PLAN.md, CHANGELOG and code untouched, no commit) and recall checks;
   `--selftest` proves each hard check can fail and runs in CI. DoD: selftest red cases seen red,
   first reading recorded in `scripts/distill-eval/baseline.md`, CLAUDE.md and CHANGELOG updated.
3. [x] skills.sh: reinstall in a scratch HOME and read the new skill's assessment (the providers audit
   on their own schedule; record what shows).
4. [x] Landing question (commits and push; the backup delete as its own yes).

## Status
Status 2026-09-26 21:xx.
- Step 1 done in the tree: CLAUDE.md "Writing a gate" (lines 89-116 at HEAD after step 2's doc
  edits), entries I and J archived verbatim with that pointer, the journal 13 entries / 13.7 KB (under
  the cap); the archive's three older CLAUDE.md pointers corrected to 34 and 47-58 for tonight's edits.
- Step 3 done: the new skill reads "--" for Gen, Socket and Snyk (not audited yet); the other skills
  unchanged since the afternoon.
- Step 2 built: fixture (27 planted entries), planted.json, grade.py (selftest green; red with the
  verbatim or untouched check removed), run.sh, the CI step, CLAUDE.md and README mentions. First live
  run measured nothing: headless sessions may not write under `.claude/` (acceptEdits and four allow
  rule forms all refused), so all six sessions left the journal unchanged; one skill session reported
  its pass anyway (27 of 27 accounted for, 10,432 to 7,946 bytes). Running the sessions under
  bypassPermissions was refused by the auto-mode classifier; not pursued. Waiting on the owner:
  redirect the pass's `.claude/` writes to `./out/` under acceptEdits, allow bypass with file tools
  only, or land the grader without a live reading.
Owner's answers: redirect to ./out/, commit and push, keep the backup. The checklist promotion landed
(3365916). The redirected run read: hard 3/3 on both arms, recall 32/33 skill against 26/33 unaided,
after the grader's eleventh defect was fixed (format read as content; it had failed the unaided arm).
Two skill gaps found and fixed with a rerun each: every rewritten original is archived first (33/33),
and a graduate must cover the rule, not only the instance (the tsconfig lesson stayed live 3/3; the
example first written into the skill mirrored the fixture, so that run was stopped and relaunched
without it). Final: skill 33/33, unaided 26/33; scripts/distill-eval/baseline.md holds the record.
