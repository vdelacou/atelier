# Lessons archive

Entries a compaction pass retired from `.claude/LESSONS.md`, verbatim, newest first, each followed by the line that says why it left. Nothing reads this file at session start; grep it when a question needs the history. Format and rules: `skills/atelier/references/lessons.md`, Compaction pass.

---

## [gotcha] 2026-09-08 | a range pinned at one end is a point

The citation lock pinned the start of every `file:N-M` range and nothing else. A preview of the 56 ranges before widening it found two ending on a blank line and three inverted, end before start (`testing.md:184-127`, `security.md:227-217`, `testing.md:649-531`): every hand re-anchor of the day had moved `file:N` starts by snippet and never touched the `-M`, so the ends drifted for weeks and the gate, which only ever read N, called them intact. Both ends are pinned now, the selftest drifts an end line and requires the red, and the five ranges were repaired against the section text they meant (rule 16 and 17 for the Result row, the whole zero-warnings section for 15.3, the regression, baseline and bypass sections for 4.3, 5.7 and 15.4, the last one two citations that had been fused). Rule for next time: a re-anchor that rewrites a citation must rewrite the whole citation, and the next harness slice is a `--reanchor` mode in the gate itself, since today's hand scripts did the job eight times and missed the ends every time. Landed the next morning: `--reanchor` maps every lock key independently, so a range moves as two points, rewrites the citation tokens with a single regex substitution over each source, and locks only when every snippet resolved to exactly one line; rehearsed on a scratch copy of the repo with one line inserted at the top of SKILL.md, 17 failing citations became 233 intact with only the SKILL.md numbers touched.

Archived 2026-09-26: graduated, `scripts/check-citations.py` pins both ends of a range, and `CLAUDE.md:32` documents `--reanchor`.

---

## [decision] 2026-09-08 | the tier-1 selector measures changed references, not changed lines

Fixing the "(1-37)" over-selection found three defects, not one. The count: a range from rule 1 over at least half the set is the size of the rule list (red flags, pointer block) and names no rule; it is reported and skipped. The ceiling: `MAX_RULE = 35` was a constant, so "rule 36" and "rule 37" in a changed line had selected nothing since rule 36 landed; the ceiling is now the highest number in the hard-rules section. The line: the selector read every reference on a changed line, so editing the count on the red-flags line selected the discipline tier through its unchanged "(27-34)"; it now takes, per hunk, the symmetric difference of the references in the removed and the added text. Per hunk and not per file, because the first draft cancelled a genuinely new "(hard rule 13)" in the mock-ban message against a rewritten bullet elsewhere in the same file that had named rule 13 before and after. Each fix has a selftest case, and each case was run against a copy with that fix reverted to see it fail. The lint-gates diff of the morning selects 5 of 21 under the new selector. Rule for next time: a selector that reads lines will select on context; diff the references, not the text.

Archived 2026-09-26: graduated, `scripts/conformance-eval/select-tasks.py:19` (count ranges ignored, references diffed per hunk, selftested).

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

## [decision] 2026-09-03 | em dashes are a gate, not a convention

The authoring rule "never use em dashes" had held for the canon and this journal and failed for the skill: 83 in SKILL.md alone, 300-odd across skills/ and README, because a rule only a reviewer checks drifts the moment the reviewer is the same model that writes the prose. `scripts/check-no-em-dash.sh` now runs first in the pre-commit hook (staged diff), in CI (pushed range) and under `--selftest`; the sweep went in five slices before any doctrine edit so the diffs stayed readable. In a worktree the hook only bites after merge, since `core.hooksPath` points at the main checkout; CI covers the gap.

Archived 2026-09-26: graduated, `CLAUDE.md:8` and `scripts/check-no-em-dash.sh`.

---

## [gotcha] 2026-09-03 | the commit-message gate was vacuous on a push to main

`check-commit-messages.sh` walked `origin/main..HEAD`, which is empty on a push to main, so the gate printed "no commits in range" and passed every message. The push path now takes `github.event.before` through a `GITHUB_EVENT_BEFORE` job env (the zero SHA of a new branch falls back to `HEAD~1..HEAD`); the same default went into `check-commit-range.sh` and the em-dash gate. The red fixture that proves it is a `wip:` commit with `refs/remotes/origin/main` pointed at HEAD.

Archived 2026-09-26: graduated, `skills/atelier/assets/check-commit-messages.sh:19` (`GITHUB_EVENT_BEFORE`).

---

## [decision] 2026-09-03 | boundary factories return Result, constructors assert

