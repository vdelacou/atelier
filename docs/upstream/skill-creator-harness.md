> Status: FILED 2026-07-12 as https://github.com/anthropics/claude-code/issues/76818. Kept here as the durable record; the patched runner is committed at scripts/trigger-eval/run_eval.py.

# Draft issue: skill-creator plugin (trigger-eval harness)

Title: run_eval.py false-negatives: shared probe root contaminates parallel workers; first-tool-only detection penalizes exploring models

## Summary
Evaluating a previously optimized description returned trigger_rate ~0.0 on EVERY
should-trigger case. Three compounding harness issues; the first is decisive.

## 1. Cross-probe contamination (decisive)
All parallel workers (default 10) write their uuid-suffixed command file into the SAME
project root's .claude/commands. Each probe's model therefore sees up to N near-identical
clones of the skill and picks an arbitrary one; the detector greps for its own uuid, so
almost every probe reads as non-triggered. A single serial probe triggers instantly.

Fix that worked: give each probe an isolated temp project root (copy the fixture in,
write exactly one command file), run claude -p with cwd there, rmtree in finally.

## 2. First-tool-only detection
run_single_query returns False the moment the first tool_use block is anything other than
Skill/Read. Models that explore the repo before consulting a skill (ls, Read package.json)
are scored as non-triggered even when they invoke the skill on the second tool call.
Fix: watch the whole stream until the result event; conclude on match, result, or timeout.

## 3. Timeout vs thinking models
The default 30s timeout straddles time-to-first-tool for thinking models (measured 18.3s
on one run of the same query that timed out on others). With fix 2, probes need the larger
window anyway: 90s worked well.

With all three applied, the same description scored 31/34 (negatives 16/16 clean).
Happy to share the patched run_single_query.
