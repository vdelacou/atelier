# PLAN: codify plan-first + durable DoD into atelier

Status: DONE. Started and completed 2026-07-05. Kept as the worked example of the convention it introduces; the next task overwrites it.

## Goal
Add the durable-plan discipline to the atelier standard: for multi-step work, the plan and a per-step definition of done are written to `.claude/PLAN.md` (not just stated in chat), so work resumes losslessly after either the human or a fresh Claude session loses context. Same rigor as the rest of the standard; no em dashes in new prose; keep SKILL.md lean.

## Definition of done (whole task)
- SKILL.md Behavioural Guideline #4 mandates the durable plan and states the resumability why.
- SKILL.md start-of-session read and workflow steps cover reading/maintaining `.claude/PLAN.md`.
- references/workflow.md carries the full convention (contents, lifecycle vs LESSONS.md, commit behaviour, resume workflow).
- SKILL.md reference-index line for workflow.md mentions the durable plan.
- Frontmatter validator green; description still <= 1024 chars; no em dashes in new text.
- Commit proposed (rule 25); not pushed without confirmation.

## Steps
1. [x] Extend Behavioural Guideline #4 (Goal-driven execution) in SKILL.md to introduce the durable `.claude/PLAN.md` + per-step DoD + resumability rationale, distinct from the append-only LESSONS.md.
   DoD: guideline names `.claude/PLAN.md`, per-step DoD, and the resume purpose. [met]
2. [x] Wire PLAN.md into the start-of-session read and the "Workflow when writing or editing code" steps.
   DoD: an agent reading SKILL.md knows to read PLAN.md first and to keep it live. [met: Lessons section + workflow steps 0, 2, 8]
3. [x] Add the full "durable plan" convention section to references/workflow.md.
   DoD: covers PLAN.md contents, its lifecycle vs LESSONS.md, commit behaviour, and the resume workflow. [met: new opening section]
4. [x] Update the SKILL.md reference-index line for workflow.md.
   DoD: line mentions the durable plan. [met]
5. [x] Verify: frontmatter validator, description length, em-dash grep on new prose, cross-refs resolve; update README Memory row (PLAN.md is now user-visible surface, Guideline #5).
   DoD: all green + README mentions PLAN.md. [met: validator ok, desc 981, 0 em dashes in new prose, README updated]
6. [x] Propose commit (rule 25) + decide fate of this .claude/PLAN.md. [met: user chose commit-and-push + keep PLAN.md as a worked example]

## Notes / breadcrumbs
- Home decision: full doctrine in references/workflow.md (the process reference); concise mention in SKILL.md. This extends Behavioural Guideline #4 (a working practice), NOT a new hard rule (which are code invariants).
- PLAN.md is committed and updated alongside work slices; on disk it is live even before a commit, so it survives context loss immediately.
- Memory already saved this session: plan-first-durable-dod (feedback type), MEMORY.md indexed.
- Distinction to preserve: LESSONS.md = append-only history (decisions/gotchas); PLAN.md = the mutable current work plan + DoD + status.
