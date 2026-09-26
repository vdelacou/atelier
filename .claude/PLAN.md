# Plan: eval arms blind to the user's installed skills (2026-09-26, late)

The conformance and review runners start nested `claude -p` sessions that see the skills installed under
`~/.claude/skills` (here, links to this repo's atelier suite), so the unaided arm is not skill-less by
construction. No atelier skill was invoked in 42 baseline sessions of the frozen fixture's passes; two
called `claude-api` on h6. The trigger runner was fixed with `--setting-sources project,local`
(b532bbc); the distill runner shipped with it.

## Steps and definition of done

1. [x] Find out everything a nested session inherits from the user's machine before choosing the flag:
   user settings (permissions, hooks, env), user-level skills, and the memory it loads (the run dirs
   sit inside this repo, so a directory walk-up may load this repo's CLAUDE.md and project memory).
   DoD: a probe per candidate, read from the session's own init event and context, recorded.
2. [x] Apply the narrowest isolation that removes the atelier context and nothing the measurement relies
   on, to `scripts/conformance-eval/run.sh` and `scripts/review-eval/run.sh`, with a comment in each
   runner's idiom; one short probe per runner shows the unaided arm sees no atelier skill while the
   skill arm still reads its injected copy by path.
3. [x] The frozen baseline arm and the review baseline were measured without isolation: ask the owner
   whether to re-freeze now (cost stated), and record the decision in both `baseline.md` files.
4. [x] CHANGELOG Harness entry; a journal entry only if the lesson is new (the 2026-09-26 trigger-eval
   entry already says a verdict is only as valid as the choice set); commits on the owner's yes.

## Status
Step 1 done (probes 2026-09-26 late, `claude -p` from a folder inside skills/atelier-workspace unless
noted; the session's init event and its own account of its context):
- default (today's conformance and review runners): this repo's CLAUDE.md and the project MEMORY.md
  load by walk-up, the four atelier skills are listed (55 skills), auto mode and the "Vincent rules"
  output style come from the user settings;
- `--setting-sources project,local`: atelier skills gone, but CLAUDE.md and MEMORY.md still load, and
  the user settings are gone too (default permission mode, default output style), which would change
  the instrument for both arms;
- that plus `--settings ~/.claude/settings.json`: atelier skills gone, user settings kept;
- `--disable-slash-commands`: every skill gone, settings kept, CLAUDE.md and MEMORY.md still load;
- default flags from a folder outside the repo: only `~/.claude/CLAUDE.md` (the owner's global rules,
  shared by both arms, not atelier-specific) loads; atelier skills still listed.
Decision: run each session in a folder outside the repo and copy its tree back for grading, with
`--setting-sources project,local` plus the user's settings file passed back; same for the distill
runner, whose sessions also ran inside the tree.
Step 2 done: 05887b9 (pushed). Sessions run in a scratch folder outside the repo, copied back for
grading, with --setting-sources project,local plus the user's settings file; the distill runner too.
Verified by a stub claude on PATH (plumbing) and one real session per arm (acceptEdits, the owner's
output style, no atelier skill listed, the skill arm reading its injected copy). Correction on the way:
the unaided sessions' 89 `bun` calls were refused ("requires approval"), not run; my refusal count had
keyed on the word "permission". Known and left as is: the conformance and distill watchdogs leave an
orphaned `sleep` for the cap's length when a session ends early, which holds a pipe open (log files are
unaffected).
Step 3: the owner chose to re-measure everything now. Driver in the scratchpad (remeasure/driver.sh),
launched 22:08: lane A, conformance baseline arm, 3 passes (CONFORMANCE_TAG=iso-bl1..3); lane B, distill
(DISTILL_TAG=iso), then review bun and java, 3 passes each (REVIEW_TAG=iso-r1..3). All claude-opus-5.
After: grade, check for dead sessions, freeze-baseline.py over iso-bl1..3, update the three baseline.md
files, the README review and distill rows, CHANGELOG; commit and push (owner's yes given).
22:26: the API refused nested sessions ("Failed to authenticate. API Error: 403 Request not allowed")
for about two minutes; a one-turn probe answered ok at 22:28. Distill had finished (graded: skill hard
3/3 and recall 33/33, unaided hard 0/3 and recall 24/33, after two expectation fixes: five planted
entries that restate atelier rules are neutral, and the untrusted entry is exempt from verbatim).
Conformance pass 1 kept 14 of 21 sessions; the rest and all review runs but one arm were refused.
Driver 1 stopped. Driver 2 (remeasure/driver2.sh, 22:30): one lane at a time, a probe before each run,
three attempts per refused session: review bun r1 (skill arm), r2, r3, java r1-r3, then conformance
iso-bl1 (the seven refused tasks), iso-bl2, iso-bl3 at three jobs. Resume from lanes2.log if it stops.
Draft for distill's baseline.md: remeasure/distill-section.md.
Done 2026-09-27 00:4x. Driver 2 finished at 00:30 with no refusal: review 3 passes per variant, conformance
iso-bl1 (the 7 refused tasks), iso-bl2, iso-bl3 (under conformance-2026-09-27, the date turned mid-run).
Readings, graded and read before recorded: conformance unaided 35, 36, 37 of 61, re-frozen 108/183
(was 138/183; soft delete 9/12 to 0/12); review Bun skill 36/36 cited 36/36 with 2 claims true on the
fixture's text, unaided 19/36; Java skill 27/27, unaided 24/27; distill skill hard 3/3 recall 33/33,
unaided hard 0/3 recall 24/33. Grader fixes: the review console evidence (twelfth defect), distill
expectations (five atelier-restating entries neutral, the untrusted entry's annotated copy exempt).
Open follow-ups: the review clean files need a consumer and a typed error; the skill arm's first
isolated conformance reading is the 2.5.0 tier 2.
