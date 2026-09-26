# LESSONS

Journal of mistakes, decisions, and gotchas for this repo, newest first. Append-only between compaction passes: supersede a decision with a newer `[decision]`; only an approved compaction pass rewrites or retires entries, into `.claude/lessons.archive.md`. Format and triggers: `skills/atelier/references/lessons.md`.

## [decision] 2026-09-26 | a gate that executes documentation is a code channel; pin artifacts, not only versions

The skills.sh audits that `npx skills add` prints (Gen, Socket, Snyk) flagged `check-docs.sh` for running the README's Verify block through `bash -eu -c`: README text had become a second way to run code in CI, and the script's own comment accepted that risk instead of removing it. Canon 12.1 says to run the documented commands, so the fix kept execution and removed the channel: only repo entry points run, as argument lists, and any shell syntax refuses the whole block before anything runs. The gitleaks tarball was pinned by version and installed with `sudo` unverified; the workflows now check its SHA-256, and `check-workflow-assets.sh` fails a release download without a `sha256sum -c` before its first use. The providers re-audit on their own schedule, so the install output lags a pushed fix.

Rule for next time: a check that executes content from a file that is not code is a code channel whatever its comment says, and a pinned version is not a pinned artifact.

## [gotcha] 2026-09-26 | grader defects favour the weaker answer; read the answer before the number

Ten grader defects so far, in the conformance and the review eval alike, and every one favoured the less thorough answer, because a weaker answer says less and gives the instrument less to misread: an exoneration that cites a rule read as an accusation, "rules 3 and 1" cited neither rule, a regex written from the violation matched a conforming `query.byOrg(orgId)`, a hard-delete check read a test fake's `Map.delete`, and the word `eval` was asserted where the run shipped `evals/` with a bar. An absent-mode assertion gets a green fixture from a conforming shape that shares its vocabulary on the day it is written, shares the tripwire's scope (`exclude` the test tier by default), and asserts the shape, not the naming. When a grader and a skill disagree, check first whether the skill told the answer to write the very sentence the grader penalises, and give two numbered lists that share numbers distinct citation forms (`rule N`, `guideline N`). A clean fixture must be clean on every rule, not only on the one it was planted for.

Rule for next time: when an eval reports a false positive or a miss against the skill arm, read the answer before believing the number.
Merges: 2026-09-26 (clean fixture), 2026-09-10 (absent-mode scope), 2026-09-09 (absent-mode regex), 2026-09-03 (vocabulary assertion), 2026-08-30 (review-grader defects).

## [gotcha] 2026-09-26 | both arms dropping at once is the environment, not the doctrine

A real regression moves the skill arm; the unaided arm never reads the skill and cannot regress, so a scorecard where both arms collapse on tasks that just passed is an environmental failure. Seen four times: an expired OAuth session that made every trigger probe, negatives included, read 0.0 (2026-08-29), an overnight `ENOTFOUND` outage (2026-09-04), a revoked CLI token (2026-09-06), and 24 of 42 sessions refused with "API Error: 403 Request not allowed" after midnight (2026-09-20). `grade.py` leaves a dead session (a refusal or transport error on an untouched tree) out of the score instead of scoring it zero, and each new failure text the CLI can leave in `.result.txt` is a shape it has to learn, selftested.

Rule for next time: when both arms drop, read `.result.txt` and run a one-turn probe before reading the doctrine.
Merges: 2026-09-20 (a 403 after midnight), 2026-09-04 (overnight API outage).

## [gotcha] 2026-09-26 | read a tier-1 miss against variance and session budget before the doctrine

