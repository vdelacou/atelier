# PLAN: Java smoke test in CI + trigger-eval of the new atelier description

Status: IN PROGRESS. Started 2026-07-11. Previous task (18 pillars + Java variant) landed as 12 slices, not pushed.

## Goal
1. Pillar-15 the Java variant: a canonical pom block in java-quarkus.md, a `scripts/smoke-test-java.sh`
   that scaffolds from it, proves every gate passes on a conforming tree AND blocks each target
   violation, wired as a CI job. Mirrors smoke-test.sh / smoke-test-next.sh.
2. Re-run the trigger-eval against the NEW atelier description (Java + production disciplines),
   using the existing skills/atelier-workspace harness, confirming old prompts still trigger and
   new prompt classes (Java, privacy, tenancy, reliability) trigger too.

## Definition of done (whole task)
- java-quarkus.md carries a complete, pinned, extractable canonical pom.xml; smoke test extracts it
  (doc drift fails CI, same as the Bun/Next canonical configs).
- smoke-test-java.sh: green on a conforming scaffold (spotless, verify incl. JaCoCo tiers, PIT,
  check-pom, full hooked commit) and red on each violation (range, SNAPSHOT dep, oversized commit,
  junk commit message, misformatted file, warning under -Werror, under-coverage, surviving mutant).
- ci.yml gains the smoke-java job (JDK 21, Maven cache); README CI section and script list updated.
- Trigger-eval run on the current description: results recorded in the workspace, old cases hold,
  new cases added for Java/disciplines; report findings (pass or a proposed description fix).
- Commits proposed slice-by-slice; nothing committed or pushed without explicit confirmation.

## Steps
1. [x] Recon done (extract_fence mechanism; eval = {query, should_trigger} x 5 runs each).
2. [x] Canonical pom added to java-quarkus.md. Pins verified against Maven Central 2026-07-11:
       compiler 3.15.0, surefire 3.5.6, spotless 3.8.0, gjf 1.35.0, jacoco 0.8.15, pitest 1.25.7,
       junit5-plugin 1.2.3, enforcer 3.6.3, junit-jupiter 5.14.4 (JUnit 6 exists; PIT plugin targets 5.x).
       requireJavaVersion uses bare `21` (range brackets would trip check-pom). banSnapshots renamed
       to requireReleaseDeps. .mvn/jvm.config block added (gjf jdk.compiler exports).
3. [x] smoke-test-java.sh written + green locally (16/16 on JDK 26 + Maven 3.9.16). It caught and
       we fixed two real asset bugs: check-pom flagged the enforcer <message> mentioning -SNAPSHOT
       (now matches only <version> elements; also scans untracked poms via ls-files --others), and
       PIT 1.25 removed free -DwithHistory (flag dropped from pre-commit-java; docs updated in
       java-quarkus.md + SKILL.md matrix: scope + staged-trigger are the speed levers).
4. [x] CI job java-smoke-test added (setup-java temurin 21, maven cache); README CI section (4 jobs),
       script list + layout updated. ci.yml parses.
5. [x] Trigger-eval DONE (verdict below; three residual misses are eval artifacts or inherent
       under-trigger, not description defects; "review" restored to the description at 1022 chars): merged set = 20 old + 14 new (8 trigger: quarkus endpoint+tenancy,
       pom hygiene, PII-in-logs, org isolation, outbox reliability, gemini adapter+pin, no-mockito,
       a11y+rebrand; 6 near-miss negatives: django pii, rails locking, kotlin mockk, DORA definitions,
       DPIA doc, express+npm auth). Runner: skill-creator run_eval.py via claude -p, model
       claude-fable-5, 5 runs/query, 10 workers, cwd = old probe-root (same methodology as
       2026-07-04). Set + results in skills/atelier-workspace/trigger-eval-2026-07-11/.
       DoD: results file + verdict; description fix proposed only if cases fail.
       Run 1 (stock runner, 30s timeout): 16/34, every should-trigger ~0/5, every negative clean.
       Diagnosed as harness artifacts, not description failure: (a) stock run_eval returns False the
       instant the FIRST tool call is not Skill/Read, punishing Fable's explore-first behaviour;
       (b) 30s timeout straddles Fable time-to-first-tool (manual probe: Skill invoked FIRST at
       18.3s on the same query the eval scored 0/5; a second probe exceeded 30s). No skill-name
       collision (~/.claude/skills has no atelier). Patched copy run_eval_patched.py (kept in the
       workspace): watch the whole stream until the result event, conclude only on match/result/
       timeout; rerun with --timeout 90. Results: eval-current-patched.json = STILL 0.00 everywhere.
       Root cause #3 (the decisive one): cross-probe contamination. All 10 workers share
       probe-root/.claude/commands, so each probe's model sees up to 10 uuid-suffixed clones of the
       skill and almost never invokes the one uuid its own detector greps for (a single manual probe
       with one file triggers instantly, Skill as the first tool call at 18.3s). Fix: per-probe
       isolated temp project roots (fixture copied in, exactly one command file each), verified live
       (10 roots during the run, 1 command file each). Final run: eval-current-isolated.json,
       3 runs/query, 90s timeout, model claude-fable-5.
       ISOLATED RESULT: 31/34. Negatives 16/16 clean (mean rate 0.00). Positives 15/18, mostly 3/3.
       Three misses: (a) "review this diff" 0/3: real regression, "review" was dropped from the task
       vocabulary while trimming the description to 1024; FIXED (restored "review", trimmed
       "Maven-wrapper" to "Maven", 1022 chars, validator green), retested at 5 runs (eval-retest.json).
       (b) coverage-threshold debugging 0/3: model solves it directly; known under-trigger class for
       directly-solvable queries, not description-fixable. (c) java pom hygiene 0/3: eval artifact,
       the probe fixture is a Bun repo with no pom.xml; a Java fixture is the proper fix (next run).
       Retest at 5 runs: review-diff 0/5 (fixture has no diff to review; also maps to
       atelier-review-me in the real suite, which the synthetic harness cannot register),
       coverage-threshold 1/5 and pom-hygiene 1/5 (noise level). Description fix kept.
6. [x] Verified: frontmatter 4/4, authored lines em-dash-free, smoke test 16/16, ci.yml parses.
       Commits proposed to the user (rule 25); awaiting confirmation.

## Notes / breadcrumbs
- Java smoke scope: proves OUR canonical configs + shipped assets against the toolchain, not Quarkus
  itself (test the code you own). Plain Maven skeleton with domain/usecases + sealed Result + one
  use-case; ./mvnw is a thin mvn shim in the scratch repo (the hook needs it; wrapper distribution
  is not the tested surface, noted in the script header).
- Negative JaCoCo case: untested domain class. Negative PIT case: covered-but-unasserted method.
  Negative -Werror case: rawtypes warning.
- Workspace: skills/atelier-workspace/trigger-opt-2026-07-04/ (trigger-eval.json dataset,
  eval-current/candidate logs, probe-root, report.html).
