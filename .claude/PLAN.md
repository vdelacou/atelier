# Plan: close the pre-release audit (2026-09-27)

The owner's go ("go one by one do all") on the audit's next steps. The audit report (185 findings) is
in the session scratchpad, `release-audit-2026-09-27.md`; its section numbers are used below. Commits,
pushes and the tags each need their own yes. The Edit/Write hook claims a removed worktree, so edits go
through Bash (see the worktree-landing-flow memory).

## Steps and definition of done

1. [x] Phase 1, the 11 blockers and the latent PR smoke bug (report section 1). DoD: each fix in place;
   a gate or config fix has a red case in the matching smoke test seen red then green; the three smoke
   tests green; fast gates green; tier-1 selector dry run named.
2. [x] Phase 2, the gate holes (section 2): TypeScript gates, Java gates, repo harness. DoD: each hole
   closed with a red case wired into its smoke test or selftest, seen red first.
3. [ ] Phase 3, doctrine drift, contradictions, wrong examples, broken pointers, matrix citations
   (section 3). DoD: each item fixed or recorded as a decision; citations re-anchored and intact;
   frontmatter and em-dash gates green.
4. [ ] Phase 4, release notes and docs (section 4). DoD: README and CHANGELOG numbers trace to files.
5. [ ] Phase 5, evals: one tier 2 (both arms) after phases 2-4; it covers every doctrine change, and tier 1 already selected 17 of 21 tasks after phase 1 alone. DoD: scorecards read
   answer-first, numbers into baseline.md and the CHANGELOG.
6. [ ] Phase 6, release 2.6.0: tag v2.5.0 on 6320b92, then the 2.6.0 CHANGELOG with a Security entry,
   tag v2.6.0. Each tag on its own yes. Nice-to-haves (section 5) stay backlog unless the owner says.

## Status
Landing: the owner chose "commit green slices, push per phase"; tags still ask.
Phase 1 done 2026-09-27: 11 commits 977f282..91d4d69, pushed. Smoke tests green on that tree (Bun 118 ok,
Java 64, Next all); Stryker's JSON-fixture case and the em-dash gate's two new cases seen red on the old
files first. Commits built with scratchpad hunks.py at -U3: zero-context insertions misplaced lines once,
caught by a residual-diff check, the five local commits reset and rebuilt before any push.
Phase 2 done 2026-09-28: d0d2468..6c712c9 plus the scanner/action-pin slice, each gate hole probed red on the
old code first; smoke tests green on each batch (Bun 140 checks). One harness defect found live and fixed:
--reanchor cascaded on a partial run (row 13.4, restored). Phase 4 docs partly done ahead (CLAUDE.md,
README eval count, .gitignore, CHANGELOG 2.5.0 distill numbers, profile 17.7 re-pinned).

## Phase 3 checklist (doctrine drift; file:line as found by the audit, lines shift as edits land)

## Cascade drift
- [ ] rule 36 `bun test` -> `bun run test`: SKILL.md:83,187; wf:45,627,670 (inner loop); bt:568 "bare bun test"; result-type.md:359
- [ ] fast-gate lists: SKILL.md:187 (7 gates), SKILL.md:119 pre-commit row (Next + Java cells); bt:370,598,647 gate numbers; assets/regenerate-coverage-preload.ts:31; nx:77, nx:628-634 CI prose; ci-next.yml:3-4 header; smoke-test-java.sh:11-12 header; wf:256, wf:674 summary, wf:677 "mutation on staged files in CI"
- [ ] SKILL.md:137 "1-35" -> 1-37; matrix :63 "1-34", :94 "five fast gates", :195 "gate 5"
- [ ] SKILL.md:121 Result->HTTP "via a presenter" -> infra (nx:744, architecture.md:266)
- [ ] SKILL.md:53 rule 17 closed list: add Next route handler
- [ ] build.gradle: SKILL.md:106,144; greenfield:24
- [ ] axe gate -> jsx-a11y: SKILL.md:98, product.md:109, wf:573
- [ ] "Rule 35 arrived later" -> 35-37 (SKILL.md:75); calisthenics rule 3 (SKILL.md:89); Next mock cell (SKILL.md:123); rule 24 Java tests (SKILL.md:60); branded where they cross a trust boundary (SKILL.md:83,176); SKILL.md:183 discipline list vs :64; SKILL.md:129 style row; SKILL.md:56 rule 20 lint vs review; SKILL.md:178 legacy carve-out wording
- [ ] reference table triggers (SKILL.md:146,157): workflow.md row + rules 5, 35; testing.md + 36 (selector reads it: dry-run after)

