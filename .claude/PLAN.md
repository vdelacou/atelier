# Plan: cut 2.2.0, with the README made readable first (2026-09-06)

Goal: the 2.2.0 release (the six-pack release) with a README a newcomer understands in one
screen: what atelier is, what it changes in the code an agent writes, and how to use it, alone or
as the six-pack. The two redirect stubs due for removal go, the tier-2 pass runs before the tag,
and consumers get an "Upgrading from 2.1.0" list.

Definition of done (whole task): README's first screen carries the value and two copy-paste
quick starts; `references/tdd.md` and `references/class-to-module.md` are gone and nothing
points at them but CHANGELOG history; CHANGELOG has `[2.2.0]` with an upgrade list and README
names 2.2.0; tier 2 (both arms, 21 tasks, opus) is recorded in `baseline.md` at or above the
2.1.0 skill arm (59/61) or with every miss explained by the variance rule; CI nine jobs green
on the push; annotated tag `v2.2.0` after the pass, as `v2.1.0` was after b1ac83a.

Facts (verified 2026-09-06): README is 431 lines; the value proposition is a two-line intro,
then a 98-line skill catalogue (use-when bullets, the pillar table, the reference list) before
any quick start; the six-pack quick start sits at line 105-140, Installation at 140-250, Usage at
269-289, and a 108-line repository layout tree follows. The stubs are pointed at only by
README.md:367 and :387 (tree lines) and CHANGELOG.md:59 (2.1.0 history); citations-lock.json,
SKILL.md, scripts/ and the eval sets never name them. The frozen baseline (2026-09-04, opus, 3
passes) is keyed to tasks.json, which is unchanged, so no re-freeze is due. No SKILL.md
description changes are planned, so the trigger eval is not owed. smoke-test.sh:62-76 hand-copies
the README's Bun install steps; the two must stay in agreement.

