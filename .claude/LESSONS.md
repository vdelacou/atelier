# LESSONS

Append-only journal of mistakes, decisions, and gotchas for this repo. Never rewrite or delete entries; supersede a decision with a newer `[decision]`. Format and triggers: `skills/atelier/references/lessons.md`.

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