One opus generation of a completeness task drops a noun a few percent of the time and the frozen unaided arm moves two or three points between passes, so a miss on a rule the diff touched is the finding and a miss on a rule it did not touch is rerun twice before it is called anything (a 43/47 pass read 12/12 and 12/12 on rerun). Flickering assertions track session budget first: the failing h7 generations wrote 24 to 27 files against 32 to 41 for the passing ones, and the first pre-registered ablation (five generations per side) returned a null. Every cap the harness applies is an instrument parameter: the 60-turn cap bound for the first time in the 2.4.0 pass and read like a regression until a 120-turn rerun finished the same tasks with full marks.

Rule for next time: read the turn census, file count and transcript (`turns=N`, `.transcript.jsonl`) before writing a doctrine fix, and credit an edit only by ablating one rule on the task it governs.
Merges: 2026-09-19 (turn cap), 2026-09-04 (pre-registered ablation), 2026-09-03 (tier-1 miss on an untouched rule).

## [gotcha] 2026-09-26 | running the conformance harness: dry-run the selector, tag a second run, never edit it mid-run

Dry-run `select-tasks.py --since <ref>` before `run.sh` and read its stderr: a comment that names a rule selects that rule's tasks, and any hunk in `workflow.md` selects rules 19 and 23-26 through the trigger table; kill an over-selected run by process group (`kill -TERM -- -<pgid>`), since `run.sh` forks one subshell per job. A second run on the same day needs `CONFORMANCE_TAG=<name>`, because `run.sh` wipes each task directory of the day's runs dir before running it. bash reads a running script lazily, so an edit to `run.sh` mid-run killed a pass after 18 of 21 tasks with a syntax error; copy a long-running script aside or finish the edits first, and check `done:` lines against run dirs before freezing anything.

Merges: 2026-09-08 (rule range in prose), 2026-09-03 (bash reads a running script lazily).

## [gotcha] 2026-09-26 | the evals catch regressions, not improvements; credit a doctrine edit by ablation

Every instrument here saturates on the skill arm: conformance reads near 100 percent pass after pass, harder trap prompts did not move the ceiling, and the pairwise judge handed skill against no-skill answers 7-0 as uninformatively as a grader answers 24/24. The judge's real use is A/B-ing two skill versions on one task (`CONFORMANCE_SKILL_PATH`, `judge.py --ab`); its first readings sat within generator variance, and position bias shows exactly at the near-tie, so report inconsistency per comparison. The regression half works, once the skill is proven loaded: compressing SKILL.md from 570 to 194 lines lost two nouns that tier 1 caught, and a with_skill arm that could not read an absolute path from its nested `claude -p` sandbox read as parity until `run.sh` copied the skill into the run dir. The skill's delta shrinks on smaller models, and only a consumer repo measures the standard against time, as the 2026-08-30 field test did.

