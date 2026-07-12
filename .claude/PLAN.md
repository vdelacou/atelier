# PLAN: the atelier roadmap (all open next steps, prioritized)

Status: PROPOSED 2026-07-12. Nothing below is started; each phase lands independently in
green slices. Rounds 1-4 are done and pushed (18 pillars encoded, Java variant, smoke tests
for all three variants, trigger evals 32/34 + companions, conformance evals 13/13 vs 10/13,
rule 27-30 guards, CLAUDE.md seed, committed trigger-eval harness, CI green at ce66856).

## Round 5 progress (2026-07-12, started from "start")
- 1.1 DONE: suite-mode trigger probing (`--suite` + `expected_skill`); routing set 13/13 with
  all four skills registered. Closes both prior artifacts (review-diff, existing-repo eslint).
- 1.2 DONE (committed harness) + PARTIAL (data): `scripts/conformance-eval/` (tasks.json,
  run.sh bash-3.2-safe, grade.py declarative). Clean verdict on the 6 completed tasks:
  with_skill 17/17, baseline 14/17. Deltas were the disciplines: e1 baseline used GET (skill
  POSTed with a deadline), e2 baseline hard-deleted (skill soft-deleted + test). e6 surfaced a
  GRADER false positive (matched a redactEmail helper), retuned. e7-e10 blocked: the `claude -p`
  subagents hit the account monthly spend limit mid-run, so those dirs are empty/partial and
  are NOT counted. Rerun e7-e10 when the limit resets: `bash scripts/conformance-eval/run.sh
  e7-outbox e8-lost-updates e9-migration e10-llm`.
- 1.4 DONE: rule-24 unattended carve-out (new tests may be written headless; existing tests
  stay gated) in SKILL.md rule 24 + Interaction + review-me; e2 pins it with a test assertion.
- 2.3 DONE: `.github/workflows/canary.yml` weekly-runs the Bun smoke test with typescript
  unpinned (SMOKE_TS_SPEC), non-blocking, to signal when the ^5 pin can lift.
- 3.3 DONE: four LESSONS entries (conformance methodology, guards-as-tripwires, single-skill
  probe limitation, pycache).
