# Plan: gap hunt, rule 26 gate then the tripwires as default gates (2026-09-09)

Findings: rule 26 (identity in commit metadata, never in file contents) has no gate in any variant;
the four rule 27-30 tripwires ship but nothing runs them (the Bun and Next checklists never copy
them, no hook or CI calls them, Java copies them with "wire them" as prose). Owner chose both
closures, two slices.

## Slice 1: rule 26 gate

Definition of done: `assets/check-identity.sh` (staged added lines by default, `--all` over every
tracked text file; a multi-word git name in both orders and the email from git config, every
multi-word author and committer and every email in the history under `--all`, `IDENTITY_DENYLIST`
env entries; one-word names and GitHub noreply addresses are handles and skipped; CODEOWNERS and
`.mailmap` exempt; a lone first name stays review) probed red and green in a scratch repo first;
wired as a hook gate in `pre-commit` (Bun) and `pre-commit-java` and in the Next `simple-git-hooks`
line, and as an `--all` step in `ci.yml`, `ci-next.yml`, `ci-java.yml`; copied by the three
bootstrap checklists (the workflow-asset gate proves it); this repo runs it on itself (hook and CI);
the three smoke tests prove a planted name red, a handle and a CODEOWNERS mention green, and (Bun,
Java) the hook itself red on a staged leak; SKILL.md rule 26 names the gate and the matrix gains its
row; workflow.md's Commit identity section and tripwire table carry it; matrix row 13.5 cites the
script; citations re-anchored and locked; CHANGELOG, LESSONS; tier 1 dry run; commit on the yes.

1. [x] (probe 1: 15 of 15; probe 2 after the one-word-name refinement: 5 of 5) Script drafted and probed.
2. [x] (workflow-asset gate green; this repo passes its own gate staged and --all) Hooks and CI wired (three each), bootstraps copy it, this repo's own hook and CI run it.
3. [x] (16:16 to 16:2x, all three suites green: Bun 7 rule-26 checks incl. the hook, Java 3 incl. the hook and --all, Next 3) Smoke tests: fixtures in all three; the hook path is the proof in Bun and Java.
4. [x] (doctrine, matrix 13.5, 235 locked, CHANGELOG, LESSONS; tier 1 selects nothing for rule 26, the conscious skip; three commits pushed on the yes) Doctrine, tier 1, commits.

## Slice 2: pii, deadline and data-lifecycle tripwires as default gates

Done 2026-09-10: `check-disciplines.sh` probed (5 of 5), wired (hooks, CI, checklists, doctrine, matrix notes), the three smoke suites green (Bun after one rerun: the rule-27 hook proof ran before the identity script was copied), tier 1 12 tasks 37/37 vs frozen 30.3/37 once the h3 hard-delete check learned the tripwire's scope (the sixth grader defect; fixture re-frozen from the same three passes, 139/183). Five commits wait for the yes. The plan was: the three wired the same way (hook staged, CI `--all`), isolation stays opt-in
where tenants exist, checklists copy them, workflow.md's "optional gates" becomes "default gates,
isolation opt-in", the smoke tests prove one hooked commit red per tripwire, tier 1.