1. [x] (reviewed section by section 2026-09-06; three commits) README, the fold. Reshape, not rewrite; keep every fact and the existing voice. First
       screen (about 60 lines): one paragraph on what atelier is; the value in concrete terms,
       what the agent refuses and what it does instead (lift the five bullets from Usage: no
       class/function/interface/console, test first, branded primitives, the disciplines,
       LESSONS); then two quick starts side by side, single agent (`bunx skills add`, the
       pointer block, one example prompt) and six-pack (the existing clone + installer + `./swarm`
       block, "write a card, approve the spec"). Install simply: the single-agent quick start
       is three commands at most (install the skills, seed the pointer block, ask), and the
       gates are the agent's job, not a 50-line copy block: a new repo asks for
       atelier-greenfield (it copies the assets and wires the hooks), an existing one asks for
       atelier-review-me adopt mode (its first slice installs the gates and the pointer block).
       The manual gate block survives as "By hand", below, since smoke-test.sh:62-76 mirrors it.
       Guided-review decision: whether a `get-atelier` installer (the single-agent twin of
       `get-atelier-six-pack`: copy the assets, wire the hooks, seed the block) should replace
       that appendix; default is no new tooling in this release. Six-pack, the operator's loop:
       a "Your first card" walkthrough of about 15 lines right after the six-pack quick start,
       since neither README nor the pack manual says what the operator does once `./swarm` runs:
       where the card is written (the dashboard's New Task form and its address after
       `./swarm`), one example card in full (the invoice-totals card of the first run, from
       six-pack-live's `docs/specs/` and `tasks/`), how the Attention approval of the spec is
       given and where it appears, how a clarification reaches the operator and how it is
       answered, how Done shows and where the spec, the verdict and the LESSONS append land,
       then push; plus one line on stopping and restarting the swarm. Take the mechanics from
       SwarmForge's own README (unclebob/swarm-forge, the dashboard and board) and the first
       run's paper trail in `~/Documents/CODE/six-pack-live`; verify any step the sources
       leave implicit on a throwaway project before writing it, never from memory. The pack
       manual keeps the details and gains nothing it does not already say. Everything else moves below: the four skills
       with their use-when, the pillar table under one heading that links to SKILL.md, the
       six-pack roles and the measured run, the gate scripts (Installation step 2), the pointer
       block section. Repository layout, Repository CI and Variant references go last under one
       "Working on this repository" heading (splitting them into CONTRIBUTING.md is a guided-review
       decision, not a default). DoD: `sed -n 1,60p README.md` answers what, value, how for both
       paths with no forward reference; the single-agent quick start is at most three commands
       and names where the gates come from; the "Your first card" walkthrough covers card, Attention,
       clarification, Done and push in order, with every mechanical step verified against the
       runtime or a live run; each install command appears once; the Bun install block
       still matches smoke-test.sh:62-76 line for line; the em-dash gate and the links resolve
       (`grep -o '](\S*)' README.md` targets exist); the guided section-by-section review ran
       before the commit, one decision question per section (memory: guided review before
       landing). Commit in gate-1 slices if the moves exceed 300 lines: one slice per section move.
2. [x] Remove the stubs. `git rm` `references/tdd.md` and `references/class-to-module.md`; drop
       README's two tree lines; CHANGELOG Unreleased gains a Removed entry naming both and the
       files that hold their content (`testing.md`, `design-patterns.md`); the 2.1.0 entry stays.
       DoD: `grep -rn 'tdd\.md\|class-to-module\.md' --include='*.md' --include='*.json'
       --include='*.sh' --include='*.ts' --include='*.py' .` returns CHANGELOG lines only;
       `python3 scripts/check-citations.py` 160 intact; `bun run scripts/validate-frontmatter.ts`
       4/4; `bash scripts/check-workflow-assets.sh` green.
3. [x] CHANGELOG and README name the release. Unreleased becomes `[2.2.0] - <date>` with a
       one-paragraph lead (the six-pack release: the standard as a team of six, its first
       measured run, the third re-probed sonarjs rule) and "Upgrading from 2.1.0": re-extract
       `eslint.config.js` (function-return-type off), re-copy `assets/claude-md-pointer.md`
       (rules 1-35), copy `check-commit-messages.sh`, `check-commit-range.sh` and `audit.yml` if
       the old README install block skipped them, re-point any pinned path at the two removed
       stubs, and the six-pack install for those who want the pipeline. README's "current
       release" line (now 429) says 2.2.0 with the same lead. DoD: headings follow Keep a
       Changelog; the em-dash gate; `git diff --stat` within gate 1.
4. [x] (skill 61/61, unaided 43/61, 19:52 to 20:50, none capped; recorded in baseline.md; no re-freeze) Tier 2. From a clean tree with steps 1-3 landed: `CONFORMANCE_ARMS=both
       CONFORMANCE_MODEL=claude-opus-5 bash scripts/conformance-eval/run.sh`, detached (`nohup bash
       -c '...; echo exit=$?' >> log &`, no setsid on macOS) with a Monitor on the log; hours, so
       start it early in the day (2.1.0's ran 17:44 to 01:18 and lost the API). Never edit
       run.sh or skills/atelier while it runs. Grade with `python3 scripts/conformance-eval/grade.py
       <runs-dir>` (both arms present); check `.result.txt` sizes before believing any cliff; a
       miss on a rule no diff touched is rerun twice before it is called anything. Record the
       result as a "Tier 2 for the 2.2.0 release" section in `scripts/conformance-eval/baseline.md`
       with the same table shape as 2.1.0's. DoD: skill arm at or above 59/61, or each miss
       explained and rerun; unaided arm within a few points of 39/61 (it cannot regress; a move
       is variance or an outage); no re-freeze (tasks.json sha unchanged), stated in the entry.
5. [x] Commits, each proposed and each waiting for the yes (rule 25): (a) `docs(readme): value
       and two quick starts above the fold` plus the section-move slices, (b) `chore(references):
       remove the two redirect stubs`, (c) `docs(release): 2.2.0 changelog and upgrade notes`,
       (d) `chore(conformance-eval): the 2.2.0 tier-2 pass`. Land through the worktree flow:
       commit on `claude/hello-962356`, `git -C ~/Documents/CODE/atelier merge --ff-only
       claude/hello-962356`, `git push origin main`; push waits for its own yes.
6. [x] (v2.2.0 on c406ec5, pushed 2026-09-06) Tag and push. `git tag -a v2.2.0 -m 'atelier 2.2.0, the six-pack release' -m '<the
       CHANGELOG lead>'` on the tier-2-recorded commit, `git push origin v2.2.0`. DoD: `git tag
       -n1 v2.2.0` prints the lead; the GitHub release page shows the tag; CI green on main.
7. [~] (LESSONS decision written; memory corrected) After the tag: LESSONS `[decision]` on the README fold rule (value and quick starts before
       the catalogue) if the guided review confirms it as a convention; memory
       `conformance-audit-phases` still says "2.1.0 release pending", correct it to 2.2.0 shipped.

After the tag, the first 2.3.0 change: the random-order rule (decided 2026-09-06; drafts in
`.claude/rule-36-drafts.md`, untracked until they land, verified on bun 1.4.0: `--randomize` shuffles within a
file, prints `--seed=<n>`, and an order-dependent pair fails under six of eight seeds).

8. [x] Canon 4.9 "Run the tests in random order": the dos-and-donts section with the TS and Java
       examples, the pillar-4 index link, the pillar prose bullet, the proposed-revisions entry
       (ACCEPTED by the owner 2026-09-06), count 119 to 120 and PER_PILLAR pillar 4 from 8 to 9 in
       `check-matrix-drift.py`, both sha256 and line pins in the matrix header. DoD:
       `python3 scripts/check-matrix-drift.py` green; the forward row 4.9 cites the doctrine lines
       step 9 lands (same commit as step 9, or the row reads GAP for one commit).
9. [x] Doctrine: hard rule 36 in SKILL.md, the testing.md section and the smells row, the test
       script `bun test --randomize` in bun-typescript.md and nextjs-monorepo.md, `ci.yml` and
       `stryker.conf.json`, the JUnit properties file in java-quarkus.md, the pointer block and
       README counting 36, the companions swept for 35. DoD: `check-citations.py` re-anchored per
       slice then `--lock`; frontmatter 4/4; the reverse matrix row for 36; SKILL.md description
       untouched (no trigger eval owed).
10. [x] (Bun 78, Next 15, Java 41 checks green 2026-09-06; the fixture is a three-step chain, a pair was green for the wrong reason in Java) Gates prove red: the counter pair in each smoke test (Bun, Next, Java), green in declaration
       order, red under at least one seed of eight, the conforming fixture green under the same eight (three seeds in Java, each a full Maven run);
       every `bun test` in the smoke tests carries `--randomize`. DoD: the three smoke tests green
       locally (Java needs JDK 21 and mvn), CI nine jobs green on the push.
11. [x] (2026-09-06 21:14 to 21:23, five tasks e2, a1, a3, a4, h1: skill 13/13 vs frozen 6.5/13; ran untagged into the tier-2 directory, see LESSONS) Tier 1: `CONFORMANCE_SINCE=v2.2.0 CONFORMANCE_MODEL=claude-opus-5 bash
       scripts/conformance-eval/run.sh`, graded `--frozen-baseline`; tasks.json unchanged. DoD: no
       miss on a rule the diff touched; misses elsewhere rerun twice before they are called.
12. [x] (six slices landed 2026-09-06 after the yes; push pending) CHANGELOG Unreleased (2.3.0): Added rule 36 and canon 4.9, the consumer action; LESSONS
       `[decision]`; commits gate-1 sized in canon, doctrine, gates order, each waiting for the yes.

Not in scope: any SKILL.md description edit (it would owe tier 2 anyway plus the trigger eval;
none is planned); the six-pack's second live run; folding the eval harness docs into the README.