Rule for next time: to credit a doctrine edit, ablate one rule's text and measure the task it governs with several generations per side.
Merges: 2026-08-30 (conformance ceiling, judge's value, doctrine A/B, delta below variance, Phase 5 field test), 2026-07-19 (with_skill arm ran skill-less), 2026-07-12 (delta shrinks on smaller tiers).

## [gotcha] 2026-09-26 | a trigger verdict is only as valid as the choice set the probe shows the model

Uniform zeros mean the harness, not the description: the stock runner stopped at the first non-Skill tool call, timed out at 30 s and shared one `.claude/commands` across workers (the patched `run_eval.py` fixes all three), and an expired OAuth session makes the negatives read 0.0 too, so a pass count equal to the negative count is the auth tell. Measure routing with the whole suite registered (`TRIGGER_EVAL_SUITE`), from a fixture that matches the query's premise (`probe-root-journal` carries a journal for the distill set), and keep user-level skills out: with the suite installed under `~/.claude/skills`, the model invoked the real skill beside each synthetic clone and routing read 5/15 on correct routes until the runner passed `--setting-sources project,local`. The contract is tuned for the top tier: smaller tiers under-invoke (every failure a none, never a wrong skill), and one 3-runs-per-query pass is too noisy to claim a delta.

Rule for next time: before touching a description, run one probe by hand and read the `Skill` tool_use in its stream-json.
Merges: 2026-07-12 (high variance, tuned for Fable, single-skill probes), 2026-07-11 (stock runner false-zeros).

## [gotcha] 2026-09-26 | the environment is an input: a gate proven on one machine is proven on that machine

macOS BSD `awk -v pat='\\.'` delivers `.` to the program, so regexes live as awk literals in the program text; zsh does not word-split an unquoted variable and has no `PIPESTATUS`. A pipe to `tail` returns tail's status, so `check-citations.py | tail -1` hid a failure for a slice; verification chains are `&&` sequences where the verifier's own exit status decides. A selftest that shells out to the gate under test inherits the CI job's environment (`GITHUB_EVENT_NAME=push` sent the em-dash gate down its range branch), so it runs the gate with `env -u GITHUB_EVENT_NAME -u GITHUB_BASE_REF -u GITHUB_EVENT_BEFORE`.

Rule for next time: reproduce a CI-only red by exporting the job's environment locally, and run a shell gate under both bash and zsh before calling it portable.
Merges: 2026-09-03 (BSD awk -v, pipe to tail, selftest environment).

## [decision] 2026-09-26 | a gap closes as canon, rule, gate and red fixture, probed on the toolchain first

Every gap closed between 2026-09-06 and 2026-09-19 went the same way: take the enforcement claim (the SKILL.md table of what applies where, a rule's "lint-enforced", a reference's "the check is"), probe it in a scratch tree on the real toolchain with one violation per rule and the fixture trees included, and only then write doctrine. The closure is a canon sub-concept if missing, a hard rule if missing, the gate in its family's shape (staged lines in the hook, `--all` in CI, copied by every variant's checklist, which `check-workflow-assets.sh` enforces), a red fixture per variant proven through the hook, then tier 1. The probes kept changing the design: PMD's own `AvoidPrintStackTrace` fired on nothing, ArchUnit fails an empty layer unless `withOptionalLayers(true)`, and "optional gate" turned out to mean "inert where the concern is absent", so three tripwires went on by default. A rule that is only a table row and a habit is not a rule; the gate that fails is what makes it one.

Merges: 2026-09-19 (rules 4 and 20), 2026-09-10 (three tripwires default), 2026-09-09 (rule 26 tripwire, rule 37 in Next), 2026-09-08 (rule 5, rule 15 Java and lint, Java mock ban, rule 37 Java, style rules and rule 37), 2026-09-06 (random order).

## [gotcha] 2026-09-26 | how a gate lies: proofs that were green for the wrong reason

