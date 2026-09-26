# Plan: harness slices after 2.4.0 (2026-09-26)

Open since the release: the harness keeps no transcript (`.run.log` is the CLI's empty stderr,
`.result.txt` its final message), so a turn-capped session cannot be explained; and the frozen
baseline arm is one pass at the 120-turn cap. Also a doc drift of mine: CLAUDE.md still says the
wall-clock default is 20 (40 since 2026-09-19) and does not name the 120-turn cap.

## Slice 1: a transcript per session

Definition of done: `run.sh` runs each session with `--output-format stream-json --verbose`, writes
the stream to `<run-dir>/.transcript.jsonl`, and derives `.result.txt` from the final `result` event
so every consumer reads what it read before (the final text on success, "Error: Reached max turns
(N)" on a turn cap, the error text on a refusal); `grade.py` prints `turns=N` on each scorecard line
when a transcript exists; probed on single cheap sessions first (a normal one, a forced turn cap);
CLAUDE.md's cap line corrected; selftests green; commit on the yes.

1. [x] (success carries `result` and `num_turns`; a turn cap carries `subtype: error_max_turns`, `errors`, `terminal_reason: max_turns`, no `result`; nothing on stderr) Probe the stream shapes (success, max turns) with one-turn sessions.
2. [x] (transcript.py; run.sh streams to .transcript.jsonl and derives .result.txt; grade.py turns= and census; selftest red with the max-turns branch removed; old runs grade unchanged; CLAUDE.md) run.sh and grade.py edits, selftest scenario for the turn read, CLAUDE.md line.
3. [x] (a4 skill arm 2/2, turns=24 on the scorecard; 167-event transcript, 9 Read, 10 Bash, 4 Write; .result.txt the plain file list; stderr empty) One real task through the new run.sh (a4-tdd-feature, skill arm) to prove the pipeline end to end.

## Slice 2: the fixture back to three passes at 120

Definition of done: two baseline-arm passes (`bl120-2`, `bl120-3`, opus, defaults 120 turns / 40 min)
on the new run.sh, none refused or capped; `freeze-baseline.py` over them and the 2026-09-20 release
pass's baseline arm writes `passes: 3`; the release run grades 61/61 against it; `baseline.md`
records it with the turn census the transcripts now allow; CHANGELOG Harness bullet; commit on the yes.
