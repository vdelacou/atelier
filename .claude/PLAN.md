# Plan: the Java rules table gains row 36 (2026-09-08)

Goal: `java-quarkus.md`'s "The hard rules, translated" table runs 1-35 then 37; rule 36 (random test
order) lives only in the Testing section, so a reader scanning the table for a rule's Java expression
finds a hole. Add the row, pointing at the Testing section and the smoke proof.

Definition of done: row 36 between rows 35 and 37 (the properties file, the two orderers, the seed
replay flag, what it forbids, "Testing, Random order" as the pointer); the one citation the insertion
shifts (`java-quarkus.md:392`, the properties line cited by forward row 4.9) re-anchored and locked;
frontmatter 4/4; em-dash gate; CI green. No CHANGELOG entry (no consumer action).

1. [x] (row in, 173 citations intact after the re-anchor; committed and pushed 2026-09-08 on the owner's yes) Insert the row; re-anchor and lock; gates. Commit on the yes: `docs(java): the rules table
       names rule 36`. Push on its own yes.