The branded factory threw while rules 16-17 and eval task a2 wanted a `Result`, and Money was integer cents in one reference and a float in four. The form is two-tier, mirroring `assets/java/Email.java`: `parseX(raw)` returns `Result<X, XError>` and is the only entry for untrusted input; `x(value)` asserts and throws as a programmer-bug check for values already proven. Sink guards became `parseSafeUrl` and `parseSafePath`; Money is `{ cents, currency }` with one canonical copy in object-design.md.

Archived 2026-09-26: graduated, `skills/atelier/references/result-type.md:36`.

---

## [gotcha] 2026-09-03 | re-anchor citations per slice, never in bulk

`citations-lock.json` pins the first 72 characters of every `file:line` the matrix cites, so any slice that moves or rewrites a pinned line breaks V3. A bulk `--lock` at the end would have blessed wrong lines silently; the discipline that worked was a snippet-matching re-anchor per slice (same file, rule-number or heading prefix when the line was rewritten, cross-file when the text moved), exiting non-zero on anything ambiguous, and only then `--lock`. Rewriting a pinned line in place is a re-lock, not a move.

Archived 2026-09-26: graduated, `CLAUDE.md:32` (`--reanchor`).

---

## [decision] 2026-08-30 | the Java variant never saw its own tripwires

All four discipline tripwires ship Java detection (ROUTE_GLOBS_JAVA, @QueryParam, HttpClient, deleteById), but java-quarkus.md named none of them, so a Java bootstrap followed verbatim copied zero of the four. The capability existed and the install path hid it, the same shape as the field test's other findings. Fixed by adding them to the Java asset list with their Java triggers and proving all four in smoke-test-java (six new checks, red on the violation, green on the fix). Rule for next time: an asset that handles a variant is not shipped to that variant until the variant's bootstrap names it.

Archived 2026-09-26: graduated, `skills/atelier/references/java-quarkus.md:419` copies the tripwires; `scripts/check-workflow-assets.sh` enforces the copy.

---

## [decision] 2026-08-30 | staleness is now a gate, and the size rule got its CI half

Two gates from the field test's findings. check-commit-range.sh walks every non-merge commit in a pushed range against the same <=10 files / <=300 lines cap the hook applies to one staged diff: the size gate's --no-verify-proof half, exactly what check-commit-messages.sh is to the commit-msg hook, adopted from the consumer that had written it independently. check-skill-pin.sh compares a vendored SKILL.md against upstream and fails when it is behind; it rides in audit.yml beside the CVE scan rather than blocking commits, because upstream doctrine changes independently of your diff, and it degrades when it cannot reach upstream while saying plainly that unverified is not current. Proven on the real stale consumer copy before shipping.

Archived 2026-09-26: graduated, `skills/atelier/assets/check-skill-pin.sh` and `check-commit-range.sh`.

---

## [gotcha] 2026-08-30 | line-referenced evidence rots in bulk; one day of insertions broke 38 citations

