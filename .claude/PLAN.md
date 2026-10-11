# Plan: the reply gate's first reading, its blind spot, and the next check-in (2026-10-11)

The previous plan (the reply gate reads and writes UTF-8 on every platform) closed with PR #4 merged
by rebase into main (926ec04). The firing-rate check-in fired on 2026-10-11 and found one session
that ran with the gate, this repository's own: 4 blocks in 25 judged replies, all bold lead-ins,
3 after the session's first, every restatement clean. It also found a blind spot: the Stop hook
judges a turn's last message only, and 2 of the 6 replies that broke a rule after the gate went
live were summaries written before an AskUserQuestion call. panda-social-cli wired the gate on
2026-10-05 (1a94fa7) but no session has run with it; ask-marcel-studio, extract-html and
run-with-heart are not wired; the two ask-marcel org repos could not be read, and their cloud
sessions ran one Stop hook per turn. The owner chose all three next steps: record the reading,
close the blind spot with a pre-question hook, re-arm the check-in.

## Steps and definition of done

1. [x] Re-arm the check-in (trig_01SaAdsRteii5z8BaXw2RFpA) for 2026-10-18 08:00 UTC with what the
   first one learned. DoD: the trigger shows next_run_at 2026-10-18T08:00:00Z and the new prompt.
2. [x] Probe the pre-question hook before any doctrine. AskUserQuestion is not offered to a headless
   run, so the probe holds a Bash call instead (PreToolUse runs the same way for every tool).
   Found: the text written before the call is not in the transcript when the hook fires and lands
   within 100 ms, so a hook must wait for its own tool_use_id; a hold lands as an is_error
   tool_result, so a retry can see it; and held twice (Opus 5.5, feedback asking for the text in
   the same message as the call), the model retried with no text both times and fixed the prose
   only in its final reply. DoD: the finding recorded; nothing built on it.
3. [x] workflow.md's Reply gate: the first reading replaces "not yet measured", and a paragraph
   names the blind spot and the probe. DoD: citations re-anchored once and intact, drift and the
   em-dash scan green.
4. [x] The owner's call on the blind spot, since the hook as designed does not fix the text before
   the question: measure first. The probe's gate line counts the mid-turn replies that broke a
   rule, text followed by a tool call in the same turn (a prompt starts a turn, a subagent's calls
   are its own, a turn's last message is the gate's). The check-in asks for that count in place of
   the hook's blocks. DoD: a planted session in the selftest counts its one broken summary before a
   question and never two turns' broken last messages or a subagent's broken text and call, four
   mutants go red (never counts, counts every text, counts a subagent's call, no reset at a
   prompt), and workflow.md and the changelog name the count and why nothing was built.
5. [ ] Land on the owner's yes: commits, push over the landed remote main-f7v4vj with a pinned
   lease, a pull request, CI green, rebase merge.

## Status

Steps 1-4 done 2026-10-11. The owner chose to measure the blind spot first. On the session log of
the first reading the probe reads 4 blocks, 3 after the session's first, 0 restatements still
breaking a rule and 3 mid-turn replies breaking a rule, each a bold-lead-in summary before an
AskUserQuestion call (2026-10-04 09:53, before the gate went live; 10-04 12:09; 10-09 15:07). The
session's second log repeats those events from 2026-10-04 14:01 on, which the check-in now knows
to skip. Selftest green, the four mutants red, citations intact after one re-anchor (9 moved with
workflow.md), drift and the em-dash scan green. The owner said yes to landing. Next (step 5):
three slices, push over the landed remote main-f7v4vj with --force-with-lease pinned to 574eb10,
PR #5, CI green, rebase merge on the owner's go.
