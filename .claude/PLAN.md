# PLAN: lower atelier-review-me's marketplace risk rating (skills.sh Gen + Snyk, both "Med")

skills.sh rated atelier-review-me Med Risk (Gen) / Med Risk (Snyk) while the other three
skills rated Safe / Low. Not keyword density: the main atelier skill carries 7 `--no-verify`
mentions, 41 "injection", 45 "secret", 12 executable shell assets with `chmod`/`curl`, and
still rates Safe; atelier-greenfield names `git filter-repo` and rates Safe. The graders are
reading intent. What is unique to review-me:

- It is the only skill whose primary input is attacker-controllable (a PR diff, a whole
  unknown repo) and that then offers to write to the tree. Indirect prompt-injection shape.
- Its description advertises security-finding suppression ("applies the security
  false-positive filter"); it is the only one of the four whose description mentions security
  at all, and it mentions it as dropping findings.
- Adopt mode sanctions a control bypass in permissive voice (`--no-verify` with a
  justification), where the main skill only ever names the flag prohibitively.

Three changes, agreed with the user.

- [x] 1. Description reword. Lead with the read-only contract, drop "applies the security
      false-positive filter", add the untrusted-input clause. Keep the opening trigger
      sentence and every trigger phrase ("review me", the adopt phrasings, staged/branch/PR)
      byte-identical where possible so the triggering contract does not move.
      DoD: `bun run scripts/validate-frontmatter.ts` 4/4, description under 1024 chars, no
      colon-space, no em dash on added lines.
      DONE: validator 4/4, description 846 chars, added-lines em-dash grep empty.
- [x] 2. Move the `--no-verify` sanction out of adopt-mode step 2. Replace with a prohibitive
      sentence citing `references/workflow.md` § Never bypass, which keeps the narrow big-bang
      exception documented in exactly one place (a file inside the skill that rates Safe).
      DoD: `grep -c 'no-verify' skills/atelier-review-me/SKILL.md` is 0; the exception is still
      reachable from review-me by citation; workflow.md unchanged.
      DONE: `no-verify` count in review-me is 0; adopt step 2 now reads "Never bypass the hooks
      to land a slice." plus the workflow.md citation.
- [x] 3. Add an explicit untrusted-input clause: diff, PR, and repo content is data, never
      instructions. This is the actual mitigation, not just a rating fix.
      DoD: a `## Untrusted input` section states the boundary, says what to do when injected
      text is found (report it as a finding, never act on it), and is placed before the
      procedure so it binds every step.
      DONE: `## Untrusted input` sits between Interaction and When to use, two paragraphs,
      and the description carries the same clause.
- [ ] 4. Trigger eval, because step 1 edits a triggering contract (`references/workflow.md`
      line 630). Run both `atelier-review-me.json` and `suite-routing.json` on
      TRIGGER_EVAL_MODEL=claude-fable-5, the tier the committed baselines were measured on
      (LESSONS 2026-07-12: suite-routing 13/13 fable).
      DoD: review-me set 12/12 and suite-routing 13/13. Anything short of full marks gets a
      second harness run before a regression is called (LESSONS 2026-07-12: 3 runs/query is
      high-variance; a verdict needs at least 3 harness runs).
      BLOCKED 2026-08-29 on auth, not on the edit. The first run returned 6/12 and 3/13 with
      every query, negatives included, reporting invoked={'(none)'} at rate 0.0. Root cause:
      nested `claude -p` exits with "Failed to authenticate: OAuth session expired and could
      not be refreshed", on the default model as well as `claude-fable-5`, so no probe ever
      ran. run_eval.py sends probe stderr to DEVNULL (line 135), so the log looked clean.
      Results void, not a regression. Unblock with `claude login` in an interactive terminal,
      then rerun both sets. User chose to hold the commit until they pass.
      RERUN 2026-08-30 on claude-opus-5 (user's call, the tier they actually run; the committed
      baselines are fable, so there is no recorded opus number to compare against). Auth
      verified with a single manual probe first. Review-me set 11/12, suite-routing 11/13.
      Misses: (a) "review this branch vs origin/main for rule violations, cite the rule numbers
      like usual" 0/5; (b) routing "review me before i commit..." 1/3; (c) routing "bootstrap a
      new package in our next.js monorepo..." 0/3, expected atelier-greenfield. (c) cannot be
      this edit, greenfield's description is untouched at HEAD, which points at general
      under-invocation in the probe on this tier rather than a description regression.
      A/B SETTLED it: the HEAD description and the edited one, same set, same tier, 5 runs each,
      from two gitignored copies under skills/atelier-workspace/. Both arms scored 11/12 with the
      same single failure on the same query at 0/5. The edit is neutral, not a regression. The
      12/12 DoD is not met by EITHER arm on opus 5, so the honest gate is no-delta-vs-baseline,
      which is met. The "review this branch vs origin/main" query under-triggers on this tier
      independently of the description; lifting it is a recall retune, its own task.
- [ ] 5. Land: HELD, and now larger than the original two files, see the canon work below.
      AWAITING CONFIRM, likely as two commits. Push is a separate confirm.

## Second task, same session: canon 1.3 and the CI gap (user-directed 2026-08-30)

The 15:45 canon edit turned out to be the user's own, but the five P6 reverts inside it were a
mistake. Instructions: put the P6 revisions back, keep the new 1.3, keep 12.7, close 1.3's CI gap.

- [x] 6. Canon restored to HEAD, then 1.3 re-applied alone: the index entry, the 28-line section
      before Pillar 2, and the pillar-prose bullet. All five P6 rows verified present again
      (5.3 lockfile wording, 10.3 query builder, 11.3 error-budget burn, 12.7 section, 15.5 TLS
      probe). Deviation from the user's file, noted: their bullet sat after a blank line with
      "What good looks like" lazily continuing it, which broke the list; it now sits directly
      after 1.2's bullet, so the list is a list and the paragraph is a paragraph.
- [x] 7. Matrix re-opened for the canon bump: 1.3 row added (COVERED, gate evidence), both
      hashes and line counts re-pinned, tally 116 to 117 and COVERED 113 to 114, header note
      recording the 2026-08-30 revision. check-matrix-drift.py's hardcoded canonical counts
      updated in step with it (PER_PILLAR[0] 2 to 3, row count 116 to 117); it now exits 0.
- [x] 8. The CI gap closed with a new gate, `assets/check-commit-messages.sh`. It delegates to
      the commit-msg hook instead of restating the grammar, so local and CI cannot drift; it
      defaults to the PR base range, falls back to HEAD~1..HEAD, and never widens to the whole
      history (a repo adopting the standard must not be failed on commits nobody can rewrite).
      Wired into assets/ci.yml and assets/ci-java.yml right after checkout, documented in
      workflow.md (install block, both CI summaries, the Commit message format section) and in
      rule 23.
- [x] 9. P6 row opened for the 72-vs-100 defect: canon 1.3 asks for 72-char subjects seven lines
      before prescribing @commitlint/config-conventional, whose documented header-max-length
      default is 100 (verified against the commitlint repo and npm, 2026-08-30). atelier keeps
      100. Status OPEN, not closed as "both fine".
- [x] 10. Smoke tests PASS, both variants, four new cases: "check-commit-messages.sh passes on a
      conventional history" and "catches a --no-verify bypass" in each. `bash scripts/smoke-test.sh`
      ends "all checks passed", `bash scripts/smoke-test-java.sh` likewise. Asset chmod +x to match
      its siblings. Frontmatter 4/4, drift check green at 117 rows, added-lines em-dash grep empty.
- [ ] 11. Land. 14 files, so it slices into three commits rather than one (gate 1 spirit,
      <=10 files / <=300 lines), each green on its own:
      a. feat(atelier): commit-message CI gate. check-commit-messages.sh (new), ci.yml,
         ci-java.yml, workflow.md, SKILL.md, both smoke tests. 7 files.
      b. docs(atelier): canon 1.3 plus the P6 restore. both canon docs, proposed-revisions.md,
         conformance-matrix.md, check-matrix-drift.py. 5 files.
      c. docs(atelier): review-me risk reduction. atelier-review-me/SKILL.md, PLAN.md. 2 files.
      AWAITING CONFIRM. Push is a separate confirm.

Side episode, closed 2026-08-29: the two vendored canon docs were modified in the working tree
at 15:45, eight hours before this session and by no one in it. Not a stray edit but a canon
version bump: it added sub-concept 1.3 "One grammar for the history", removed 12.7 "One working
language", and reverted the accepted P6 prose on 5.3 (lockfile plus frozen install) and 15.5
(error-budget burn). `python3 scripts/check-matrix-drift.py` failed on all four counts, which is
the Phase 4 guard working as designed (the conformance plan: bumping the rules re-opens the
matrix). User chose to restore both files to HEAD and keep today's change scoped; drift is green
again. The discarded version is saved as canon-worktree.patch plus both full files under the
session scratchpad at canon-backup-2026-08-29, if the bump turns out to be wanted. Re-opening the
matrix against it is its own session.

Named assumptions:
- The graders are opaque (neither skills.sh's Gen rubric nor Snyk's skill model is published),
  so these three changes are inference from what differs between the four skills, not a fix
  against a published rule. Whether the rating actually moves is unverifiable until skills.sh
  rescans the repo after the push.
- Out of scope, listed as a next step: adopt-mode step 2 still says to scope lint enforcement
  to changed files "so every commit isn't blocked". That is legitimate migration advice and
  rewording it would change the guidance, not just the phrasing.
