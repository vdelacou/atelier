# Plan: release 2.3.0 (2026-09-09)

Goal: ship the changes accumulated since v2.2.0 (hard rules 36 and 37, rules 5, 13 and 15 gated in
every variant, the Next CI workflow, the README pitch, the citation gate's range pins and
`--reanchor`) as 2.3.0, the same shape as 2.2.0: release notes, the tier-2 pass on the release tree,
the pass recorded, the annotated tag, main and the tag pushed.

Definition of done: CHANGELOG has `## [2.3.0] - 2026-09-09` with a release paragraph and an
"Upgrading from 2.2.0" list distilled from the Consumers notes; README names 2.3.0 as the current
release; `baseline.md` records the tier-2 pass (both arms, 21 tasks, opus, scores, capped sessions,
tree under test); tag `v2.3.0` sits on the record commit with a message in the v2.2.0 shape;
`git ls-remote --tags origin` shows it; CI green on the pushed range. Owner's one yes covers the
three commits, the tag and the push (given in advance, 2026-09-09).

Facts: CLI logged in (claude.ai, first party); `tasks.json` unchanged since the 2026-09-04 freeze
(last commit 257ee2d, 2026-09-03), so no re-freeze; `skills/atelier/` diff since v2.2.0 is 20 files,
+560/-62; 2.2.0's tier 2 took 58 minutes at six jobs; the Bash tool caps a background run at 10
minutes, so the pass runs under `nohup ... & disown` with a Monitor on its log (no `setsid` on
macOS); nothing under `skills/` or `scripts/` is edited while it runs.

1. [~] (launched 12:20, six sessions live, first task done at 12:23) Tier 2 on the current tree: `CONFORMANCE_ARMS=both CONFORMANCE_MODEL=claude-opus-5
       CONFORMANCE_JOBS=6 CONFORMANCE_TAG=release-2.3.0 bash scripts/conformance-eval/run.sh`, log in
       the scratchpad, Monitor on `done:|capped:|exit=|rror`. DoD: 42 sessions finished, `.capped`
       empty (or each capped run named), `grade.py <runs-dir>` over the finished directory read
       for both arms.
2. [ ] Release notes while it runs (CHANGELOG.md and README.md only): the Unreleased block becomes
       2.3.0 with the release paragraph and the upgrade list; README's current-release line. Commit
       `docs(release): 2.3.0 changelog and upgrade notes`. DoD: em-dash gate, frontmatter, citations
       green; the upgrade list names every "Consumers:" action of the Unreleased block once.
3. [ ] Record the pass in `scripts/conformance-eval/baseline.md` under
       `## Tier 2 for the 2.3.0 release (2026-09-09)` in the 2.2.0 shape (arms table, capped, tree
       under test, anything environmental). Commit `chore(conformance-eval): the 2.3.0 tier-2 pass`.
       If the skill arm is below full marks on any task, stop and report before tagging.
4. [ ] `git tag -a v2.3.0` on the record commit with a message in the v2.2.0 shape (one line, then
       the release paragraph and the tier-2 numbers); `git push origin main v2.3.0`. DoD: the tag on
       the remote, CI green, plan closed.
