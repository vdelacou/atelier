# Plan: doctrine A/B + consumer re-sync + field pass (2026-08-30)

1. [ ] Make the judge's stated purpose executable.
   - run.sh: CONFORMANCE_SKILL_PATH override (arms are already parameterised).
   - judge.py: pair the SAME task across two run dirs with custom arm labels, so
     two skill VERSIONS can be compared, not just skill vs no-skill.
   - Test-first: selftest cases for custom labels and cross-dir pairing, red first.
   - Validate live: current skill vs the 2026-07-12 skill (the version the field-test
     consumer pinned) on two tasks, judged both orders. A real doctrine A/B.
2. [ ] Consumer re-sync: six pushes have landed since the last one, so the pin gate
   now reports behind. Re-sync both vendored trees, re-verify, leave uncommitted.
   Propose *.tfplan for their .gitignore (plan files can carry resolved secrets).
3. [ ] Phase 5 second field pass over the caught-up tree, read-only, short delta report.
4. [ ] Gates, then propose slices. Land on confirmation only.