## Companions
- [ ] greenfield: step 9 >10 files (sanctioned --no-verify for the initial scaffold with a body justification, or slices); junk-message proof via .githooks/commit-msg on a file; Java asset list -> point at java-quarkus Gates block; CI list + ci-next.yml; step 8 Java suppression proof; When to use + Java; LESSONS header vs lessons.md:199 (add greenfield exception in lessons.md File starters); identity proof one-word name (IDENTITY_DENYLIST); no README step
- [ ] review-me: adopt mode Java branch (steps 2, 6); file->rule map (package.json -> 5, 19, 36 + Next hook line; check-coverage.ts, bunfig.toml, pmd-ruleset.xml, LayerRulesTest.java, junit-platform.properties); app/**/route.ts adapter subset; :39 held-back steps
- [ ] companion lists consistent (greenfield:10, review-me:10, distill:10); grill-me:35 Owner template (product.md:100)

## Wrong examples
- [ ] security.md:206 apiKey lowercase (and matrix :106 evidence); security.md:99-102 fetch deadline + Result
- [ ] isolation.md:38-42 ENABLE + FORCE ROW LEVEL SECURITY
- [ ] delivery.md:85 restore drill test -gt 0
- [ ] metrics.md:47 increase()
- [ ] lessons.md:408 lesson never overrides hard rules
- [ ] ai.md:73-75 eval trigger paths (pin file, schema); ai.md:25 dated pin
- [ ] rule 18 curried GOOD: governance.md:130, architecture.md:133-137, behavioural-examples.md:225-227, nx:738
- [ ] rule 7 inline type: nx:754 (now shifted), testing-infra.md:201
- [ ] product.md:69,80-81 className in app code
- [ ] outbox note: code-smells.md:88-89, complexity.md:240-241, solid-principles.md:52-53
- [ ] privacy.md:131 PII guard core
- [ ] architecture.md:419-423 test layers vs testing.md
- [ ] feature-first GOOD paths: architecture.md:34-44, clean-code.md:234, code-smells.md:125,135, solid-principles.md:29-44,240; architecture.md:78 "Domain defines the contract"
- [ ] governance.md:102,113 names -> role handles
- [ ] testing-infra.md:36-47 inline fetch-mock -> asset pointer; :337 `{} as never`
- [ ] format-error.ts JSON.stringify(undefined) + test
- [ ] rule 9 commitlint.config.cjs module.exports (ESM .mjs, test in Next smoke) or carve-out
- [ ] bt skeleton: current majors (eslint 10, @eslint/js 10, unicorn 76, security 4, stryker 10), add globals, typescript devDep ^5.9.3; bt:9 Bun 1.3; bt:17 tsc; bt:614 commit-msg self-check; commit-msg "identical grammar" wording
- [ ] nx: "type": "module" in package skeleton; :176 react-jsx; :709 allowImportingTsExtensions; :704 serve; :480 ^4.0.2; :694,:831,:833 pointers
- [ ] wf:187 vs :115 preload check home
- [ ] broken pointers: wf:700 Security section; wf:152 testing-infra.md; privacy.md:61; governance.md:89 + jq:344,486 "The internal model is yours"; jq:397 "Test the bypass"; testing-infra.md:94; bt:334 "See LESSONS.md"; check-commit-range.sh:24 field-test.md
- [ ] guard counts four -> five (wf:525, isolation.md:137)
- [ ] canon ids as "rule 15.1": ci.yml, ci-java.yml, pre-commit, pre-commit-java, lint-staged.sh, check-bundle-size.sh, wf:302
- [ ] rule 19 misuse: complexity.md:125, behavioural-examples.md:44; delivery.md:55 "rule 12's config module"
- [ ] matrix stale citations: 3.9, 4.8, 5.8, 5.9 (behavioural-examples:42), 3.5 + watchlist 6 (nx gateway), 17.5 (nx catalog), 1.2, 2.3, 4.3 (SKILL lines), 15.7 range
- [ ] profile values 10.8 (100 VUs 2 min -> reliability.md), 14.3 (4 business hours, 90% on current major -> governance.md), 16.4 (CFR > 0.15 held 24 h -> metrics.md)
- [ ] LESSONS.md:77 sonarjs 4.1.0 claim (re-probe or soften)