A red fixture proves a gate only when it greps the rule's own tag (a formatting slip also exits non-zero), plants the route real code takes (the transitive `quarkus-junit5-mockito`, not only `mockito-core`), uses the idiom the reference teaches (the smoke fixture satisfied `sonarjs/function-return-type` with literals where consumers return through `ok()`), lives inside every later block that replaces the rule's options (ESLint keeps only the last matching block's), and cleans up exactly the files it created; walk the old gates through each new red-fixture helper, since the mock ban had never been seen red. The logic traps: an empty string equals nothing and passed as a pin, a grepped token appears in prose about the rule (`-SNAPSHOT` in the enforcer's own message), human-readable output carries defaults on failure (openssl's `Protocol` line on a refused handshake, so key on the exit status), a `git diff` scope ignores untracked files and `|| true` after a failing first command turns a dead base ref into a pass, a check that reads a sample must say so, and a leak has more than one constructor (`new URLSearchParams({ email })`). A ban on a tool's own suppression cannot live in that tool (`@SuppressWarnings("PMD")` silences the PMD rule that flags it), and for toolchain behaviour the smoke test outranks the docs.

Merges: 2026-09-08 (blank pin, oldest gate never red), 2026-08-30 (check-skill-pin, smoke fixture -A), 2026-08-29 (diff-derived scope), 2026-07-20 (openssl), 2026-07-12 (construction-based evasions, PIT history), 2026-07-11 (-SNAPSHOT grep).

## [gotcha] 2026-09-26 | when the unpinned toolchain contradicts the standard, turn the rule off and re-probe it; do not pin the world back

Three times the unpinned toolchain broke a conforming tree: TypeScript 7 crashed `eslint-plugin-sonarjs` at rule load (the smoke install pins `typescript@^5`), and sonarjs 4.2 flagged the branded-type doctrine (`no-useless-intersection`, `null-dereference`) and every `ok()`/`err()` return (`function-return-type`), in the type-aware lane only. Each time the answer was one dated pin or one rule off with its reason in the canonical config, plus a weekly canary that re-probes it (`canary.yml`, `SMOKE_SONARJS_PROBE=1`), because sonarjs 4.1.0 does not even load under ESLint 10 and pinning it back would have dragged every other pin with it.

Rule for next time: when a linter contradicts the standard, check that correct code can satisfy the rule at all and that the downgrade path loads; a noisy tool gets narrowed, a tool wrong about mandated doctrine gets turned off and re-probed.
Merges: 2026-09-05 (function-return-type, decision and gotcha), 2026-08-29 (sonarjs 4.2.0), 2026-07-12 (typescript 7).

## [decision] 2026-09-19 | the six-pack leaves the repository

At the owner's request the six-pack went: `packs/six-pack/`, `get-atelier-six-pack`, `scripts/check-six-pack.sh` and its CI job, the swarm-forge block of `.gitignore`, the README's six-agent sections and the CLAUDE.md bullets. The 2.2.0 changelog entry stays (Keep a Changelog records what shipped), and the pack's journal entries now sit in `.claude/lessons.archive.md`.

Rule for next time: a removal is a census first (`git grep` the name across the tree, the lock, the workflows and the ignore file), then one commit that deletes the artifacts and every current-state mention together, leaving history untouched.

## [decision] 2026-09-09 | the README is a pitch written from scratch; the gate copy block lives in the bootstrap checklists

The owner asked for the README deleted and rewritten from scratch with a marketing mindset; a first pass that reshaped the old one and carried blocks through verbatim came back with "i asked you to rewrite from scratch". From scratch means every section is new copy and no block is pasted through: the copy block's one technical consumer (the Bun smoke test replays it) was served by moving the block into each variant's Bootstrap checklist and repointing the smoke test's header, not by keeping it. Numbers in the pitch come only from files in the repo (the conformance and review `baseline.md`, the matrix and citation counts). Supersedes the 2026-09-06 README decision.


## [gotcha] 2026-09-03 | a compressed checklist drops the nouns the eval asserts

Cutting SKILL.md from 570 to 194 lines kept every hard-rule noun in the one-liners, yet h4 lost its cross-tenant 404 test and h6 its eval gate in three reruns out of three. The one item that had carried them was the after-change checklist's per-discipline list ("ships its cross-tenant 404 test (28)", "its eval run (32)"), compressed into "each with the concrete check its rule states". A rule stated once in the rule list is not the same as the same rule stated at the moment of checking; the compact list is back. Also honest: h4 is a list endpoint, so a forged-id test returning the caller's own rows is a defensible answer the 404 pattern does not credit.

## [decision] 2026-08-30 | the conformance eval runs locally, never in CI

`eval.yml` gated skill PRs on one eval pass but needed an `ANTHROPIC_API_KEY` secret, skipped without it, and never once ran: a gate that looked wired and was inert. The owner's call: no eval in CI; the evals are a pre-land step on the author's machine, where the `claude` OAuth session pays for the runs, and `baseline.md` carries the commands. What stays in CI is the cheap half, the grader selftests and `check-matrix-drift.py`.

Rule for next time: a gate that cannot run where it is installed is a reminder, not a gate; give it what it needs or move it to where it runs.
