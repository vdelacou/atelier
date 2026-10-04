# Plan: the reply gate in review, in this repo, and measured (2026-10-04)

The previous plan (the reply gate) landed in seven slices, 0c15171 to 6a9b0ce on main-f7v4vj. The
owner then asked for three things: open a PR so CI runs; install the gate in this repo's own
`.claude/settings.json`; measure later how often it fires after a session's first block. A session
log records a Stop-hook block as a user event, "Stop hook feedback: [<command>]: <stderr>" (isMeta in
a session log, a text block in stream-json), so the gate's own message makes the count mechanical.
Commits and the push each need the owner's yes.

## Steps and definition of done

1. [x] PR #1, main-f7v4vj into main (https://github.com/vdelacou/atelier/pull/1). DoD: CI runs.
2. [x] This repo's `.claude/settings.json` runs `skills/atelier/assets/check-reply.py --hook`, the
   shipped file itself rather than a copy, and CLAUDE.md says so. DoD: the command, run from the
   repo root, blocks a planted reply with exit 2 and the tag; a live `claude -p` in a scratch copy
   of the repo's layout blocks once and passes the restatement.
3. [x] The probe counts the gate's blocks per session: blocks, sessions with one, blocks after a
   session's first, and restatements that still break a rule. The hook prints the message the
   counter keys on from one constant. DoD: selftest red under a mutation of each; another hook's
   feedback and a person quoting the message are not counted.
4. [x] Docs: workflow.md's Reply gate section and the docstring name the count; CHANGELOG. DoD:
   citations intact, drift and frontmatter green.
5. [ ] Land 2-4 on PR #1 on the owner's yes; CI green on the head. DoD: CI green.
6. [x] A check-in on 2026-10-11 reads the firing rate from the session logs of repos that run the
   gate (this one, once #1 merges). DoD: scheduled; at fire time, the numbers or a note that no
   session ran with the gate yet.

## Status

Steps 1-4 done 2026-10-04. PR #1's CI on 6a9b0ce: 8 of 8 checks green, the new selftest step and
all three smoke tests included. The repo's settings run the asset itself; from the repo root the
command blocks a planted reply (exit 2, the tag) and passes a plain one, and a live `claude -p` in a
scratch copy of the layout blocked once and came back as a table, second stop exit 0, $0.040. The
counter keys on one message constant (GATE_SAID); its selftest reads two blocks (a session log's
string, stream-json's text block), one restatement still broken, and ignores another hook's
feedback and a person quoting the message; red under five mutations. On the live transcript it
read 1 block in 1 session, none after the first, none still broken. Next: the owner's yes on
landing 2-4 on PR #1 (step 5). The check-in is scheduled: trig_01SaAdsRteii5z8BaXw2RFpA, fires
into this session 2026-10-11T08:00Z with the procedure. Landing approved 2026-10-04, and PR #1
watched until it merges.
