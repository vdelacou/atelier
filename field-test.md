# Atelier field test (Phase 5)

The conformance plan's last open phase: take the skill to a repo that was actually built with
it, and score what survived contact. `conformance-matrix.md` proves the doctrine is complete
against the canon; the evals prove an agent holding the skill writes better code than one
without it. Neither can tell you what a real repo looks like months after its scaffold.

## Subject and method

A private Bun/TypeScript monorepo built by its author under this standard, at its foundations
milestone: 120 tracked files, 19 commits, extensive design docs and infrastructure, and only
the first stub modules of application code. It vendors the four skills into the repo and pins
them by hash. Audited read-only on 2026-08-30, nothing in it was modified.

The thin application layer sets what this test can and cannot measure. Grading hard rules 1-22
against roughly 130 lines, 109 of them copied atelier test-helpers, would measure nothing. So
the graded surface is what a foundations repo actually has: the scaffold, the gates, the copied
assets, the git history, and the process artifacts.

Method: diff every copied asset against the shipped version; run the shipped commit-msg
validator over all 19 commits and the size rule over every diff; execute the repo's own gates;
scan the sources for banned constructs; check the process artifacts against the doctrine that
asks for them.

## What held

Commit grammar came through nearly intact: 18 of 19 commits pass the shipped validator
unmodified, at the same 100-character limit, the single rejection being the repo-birth commit
written before its own hook existed. Coverage tiers arrived correct at 100/100/80 and were
re-pathed for a monorepo without losing the tier boundaries. The banned-construct scan is
clean. Auth is rented rather than built (rule 33) and the extraction model sits behind a named
port before any of it is written (rule 32), both decided in ADRs rather than in code. Decision
records, an append-only lessons journal, a durable plan, and a task list are all live. No
manifest declares `latest` or `*`, and the example environment file carries no secrets.

Two local adaptations were better than what the skill shipped, which is the part worth having
run the test for.

## What the field test found wrong with the skill

1. **The dependency-pinning gate could not see a monorepo.** `assets/check-package-json.sh`
   read only the root manifest, so a workspace pinning `"latest"` passed. The consumer had
   rewritten it to walk every manifest. Atelier's own Next.js variant is a monorepo, so the
   gate had a hole in the variant that most needs it. Fixed by adopting the consumer's
   approach, with a workspace violation fixture added to the smoke test first (it passed the
   violation before the change, failed it after).
2. **The shipped CI called an uninstalled binary.** The consumer's CI installs a pinned
   gitleaks before scanning; the shipped workflow did not. The repo audit had found this the
   same morning and fixed it. Two independent discoveries of one defect is the strongest
   evidence a gate is missing, not the weakest.
3. **The ADR convention collides with rule 26.** The standard MADR template carries a
   `Deciders` field, the skill prescribes ADRs, and nothing warned that a person's name in a
   tracked file is exactly what rule 26 forbids. Every ADR in the subject repo names one.
   `references/governance.md` now says to put the accountable role or team handle there.
4. **The skeleton defined no `test` script.** Hooks and docs both call `bun run test`, so the
   consumer invented one, and reached for `--pass-with-no-tests` to make it green on an empty
   repo. That flag makes the test gate structurally unable to fail. The skeleton now ships
   bare `bun test` and says why the flag is not an option.

## What the subject repo should fix, and the one cause behind it

The repo pins the skill at a hash 49 days and nine SKILL.md commits old, so it is running
doctrine this standard has since replaced: the pre-split eight-gate hook that Phase 2 retired
for training `--no-verify`, and rule 26 in its superseded wording, which is why the ADR
bylines were legal when written and are violations now. Downstream of that pin: no
commit-message re-check in CI, so a bypassed hook still lands a malformed message; a `lint`
script without `--max-warnings=0`, so the inner loop tolerates what rule 15 forbids; no README
verify block, so the docs-check gate is unwired; no advisory scan, since automated updates
cover new versions but not new CVEs in old ones; the skill vendored twice in one tree; and two
gates that currently cannot fail, an empty suite passing on a flag and a coverage script that
announces its own bootstrap exemption. Four of nineteen commits exceed the size cap, all from
before the hook existed.

Nothing on that list is bad code. Every item is doctrine that moved after the repo copied it.

## The lesson, and what changed because of it

This standard had a drift gate for its own canon and nothing at all for the copy a consumer
pins. That asymmetry is the finding. A vendored standard is a dependency: it goes stale
silently while every gate stays green, and re-syncing it is a deliberate act that has to bring
the doctrine and the assets that enforce it across together. `references/governance.md` now
carries that as doctrine, and the CLAUDE.md pointer block says it in the one file a consumer
repo is guaranteed to read.

The uncomfortable half is that the field test found defects three evals and eight CI gates did
not, because all of them measure the skill against itself. Only a real repo measures the skill
against time.
