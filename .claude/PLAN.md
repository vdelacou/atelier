# Plan: the workflow-asset gate parses the workflows (2026-09-08)

Goal: `check-workflow-assets.sh` proves each shipped workflow calls only shipped scripts, copies them in
its bootstrap doc, and installs its binaries first, by grepping the file; it never parses it. Tonight's
first `ci-next.yml` draft did not parse (a colon-space inside a step name) and only a hand check caught it.
Add the parse.

Definition of done: every `assets/ci*.yml`, `audit*.yml`, `mutation*.yml` must parse as YAML or the gate
fails naming the file and the parser's message; the parser is `python3` with PyYAML, else `ruby` with Psych (both here and on the ubuntu runner), and
a machine with none of them gets a loud note and no false green; the selftest rejects the colon-space
fixture and fails against the old gate; the seven shipped workflows pass; CHANGELOG Harness bullet; CI
green. No skill content change.

1. [x] (python and ruby paths proven, a crashed parser fails loudly, the no-parser path prints the note and the selftest refuses to pass without a parser) `check-workflow-assets.sh`: `parse_yaml()` with the three-parser chain; step 0 of `lint_workflow`;
       selftest case `- name: gate (rules 5 and 19: no latest)`; the selftest itself requires a parser.
       DoD: selftest green; the mixed copy (old lint, new selftest) fails; the gate green on the assets.
2. [x] (two slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Harness bullet; LESSONS one line; plan final. Commits on the yes: (a) `fix(check-workflow-
       assets): parse every shipped workflow`, (b) `docs: changelog, lessons and plan for the parse step`.
       Push on its own yes.

Not in scope: range-end pinning in the citation gate.
