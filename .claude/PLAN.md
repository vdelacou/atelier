# Plan: the mock ban proves red (2026-09-08)

Goal: hard rule 13 (`mock` from `bun:test` banned, `no-restricted-imports`) has shipped since the
first config and no smoke test has ever seen it fail; canon 15.10 says a gate only ever seen green is
a hypothesis. Both smoke tests gain the red fixture, in the two places the ban lives: the base block
(a `*.test.ts` importing `mock`) and a scoped block that had to re-declare it (a production file in a
Bun layer zone; a design-system component in Next), so the replace-not-merge trap is what the fixture
guards.

Definition of done: the Bun `MOCK_BAN` message ends with "(hard rule 13)" like the Next one, so the
`ban_red` helper can grep the rule tag; four `ban_red` cases (two per variant) red on that tag; both
smoke tests green locally; CHANGELOG Unreleased notes the message change; CI nine jobs green on the
push. No SKILL.md change, no tier 1 (no doctrine moved; a message gained four words).

Facts (2026-09-08): `smoke-test.sh` and `smoke-test-next.sh` carry no rule 13 proof (grep); the Bun
message is `bun-typescript.md:121`, uncited by the matrices; the Next messages (lines 256, 308) already
carry the tag; both scripts have the `ban_red` helper from the rule 37 slice; the Bun layer zones and the
Next design-system block each repeat the ban object by hand.

1. [x] (no line shift, 172 citations intact) `bun-typescript.md`: the `MOCK_BAN` message ends "then pass a fake at construction (hard rule
       13)." DoD: no line shift (citations intact), frontmatter, em-dash gate.
2. [x] (Bun 87 checks, Next 20 checks green 2026-09-08) `smoke-test.sh`: after the rule 37 case, `ban_red` on `src/domain/mocky.test.ts` (base block) and
       on `src/domain/mocky.ts` (the domain zone's copy); header list names the mock import.
       `smoke-test-next.sh`: `src/lib/mocky.test.ts` (base) and `src/components/atoms/mocky.tsx` (the
       design-system block's copy). DoD: both scripts parse; both smoke tests green locally.
3. [x] (three slices committed and pushed 2026-09-08 on the owner's yes) CHANGELOG Unreleased, a Changed line; LESSONS one short `[gotcha]`; plan final. Commits, each on
       the yes: (a) `docs(references): the mock-ban message names rule 13`, (b) `test(smoke): the mock ban
       proves red in both variants`, (c) `docs: changelog, lessons and plan for the mock-ban fixture`.
       Push on its own yes.

Not in scope: the Java variant (rule 13 there is "no Mockito in the pom", a review check with no gate
today; a pom-scan gate would be its own slice); `select-tasks.py`; the `.java` citation pattern.
