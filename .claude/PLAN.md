# Plan: a one-turn preflight before every eval pass (2026-10-15)

The previous plan (rule 38's host settings) closed with PRs #6 and #7 merged; what it left waits on
the owner: `check-host.py --apply` here and in panda-social-cli, and deleting the remote
`main-f7v4vj`. The distill pass (PR #8) proposed one promote: "both arms dropping at once is the
environment" recurred four times (an expired OAuth session that made every trigger probe read 0.0,
an overnight ENOTFOUND outage, a revoked CLI token, 24 of 42 sessions refused with a 403 after
midnight), and each spent a pass before anyone read it. The owner asked for the run.sh probe.

## The design

- `scripts/eval-preflight.sh [model]` runs one `claude -p` turn from a scratch folder outside the
  repo, with the runners' isolation flags (`--setting-sources project,local`, the user's settings
  file), the pass's model, `--max-turns 1` and a wall-clock cap (`PREFLIGHT_TIMEOUT_S`, default
  120), asking for the word `ready`. Exit 0 when the reply holds it; exit 1 with the CLI's own text
  on a refusal, a transport error, a non-zero exit, another answer or a hang past the cap.
- Each of the four runners (conformance, review, distill, trigger) calls it with its model right
  before its first session, so a pass that selects nothing still costs nothing.
- `--selftest` puts a fake `claude` first on PATH: an answer passes; a 403, a transport error, a
  non-zero exit, another answer and a hang past a 2 s cap each fail; the fake checks the flags it
  received and that it ran outside the repo. CI runs it in the conformance grader job.

## Steps and definition of done

1. [x] The script and its selftest. DoD: selftest green; mutants red (no exit check, no answer
   check, no cap, no isolation flags). Done: green in 2.2 s, and red under six mutants (those four,
   the model dropped, the probe run where it was called).
2. [x] Wired into the four runners. DoD: each calls it before its first session; `bash -n` green.
3. [x] One real probe here. DoD: exit 0 on the signed-in CLI, exit 1 on a model that does not exist.
   Done (Claude Code 2.1.300): answered in 6 s; `claude-no-such-model` stopped it in 1.7 s with the
   CLI's own "There's an issue with the selected model" text.
4. [x] CI and docs: the selftest in ci.yml, CLAUDE.md's verify list, the changelog. DoD: fast gates
   green, no em dash added.
5. [ ] Land on the owner's yes after PR #8 merges: commits, push, a pull request, CI green, rebase
   merge on the owner's go.

## Status

Steps 1-4 done 2026-10-15; fast gates green. Next: step 5 once PR #8 merges, on the owner's yes.
