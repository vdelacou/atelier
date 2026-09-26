# Lessons archive

Entries a compaction pass retired from `.claude/LESSONS.md`, verbatim, newest first, each followed by the line that says why it left. Nothing reads this file at session start; grep it when a question needs the history. Format and rules: `skills/atelier/references/lessons.md`, Compaction pass.

---

## [decision] 2026-09-06 | the README leads with the value and two quick starts; the catalogue comes second

The README opened with a 98-line catalogue (use-when bullets, the pillar table, the reference list) before any way to start, and the six-pack's operator loop was written nowhere: neither this README nor the pack manual said where a card is typed, how the spec is approved, or where the verdict lands. Reshaped, not rewritten, and reviewed section by section: the first screen says what atelier is, the five habits the agent acquires, and two quick starts (one agent in three commands; the six-pack's clone, installer, `./swarm`, then "Your first card" in six steps, each checked against the dashboard's controls, the clarify helper and the first run's files). The gates are the agent's job in the quick start (greenfield for a new repo, adopt mode for an existing one); the copy block survives as "Install the gates by hand" because the smoke test mirrors it line for line. The clone-and-symlink install went; the skills CLI is the install and the six-pack already clones. Rule for next time: a README's first screen answers what, what changes, how to start; everything a newcomer reads second goes below, and any operator loop is written from the runtime's controls, never from memory.

Archived 2026-09-26: superseded by "the README is a pitch written from scratch" (2026-09-09).

---

## [decision] 2026-09-05 | the six-pack's first live run, and the three things it changed in the pack

Empty repository, one card (a Bun CLI totalling invoices per customer, names and emails in the file): card to Done in 1h56 with one Attention approval and zero clarifications; 35 commits (specifier 3, coder 8, cleaner 5, architect 6, hardener 9, reviewer 4), 88 tests, coverage 100 on every tier, mutation 100 with 168 killed, two ADRs, verdict conformant with one Low finding fixed by the reviewer and two accepted deviations argued in ADRs. An independent re-run of every gate on the merged main agreed. Three costs the run exposed, folded into the pack: every pane asks Claude Code's folder-trust and bypass-mode questions on first start (documented, twelve answers per fresh project); two roles spent minutes reading `swarm_handoff.bb` after `AUDIT_REQUIRED` (each role prompt now says the first call is a re-read, then the same call again); the inner loop's `bun run lint` hides the type-aware rules CI runs (`lint:strict` joined the pre-handoff loop). Rule for next time: a pipeline of agents surfaces the cost of every unstated step, because nobody in it can shrug and move on.

Archived 2026-09-26: superseded by "the six-pack leaves the repository" (2026-09-19); `packs/six-pack/` is gone.

---

## [decision] 2026-09-04 | the six-pack ships on main under packs/six-pack, not on a product branch

Supersedes the product-branch decision earlier today. swarm-forge's branch-per-product exists for one mechanical reason: its installer downloads `archive/refs/heads/<name>.tar.gz`, so each pack needs a branch whose root is the pack. `get-atelier-six-pack` composes through `SWARMFORGE_PACKS_DIR` instead, and `pack_tree` looks for `$SWARMFORGE_PACKS_DIR/six-pack` first, which is swarm-forge's own multi-pack layout. So the pack lives at `packs/six-pack/` on main (a two-pack or four-pack has a home beside it), the installer stays at the root, and there is no long-lived branch to rot, which the standard's trunk rule forbids anyway. Rule for next time: copy an upstream's layout only after asking which constraint produced it; a branch that exists for a tarball URL is not a reason to keep one.

Archived 2026-09-26: superseded by "the six-pack leaves the repository" (2026-09-19); `packs/six-pack/` is gone.

---

## [gotcha] 2026-09-04 | swarm-forge keys behaviour on role names, not on the role table

Building the six-pack branch: the handoff daemon holds a `git_handoff` for Attention only when the sender is the master-worktree role AND a role literally named `specifier` exists (`handoffd.bb`, `should-hold?`), and the launcher injects Gherkin/APS startup lines (`swarm_tool.sh require gherkin-parser`, "run exactly ... ensure") into the system prompt of any role named specifier, coder, architect, hardender, or QA (`role-required-tools`). Neither is in the README or the conf format. So the specifier keeps its name, `hardener` and `reviewer` dodge the map, and `constitution.prompt` (which takes precedence over articles and Tool Startup lines) turns the APS lines off for the roles that keep a mapped name. Rule for next time: before naming anything a runtime consumes, grep the runtime for the literal, not only its documented config surface.