- 3.4 DONE: description edits gate on the trigger eval (workflow.md + review-me map).
- 2.1 DONE: accessibility gate. eslint-plugin-jsx-a11y (already a devDependency) wired
  error-level on src/components/** in the canonical Next config with the doctrine's
  interaction rules (no-static-element-interactions, click-events-have-key-events,
  interactive-supports-focus, control-has-associated-label, alt-text, anchor-is-valid);
  next/core-web-vitals only enables the recommended subset, which misses the flagship
  clickable-div. smoke-test-next proves it: conforming components lint clean, an inaccessible
  atom produces 3 jsx-a11y findings. atomic-design.md + product.md name the enforced gate;
  contrast/focus-order stay with tokens + review (not lintable), runtime axe noted as optional.
- 1.2 conformance data COMPLETED for e1-e9 (e10 still spend-blocked): reconciled clean verdict
  with_skill 24/25 (96%), baseline 22/25 (88%). Clear skill wins e1 (POST+deadline vs GET),
  e2 (soft-delete+test vs hard delete). One honest skill LOSS e7 (at-least-once status flag
  over an idempotency dedupe key: kept, not massaged). e9 baseline's earlier 0/3 was the
  contaminated empty run; the clean rerun baseline also did expand-contract (3/3). Strong Fable
  baseline conforms on most tasks, so the delta is real but modest and concentrated in the
  PII-channel/soft-delete disciplines. Rerun e10 when the limit resets.
- 2.2 DONE: Java domain assets (Result/Ok/Err/Email.java) shipped under assets/java/, copied
  by the bootstrap checklist and by smoke-test-java (16/16 green) instead of hand-written.
- 3.1 DONE: CHANGELOG.md (keep-a-changelog, 2.0.0 = production-disciplines + Java release),
  README changelog section. Tag v2.0.0 NOT cut (user declined the tag; CHANGELOG stands as the
  release record; tag later if desired: `git tag -a v2.0.0 -m ... && git push origin v2.0.0`).
- 3.2 DONE: repo CLAUDE.md dogfooding the seed, adapted to the skill repo (authoring
  conventions: no em dashes, YAML colon-space trap, description ceiling; structure; verify
  commands; plan-first + commit-slicing + confirmation gates; read LESSONS at start).
- Not yet: 1.3 (multi-model), 2.4 (guard hardening), 4.1 (SonarJS paste: yours),
  e10-llm conformance (spend-blocked).

## How this plan is ordered
Phase 1 deepens MEASUREMENT (extends the "will it respect the guidelines" thread: what we
cannot measure we cannot trust). Phase 2 extends EXECUTABLE coverage (moves more doctrine
into the machine tier). Phase 3 runs the repo AS A PRODUCT (governance.md applied to
atelier itself). Phase 4 tracks EXTERNAL follow-ups. Within a phase, items are independent.

---

## Phase 1: measurement depth

### 1.1 Multi-skill trigger probing (harness enhancement)
- What: extend scripts/trigger-eval/run_eval.py to register ALL FOUR suite skills as
  synthetic commands in each probe root, and detect WHICH one the model invokes. Eval sets
  gain an `expected_skill` field; a case passes when the RIGHT skill wins, not merely any.
- Why: the two annotated artifacts become measurable: "review this diff" should route to
  atelier-review-me (today unmeasurable, scored as an atelier miss), "set up eslint in this
  existing repo" should route to the main skill (today a greenfield false-trigger). This
  measures suite-internal routing, which single-skill probes structurally cannot.
- How: run_single_query writes four command files (stable per-skill uuids), detection
  captures the invoked name and compares to expected_skill; sets updated (atelier-bun.json
  review-diff case moves to expected_skill=atelier-review-me, etc.); rerun all sets.
- DoD: routing verdict table for the whole suite; the two artifacts either pass or become
  real description findings with fixes.
- Effort: half a day (runner change + set updates + one full rerun ~30 min probes).

### 1.2 Committed conformance harness + expanded task set
- What: promote the one-off conformance run into scripts/conformance-eval/ mirroring
  trigger-eval/: fixture(s), tasks.json (task + assertions), a runner that spawns with-skill
  and baseline agents into isolated copies, grade.py, run.sh. Expand from 5 to ~12 tasks:
  a11y component task (Next fixture: clickable-div bait), LLM adapter task (pinned snapshot
  + fake + output checkpoint assertions), expand-contract migration task, logging-PII task,
  outbox task, optimistic-locking task, plus 3 Java-fixture tasks (soft delete via
  @SQLRestriction, REST Assured 404 test presence, no-Mockito).
- Why: conformance is THE metric for the skill's promise; 5 TS tasks is a smoke, not a
  benchmark. Java conformance is currently unmeasured entirely.
- How: subagent runner can be a bash script driving `claude -p` (works headless/CI-less) or
  documented as an in-session Agent-tool procedure; assertions stay scripted greps. Add
  variance: 3 runs per arm per task, report mean pass-rate (skill-creator benchmark style).
- DoD: `bash scripts/conformance-eval/run.sh` produces the graded table; committed; verdict
  recorded; flaky assertions tightened until two consecutive runs agree within 1 assertion.
- Effort: 1-2 days including probe iterations and token spend (~36 agent runs per full pass).

### 1.3 Multi-model robustness matrix
- What: rerun trigger sets and a conformance subset with --model sonnet and haiku tiers.
- Why: evals ran on fable only; the skill ships to whatever model a user runs. Strong-model
  baselines already conform unprompted (e3/e4/e5); the skill's delta is likely LARGER on
  smaller tiers, and trigger rates may drop. Unmeasured today.
- How: TRIGGER_EVAL_MODEL env already supported; conformance runner takes a model flag.
- DoD: per-model verdict table; description or SKILL.md fixes only if a tier regresses.
- Effort: half a day, mostly probe wall-time.

### 1.4 Rule-24 headless policy (finding from conformance transcripts)
- What: decide and encode what TDD's confirmation gate means with no user present: the
  with-skill agents variously wrote tests directly or proposed-then-wrote. Options:
  (a) headless carve-out: write new tests freely, never touch existing ones (rule 24 narrows
  to protection of EXISTING tests when unattended); (b) strict: propose tests in the final
  report only. Recommendation: (a), because (b) makes headless TDD impossible and the rule's
  danger is silent weakening, not creation.
- DoD: SKILL.md rule 24 + Interaction section state the unattended behavior in one sentence
  each; review-me test-integrity lens updated; a conformance assertion pins it.
- Effort: an hour.

## Phase 2: executable coverage extensions

### 2.1 Accessibility gate as a shipped asset (rule 17.6 executable)
- What: an axe-core scan asset for the Next.js variant (script + config: render components
  or built pages, fail on violations), wired into smoke-test-next.sh with a violating
  fixture case (icon button without aria-label) and documented in atomic-design.md/product.md.
- Why: a11y is doctrine + review today; the article demands it in the gate. This is the
  largest discipline still without a machine check.
- DoD: smoke-test-next proves the gate passes conforming components and blocks the bait;
  docs updated; CI green.
- Effort: a day (axe against static export or component render needs a real DOM runner:
  evaluate playwright vs jsdom cost; pick the lightest that works).

### 2.2 Java code assets (parity with the TS asset set)
- What: ship Result.java/Ok.java/Err.java, Email.java (value-record exemplar), and a
  MemoryStore fake exemplar in assets/java/, referenced by the bootstrap checklist instead
  of write-from-doc; smoke-test-java copies them rather than heredocing equivalents.
- Why: pillar 14, artifacts over instructions; today Java bootstrap hand-writes what the
  Bun variant copies.
- DoD: java-quarkus.md checklist copies assets; smoke-test-java green using them.
- Effort: half a day.

### 2.3 TypeScript-pin lift canary
- What: a weekly scheduled CI job (allowed-to-fail / non-blocking) running the Bun smoke
  test with typescript UNPINNED, so the day sonarjs supports TS 7 we notice and lift the pin.
- Why: the ^5 pin is deliberately temporary; without a canary it silently becomes permanent
  (a pinned version rotting in reverse).
- DoD: .github/workflows/canary.yml (schedule, continue-on-error, TS_UNPINNED=1 branch in
  the smoke install line); LESSONS entry updated with the lift procedure.
- Effort: an hour.

### 2.4 Guard hardening from field use
- What: after the guards run in a real repo for a while, revisit patterns: URLSearchParams
  construction (the e1 baseline evaded the query-string regex via `new URLSearchParams`),
  logger metadata keys vs message text, multi-line fetch options. Add cases to the fixture
  battery first, then patterns.
- Why: tripwires earn trust by catching real evasions; e1 already showed one gap.
- DoD: URLSearchParams case added to check-pii-channels + battery; battery stays green.
- Effort: two hours.

## Phase 3: the repo as a product (governance.md applied to itself)

### 3.1 CHANGELOG + release tag
- What: CHANGELOG.md (keep-a-changelog style) summarizing the v2 milestone (18 pillars,
  Java variant, guards, eval harnesses), tag v2.0.0; note the deprecation/versioning policy
  (platform-as-product, 14.3).
- DoD: changelog committed, tag pushed, README points at it.
- Effort: an hour.

### 3.2 Repo CLAUDE.md (dogfood the seed)
- What: a CLAUDE.md for the atelier repo itself: no em dashes anywhere, PLAN/LESSONS
  conventions, commit slicing + confirmation gates, pointer to smoke tests and eval harness
  as the verify commands.
- Why: the skill repo is the one repo where the standard's authoring conventions are not
  yet deterministic context; this session re-derived them from memory files.
- DoD: CLAUDE.md at repo root; next fresh session follows the conventions without memory.
- Effort: an hour.

### 3.3 LESSONS round-4 entries
- What: append [decision] conformance-eval methodology (subagent pairs + scripted greps),
  [decision] guards are staged-diff tripwires with path-convention exceptions,
  [gotcha] single-skill trigger probes cannot measure suite routing,
  [gotcha] git add of a directory sweeps pycache (ignore bytecode).
- DoD: entries appended in strict format; committed.
- Effort: 30 minutes.

### 3.4 Trigger-eval as a description-change gate
- What: document (workflow.md + review-me) that any SKILL.md description edit reruns the
  relevant trigger set before landing, now a one-liner via scripts/trigger-eval/run.sh.
- DoD: one paragraph in workflow.md, one line in review-me's map for SKILL.md files.
- Effort: 30 minutes.

## Phase 4: external follow-ups (tracking, mostly not my keyboard)

### 4.1 SonarJS TS-7 report: YOUR paste
- The draft is ready at skills/atelier-workspace/upstream-drafts/sonarjs-ts7.md; venue is
  https://community.sonarsource.com/ (Report a Bug). Needs your forum account. Until posted
  or fixed upstream, the ^5 pin + canary (2.3) cover us.

### 4.2 anthropics/claude-code#76818: respond if maintainers engage
- Offer the patched run_single_query (now public in this repo at scripts/trigger-eval/
  run_eval.py); link it in a follow-up comment if asked.

### 4.3 Lift conditions ledger
- typescript@^5 pin: lift when sonarjs supports TS 7 (canary 2.3 detects).
- PIT incremental: revisit if PIT's history returns to open source.
- Single-skill probing artifacts: closed by 1.1.

---

## Suggested execution order
1.1 -> 1.2 -> 3.3 (cheap, banks the decisions) -> 2.3 (cheap canary) -> 1.4 -> 2.2 -> 2.1
-> 1.3 -> 3.1 + 3.2 + 3.4 -> 2.4 (after field use). Phase 4 runs in the background of all.

## Standing constraints (bind every phase)
- No em dashes in anything authored; YAML descriptions carry no colon-space.
- Frontmatter validator + relevant smoke test green before proposing any commit.
- Commits sliced small; nothing committed or pushed without explicit confirmation.
- Every new gate proves it can fail (a fixture violation case) before it ships.
- Eval results stay gitignored in workspaces; harnesses and sets are committed.
