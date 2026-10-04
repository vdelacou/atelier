# Plan: branch management, hard rule 38 (2026-10-04)

The previous plan (the reply gate in review, in this repo, and measured) closed with PR #1 merged by
rebase into main (50baf26) and the firing-rate check-in scheduled for 2026-10-11
(trig_01SaAdsRteii5z8BaXw2RFpA). This one: the owner asked for rules about branch management.
Atelier already says trunk-based (commit to main or a branch that lives under a day, flags not
branches, linear history) and canon 8.1 ends "merge, delete the branch same day", but nothing says
how a branch lands or that it is deleted, and nothing enforces either: check-commit-range.sh skips
merge commits by design, so a merge commit reaches main unchecked, and the session that merged PR #1
left its branch on the remote. A squash of several commits would also put one commit over gate 1 on
main. Probe before doctrine: on a pull_request run the shipped CI checks out GitHub's synthetic
merge ("Merge <sha> into <sha>"), so a merge check must step over exactly that commit.
Commits and the push each need the owner's yes.

## Steps and definition of done

1. [x] Restart main-f7v4vj from origin/main. DoD: the branch tracks origin/main's tip.
2. [x] check-commit-range.sh rejects a merge commit in the range (rule 38's tag), stepping over
   GitHub's synthetic PR merge at HEAD. DoD: selftest red on a real merge, green on the synthetic
   merge over a linear branch, red on the synthetic merge over a branch holding a real merge;
   red under a mutation of each part.
3. [x] assets/check-branches.sh (with --selftest) and assets/branches.yml, a daily watchdog: a
   remote branch whose work already landed on the default branch (judged by content with
   git merge-tree, so rebase and squash merges count) or whose oldest unlanded commit is over
   MAX_BRANCH_AGE_HOURS (24) old fails the run; KEEP_BRANCHES (default ^release/) exempts.
   check-workflow-assets.sh maps branches.yml to all three variants. DoD: selftest red per case,
   green on a fresh branch; the asset gate red before the copy lines, green after.
4. [x] References: workflow.md's Trunk-based section gains a Branch lifecycle subsection (start
   from a fetched main, rebase your own branch, land by rebase or fast-forward, delete local and
   remote on landing, follow-up from the new main, host settings as one gh api call, the gates);
   the three variant copy blocks. DoD: citations re-anchored and intact, drift green.
5. [x] SKILL.md hard rule 38, the later-rules note, the 1-38 counts, workflow step 6, the
   What-applies-where row; cascade to claude-md-pointer.md, README, CLAUDE.md, both matrices
   (forward 8.1 notes, reverse row 38), review-me (branch review, adopt mode), greenfield (copy,
   red proof, host settings), the grill-me and distill echoes checked. DoD: frontmatter valid,
   citations intact, drift green.
6. [x] Smoke tests: each variant copies the watchdog pair and runs its selftest beside the
   range gate's. DoD: the three smoke tests green.
7. [x] Tier-1 selector dry run; CHANGELOG Unreleased (Added, Upgrading, Changed). DoD: read.
8. [ ] Land in slices on the owner's yes; push on its own yes; a pull request to main, merged by
   rebase once CI is green. DoD: main carries the seven commits linear, and main-f7v4vj is deleted
   on the remote and locally (rule 38 on its own branch).

## Status

Steps 1-7 done 2026-10-04. The synthetic merge's subject was read from PR #1's CI log ("Merge
8db7ee0... into 47e68a5..."), and the same log showed a fetch-depth 0 checkout fetching every branch
and git 2.55 on the runner. check-commit-range.sh: rule 38's cases green, red under three mutations
(no merge check, the synthetic merge counted, any merge at HEAD stepped over). check-branches.sh:
selftest green, red under five (landed never detected, no age limit, an empty KEEP_BRANCHES exempting
all, the default branch checked, the age override ignored). check-workflow-assets.sh went red on all
three references before their copy lines, green after. Citations re-anchored (11, then 6), 239
intact; drift and frontmatter green. Tier-1 selector: 0 of 21 tasks. The three smoke tests passed
with the new blocks, no FAIL line in any. The owner said yes to landing: seven commits, each built
in a scratch worktree so the hooks gated its own tree (slice 2 re-anchored the two Next.js
citations its copy lines shift), pushed to main-f7v4vj (the old remote branch was already gone, so
no force), then a pull request to main. Next (step 8): CI green on the pull request, a rebase
merge, the branch deleted on both sides.
