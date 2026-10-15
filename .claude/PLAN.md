# Plan: rule 38's host settings as code, checked daily (proposed 2026-10-15)

The previous plan (the reply gate's first reading and its mid-turn count) closed with PR #5 merged
by rebase into main (b1e4ffb). The owner asked what atelier says about five host settings (a branch
called `main`, `main` the default, rebase-only merges, head-branch auto-delete, a protected `main`)
and then for a proposal to add them. Today rule 38 covers them only in part: nothing names the
branch (no checklist runs `git init -b main`, nothing sets the host's default); rebase-only and
auto-delete are a `gh api` snippet in workflow.md, set once by hand and never checked (atelier itself
has auto-delete off, so `main-f7v4vj` survived PRs #3 to #5); and "protects `main`" points at "the
branch-protection code of `references/delivery.md`", which holds one bullet and no code.

Facts from GitHub's docs (2026-10-15): reading merge-related settings over REST needs
contents:read and contents:write; anyone with read access can view a repository's active rulesets;
rulesets need a public repository or a Pro, Team or Enterprise plan; renaming the default branch
needs admin and moves branch protection and open pull requests with it; rule types include
`deletion`, `non_fast_forward`, `required_linear_history`, `pull_request` and
`required_status_checks`, and `~DEFAULT_BRANCH` targets the default branch.

## The design

- `assets/host-ruleset.json`: a ruleset on `~DEFAULT_BRANCH`, enforcement active, no bypass actors,
  rules `deletion`, `non_fast_forward`, `required_linear_history`. No `pull_request` and no
  `required_status_checks`, since rule 38 allows committing straight to `main` and both block that.
- `assets/check-host.py` (python3 and `gh`, like `check-reply.py`): with no flag it fails when the
  default branch is not `main`, when `main` lacks one of the ruleset's rules, when merge commits or
  squash are allowed, rebase is off or auto-delete is off; each finding prints its fix, and a
  setting it cannot see is named as such, never passed. `--apply` is the owner's one-time,
  idempotent setup: rename the default branch to `main` or point the default at an existing
  `main`, PATCH the four merge settings, create or update the ruleset, re-run the check.
  `--selftest` serves a fake GitHub in process.
- `branches.yml` runs it as a second step, read-only like every shipped workflow: GraphQL shows a
  read-only token all four merge settings (step 1), so every setting is checked directly.
- A private repository on GitHub Free cannot hold a ruleset: the doctrine names an opt-out in
  `branches.yml` (`HOST_RULESET: unavailable`), who uses it and why; the check then reports `main`
  unprotected without failing. Rule 26's history scrub force-pushes `main`, so workflow.md says to
  disable the ruleset for the rewrite and restore it after.

## Steps and definition of done

1. [x] Probe before doctrine: a throwaway workflow on `main-f7v4vj` (one push, dropped before the
   pull request) prints what a contents:read `GITHUB_TOKEN` sees here: REST merge fields, GraphQL
   merge fields, `rules/branches/main`. DoD: the visible set recorded; it fixes what the daily step
   checks directly. Found (run 38735783885, 2026-10-15, this repository, public): REST returns
   `default_branch` and `private` but null for all four merge settings; GraphQL returns them all
   (`rebaseMergeAllowed`, `squashMergeAllowed`, `mergeCommitAllowed` true, `deleteBranchOnMerge`
   false: GitHub's defaults, and auto-delete off matches `main-f7v4vj` surviving its merges);
   `rules/branches/main` and `rulesets` answer 200 with `[]`; classic `branches/main/protection`
   answers 403. So the daily step stays read-only and reads every setting over GraphQL: no blind
   spot left. A null still reads as not visible, never as a pass; the first daily run after the
   owner's `--apply` proves GraphQL reports the applied values.
2. [x] `host-ruleset.json` and `check-host.py` with `--apply` and `--selftest`. DoD: the selftest
   is red on each drift (default `master`, no ruleset, each rule missing, squash on, merge commits
   on, rebase off, auto-delete off, a field the token cannot see) and green on a compliant repo;
   mutants that drop a check go red. Done: green, and red under each of 13 mutants (no default
   check, a hidden setting passing, the opt-out holding on a public repository, any error read as
   no branch, an empty ruleset loading, `--apply` never updating, merge values never compared, rules
   read off the wrong branch, the opt-out failing its rules, two GraphQL names swapped, rebase wanted
   off, a rename over a repository that has `main`). Two commits: the check (295 lines with its
   selftest), then `--apply`.
3. [x] `branches.yml` second step; `check-workflow-assets.sh` fails a variant whose checklist does
   not copy the script and the ruleset; the three smoke tests run the selftest and grep the copied
   workflow. DoD: asset selftest and all three smoke tests green here. Done: the asset check went
   red on the real tree until the three checklists copied both files; its selftest gained an
   uncopied data file. This repository's own CI also runs the selftest and reads its own host with
   a read-only token (a finding passes there, exit 2 fails).
4. [x] Doctrine and cascade: SKILL.md rule 38 and its table row, workflow.md Branch lifecycle (the
   snippet and the dangling pointer replaced, the opt-out, the scrub note), delivery.md's bullet, the
   three variant checklists, atelier-greenfield (`git init -b main`, `--apply` after the first push
   on the owner's yes), atelier-review-me (the check first, `--apply` on the owner's yes), matrix
   row 8.1, the changelog. grill-me and distill carry no echo. DoD: one citation re-anchor, drift,
   frontmatter and em-dash green; tier 1 conformance on the skill diff. Done: 11 citations moved
   in one re-anchor, 239 intact; tier 1 selects 0 of 21 tasks (no task exercises the touched
   rules; assets and the delivery, java-quarkus and nextjs-monorepo references select nothing), and
   tier 2 is not due (no description changed). reverse-matrix row 38 and the changelog's rule 38
   entry carry the host half too.
5. [x] Land on the owner's yes: slices under gate 1, push with a pinned lease, a pull request, CI
   green on Linux and Windows, rebase merge on the owner's go.
6. [ ] The owner runs `python3 scripts/check-host.py --apply` in panda-social-cli (and atelier if it
   should hold the same); the next morning's watchdog is green there.

## Status

Steps 1-5 done: PR #6 merged by rebase into main on 2026-10-15 (f875951), all 11 checks green on
Linux and Windows, and its CI step read this repository's host with a read-only token (6 findings:
no ruleset, merge commits and squash allowed, auto-delete off). Step 6 waits on the owner's
`--apply`, here and in panda-social-cli; the remote `main-f7v4vj` waits on the owner's delete.