The full-repo audit found 27 HIGH + 11 MED stale `file:line` citations in conformance-matrix.md, nearly all from the same day's canon and reference insertions shifting everything below them. Worse, the shipped `assets/ci.yml`/`ci-java.yml` would fail in any consumer repo (bare `gitleaks`, no install step; a CI script the Java bootstrap never copies) and no gate ever caught it, because nothing executes the workflow assets: gates never seen red, exactly canon 15.10. Two gates added, each proven red before the fix landed: `scripts/check-citations.py` pins every cited line's content in `citations-lock.json` (verify/`--lock`/`--selftest`), and `scripts/check-workflow-assets.sh` lints the shipped workflows (referenced scripts must ship in assets/ and be copied by the variant's bootstrap reference; non-preinstalled binaries need an install step). Rule for next time: evidence cited by line number is a liability without a content pin; and an asset nothing executes is untested code, however green the repo looks.

Archived 2026-09-26: graduated, `scripts/check-citations.py` with `citations-lock.json`, and `scripts/check-workflow-assets.sh`.

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

## [decision] 2026-07-19 | rule 26 final form, identity in commit metadata only, never in file contents

Three same-day iterations converged here. The standard first treated attribution as a leak
(pre-publish identity audits, an identity red flag), then flipped to "identity is normal,
anonymity is an up-front opt-in", then dropped the opt-in too. The final rule splits by
location: contributor identity in commit metadata is normal, public by design, and never a
finding, an audit item, or a publish blocker; file contents are the opposite, no tracked
file ever names a person, an employer, or a client (neutral handles like `atelier` where a
holder string is required; CODEOWNERS and .mailmap exempt as metadata in file form). There
is no per-repo identity decision left to make. Enforcement moment is review (review-me's
universal checks); scrubbing after a push stays a gated filter-repo rewrite that leaves
cached commits exposed. Supersedes the entry below, whose own naming of the contributor
showed the problem: the acceptance it records stands for commit metadata, and its wording
is redacted at tip to conform (pushed history keeps the original, accepted as exposed).

Archived 2026-09-26: graduated, `skills/atelier/SKILL.md:62` (rule 26) and `skills/atelier/assets/check-identity.sh`.

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

## [gotcha] 2026-07-12 | the conformance grader must grade the agent's diff, not fixture scaffolding

grade.py graded every file in the run directory, so the fixture's own `src/domain/result.ts` (it defines `Result` and `ok: false`) satisfied the present-mode "failure is a value" assertion for BOTH arms of e1, e5, and e10 regardless of what the agent wrote. The module even computed a FIXTURE_FILES set for exactly this exclusion and never used it. The e10 Sonnet baseline exposed it, returning bare `Promise<string>` that throws on error yet scoring the Result assertion. Fix: grade only files whose bytes differ from their fixture original (agent-created or agent-modified, keyed on content so genuine edits still count), and exclude the `skills/` subtree that older run dirs nested from a transiently polluted fixture. `python3 scripts/conformance-eval/grade.py --selftest` proves it, a pristine fixture copy must score 0, red under the old grader and green now, and it is wired as its own CI job. Re-grading the existing runs moved exactly one cell (e10 baseline 2/3 to 1/3); e1 and e5 baselines were unchanged, so the Fable e1-e9 verdict (24/25 vs 22/25) was honest and only the new e10 row needed correcting. Rule for next time: an eval that seeds a fixture must grade the DIFF from that fixture, or shared scaffolding silently passes assertions for every arm and flatters the weaker one.

Archived 2026-09-26: graduated, `scripts/conformance-eval/grade.py:165` (a pristine fixture copy scores 0, selftested).

---

## [decision] 2026-07-12 | conformance evals are the skill's benchmark

Trigger evals prove the skill LOADS; conformance evals prove the produced code FOLLOWS the rules: each task in `scripts/conformance-eval/tasks.json` runs with-skill and baseline in isolated fixture copies via `claude -p --permission-mode acceptEdits`, then declarative regex assertions grade the output (`grade.py`). First measurement: with-skill 14/14, baseline 11/14; the deltas were exactly the discipline rules (soft delete, POST-not-query, deadline). Rerun with `bash scripts/conformance-eval/run.sh` after any change to SKILL.md's rules or the discipline references.

Archived 2026-09-26: superseded by "the conformance harness has three tiers" (2026-09-03) and "the conformance eval runs locally" (2026-08-30).

---

## [decision] 2026-07-12 | discipline guards are staged-diff tripwires

The rule 27-30 guards check STAGED ADDED LINES by default (like gitleaks protect), with `--all` for adopt-mode tree audits, and exceptions ride on path conventions (erasure/retention paths, `*contract*` migrations, `*public*`/`*health*` routes), never inline suppressions (rule 15). They are tripwires, not proofs: conservative patterns, review keeps the full duty.

Archived 2026-09-26: graduated, `skills/atelier/references/workflow.md` (the tripwire sections) and `assets/check-disciplines.sh`.

---

## [gotcha] 2026-07-12 | git add of a directory sweeps bytecode

`git add scripts/trigger-eval` happily staged `__pycache__/run_eval.cpython-312.pyc` because nothing ignored it; the repo had never held Python before. When a commit adds a directory wholesale, list what got staged before committing, and extend .gitignore the moment a new language enters the repo.

Archived 2026-09-26: graduated, `.gitignore:28` (`__pycache__/`).

---

## [gotcha] 2026-07-12 | setup-java cache maven requires a pom in the repo

`actions/setup-java` with `cache: maven` fails the job in seconds ("No file matched to [**/pom.xml]") when the repository holds no pom, which is exactly this repo's shape: the smoke test generates its pom at runtime from the reference doc. Drop the cache option; the probe re-downloads plugins each run and that is fine.

Archived 2026-09-26: graduated, `.github/workflows/ci.yml:65`.

---

## [gotcha] 2026-07-11 | pit moved incremental history behind a paid plugin

`-DwithHistory` on pitest-maven >= 1.25 fails the build outright ("no history plugin installed"); the free incremental analysis is gone. The open-source speed levers are a narrow `targetClasses` scope plus running the gate only when staged files touch it, which `assets/pre-commit-java` does. Applies to: any doc or hook that suggests PIT incremental runs.

Archived 2026-09-26: graduated, `skills/atelier/references/java-quarkus.md:400` (Arcmutate's `+arcmutate_history`).
