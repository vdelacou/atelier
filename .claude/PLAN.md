# Plan: the tier-1 selector reads a count as a count (2026-09-08)

Goal: `scripts/conformance-eval/select-tasks.py` turned tier 1 into a 21-task pass on 2026-09-08 because
the Red flags line changed from "(1-35)" to "(1-37)" and a range in a changed line names every rule in
it. Reading the code found a second defect: `MAX_RULE = 35` is a constant, so an explicit "rule 36" or
"rule 37" in a changed line is dropped silently. Fix both, prove both in the selftest (the CI gate).

Definition of done: a range that starts at rule 1 and spans at least half the hard-rule set is a count
of the set and selects nothing (reported on stderr as such); "rules 1-3" and "rules 27-34" still
select; the highest rule number comes from the SKILL.md hard-rules section, never a constant, so
"rule 36" selects 36; the selftest carries a case for each; the dry run over the 2026-09-08 lint-gates
diff (`--since 8223cf8`, still the ref before rule 37) selects h2 for rule 17 and not the whole matrix;
`baseline.md`'s tier-1 paragraph names the count rule; CI green on the push.

Facts (2026-09-08): `expand()` filters to `1 <= n <= MAX_RULE`; `touched()` already parses the
hard-rules section into `rule_lines` (line -> rule), so the maximum is one `max()` away; both added and
removed lines are scanned for references, so the pointer block's "1-36" to "1-37" edit contributes two
count ranges; `trigger_table()` calls `expand()` too and needs the same maximum; the selftest's
synthetic skill has rules 1, 27, 28, 32 and the trigger table maps `ai.md` to rule 32; `baseline.md:327`
records the known limit ("a diff on the 27-34 checklist line selects the whole discipline tier"), which
stays as intended behaviour.

1. [x] (three fixes, each with a selftest case proven to fail without it; the third, the per-hunk difference, found while dry-running) `select-tasks.py`: `expand(spec, max_rule, counts)` drops a `lo-hi` part with `lo == 1` and
       `2 * (hi - lo + 1) >= max_rule`, recording it; `touched()` computes `max_rule` from `rule_lines`
       (fallback to the old constant only when the section is absent) and returns the dropped counts;
       `main()` prints "count ranges ignored: 1-37" on stderr; docstring bullet. Selftest: a skill with a
       rule 37 line; "(1-37)" and "rules 1-36" touch nothing and are reported; "rules 1-3" touches
       {1, 2, 3}; "rules 27-34" touches 27..34; "rule 36" touches {36}. DoD: `--selftest` green, and
       green only after the fix (run it against the pre-fix file once to see it fail).
2. [x] (lint-gates slice 5 of 21 with h2; whole range 6 of 21) Dry run: `python3 scripts/conformance-eval/select-tasks.py --since 8223cf8` selects a handful, h2
       among them, not 21 of 21. DoD: the reasoning line names the ignored counts.
3. [x] (two slices committed and pushed 2026-09-08 on the owner's yes) `baseline.md` tier-1 paragraph: one sentence on count ranges. Commits, each on the yes:
       (a) `fix(conformance-eval): a rule range from 1 is a count, and the rule ceiling is read from SKILL.md`,
       (b) `docs: baseline, lessons and plan for the selector fix`. Push on its own yes.

Not in scope: the `.java` citation pattern in check-citations.py; the Java rules-table row 36; a Java
rule 13 gate.
