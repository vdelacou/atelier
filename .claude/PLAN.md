# PLAN: reshape rule 26, identity in metadata only, never in file contents

Decision (2026-07-19): the anonymity opt-in is removed. Rule 26 becomes: contributor
identity in commit metadata is normal and never a finding; file contents never name a
person, an employer, or a client. Rule keeps its number so 27-34 do not renumber.
Named assumption: host control files whose format is identities (CODEOWNERS, .mailmap)
count as metadata in file form and are exempt.

1. [x] atelier/SKILL.md rule 26 rewrite + workflow pointer line  DoD: no opt-in text; pointer matches
2. [x] greenfield step 5 becomes "keep identity out of file contents" (numbering intact) + output line  DoD: no anonymity mention; review-me § step 6 ref still valid
3. [x] grill-me repo-publish/anonymity bullet deleted  DoD: no rule-26 mention left
4. [x] review-me universal checks gain the content-mention lens (26)  DoD: step 3 cites 26
5. [x] workflow.md § Commit identity rewritten (metadata vs contents; scrub mechanics kept for security.md ref) + summary bullet  DoD: no opt-in; filter-repo + no-purge intact
6. [x] java-quarkus.md bootstrap step 10 clause swapped  DoD: names no opt-in; cites 26
7. [x] README.md Identity row rewritten  DoD: row matches new rule
8. [x] docs/upstream/sonarjs-ts7.md status line, drop the name, mark FILED  DoD: no person named
9. [x] Verify, bun run scripts/validate-frontmatter.ts; git diff '^+' em-dash grep empty; anonymity grep clean  DoD: all three pass
10. [x] Report, LESSONS self-violation decision (entries name the email), proposed [decision] entry, proposed commit; wait for rule-25 confirmation  DoD: proposals delivered, nothing committed
