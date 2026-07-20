# LESSONS

Append-only journal of mistakes, decisions, and gotchas for this repo. Never rewrite or delete entries; supersede a decision with a newer `[decision]`. Format and triggers: `skills/atelier/references/lessons.md`.

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

## [decision] 2026-07-20 | 5.3 P6 revision ACCEPTED: canon allows caret + committed lockfile; matrix now 115/115 covered

The canon maintainer accepted the 5.3 P6 revision, so the vendored canon changed. dos-and-donts 5.3 (Do,
Don't, TS example) and the pillar-prose companion now allow a constrained range (caret or tilde) plus a
committed lockfile and a frozen-lockfile CI install, instead of mandating exact pins. Canon hashes changed
(dos-and-donts 5d9eb10c -> 3d84cf69, every-new-project 63f7b8d8 -> 1487a91a); conformance-matrix.md pins
the new hashes, flips 5.3 CONTRADICTS -> COVERED, and check-matrix-drift.py passes. Tally now COVERED 112,
STRICTER 3, GAP 0, CONTRADICTS 0 (115/115), work list empty. The skill's dependency gate was UNCHANGED
(check-package-json.sh already permitted caret + lockfile). proposed-revisions.md 5.3 marked ACCEPTED. The
P6 loop closed: the skill exposed a rule defect, the fix went back to the canon, not the skill. When you
edit the vendored canon, update the matrix header pins in the same change or the drift gate fails (by design).

## [decision] 2026-07-20 | optional strengthenings: Java hook split, docs-check + bundle gates, architecture eval tasks

Four strengthenings, each a shipped gate that proves it can fail via the matching smoke test:
- Java hook split (rule 15.1, mirrors the Bun fix): assets/pre-commit-java is now the 4 fast gates
  (size, pom, gitleaks, spotless:check); `./mvnw verify` + PIT moved to a new assets/ci-java.yml.
  Reframed java-quarkus.md + the SKILL variant matrix; smoke-test-java green (fast hook end-to-end,
  verify + PIT still proven directly).
- 12.1 docs-check as a gate: assets/check-docs.sh runs the README's `## Verify` bash block; smoke-test.sh
  proves it passes on a working block and fails on a broken one; governance.md points at it.
- 17.7 bundle budget as a gate: assets/check-bundle-size.sh (gzipped built JS vs BUDGET_KB); smoke-test-next.sh
  proves it on the real static export (under a generous ceiling passes, BUDGET_KB=0 fails); product.md points at it.
- Architecture eval tasks a1-a4 (pillar 3 ports/fakes, branded types, TDD) added to tasks.json, rule-tagged;
  1-pass sonnet-5 validation with_skill 8/9 vs baseline 6/9, skill ahead on 3.2 (port+fake) and 10.13
  (deadline). Full 3-pass re-baseline including them is pending (baseline.md notes it).
Remaining: enable eval.yml with the ANTHROPIC_API_KEY secret; Phase 5 field test.

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

## [gotcha] 2026-07-19 | conformance-eval with_skill arm ran skill-less: nested claude -p sandboxes reads to the run dir

The eval's with_skill prompt told the agent to read SKILL.md at an ABSOLUTE path
($REPO/skills/atelier), but a nested `claude -p` sandboxes Read and Bash to its own working
directory, so that path is unreadable ("permission to read ... was requested but not granted",
confirmed empirically and in the agent's own result.txt). The Skill tool has no atelier entry in
that session either. Net: every with_skill run executed with ZERO skill content, baseline vs
baseline, which is exactly why the first pass showed parity (single run with_skill 23/28 vs baseline
25/28) instead of the skill helping. Both the single run and the 3x sonnet-5 replication
(runs-claude-sonnet-5-r1..r3) are INVALID as skill measurements; discard them. Fix (run.sh): copy the
skill INTO the run dir ($dir/skills/atelier) for the with_skill arm and point the prompt at the
relative ./skills/atelier/SKILL.md; grade.py already excludes the skills/ subtree so injected files
are never graded. Verified: e2-removal-with_skill went 1/3 -> 3/3 (hard db.delete became a rule-30
soft-delete via deletedAt with a test), the agent citing "Rule 30" explicitly. Rule for next time:
an eval that depends on the agent READING a file must inject that file into the sandboxed working
directory, never reference an absolute path outside it, and verify skill loading (does the output
change) before trusting any with_skill vs baseline delta.

## [decision] 2026-07-19 | conformance-eval checks are now rule-id tagged; the scorecard is per-rule

Phase 3 step: every assertion in scripts/conformance-eval/tasks.json carries the global-rules
sub-concept id it proves (its `rule`), and grade.py prints a BY RULE scorecard (with_skill vs
baseline per rule) alongside the per-task and TOTALS lines, so an eval result maps straight to its
conformance-matrix.md row. 28 assertions across 11 rules (3.9, 4.3, 6.3, 7.1, 8.5, 10.2, 10.5, 10.9,
10.11, 10.12, 10.13); grade.py --selftest still green and a synthetic run confirms the rendering.
This is what Phase 4's CI eval-threshold gate reads. The runner (run.sh, `claude -p` per task per
arm) and the 10 discipline tasks (e1-e10) are unchanged; the plan's architecture-focused tasks and a
fresh baseline run are the remaining Phase 3 work.

## [decision] 2026-07-19 | conformance: the five remaining gaps closed as doctrine (5.10, 7.7, 10.14, 12.1, 17.7)

Phase 2 finished by closing the last five matrix work-list gaps, each an added doctrine section
citing its rule id (doctrine counts as COVERED per the matrix convention, as for the org-pillar
rows). 5.10 -> security.md: single filtering edge plus origin-lock, with the x-edge-secret origin
check. 7.7 -> isolation.md: no anonymous service-key bulk route, analytical volume from the data
platform. 10.14 -> reliability.md: OLTP/OLAP separation, ETL/CDC copy, the pipeline as the one
sanctioned bulk reader. 12.1 -> governance.md: a docs-check CI job that runs the README's documented
commands, with scripts/smoke-test.sh as the exemplar. 17.7 -> product.md (mobile-first,
one-primary-action, progressive-disclosure, bundle budget) plus an atomic-design.md note that
breakpoints scale up from the smallest screen. Matrix tally now COVERED 111, STRICTER 3, CONTRADICTS
1 (only 5.3, P6 pending), GAP 0. 12.1 and 17.7 are covered as doctrine that prescribes a gate
(docs-check, bundle budget); shipping those as fixture-tested gates, and splitting the Java
pre-commit-java hook (same 15.1 shape), are the remaining strengthenings.

## [decision] 2026-07-19 | conformance 15.1 + 4.6: pre-commit hook runs the fast gates, CI runs the full set

Phase 2 resolved the 15.1 contradiction: the hook ran the full test suite, coverage, and
1-3 min/file Stryker mutation locally, which the canon confines to CI because a multi-minute
hook trains --no-verify. The canon is right here, so the skill was amended, not the rule.
`assets/pre-commit` now runs only five fast gates (commit-size, package.json, gitleaks protect,
lint:staged, typecheck; each O(staged) or O(1), targeting a ~5s budget), and a new asset
`assets/ci.yml` runs the full set (strict lint, typecheck, test, coverage, mutation
changed-on-PR / full-on-main, bun audit) on a frozen lockfile as the required merge check,
which also closes the 4.6 gap (no consumer CI workflow shipped). New helper
`assets/lint-staged.sh` does the staged eslint. The "eight gates" branding was reframed across
SKILL.md, workflow.md, greenfield, review-me, bun-typescript.md, nextjs-monorepo.md, commit-msg,
and README as "fast hook gates plus the full CI set"; smoke-test.sh now runs the fast hook
end-to-end and the CI gates (mutation included) directly. Measured on a small conforming repo
the fast gates are all sub-2s and even mutation is ~4s/file, but the documented lint:strict ~25s
and mutation 1-3 min/file are the realistic-repo numbers, so the split is by gate nature (scales
with repo size goes to CI), not day-one speed. The Java `pre-commit-java` hook has the same
shape and is NOT yet split (deferred). See conformance-matrix.md 15.1 and 4.6.

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

## [gotcha] 2026-07-12 | PIT 1.25.7 needs a history plugin for ALL incremental; the smoke test beats the docs

Prompted to correct the 2026-07-11 PIT entry, I trusted pitest.org docs (via ctx7) that present withHistory and historyInputFile/historyOutputFile as free, live parameters, and enabled withHistory in the pom. smoke-test-java then failed TWICE: both withHistory=true AND explicit historyInputFile/historyOutputFile error "History has been enabled but no history plugin has been installed/activated" (pointing at Arcmutate's +arcmutate_history). So in PIT 1.25.7 with the base pitest-maven + junit5 plugins, incremental history of ANY kind is gated behind Arcmutate's commercial history plugin; the 2026-07-11 entry was RIGHT. The free speed levers are the narrow scope (targetClasses/targetTests), parallel threads (now added to the pom, a lever the earlier note missed), and staged-file gating; incremental speed at scale means Arcmutate, a licence decision not a library swap. Reverted the withHistory change. Lesson: for toolchain BEHAVIOR, not just API shape, the smoke test is ground truth over the docs; run it before overturning a hard-won gotcha. The challenge to the claim was still worth it, because it forced the empirical check that upgraded the original from asserted to verified and pinned the exact gate (Arcmutate's history plugin, not merely a vague "commercial add-on").

## [gotcha] 2026-07-12 | trigger-eval is high-variance at 3 runs/query; single-run routing verdicts overstate regressions

The committed suite-routing tier finding (13/13 fable to 8/13 sonnet to 4/13 haiku) was single-run per tier. Replicating the Sonnet routing 3 times with the SAME description gave 12/13, 12/13, 12/13, so the 8/13 was one unlucky draw and the real Sonnet routing is about 12/13, near Fable parity. The logs were clean (no probe timeouts), so this is genuine run-to-run variance in whether the model invokes a skill, not a harness fault. The earlier "sharp Sonnet recall regression" was therefore mostly a measurement artifact, and the Haiku 4/13 is likewise a single unverified draw. Rule for next time: a routing/trigger verdict needs replication (at least 3 harness runs, so at least 9 samples per query) before a tier delta is claimed; one 3-runs-per-query pass is too noisy for the routing set. Aside: the grill-me description was restructured trigger-first as a structural-lever test, and a replicated A/B showed a small real lift on its own cases (0.89 to 1.00) with the unedited control flat (0.66 to 0.66) and negatives at 0, so it was kept, but the effect is marginal and the motivating regression was largely noise. Partially supersedes the two tier-finding entries below.

## [gotcha] 2026-07-12 | the skill's conformance delta SHRINKS on smaller tiers (soft-delete collapses)

Firming the earlier noisy n=1 read with 3 runs/task/tier resolved it: the skill helps on both tiers but by less as the tier shrinks, the OPPOSITE of the prior hypothesis that the delta would grow on smaller models. On the e1+e2+e6 overlap the with_skill-minus-baseline delta is Fable +3.0/10, Sonnet +0.67/10, Haiku +0.33/10; adding e10 the subset delta is Sonnet +2.0/13 (with_skill 8.3 vs baseline 6.3) and Haiku +0.7/13 (8.0 vs 7.3). The single-sample "Sonnet delta 0" was bad luck. Driver of the shrink: the soft-delete discipline (e2) collapses on both small tiers EVEN WITH the skill (with_skill e2 pass-count Fable 3/3 to Sonnet [0,1,0] to Haiku [0,0,0]); agents hard-delete regardless. The skill's most robust win is e10, the LLM-adapter port+pin discipline (Sonnet with_skill [3,3,3] vs baseline [2,1,2]). Combined with the trigger under-invoke finding, smaller/faster models both reach for the skill less AND apply its disciplines less thoroughly. Harness: conformance run.sh gained CONFORMANCE_TAG so N variance passes land in runs-<model>-<tag> without overwriting. Supersedes the "conformance across tiers is too noisy to call" caveat in the entry below.

## [gotcha] 2026-07-12 | the trigger contract is tuned for Fable; smaller tiers under-invoke

Running the trigger sets on Sonnet and Haiku (TRIGGER_EVAL_MODEL) showed recall degrading monotonically while precision stayed perfect: atelier-bun 29/31 sonnet to 24/31 haiku, suite-routing 13/13 fable to 8/13 sonnet to 4/13 haiku, and EVERY failure was under-trigger (over-trigger=0 on all sets/tiers). Smaller/faster models invoke NONE rather than the wrong skill; the companion skills (grill-me, greenfield) under-fire hardest. So a description tuned to trigger on Fable is not a guarantee on the tier a user actually runs, and lifting small-tier recall is a recall-vs-precision retune (more assertive descriptions risk Fable false-fires), its own task. Conformance across tiers was measured at n=1 per task and came out noisy (sonnet with_skill 7/13 = baseline 7/13, haiku 9/13 vs 7/13, inconsistent direction), so a tier-trend on the skill's code-quality delta needs at least 3 runs per task before it can be claimed; a spot-check confirmed the noise is real agent variance (sonnet e2 with_skill hard-deleted, no test), not a grader bug. Harness: both run.sh now namespace output by model so tiers no longer overwrite each other.

## [decision] 2026-07-12 | discipline guards catch construction-based evasions, not only literal syntax

The rule-27 pii guard blocked `?email=` in a URL literal but not `new URLSearchParams({ email })`, which builds the same query string, so an earlier e1 baseline slipped PII into a query through the constructor. Added a URLSearchParams-construction pattern and kept it URLSearchParams-specific, so a POST body or FormData carrying email (the correct channel) is untouched; the incremental `.set`/`.append` form stays a review duty, because a line-local grep cannot know a variable is a URLSearchParams. The battery now pins both directions, the constructor evasion blocked and the POST-body form allowed. Rule for next time: a tripwire matching one syntax for a leak must consider the other constructors that reach the same sink.

## [gotcha] 2026-07-12 | the conformance grader must grade the agent's diff, not fixture scaffolding

grade.py graded every file in the run directory, so the fixture's own `src/domain/result.ts` (it defines `Result` and `ok: false`) satisfied the present-mode "failure is a value" assertion for BOTH arms of e1, e5, and e10 regardless of what the agent wrote. The module even computed a FIXTURE_FILES set for exactly this exclusion and never used it. The e10 Sonnet baseline exposed it, returning bare `Promise<string>` that throws on error yet scoring the Result assertion. Fix: grade only files whose bytes differ from their fixture original (agent-created or agent-modified, keyed on content so genuine edits still count), and exclude the `skills/` subtree that older run dirs nested from a transiently polluted fixture. `python3 scripts/conformance-eval/grade.py --selftest` proves it, a pristine fixture copy must score 0, red under the old grader and green now, and it is wired as its own CI job. Re-grading the existing runs moved exactly one cell (e10 baseline 2/3 to 1/3); e1 and e5 baselines were unchanged, so the Fable e1-e9 verdict (24/25 vs 22/25) was honest and only the new e10 row needed correcting. Rule for next time: an eval that seeds a fixture must grade the DIFF from that fixture, or shared scaffolding silently passes assertions for every arm and flatters the weaker one.

## [decision] 2026-07-12 | conformance evals are the skill's benchmark

Trigger evals prove the skill LOADS; conformance evals prove the produced code FOLLOWS the rules: each task in `scripts/conformance-eval/tasks.json` runs with-skill and baseline in isolated fixture copies via `claude -p --permission-mode acceptEdits`, then declarative regex assertions grade the output (`grade.py`). First measurement: with-skill 14/14, baseline 11/14; the deltas were exactly the discipline rules (soft delete, POST-not-query, deadline). Rerun with `bash scripts/conformance-eval/run.sh` after any change to SKILL.md's rules or the discipline references.

## [decision] 2026-07-12 | discipline guards are staged-diff tripwires

The rule 27-30 guards check STAGED ADDED LINES by default (like gitleaks protect), with `--all` for adopt-mode tree audits, and exceptions ride on path conventions (erasure/retention paths, `*contract*` migrations, `*public*`/`*health*` routes), never inline suppressions (rule 15). They are tripwires, not proofs: conservative patterns, review keeps the full duty.

## [gotcha] 2026-07-12 | single-skill trigger probes cannot measure suite routing

A probe registering only one synthetic skill scores "review my diff" as an atelier miss and "set up eslint in this existing repo" as a greenfield false-trigger, because the skill that SHOULD win is not in the model's choice set. Fixed by suite mode in `scripts/trigger-eval/run_eval.py` (`--suite`, cases carry `expected_skill`): with all four registered, routing scored 13/13. Rule for next time: a triggering verdict is only as valid as the choice set the probe shows the model.

## [gotcha] 2026-07-12 | git add of a directory sweeps bytecode

`git add scripts/trigger-eval` happily staged `__pycache__/run_eval.cpython-312.pyc` because nothing ignored it; the repo had never held Python before. When a commit adds a directory wholesale, list what got staged before committing, and extend .gitignore the moment a new language enters the repo.

## [gotcha] 2026-07-12 | typescript 7 crashes eslint-plugin-sonarjs at rule load

The smoke test's unpinned toolchain install pulled TypeScript 7.0.2, and sonarjs (<= 4.1.0, dependency spec `typescript: '>=5'`) crashed ESLint outright: its rules read `ts.SyntaxKind.*` at module scope, and TS 7's module shape breaks the CJS default-export interop (`Cannot read properties of undefined`). `tsc` itself is fine; only programmatic API consumers break. Fix: `typescript@^5` is the one deliberate pin in the smoke-test install (matching the canonical skeleton's `^5.0.0`), lifted when sonarjs supports TS 7. Rule for next time: an unpinned-toolchain canary that fires is a success; respond by pinning the one incompatible dep with a dated reason, not by pinning everything.

## [gotcha] 2026-07-12 | setup-java cache maven requires a pom in the repo

`actions/setup-java` with `cache: maven` fails the job in seconds ("No file matched to [**/pom.xml]") when the repository holds no pom, which is exactly this repo's shape: the smoke test generates its pom at runtime from the reference doc. Drop the cache option; the probe re-downloads plugins each run and that is fine.

## [gotcha] 2026-07-11 | stock trigger-eval runner false-zeros with fable

The skill-creator `run_eval.py` scored every should-trigger case ~0/5 against a previously optimized description. Three compounding causes: it concludes False on the first non-Skill tool call (Fable explores the repo before consulting a skill), its 30s timeout straddles Fable's thinking latency, and, decisively, parallel workers share one probe root's `.claude/commands`, so each probe's model sees N uuid-suffixed clones and almost never invokes the uuid its own detector greps for. A patched runner (full-stream detection, per-probe isolated roots, 90s timeout) lives in the gitignored `skills/atelier-workspace/trigger-eval-2026-07-11/`; with it the same description scored 31/34. Rule for next time: uniform ~0 trigger rates mean harness artifact, not description failure; verify with one manual `claude -p` probe before touching the description.

## [gotcha] 2026-07-11 | pit moved incremental history behind a paid plugin

`-DwithHistory` on pitest-maven >= 1.25 fails the build outright ("no history plugin installed"); the free incremental analysis is gone. The open-source speed levers are a narrow `targetClasses` scope plus running the gate only when staged files touch it, which `assets/pre-commit-java` does. Applies to: any doc or hook that suggests PIT incremental runs.

## [gotcha] 2026-07-11 | -SNAPSHOT grep must match version elements only

`check-pom.sh` originally flagged any `-SNAPSHOT` inside dependency/plugin blocks, which false-positived on the enforcer's own `<message>No -SNAPSHOT dependencies</message>` prose in the canonical pom, blocking a fully conforming commit. The gate now matches `<version>[^<]*-SNAPSHOT` only, and scans untracked poms too (`git ls-files --others`), since a brand-new pom is otherwise invisible before its first commit. Rule for next time: a gate that greps for a token must consider the token appearing in prose about the rule itself.

## [decision] 2026-07-11 | decision records are two-tier

Every significant decision gets a one-line `[decision]` entry here; a choice with rejected alternatives and a reversal path worth keeping (vendor, storage engine, deliberate lock-in) additionally gets a full ADR in `docs/adr/NNNN-title.md`, committed with the change. The atelier-grill-me output is the natural ADR draft. Supersedes the earlier stance that the repo keeps no ADR tree. See `skills/atelier/references/governance.md`.

## [decision] 2026-07-11 | production disciplines are the diff-visible rule tier

The eighteen global-rules pillars split two ways: concerns visible in a diff became hard rules 27-34 (PII channels, tenant isolation, deadlines, data lifecycle, optimistic locking, AI ports, rented auth, synthetic fixtures); organizational pillars (observability, delivery, governance, metrics, product) stay reference doctrine that binds when the concern exists. Rationale: a hard rule must be something an agent can refuse-and-rewrite on sight.

## [decision] 2026-07-11 | java variant is quarkus-flavoured only

`references/java-quarkus.md` mirrors the source articles' Quarkus idiom (Panache, JAX-RS, MicroProfile, Flyway) with a one-line note that Spring translates one-to-one. No separate Spring reference until a real repo demands it (YAGNI).

## [decision] 2026-07-11 | pillar 16 lives in its own metrics reference

DORA, flow metrics, and cost-as-a-metric were split out of `delivery.md` into `references/metrics.md` on review, so the measurement doctrine has its own consult moment instead of hiding inside the deploy file.