Archived 2026-09-26: superseded by "the six-pack leaves the repository" (2026-09-19); the swarm runtime is no longer vendored.

---

## [decision] 2026-09-04 | the six-pack is a root-level product branch, and how the two gates land in a swarm

`atelier-six-packs` carries the pack at the repo root (`swarm`, `swarmforge/`) beside `skills/`, so `SWARMFORGE_PACKS_DIR=<checkout> get-swarm-forge six-pack` composes it with the upstream runtime unchanged and `get-atelier-six-pack` links the four skills from the same checkout. Rules 24 and 25 without a user in the pane: the operator's Attention approval of the spec is the yes for the scenarios it names and for every commit the card's pipeline produces; no role pushes; a test older than the task is frozen. The reviewer may apply narrow rule-cited fixes (review-me is report-only because a user is there to say "apply"; in the swarm nobody is) and escalates the rest. Plans are per role and untracked (`./tmp/plan.md`) and `.claude/LESSONS.md` has one writer (the reviewer), because six roles merging one file would conflict on every handoff. Prompts point at the skills and restate no doctrine, so a doctrine change reaches the swarm through `skills/`, not through the prompts.

Archived 2026-09-26: superseded by the six-pack entries of 2026-09-04 and 2026-09-19.

---

## [gotcha] 2026-09-04 | the swarm launcher rewrites `.git/hooks/commit-msg` at every start

`swarmforge.bb` `install-commit-msg-hook!` writes its byline hook into `git rev-parse --git-path hooks` unconditionally. Under `core.hooksPath=.githooks` (Bun script, Java) the file is inert and the atelier hooks run in every role worktree, since the config is repository-wide. A Next.js package on `simple-git-hooks` loses its commitlint hook on each `./swarm` until `bunx simple-git-hooks` is re-run; CI's `check-commit-messages.sh` catches it either way. Documented in the pack README and `local-engineering.prompt`; not fixable from the pack side.

Archived 2026-09-26: superseded by "the six-pack leaves the repository" (2026-09-19); the swarm launcher is no longer used here.

---

## [decision] 2026-07-20 | canon internal-consistency pass: 4 P6 rows drafted (10.3, 11.3, 12.7, 15.5)

Ran a canon-vs-canon consistency pass (6 read-only agents over the 18 pillars plus the values doc, pillar
PROSE in every-new-project.md vs SUB-CONCEPTS in dos-and-donts.md). 13 pillars and the values-to-pillars
mapping are consistent. Four real issues, drafted as proposed P6 rows in docs/global-rules/proposed-revisions.md:
10.3 (Do says "hand-authored SQL" but the canon's own 10.4 example uses a query builder, db.select().from()...,
an internal contradiction), 11.3 (prose requires alerting on anomalies not only fixed thresholds; the sub has
only budget-tied static thresholds), 12.7 (the prose's "one working language for the whole project" has no
sub-concept; the skill's governance.md already covers it), 15.5 (the TLS-probe example tests only TLS 1.1 while
printing "refuses TLS < 1.2", a real bug). Minor and left as noted: 1.1 naming/logging, 3.8 swap-proofs, 10.6
quarterly floor, 13.4 route-the-fix, 18.1 interview-count (the sub is stricter, not a defect), 12.1b meta. All
four rows are status: proposed, none applied; the matrix is unaffected (all four COVERED today, these are
canon-internal fixes not skill gaps). 12.7 Option A (a new sub-concept) would make the count 116 and cascade to
the matrix/index/drift-gate per-pillar counts.

Archived 2026-09-26: superseded by the two 2026-07-20 resolutions (11.3 and 12.7; 5.3 accepted).

---

## [decision] 2026-07-20 | Phase 4 wired: matrix-drift CI gate (always) + eval-threshold gate (skill PRs)

Two gates close the drift loop. (1) scripts/check-matrix-drift.py holds conformance-matrix.md to the
vendored canon: 115 rows with the canonical per-pillar counts, every id+title verbatim from the index
(rule 12.1), and the canon sha256 pins in the matrix header intact (so changing docs/global-rules/
without re-auditing the matrix fails). Wired as the always-on `matrix-drift` job in ci.yml, with a
--selftest that proves it rejects a retitled row and a corrupted pin. (2) grade.py gained
--min-with-skill / --min-delta (exit non-zero below the baseline), and .github/workflows/eval.yml runs
one eval pass on skill-touching PRs and gates on it (single-pass floor with_skill >= 24/28, delta >=
+4, conservative vs the 3-pass baseline 82/84 +23.8). eval.yml needs the ANTHROPIC_API_KEY secret and
the claude CLI; without the secret it SKIPS rather than blocking, so it is inert until enabled. This is
rule 4.8 applied to the skill itself: a skill edit ships on its eval score.

