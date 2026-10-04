# Plan: a reply gate for the Interaction section (2026-10-04)

The previous plan (probe the replies before any Interaction edit) closed in 1e3da37: 831 replies
from 16 recent cloud coding sessions showed no habit for any Simplified Technical English clause,
and showed the existing bold lead-in rule broken in 63 percent of the current model's long replies,
in 52 percent even where a tool call named atelier. A doctrine line alone does not hold it; per
CLAUDE.md, Writing a gate, the rule needs a gate that fails. The owner chose a reply gate.

The gate: `check-reply.py --hook` as a Claude Code Stop hook. Probed live on Claude Code 2.1.289
and read against the hooks docs: the Stop input carries `last_assistant_message` (the docs say to
use it, the transcript can lag); exit 2 with stderr blocks the stop, Claude reads the reason and
restates the reply (seen: a bold-lead-in list came back plain, $0.03 for both turns); the second
stop carries `stop_hook_active` and passes, so the gate never loops (Claude Code also caps a Stop
hook at 8 blocks). Blocking shows the user a "Stop hook error" notice in either form, and the
blocked reply shows twice; how often it fires after a session's first block is not measured. Only
the five doctrine tags block; the candidates stay counts. Commits and the push each need the owner's yes.

## Steps and definition of done

1. [x] Probe the Stop hook on the real CLI and in the docs. DoD: the input fields, the exit-2
   block and restatement, and the loop guard seen live.
2. [x] The asset: `git mv scripts/check-reply.py skills/atelier/assets/check-reply.py` (one checker,
   the gate in consumer repos and the probe here); `--hook` reads the Stop JSON, falls back to the
   transcript's last reply, passes on `stop_hook_active`, exits 2 with each doctrine finding and its
   fix on stderr, exits 1 (a visible hook error, never a silent pass) on input that is not the Stop
   JSON. The SKILL.md drift check runs where SKILL.md sits beside assets/. New
   `assets/claude-settings.json` wires it. CI, CLAUDE.md and the CHANGELOG follow the move. DoD:
   `--selftest` green and red under a mutation per new behaviour; the copied pair blocks once and
   passes the restatement on the real CLI.
3. [x] Smoke tests: each variant copies the pair as a bootstrap does and proves red (exit 2 and the
   `bold-lead-in` tag on a planted reply), green (a plain reply), the loop guard, and that the
   settings run the copied file. DoD: the three smoke tests green.
4. [x] References: workflow.md (the gate, its cost, python3; no asset-table row, since the tables
   there list git-hook gates); the copy blocks of bun-typescript.md, nextjs-monorepo.md and
   java-quarkus.md; check-workflow-assets.sh checks the settings like a workflow. DoD: citations re-anchored and intact,
   drift green.
5. [x] SKILL.md: Interaction names the gate and gives the bold lead-in's replacement shape; the
   What-applies-where table gains its row. Companions: greenfield copies and proves it, review-me's
   adopt mode installs it, the grill-me and distill echoes checked. DoD: frontmatter valid,
   citations intact, the probe's cut-list drift check still parses.
6. [x] Tier-1 selector dry run (tier 1 itself only on the owner's yes if it selects a task: eval
   cost); CHANGELOG Unreleased (Added, Upgrading, Harness). DoD: the selector's output read.
7. [x] Land in slices on the owner's yes (references before the SKILL.md that cites them); push on
   its own yes.

## Status

Steps 1-6 done 2026-10-04. The asset: `--hook` blocks a doctrine finding (exit 2, grouped tag, example
and fix on stderr), passes the restatement, reads the transcript where no `last_assistant_message`
comes, and exits 1 on input that is not a Stop event; the selftest covers each and goes red under a
mutation of each (loop guard, candidates blocking, transcript fallback, event check), and fails
outside the skill tree. Live, with the copied pair on Claude Code 2.1.289: a bold-label list blocked
once (exit 2, three findings), came back plain, second stop exit 0; $0.037 for both turns; the
prompt had asked for bold labels, and the gate overrode it. check-workflow-assets.sh went red on all
three references before their copy lines and green after; its selftest proves the settings case.
Smoke tests all passed: Bun 143 checks, Next 48, Java 78.
Citations re-anchored twice (11 lines, then 1), 239 intact; drift and frontmatter (5/5) green. Tier-1
selector: 0 of 21 tasks (assets select nothing; the workflow.md hunk maps to rules no task asserts).
Step 7 approved 2026-10-04: seven slices committed and pushed to main-f7v4vj. Next: measure how often
the gate fires after a session's first block, from session logs once consumers run it.
