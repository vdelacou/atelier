# Plan: land from main, not from the pull request (2026-10-25)

The previous plan closed: PR #21 landed itself through its own land job on 2026-10-25 (main a03f0a1),
deleting its branch. The owner then showed the skills.sh install audit: Socket raised two MEDIUM alerts
on `assets/ci.yml` and `assets/ci-java.yml`, both on the land job, which checked out the pull request
and ran its copy of `land-on-green.sh` with a write token. The owner asked to fix it.

## The design

- `assets/land.yml` on `workflow_run` (the ci workflow, completed): the file and the checkout come
  from the default branch, the job needs `workflow_run.conclusion == 'success'`, skips drafts, forks
  and `LAND_ON_GREEN=off`. The land job leaves the three CI workflows and this repository's.
- `land-on-green.sh` reads the pull request through the API only: the open pull request on the tested
  head (skip, green, when none or a draft), every other check passed, the head not behind its base
  (when it contains the base, the tested merge is the head itself), then the pinned rebase merge.
- `check-workflow-assets.sh` fails the land script on any trigger but `workflow_run`, a checkout of
  another ref, and a job without CI's success in its condition; it maps `land.yml` to every variant.

## Steps and definition of done

1. [x] Script, `land.yml`, the CI workflows, the check. DoD: both selftests green and red under
   deliberate breaks; the check red on 2.8.0's shipped `ci.yml`.
2. [x] Docs: workflow.md Landing on green, SKILL.md, atelier-review-me, the bootstrap lists, CLAUDE.md,
   the changelog's Security entry and upgrade note, a lesson. DoD: fast gates green, Bun smoke green.
3. [ ] Land: PR, CI green, merged by hand (`land.yml` acts from the next pull request on).