Archived 2026-09-26: the eval.yml half superseded by "the conformance eval runs locally" (2026-08-30); the drift half is the `matrix-drift` job in `.github/workflows/ci.yml`.

---

## [decision] 2026-07-19 | conformance-eval credible baseline: with_skill 82/84 vs baseline 62/84 (+23.8 pts) on sonnet-5

After fixing the skill-injection bug, the 3-pass replication (60 runs, claude-sonnet-5, 0 failures)
gives the real delta: with_skill 82/84 (97.6%) vs baseline 62/84 (73.8%), +23.8 points, recorded in
scripts/conformance-eval/baseline.md. The skill's wins concentrate on the disciplines a capable base
model forgets unaided: 4.3 test-first (3/3 vs 0/3), 10.9 soft-delete (5/6 vs 0/6), 6.3 PII channels
(15/15 vs 10/15), 10.13 deadlines (12/12 vs 9/12), 10.5 outbox dedup (9/9 vs 7/9), 3.9 AI port (5/6
vs 3/6). Parity on 7.1, 8.5, 10.2, 10.11, 10.12 (both perfect): the base model handles those unaided.
with_skill is near-perfect and stable across passes, baseline lower and flakier. This is the Phase 3
deliverable and Phase 4's gate reference (proposed threshold: with_skill >= 80/84 and beats baseline
by >= 15 pts). Re-baseline when tasks.json or the skill changes materially.

Archived 2026-09-26: superseded by the later baselines in `scripts/conformance-eval/baseline.md`.

---

## [decision] 2026-07-19 | conformance 5.3: caret ranges are right, the canon exact-pins mandate is a P6 defect

Phase 2 judged the skill right and the canon defective on 5.3, so a P6 revision row was recorded
in `docs/global-rules/proposed-revisions.md` and the skill's dependency gate
(`check-package-json.sh`, which bans `*` / `latest` / dist-tags but permits `^X.Y.Z`) was left
unchanged. The canon's exact-pins Do brands `^4.0.0` the DON'T ("resolve to unknown code on every
install") yet its own DO mandates a committed lockfile and `bun install --frozen-lockfile` in CI,
which fix the install regardless of the manifest range, so the stated anti-caret reason is false
under the canon's own required conditions. conformance-matrix.md keeps 5.3 as CONTRADICTS against
the current canon text (honest to the pinned canon) with a pointer to the proposed revision; it
flips to COVERED only if the revision is accepted. Decided with the user (P6 over amend).

Archived 2026-09-26: superseded by "5.3 P6 revision ACCEPTED" (2026-07-20).

---

## [decision] 2026-07-19 | commit identity is the contributor's work email, deliberately; public push approved

Rule 26 separates accidental identity leaks from a conscious choice of attribution. For this
repo the choice is now recorded: all history is authored under the contributor's own work
email, and the contributor explicitly accepts that a public push exposes that address
(decided 2026-07-19, after the question had been re-raised and re-answered across several
sessions because it was never written down). This satisfies rule 26's "your own identity
when you deliberately want attribution" arm; no filter-repo rewrite is wanted. Publish and
push audits must not raise the email exposure as a blocker again. The rule 25 gate is
untouched: each commit and push still needs explicit confirmation, but for the act itself,
not for re-litigating the identity.

Archived 2026-09-26: superseded by "rule 26 final form" (2026-07-19).

---

## [decision] 2026-07-12 | conformance evals are the skill's benchmark

Trigger evals prove the skill LOADS; conformance evals prove the produced code FOLLOWS the rules: each task in `scripts/conformance-eval/tasks.json` runs with-skill and baseline in isolated fixture copies via `claude -p --permission-mode acceptEdits`, then declarative regex assertions grade the output (`grade.py`). First measurement: with-skill 14/14, baseline 11/14; the deltas were exactly the discipline rules (soft delete, POST-not-query, deadline). Rerun with `bash scripts/conformance-eval/run.sh` after any change to SKILL.md's rules or the discipline references.

Archived 2026-09-26: superseded by "the conformance harness has three tiers" (2026-09-03) and "the conformance eval runs locally" (2026-08-30).
