# Plan: release 2.1.0 (2026-09-03)

1. [x] Tier 2 (skill 59/61, unaided 39/61, +20; five sessions lost to an API outage, re-run): the full matrix, both arms, 21 tasks (`CONFORMANCE_TAG=tier2-2.1.0`), running in
       the background. DoD: with_skill at or above the recorded floor (`--min-with-skill 24
       --min-delta 4` on the e/a tier; the h tier read against the frozen arm), no task below its
       last reading without a rerun explaining it.
2. [x] Re-freeze the baseline (78/125 over three passes, dead sessions skipped). Was: from the frozen-base and tier-2 dirs summed (two passes):
       `python3 scripts/conformance-eval/freeze-baseline.py <frozen-base> <tier2> --model claude-opus-5`;
       `grade.py --selftest`; commit.
3. [x] Release text drafted locally: CHANGELOG `## [2.1.0] - 2026-09-03` with an intro and an
       "Upgrading from 2.0.0" list (workflows, check scripts, ESLint and pom fences, the stubs,
       the doctrine changes), README's current-release line. Not pushed, not tagged.
4. [ ] On a clean tier 2: push, then `git tag -a v2.1.0` on that commit and push the tag (the
       first tag in the repo; consumers pin by tag from here). Both on the owner's word.
5. [ ] Owner: re-sync the consumer repo to v2.1.0 (`check-skill-pin.sh` compares the tree).
6. [x] Canon row B ACCEPTED and applied 2026-09-03 (104c5a0 draft, 81846e5 applied): eighteen numbers
       tagged, 7.6's Do restated, eleven profile rows, both pins re-pinned.
