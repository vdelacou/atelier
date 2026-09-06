# Proposed canon revisions (P6 rows)

When the atelier skill and the Global Rules canon collide, the rule is canon and the skill
amends. The one exception: when the skill exposes a defect in the rule itself, the
resolution is a proposed revision to the canon, recorded here, not a change to the skill.
Each row names the rule, quotes the current canon text with a line reference into the
vendored copy, states the defect, and proposes replacement text. Status stays "proposed"
until the canon maintainer accepts or rejects it.

This file is the P6 log for the conformance plan. A row stays a proposal until the maintainer
accepts or rejects it; on acceptance its proposed text is applied to the vendored canon at
`docs/global-rules/` and the row is marked ACCEPTED (see 5.3). `conformance-matrix.md` pins the
canon hash, so an accepted revision re-pins it in the same change.

---

## 5.3 Control your dependencies (proposed 2026-07-19, status: ACCEPTED 2026-07-20)

**Current canon** (global-rules-dos-and-donts.md:928-938):
- Do: "Pin every dependency to a fixed version, scan continuously for known
  vulnerabilities, and let automated updates keep you current."
- Don't: "Float on version ranges, or leave advisories unread until an incident."
- TypeScript example brands `{ "hono": "^4.0.0" }` the DON'T ("caret ranges resolve to
  unknown code on every install") and `{ "hono": "4.6.14" }` the DO, and annotates the DO
  with "a committed lockfile, and a scanner in CI ... bun install --frozen-lockfile in CI".

**Defect.** The rule conflates two separable things and requires both, though only one
serves its stated goal. The goal is a deterministic install. Determinism is delivered by a
committed lockfile plus a frozen-lockfile install, which the Do's own example already
mandates. Once the lockfile is committed and CI runs `--frozen-lockfile`, the installed
version is fixed by the lockfile, not by the manifest range, so whether the manifest reads
`^4.0.0` or `4.6.14` makes no difference to what installs. The rule's stated reason for
banning carets, "caret ranges resolve to unknown code on every install", is therefore false
under the very conditions the rule itself requires. Requiring exact pins in the manifest on
top of the lockfile adds no determinism, fights the package manager (`bun add` and npm both
write `^X.Y.Z`, so exact pins mean hand-editing and re-pinning after every `bun update`),
and erases the semver-compatibility intent a range documents. The genuine footguns are
`"*"` and `"latest"` and bare dist-tags, which signal unconstrained or always-upgrade
resolution; a caret backed by a committed lockfile is not one of them.

**Proposed revision.**
- Do: "Make every install deterministic with a committed lockfile and a frozen-lockfile
  install in CI, keep version declarations constrained (a caret or tilde range, never `*`
  or `latest`), scan continuously for known vulnerabilities, and let automated updates keep
  you current."
- Don't: "Declare `*`, `latest`, or a bare dist-tag, leave the lockfile uncommitted, or
  install without `--frozen-lockfile` in CI, so an install can silently drift; or leave
  advisories unread until an incident."
- TypeScript example: keep `{ "zod": "*" }` as the DON'T (unconstrained updates), move
  `{ "hono": "^4.0.0" }` to the DO alongside the committed lockfile and the CI scanner, and
  drop the "resolve to unknown code on every install" annotation.

**Skill evidence (unchanged, correct).** `assets/check-package-json.sh:31` bans exactly
`*`, `latest`, and bare dist-tags while permitting `^X.Y.Z` / `~X.Y.Z` / `>=X.Y.Z`;
`references/workflow.md:432-444` requires a committed lockfile and `bun update` in the same
commit; `references/security.md:66` requires `bun install --frozen-lockfile` in CI. This is
the more precise expression of the rule's real goal, so the skill is not amended.

**Matrix disposition.** Accepted 2026-07-20. The vendored canon 5.3 (both the dos-and-donts Do,
Don't, and TS example, and the pillar-prose sentence) now carries this revision; the proposed text
above is what landed, with one addition made at acceptance: the Do's parenthetical also admits an
exact pin, which is constrained in exactly the way a caret or tilde range is. `conformance-matrix.md` pins the revised canon hashes and records
5.3 as COVERED, and the skill's dependency gate (`check-package-json.sh`, which already permits a
constrained range plus a committed lockfile) needs no change. The finding text in the matrix
watchlist is kept as the record of what the collision was before it closed.

---

## 10.3 Keep read paths explicit (proposed 2026-07-20, status: ACCEPTED 2026-07-20)

**Current canon** (global-rules-dos-and-donts.md:1991-1992):
- Do: "Write reads as hand-authored SQL you can see and tune, and let the ORM own writes."
- Don't: "Let an ORM generate opaque queries on your hot read path (a lazy N+1 or a hidden relation cascade) that you cannot see or tune."

**Defect (mild: the letter is narrower than the intent).** The Don't targets the real problem, opaque
queries you cannot see or tune (N+1, hidden relation cascades). But the Do restricts the answer to
"hand-authored SQL", which excludes a typed query builder (Kysely, or Drizzle's query-builder API) that
emits visible, EXPLAIN-able, tunable SQL from typed code. Such a builder meets the pillar's goal exactly:
you can read the query, you can tune it, and there is no hidden relation walk, all without a raw SQL
string, and it keeps the read path type-checked against the schema. The canon in fact already uses a query
builder for reads in its OWN example: 10.4's DO is `db.select().from(receipts).where(after)...`
(dos-and-donts.md:2046), typed query-builder code, not hand-authored SQL. So 10.3's letter is inconsistent
with the canon's own sanctioned 10.4 example, and the Do forbids a middle ground the canon elsewhere relies
on. That makes this closer to a real defect than a pure judgment call, though milder than 5.3's self-contradiction.

**Proposed revision.**
- Do: "Write reads as explicit, tunable queries you can see and EXPLAIN (hand-authored SQL, or a typed
  query builder that emits visible SQL), and let the ORM own writes."
- Don't: unchanged (it correctly forbids opaque queries, not a specific tool).
- TypeScript example: optionally add a query-builder DO variant next to the raw-SQL one (for example
  `db.select({ id: receipts.id, lineCount: count(lines.id) }).from(receipts).leftJoin(lines, ...).where(eq(receipts.orgId, orgId)).groupBy(...)`),
  to show the sanctioned middle ground; the ORM relation-walk DON'T stays.

**Skill evidence.** The skill's `references/reliability.md` ("Keep read paths explicit") mirrors the
canon's hand-written-SQL framing. If this revision is accepted, that reference gains the query-builder
allowance in the same change, so the skill still matches the canon.

**Matrix disposition.** Accepted 2026-07-20. The vendored canon 10.3 Do now admits a typed query builder
that emits visible SQL alongside hand-authored SQL, removing the contradiction with the canon's own 10.4
builder DO; `references/reliability.md` gained the same allowance in the same change. 10.3 stays COVERED and
`conformance-matrix.md` pins the revised canon hash. The Don't is unchanged, and the optional query-builder
DO example variant was left for a later change to keep this commit tight.

---

## 11.3 Alert on what matters (proposed 2026-07-20, status: ACCEPTED 2026-07-20)

**Current canon** (global-rules-dos-and-donts.md:2450-2451): the Do alerts on "error rate and p95/p99 latency crossing a user-visible budget", pages only when a human must act, and retires alerts that page twice without a fix. The Don't forbids "noisy static-threshold alerts that fire nightly".

**Defect (internal drift).** The pillar-11 prose (every-new-project.md:184) requires "alert on anomalies rather than only fixed thresholds, so the system tells you about a problem before your users do." Sub-concept 11.3 never mentions anomaly detection; its Do and its Prometheus example are budget-tied static thresholds only. A reader of the checklist alone builds exactly the "only fixed thresholds" the prose warns against, and misses novel problems a static threshold cannot catch.

**Proposed revision.**
- Do: add anomaly alerting alongside the budget thresholds, for example "Alert on error rate and p95/p99 latency crossing a user-visible budget, AND on anomalies (a clear deviation from the normal baseline) so a novel problem surfaces before users notice; page only when a human must act ..." (the rest unchanged).
- Example: optionally add a second alert that is anomaly-based (a burn-rate or baseline-deviation rule) next to the static budget-burn one.

**Skill note.** The skill's `references/observability.md` already alerts on symptom-based SLO burn, which is exactly what the softened prose now endorses, so no skill change is needed.

**Matrix disposition.** Accepted 2026-07-20 by softening the prose, not the sub. The pillar-11 prose (every-new-project.md) now alerts on symptom-based signals tied to a user-visible budget (error-budget burn) rather than "anomalies rather than only fixed thresholds", matching sub 11.3 and the skill's observability.md burn-rate alerting. The sub and the skill are unchanged and 11.3 stays COVERED; the every-new-project.md hash is re-pinned in this change. Rationale: burn-rate alerting is the actionable, lower-noise practice, so the drift closed toward the sub rather than loading anomaly detection onto the checklist.

---

## 12.7 One working language (proposed 2026-07-20, status: ACCEPTED 2026-07-20, Option A)

**Current canon.** The pillar-12 prose (every-new-project.md:192) states "Pick one working language for the whole project and keep everything in it." No sub-concept carries this rule: zero matches for "working language" across the 115 sub-concepts.

**Defect (internal drift).** A distinct pillar-12 rule has no entry in the sub-concept checklist, so a reader following only the 115 sub-concepts never meets it. The skill's `references/governance.md` already states it, so the skill is ahead of the canon's own checklist here.

**Proposed revision (Option A, as landed).** Added a new sub-concept 12.7 "One working language" to the canon: Do "Pick one working language for the project's docs, comments, commit messages, and identifiers, chosen once and kept everywhere ...", Don't "Let a repo drift into a mix of languages that taxes every reader and fragments search ...", with a stack-agnostic CONTRIBUTING.md example. Option B (fold the rule into 12.1) was declined in favor of a first-class, checkable rule. The count moved from 115 to 116, cascading as noted to the canonical index (dos-and-donts), a new conformance-matrix.md row, and check-matrix-drift.py (pillar 12 count 6 to 7, total 116); all were updated together in this change.

**Matrix disposition.** Accepted 2026-07-20 (Option A). 12.7 is now a matrix row, COVERED via `references/governance.md:5` (the skill already states one working language for docs, comments, commit messages, and identifiers, chosen once and kept everywhere). Verdict tally COVERED 112 to 113, Total 115 to 116; the dos-and-donts hash is re-pinned in this change.

---

## 15.5 Compliance is not proof (proposed 2026-07-20, status: ACCEPTED 2026-07-20)

**Current canon** (global-rules-dos-and-donts.md:2954-2959): the "DO" TLS check probes only `-tls1_1`, then prints `OK: $host refuses TLS < 1.2`.

**Defect (a bug in the canon's own example).** The script tests a single sub-1.2 protocol (TLS 1.1) but concludes the endpoint "refuses TLS < 1.2". A server still accepting TLS 1.0 or SSLv3 passes this check and prints OK, so the proof overclaims what it verifies. That is self-undermining inside a rule whose whole point is that a proof must actually check what it asserts.

**Proposed revision (as landed).** Probe every protocol below TLS 1.2 and fail if any is accepted. The
landed form keys on openssl's EXIT CODE (a forced-protocol handshake that completes means the server
accepted that protocol), not on grepping the `Protocol:` line. An earlier draft grepped
`Protocol.*:.*\(SSL\|TLS\)`, but that false-FAILs: openssl prints its session default (for example
`Protocol: TLSv1.3`) even when the forced old protocol was refused, so the grep matches on a refusal.
Verified live against OpenSSL 3.6 on 2026-07-20 (a refused `-tls1`/`-tls1_1` still printed `Protocol: TLSv1.3`
yet exited non-zero; an accepted `-tls1_2` exited zero). The OK line claims only what this build can probe,
since a modern openssl cannot offer `-ssl3` and simply skips that leg:
```bash
for proto in ssl3 tls1 tls1_1; do
  if openssl s_client -connect "$host:443" "-$proto" </dev/null >/dev/null 2>&1; then
    echo "FAIL: $host accepted $proto" >&2
    exit 1
  fi
done
echo "OK: $host refuses every sub-TLS-1.2 protocol this openssl can probe"
```

**Matrix disposition.** Accepted 2026-07-20; the vendored canon carries the corrected script. No matrix-row
impact: the skill does not vendor this script, and 15.5 stays COVERED via the skill's own re-runnable-proof
discipline. The re-pinned dos-and-donts hash reflects this fix and the 10.3 widening together.

---

## 1.3 One grammar for the history (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

**Current canon** (global-rules-dos-and-donts.md:151-177, the comment at :167): the DO example block ends with the
comment "type(scope): imperative subject, 72 chars max; the body explains why, the diff already
shows what", and seven lines later (:174) the gate block prescribes
`extends: ["@commitlint/config-conventional"]`.

**Defect (the row contradicts the gate it prescribes).** `@commitlint/config-conventional` ships
`header-max-length` at 100, not 72, so a repo that installs exactly what 1.3 asks for accepts a
90-character subject the same row calls too long. The prose limit is unenforceable by the named
config, and a reader who trusts the prose has to override a rule the canon did not mention. Two
numbers for one limit is the drift 12.1 exists to prevent.

**Proposed revision (as landed).** State 100, to match `@commitlint/config-conventional`'s
documented default. The alternative considered was dropping the count and deferring to the gate
("within your commitlint header limit"); 100 won because a concrete number is more useful than a
pointer, and it is what the prescribed gate actually enforces:

```text
# type(scope): imperative subject, 100 chars max (config-conventional's header-max-length default);
# the body explains why, the diff already shows what
```

Had the canon settled on 72 instead, the gate block would have needed the override alongside it
(`rules: { header-max-length: [2, "always", 72] }`), and the skill would have moved with it: the
hook's `max_len`, rule 23's text, and the smoke tests' >100-char case.

**Matrix disposition.** Accepted 2026-08-30 by the canon owner; the vendored canon carries the
100-char comment and the dos-and-donts hash is re-pinned in the same change. No skill change: the
`commit-msg` hook and rule 23 already cap at 100, so 1.3 stays COVERED with no divergence left.

---

## 13.5 The agent proposes, the human disposes (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

**Current canon.** Nothing. The reverse audit of the atelier profile (reverse-matrix.md,
2026-08-30) mapped all 34 of its hard rules into the canon and found exactly one category with
no counterpart that is not a deliberate stack binding: the agent-discipline rules. Atelier 24
(never create, edit, or delete a test without explicit human confirmation), 25 (never commit or
push on the agent's own initiative), and 26 (the author's identity lives in commit metadata,
never in file contents) are stack-agnostic working agreements for AI-assisted development, and
today they exist only inside one stack profile. A team adopting the canon without that profile
gets no guidance on them at all.

**Defect (a scope gap, not a contradiction).** The canon governs the codebase and the
organization; since 5.8 it also governs how software treats model OUTPUT (untrusted content is
not instructions). It says nothing about the model as an ACTOR in the development loop, and
that gap sits exactly where 13.2 already operates: separation of duties. An agent that rewrites
a failing test, lands its own commit, or stamps a person's name into an artifact is an author
approving their own change, the move 13.2 exists to prevent, but 13.2's text only imagines
human authors.

**Proposed revision.** One new sub-concept, 13.5, under pillar 13 (Clear ownership), not a 19th
pillar: three rules do not justify a pillar, the concern IS duty separation, and the 12.7
precedent (a new sub-concept for a cross-cutting working-language rule) fits. Draft:

```md
### 13.5 The agent proposes, the human disposes
**Do:** Give every AI agent in the development loop a standing working agreement: tests and
the safety net are confirmation-gated (an agent proposes a new or changed test and waits for
an explicit yes), landing is human (no commit, push, publish, or deploy on the agent's own
initiative), and artifacts stay identity-clean (a person's name, employer, or client appears
in commit metadata where attribution is deliberate, never in file contents). The agent's
change reaches main through the same separated duties as any author's (13.2).
**Don't:** Let an agent silently weaken a failing test to green, land its own work, or bake
personal identity into files, and then call the result reviewed because a human once approved
the session.
```

Cascade if accepted: index line for pillar 13, canonical count 117 to 118, both matrix files
(a 13.5 row in the forward matrix, likely COVERED by atelier 24-26 verbatim; the reverse
matrix rows for 24-26 flip from NO-COUNTERPART to CANON-ROW 13.5), the drift checker's
PER_PILLAR pillar-13 count 4 to 5, and both dos-and-donts hash pins.

**Ruling.** ACCEPTED as drafted by the canon owner, same day; the cascade below is applied. The rejected homes stay recorded: The alternative homes considered: a 19th pillar
(rejected: too small, and it would fragment duty-separation doctrine across two pillars) and
pillar 15 (rejected: 15 is about enforcement machinery, and these rules bind before any gate
runs). Cascade applied in the same change: canon section and index, pillar prose bullet, count 117 to 118, forward matrix row (COVERED), reverse matrix rows 24-26 flipped to CANON-ROW 13.5, drift checker counts, both pins.


---

## 15.10 Prove the gate can fail (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

**Current canon.** Pillar 15 carries nine sub-concepts (global-rules-dos-and-donts.md:76):
the standard is executable (15.1), fails loud (15.2), has no silent opt-out (15.3), the
product's guards are tested from the bypass side (15.4), proof is re-checkable (15.8). The
nearest statement of this row is an aside inside 15.2's example comment (:2925), "a gate
that cannot fail is worse than no gate: it lies", said there about one failure mode only,
coverage denominators that hide untested files. The pillar prose carries a second aside
(every-new-project.md's failing-loud bullet, "make sure each gate can actually fail on the
thing it exists to catch"), also without the mechanism that would make it checkable.

**Defect (a stated principle with no operational rule).** The canon demands proof-of-failure
from every layer except its own enforcement machinery. 10.6 accepts only backups you have
actually restored, 4.4 accepts only tests proven able to kill mutants, 7.5 proves isolation
per endpoint, 15.4 proves the guard refuses the forged request. The gates themselves get no
such demand: a check wired into CI and only ever seen green is a hypothesis, and it fails in
exactly the way 15.2 warns about, silently, because a toolchain major, a renamed config key,
or a flipped plugin default can turn the rule off while the pipeline stays green. Not
theoretical: the atelier profile's smoke tests exist because a sonarjs upgrade silently
changed what a rule flagged, and that repo now lands every gate beside a violation fixture
its suite proves is rejected. The canon states the insight in a comment and operationalizes
it nowhere.

**Proposed revision.** One new sub-concept, 15.10, under pillar 15. Draft:

```md
### 15.10 Prove the gate can fail
**Do:** Land every gate with its red path demonstrated: a violation fixture the gate must
reject, kept in the suite and re-run on every change, so an upgrade that silently disables
the gate turns the pipeline red. A gate is proven by the change it blocks, not by the green
runs it decorates.
**Don't:** Wire a check into CI, watch it pass on compliant code, and call that enforcement;
a gate nobody has ever seen red may already be off.
```

plus a stack-agnostic example block in the file's idiom:

```sh
# DON'T: the lint gate is trusted because it has always passed
lint src/
# DO: the suite also feeds the gate a known violation and demands rejection
echo 'forbidden_construct' > fixtures/violation.src
if lint fixtures/violation.src; then echo "gate is silently off"; exit 1; fi
```

Cascade if accepted: canon section after 15.9, pillar-15 index line (:76), a prose bullet in
every-new-project.md's pillar 15; canonical count 118 to 119; drift checker TOTAL and
PER_PILLAR (pillar 15, 9 to 10); a 15.10 row in the forward matrix, and honestly earning it
requires a skill amendment in the same change, because today the discipline binds only the
skill repo itself (its CLAUDE.md process rule and three smoke tests), not the repos the
skill produces; one doctrine sentence in SKILL.md's gate section or
references/governance.md closes that. The reverse matrix rows are untouched (this is not
one of the 34) but its "Outside the 34" paragraph gains a line. Both hash pins re-pin.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-08-30. Cascade applied in the same
change: canon section after 15.9 plus index entry; the pillar prose extends its existing
failing-loud bullet with the fixture mechanism rather than adding a redundant one; count 118
to 119; drift checker TOTAL and pillar-15 count 9 to 10; forward matrix row 15.10 (COVERED
via the new doctrine paragraph after SKILL.md's variant gate table). One knock-on the draft
did not foresee: forward row 15.4 slims from STRICTER back to COVERED, because its recorded
surplus ("each shipped gate is proven to fail on its target violation") is exactly the
discipline that is now canon row 15.10. Reverse matrix "Outside the 34" notes the origin.
Both pins re-pinned.

---

## 10.2 Errors as values, not exceptions (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

**Current canon** (global-rules-dos-and-donts.md:1982-1984):
- Do: "Return a typed success-or-failure value from anything that can fail; reserve
  exceptions for genuine bugs."
- Don't: "Throw for an expected business outcome and hope a caller catches it."
The three example blocks all show the error's type moving into the return value; none shows
where a try/catch may live. The pillar-10 prose bullet
(global-rules-every-new-project.md:163) paraphrases the same two clauses.

**Defect (the rule fixes the error's type but not the catch's place).** Foreign code throws:
drivers, SDKs, the standard library, the runtime. So every real codebase contains try/catch
somewhere, and the canon never says where. A codebase can comply with 10.2 as written while
scattering try/catch through business logic, each catch dutifully converting to a value, and
the harm 10.2 targets survives: handling smeared across layers, and jumps a signature does
not show. The placement rule that closes the gap is stack-agnostic and proven in two
languages by the atelier profile (hard rule 17 and its Java translation): thrown-to-value
translation happens once, in the adapter that owns the foreign call, and domain and
application code neither throw nor catch expected outcomes. Placement is also what makes the
rule mechanically checkable, a linter can ban `try` under `src/domain/`; no tool can check
"reserved for genuine bugs".

**Proposed revision.** Strengthen the two lines; the examples stand as-is:

```md
**Do:** Return a typed success-or-failure value from anything that can fail; reserve
exceptions for genuine bugs. Where foreign code throws, catch it once, in the adapter that
owns the call, and translate to the value there; domain and application code neither throw
nor catch expected outcomes.
**Don't:** Throw for an expected business outcome and hope a caller catches it, or scatter
try/catch through business logic when one boundary adapter should quarantine it.
```

Cascade if accepted: the two lines at :1983-1984; the pillar-10 bullet in
every-new-project.md gains the placement clause; no count change, drift checker untouched;
forward matrix row 10.2 evidence gains rule 17; reverse matrix row 17 flips STRICTER-THAN to
CANON-ROW 10.2 (tally becomes 20 canon, 5 stricter, 9 stack). Both hash pins re-pin.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-08-30. Cascade applied in the same
change: the two Do/Don't lines strengthened, the pillar-10 bullet gains the placement clause,
forward matrix 10.2 evidence now cites rules 16 and 17 (SKILL.md:168-169), reverse matrix row
17 flipped with the tally, both pins re-pinned. No skill change needed: rule 17 already says
where the catch lives, which is what made this a canon defect rather than a skill one.

---

## Cross-reference repairs, 1.3 cascade completion (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

Six mechanical defects found by the 2026-08-30 full-repo audit's canon internal-consistency
pass. No rule substance changes; every edit aligns an example, a tag, or a word with a row
that already governs it. Batched as one row because each alone is below the P6 grain.

1. **8.1 exemplar violates 1.3** (dos-and-donts.md:1655). The trunk-based DO block commits
   `"Add total_cents column to receipts (expand step)"`, which the commitlint gate 1.3
   mandates would reject. Left behind by the 1.3 addition. Fix: `"feat(receipts): add
   total_cents column (expand step)"`.
2. **Misattributed tag** (:1203). `// 7.1: unreachable looks absent` credits 7.1, which says
   nothing about 404-as-absence; that convention is 7.5's. Fix: `7.5:`.
3. **15.2 aside now duplicates 15.10** (:2925). "a gate that cannot fail is worse than no
   gate: it lies" is 15.10's thesis; the canon annotates such pairs elsewhere (4.4/15.2).
   Fix: append `(15.10)`.
4. **4.7 aside half-duplicates 13.5** (:859). "the reviewer reads the diff, not the
   attribution" is 13.5's Don't in miniature. Fix: append `(13.5)`.
5. **Misplaced 2.2 tag** (:344). The tag annotates "the empty column is the cheap one to add
   later", a claim 2.2 does not make; it belongs on the delete-bias clause "and nothing
   else". Fix: move the tag.
6. **1.3 wording drift** (:167). The Do and the pillar prose say "imperative summary"; the
   example comment says "imperative subject". Fix: "summary".

Cascade if accepted: the six line edits, no count change, no index change, both hash pins
re-pin, citations-lock re-locked. No skill change: nothing here alters what any rule asks.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-08-30, same day; all six edits applied
and the dos-and-donts pin re-pinned in the same change.

---

## Cascade repairs, 10.3 prose leg (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

Two mechanical defects found by a prose-vs-sub sweep of all 18 pillars, run after the same day's
acceptances. No rule substance changes; each edit aligns a record with a ruling already made.
Batched as one row because each alone is below the P6 grain, following the cross-reference-repairs
precedent above.

1. **10.3's prose leg never cascaded** (every-new-project.md:164). The 10.3 revision (ACCEPTED
   2026-07-20) widened the sub's Do to admit "a typed query builder that emits visible SQL", and
   `references/reliability.md:30` moved with it, but the pillar-10 prose bullet still read "Write
   read queries by hand so you can see and tune exactly what runs", forbidding what the sub now
   allows. A reader of the prose alone builds to the pre-revision rule, and the canon's own 10.4
   DO (a query builder) stays inconsistent with it. Same drift class the 11.3 row closed, prose
   against sub. Fix: "Write read queries so you can see and tune exactly what runs, by hand or
   through a typed query builder that emits visible SQL, because ...".
2. **5.3's disposition overstates fidelity** (this file, the 5.3 row). It claimed "the proposed
   text above is the text that landed", but the landed Do reads "(a caret or tilde range, or an
   exact pin, never `*` or `latest`)" where the proposal read "(a caret or tilde range, never `*`
   or `latest`)". The addition is right on the merits, an exact pin is constrained in the same way
   a range is, but this log is the record of what landed and has to say so. Fix: state the
   addition in the disposition.

**Sweep result** (every pillar prose bullet read against the sub Do/Don't it governs, 18 pillars,
119 subs). One contradiction, item 1, and it is the only one. No sub-concept is missing from the
prose. Three prose-only obligations carry no sub, which is the 12.7 class rather than this one and
is left as a finding for the canon owner rather than repaired here: pillar 17's bundle budget
("hold the bundle to a budget the pipeline enforces and measure it on a real phone",
every-new-project.md:259, absent from 17.7), pillar 18's exemption from the go/no-go for a build
whose product is the practice itself (:269, absent from 18.3), and pillar 4's PR-scoped mutation
runs (:80, absent from 4.4). The rest of the prose surplus is detail that narrows nothing (10.4's
composite index, 10.6's quarterly cadence, 10.13's circuit-breaker restraint, 7.5's real engine)
and needs no row.

Cascade if accepted: one line edit in every-new-project.md and one in this file, no count change,
no index change, no skill change (`references/reliability.md` already carries the widened rule,
which is what makes this a missed cascade rather than a divergence). The every-new-project hash
re-pins in `conformance-matrix.md`; citations-lock scans only the two matrices, so it re-locks
only if a citation pinned the edited line.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-08-30, same day; both edits applied and
the every-new-project pin re-pinned in the same change.

---

## 17.7 Mobile first, and a light interface (proposed 2026-08-30, status: ACCEPTED 2026-08-30)

**Current canon** (global-rules-dos-and-donts.md:3362-3363): the Do designs the smallest screen
first, asks for one clear primary action per view, and keeps each screen to the controls it needs.
The Don't forbids the crowded screen and the shrunk-desktop layout. Neither line mentions payload
weight. The pillar-17 prose (every-new-project.md:259) does: "hold the bundle to a budget the
pipeline enforces and measure it on a real phone", closing with the observation that most people
meet the product on a mid-range phone.

**Defect (internal drift, the 12.7 class).** A pillar-17 obligation has no clause in the
sub-concept checklist, so a reader following only the 119 subs never meets it. It is not a
paraphrase gap: the prose asks for a CI gate with a number, and 17.7 as written is satisfied by a
lean-looking screen that ships megabytes of JavaScript. The same shape as 12.7 (one working
language), found by the 2026-08-30 prose-vs-sub sweep recorded in the cascade-repairs row above.

**Proposed revision (as landed).** Strengthen the two lines rather than add a sub, since the
concern IS 17.7's lightness and a new row would split one rule across two. The 10.2 precedent
(strengthen the clause, no count change) applies:

```md
**Do:** Design the smallest screen first with one clear primary action per view, let each screen
carry only the controls that view needs, and hold the shipped bundle to a weight budget the
pipeline enforces, because a light interface should be a light payload too.
**Don't:** Crowd every screen with buttons, options, and panels, build for a wide desktop and
shrink it afterward so a phone gets a dense mess in a thumb's reach, or let the bundle grow
unmeasured until a mid-range phone pays for it.
```

The two options declined: a new sub 17.8 (rejected, it fragments one rule and moves the count off
119 for a clause), and leaving the obligation in prose only (rejected, that is the drift 12.7
exists to prevent). The prose's "measure it on a real phone" stays prose: the sub keeps the
checkable half, the gate and its number, and the React example block is left as-is, the way 10.3's
optional example variant was deferred.

**Skill evidence (unchanged, correct).** `references/product.md:86` already makes weight a number
the pipeline enforces, and `assets/check-bundle-size.sh` is the shipped gate that fails the build
when the gzipped bundle crosses its ceiling. The skill was ahead of the canon's checklist here,
which is what made this a canon defect rather than a skill one.

**Matrix disposition.** Accepted 2026-08-30 by the canon owner. Cascade applied in the same
change: the two lines at :3362-3363, no count change and no index change (the title is untouched),
forward matrix row 17.7 evidence now cites `product.md:86` and the shipped gate and stays COVERED,
reverse matrix untouched (no hard rule maps to bundle weight), and the dos-and-donts hash re-pinned
with the citations lock re-locked for the new anchored citation.

---

## 10.6 / 6.6 The restore drill never becomes a production clone (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** 6.6's Don't (global-rules-dos-and-donts.md:1370): "Clone a production dump into a lower environment." 10.6's Do (:2138) runs "a scheduled drill that restores the backup into a scratch database", and its example (:2145-2162) restores `latest.dump` into `$SCRATCH_DB_URL` inside a CI job and asserts `count(*) FROM receipts` is non-zero.

**Defect (two Do blocks that contradict).** The 10.6 drill is, byte for byte, the operation 6.6 forbids: a production backup, full of personal data, restored into a non-production database with CI-level access. The document resolves the delete conflict between 6.4 and 10.9 explicitly (:1311, :2229) and says nothing here, so a team runs the drill believing the standard blessed it. This is the one contradiction in the file a reader will act on while feeling compliant.

**Proposed revision.** Amend 10.6's Do and its example, no count change:

```md
**Do:** Run a scheduled drill that restores the backup into an isolated restore-only target under production controls (the production access tier, no lower-environment credentials, output asserted by a script and never read by a person, dropped when the drill ends), or restores a synthetic or anonymised backup produced by the same pipeline; time it against the stated recovery objective. (6.6)
```

The example's scratch database moves behind the production boundary (`$RESTORE_DRILL_URL` in the production account, the job's identity the restore role only) and the assertion stays a count, never a row. `references/delivery.md` (Backups you have restored) inherits the clause.

Cascade if accepted: dos-and-donts 10.6 Do plus example, every-new-project.md's pillar-10 backup bullet gains "under production controls"; dos-and-donts and every-new-project pins re-pin; forward matrix row 10.6 evidence unchanged (delivery.md carries the same clause once edited); citations re-locked if the pinned lines shift.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: 10.6's Do names the restore-only target under production controls or a synthetic backup and tags 6.6; its Don't names the production-dump drill explicitly; the example restores into `$RESTORE_DRILL_URL` inside the production account and asserts by count; the pillar-10 backup bullet in the prose says the same; delivery.md's Backups section inherits the clause. Both pins re-pinned.

---

## 2.4 / 2.2 A seam is earned by an external dependency, not by a second implementation (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** 2.2's Java Don't (:231-233): "an abstract base plus one subclass, ceremony around a single behavior." 2.4's Do (:268) introduces "the interface now" and its examples (:278-279 TS, :289-290 Java) are exactly an interface plus one trivial implementation (`Cache` plus `MapCache`).

**Defect (the same shape is the Don't of one sub-concept and the Do of the next).** Both are right in their own context; the distinction that reconciles them lives in 3.2 (an external thing gets a port with a real adapter and a fake) and is stated in neither. A reader of pillar 2 alone cannot tell when one implementation behind an interface is ceremony and when it is the seam.

**Proposed revision.** One clause on 2.4's Do and one tag on 2.2's Java example, no count change:

```md
**Do:** Introduce the interface now, and implement only the version you actually need today, when the thing behind it is external (a database, a mailer, a queue, a model: the port of 3.2); a purely internal behaviour with one implementation stays a plain function or class (2.2).
```

and in 2.2's Java Don't comment: `// no IO behind this, so no port: the abstraction is ceremony (contrast 2.4)`.

Cascade if accepted: dos-and-donts 2.2 and 2.4; the pillar-2 prose bullet "Defer the build, not the seam" (every-new-project.md:53) gains "when the thing behind it is external"; both pins re-pin; forward matrix rows 2.2 and 2.4 unchanged (the skill's complexity.md already carries the external-only condition).

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: 2.4's Do carries the external-thing condition and cites 3.2 and 2.2, its Don't names the internal-logic interface; 2.2's Java Don't comment carries the contrast; the pillar-2 prose bullet says the seam is for an external thing. Both pins re-pinned.

---

## 10.2 / 5.8 / 6.1 / 6.7 The Java examples throw the outcome 10.2 forbids (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** 10.2's Don't (:1984): never throw for an expected business outcome; the 2026-08-30 strengthening fixed where a catch may live. Three Java Do blocks throw an expected outcome: 5.8 `throw new ForbiddenException()` when the model's requested action is not authorized (:1141), 6.1 `throw new ConsentRequiredException()` (:1238), 6.7 `orElseThrow(() -> new AssessmentRequiredException(...))` (:1420). Each TypeScript twin returns a value (6.7's returns `Result<Decision, 'dpia_missing'>` at :1406).

**Defect (the Java track opts out of pillar 10 by example).** A refused authorization, a missing consent and a missing impact assessment are the most expected outcomes those three flows have. The Java reader is shown the exception form as the Do, so the canon's own examples teach the anti-pattern its rule names; and the two tracks disagree on the same rule, which 1.1 (one style) forbids in spirit.

**Proposed revision.** Rewrite the three Java Do blocks to return the canon's sealed `Result` / `Err` form (the shape 10.2's own Java example uses), the resource layer translating to 403 / 409 / 422 at the boundary. 5.8's `ForbiddenException` may stay only where the catch-placement clause of 10.2 lets the resource translate it, that is, thrown by the boundary and caught by the boundary, never crossing a use-case. No count change. Draft after the atelier profile's own TypeScript factory form settles (it did on 2026-09-03: `parseX` returns `Result`, `x()` asserts), so the two tracks and the profile agree.

Cascade if accepted: three example blocks in dos-and-donts; the dos-and-donts pin re-pins; forward matrix rows 5.8, 6.1, 6.7 unchanged (the skill's ai.md and privacy.md already use `Result`).

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: 5.8's Java Do switches over the parsed tool call and returns `Err(ToolError.FORBIDDEN)` for an unauthorized action, 6.1's returns `Err(SignupError.CONSENT_REQUIRED)`, 6.7's returns `Result<Void, TransferError>` with `DPIA_MISSING`; each comment names the boundary status the resource maps it to. The dos-and-donts pin re-pinned.

---

## 8.4 / 3.6 The slice's resource still maps at the boundary (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** 3.6's Do (:511, :543-547): translate at the boundary, map the domain to a response record, "DTOs never enter use-cases". 8.4's Java Do (:1755) returns `Result<Receipt>` (the domain record) straight from the JAX-RS resource.

**Defect (one example breaks the rule of another pillar to make its own point).** 8.4 is about slice ownership, not about the wire shape, but its resource returns the domain type 3.6 forbids from crossing the boundary. A reader copying 8.4 ships the domain model over the wire.

**Proposed revision.** 8.4's Java resource returns `ReceiptResponse.from(...)` with a `(3.6)` tag; the vertical-slice point (the slice owns its handler, its data access, its infra) is untouched. No count change.

Cascade if accepted: one example block; the dos-and-donts pin re-pins; no matrix change.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: 8.4's resource returns `Result<ReceiptResponse, ReceiptError>`, mapping `ReceiptResponse.from(r)` in the `Ok` arm with a 3.6 tag; the slice-ownership point is untouched. The dos-and-donts pin re-pinned.

---

## Cross-reference repairs, redundancy pass (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** Six sub-concept pairs say the same thing in two places, two of them admitting it in text: 2.6 and 6.2 (:1246 "the general form of this rule is 2.6"), 15.5 and 15.8 (both "a runnable check, not a checkbox"), 5.6 and 5.10 (5.10 is 5.6 applied to the origin, :1186), 10.1 and 12.5 (the same SLO numbers, :1979 admits it), 11.3 and 16.4 (the identical "sustained window, not a spike" rule on two metrics), 7.7 and 10.14 (bulk reads come from the warehouse, each citing the other). Two artifacts are printed twice with different contents: the branch-protection block at :1908-1910 (`contexts = ["ci/plan", "ci/typecheck"]`) and at :2729-2733 (`require_code_owner_reviews` plus `contexts: ["build", "test", "typecheck", "lint"]`); the CI gate list at :833, :1681 (`bun test && bun run typecheck && bun run lint:strict`) and :2911 (`bun run lint:strict && bun test && bun run coverage`), three orders, three contents.

**Defect (drift by duplication).** Two copies of one artifact already disagree; 12.1 names that a defect. The paired sub-concepts are not wrong, but a reader who fixes one does not know the other exists.

**Proposed revision.** No merge, deliberately: a merge moves the count off 119 and triggers the full 2026-07-20 cascade plus every external scorecard that imports the ids verbatim, which 12.1 makes a defect. Instead one batched repair: reciprocal `(see N.M)` tags on the six pairs; one canonical branch-protection artifact in 13.2, with :1908-1913 reduced to a `# the required checks are the gates of 4.6; the block is in 13.2` pointer and a single `contexts` list; one canonical gate list in 4.6, with :1681 and :2911 pointing at it. No count change.

Cascade if accepted: dos-and-donts only; its pin re-pins; citations re-locked if the four pinned dos-and-donts lines shift; no matrix change.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: reciprocal tags on the six pairs wherever one side did not already cite the other (6.2, 15.5, 15.8, 5.6, 12.5, 11.3, 16.4 gained one; 2.6, 5.10, 10.1, 7.7 and 10.14 already cited their twin); both branch-protection blocks now require the single `gates` check and name 13.2 as the canonical block; the three CI gate lines are one line, the 4.6 set, in all three places. No merge, count 119, ids untouched. The dos-and-donts pin re-pinned.

---

## Profiles appendix, row A: the numbers move out of the sub-concepts (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** Eleven sub-concepts state a stack-specific number or vendor as principle: 4.4 (:745, Stryker, PIT, 100/90/80), 15.2 (`bunfig.toml`, 0.80), 1.3 (commitlint, 100 characters), 10.8 (a pinned k6 action, p99 under 300 ms at 100 VUs), 5.9 (200 000 tokens per org per day), 17.7 (180 kB and 400 kB, 44 px targets), 7.6 (UUIDv7 and a named library), 10.13 (2000 ms, 3 attempts, 200 ms jitter), 16.4 and 16.5 (50 percent week over week, CFR over 0.15 for 7 days), 14.3 (a 4-business-hour SLA, 90 percent adoption).

**Defect (profile stated as principle).** The pillar prose says the rules "do not depend on any technology" and "the stack is a detail"; the sub-concepts then name the tools and the thresholds of one stack. A team that cannot hit 90 mutation on day one stops taking the whole file seriously, and once one gate reads as theatre, 15.1 is dead. The numbers are right for the atelier profile; they are not the principle.

**Proposed revision.** A new file `docs/global-rules/global-rules-profiles.md` (the drift checker already accepts any `docs/global-rules/*.md`), holding one section per stack profile with the tools and thresholds; each sub-concept keeps the obligation shape ("a number exists, the pipeline enforces it, the number lives in the project's profile") and points at the appendix. Row A moves one exemplar, 4.4, to prove the shape:

```md
**Do:** Judge a suite by its mutation score, not its line coverage: core logic gates on a mutation threshold and a line-coverage floor the project's profile names, glue and adapters on an explicit looser floor, and when a gate is hard to pass the code is restructured, never the threshold lowered.
```

with `global-rules-profiles.md` § atelier carrying "Stryker (TS) and PIT (Java); core 100 percent line, 90 mutation; glue 80 percent line". Row B, proposed only once A is accepted, moves the other ten the same way.

Cascade if accepted: dos-and-donts 4.4 Do; the new profiles file added to the matrix's pinned-inputs table with its sha256; the drift checker's file set (it globs the directory, so no code change, but its selftest gains the fourth file); matrix rows stay COVERED (the skill is the atelier profile) with evidence cells unchanged; both pins re-pin. The atelier hard rule 35 threshold (10) belongs to this profile too and joins in row B.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: `docs/global-rules/global-rules-profiles.md` created with the atelier section and 4.4 as its first row; 4.4's Do keeps the obligation and points at the profile; the matrix's pinned-inputs table carries the new file's sha256 (the drift checker verifies every pinned file, so no code change); matrix rows stay COVERED with their evidence unchanged; the reverse matrix's row 35 note points at row B. Row B (the other ten numbers plus rule 35's cap) is the next proposal.

## 4.4 example: the full mutation sweep is scheduled, not a push-to-main step (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** 4.4's TypeScript example closes with the comment "mutation is slow: PRs mutate changed files (--incremental), main runs the full sweep, same break either way". The Do above it (post row A) states the obligation only: a mutation threshold and a coverage floor the profile names, restructure rather than lower.

**Defect (a cadence stated as principle).** The comment fixes when the full sweep runs, and it fixes it on the merge path: every push to main pays the whole sweep, one to two hours on a mature core, so the required check either blocks main for that long or gets bypassed. The atelier profile ruled otherwise on 2026-09-03: the changed files on every pull request and push, the full sweep once a day on a schedule, never a commit gate. The example now contradicts the profile that implements it, and the cadence is the kind of number row A moved out of the sub-concepts.

**Proposed revision.** Rewrite the comment to state the shape without the schedule: "mutation is slow: every run mutates the changed files (the pushed range, never an empty one), and a scheduled full sweep, not a merge, measures the whole tree, same break either way". The profile row carries the cadence (daily). No other text changes; the Do and Don't stand.

Cascade if accepted: dos-and-donts only, one comment line; its pin re-pins; no matrix change (row 4.4 stays COVERED, evidence unchanged).

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: the one comment line in 4.4's TypeScript example now reads "every run mutates the changed files (the pushed range, never an empty one), and a scheduled full sweep, not a merge, measures the whole tree, same break either way"; the atelier profile row carries the daily cadence. The dos-and-donts pin re-pinned; row 4.4 stays COVERED with its evidence unchanged.

---

## Profiles appendix, row B: the other ten numbers and the complexity cap (proposed 2026-09-03, status: ACCEPTED 2026-09-03)

**Current canon.** Row A (accepted 2026-09-03) moved 4.4's tools and thresholds to `global-rules-profiles.md` and left the sub-concept stating the obligation. Ten more sub-concepts still carry a stack's numbers as principle, mostly inside their examples' policy comments: 1.3 (a 100-character header, commitlint), 5.9 (100 requests a minute, 200,000 tokens a day per org), 7.6 (UUIDv7, named in the Do itself), 10.8 (k6, p99 under 300 ms, 100 virtual users for two minutes), 10.13 (a 2-second deadline, a 1-second connect, three attempts with 200 ms jitter), 14.3 (a first response under four business hours, 90 percent adoption), 15.2 (0.80 glue, 1.0 core, the 4.4 tiers restated), 16.4 (a 7-day window, 0.15 change-failure rate, sustained 24 hours), 16.5 (spend up 50 percent week over week, 7-day window, 24 hours), 17.7 (44 px targets, 180 kB of JavaScript, 400 kB total). The atelier hard rule 35 (cyclomatic complexity at most 10, accepted into the skill 2026-09-03) has no canon number at all: 1.2 says a ceiling exists and CI enforces it, which is the right shape.

**Defect (the same as row A).** A team on another stack reads "p99 under 300 ms" or "180 kB" as the rule and either inherits a budget sized for someone else's product or concludes the canon is not for them. The prose says the stack is a detail; the examples say otherwise.

**Proposed revision.** Two moves, no renumbering, no Do or Don't weakened.

1. In the dos-and-donts, each policy number that an example states as the bar gains the tag "(a profile value)" on its own comment line, so the example stays runnable and the reader knows which part is theirs to set: 1.3 the header length; 5.9 the two limits; 10.8 the p99, the users, the duration; 10.13 the deadline, the connect timeout, the attempts, the jitter; 14.3 the SLA and the adoption target; 15.2 the two floors (pointing at 4.4's profile row); 16.4 the window, the rate, the hold; 16.5 the growth, the window, the hold; 17.7 the tap target and the two weights. 7.6 is the one Do that names a scheme: it becomes "Use an identifier scheme that nothing can enumerate and the index still likes (the profile names it), keep internal keys internal, and where the flow allows it expose no id at all: scope routes by the verified identity", with UUIDv7 and its 74 random bits moving into the example comment.
2. `global-rules-profiles.md` § atelier gains eleven rows, one per sub-concept above plus 1.2 for the complexity cap, each carrying the obligation in the middle column and the atelier value on the right: 1.2 cyclomatic complexity at most 10 per function (ESLint `complexity`, PMD `CyclomaticComplexity` at report level 11); 1.3 Conventional Commits with a 100-character header, the shipped dependency-free `commit-msg` hook in the fast hook and `check-commit-messages.sh` over the pushed range in CI; 5.9 a per-caller spend guard before the call (100 requests a minute, 200,000 tokens a day per org as the shipped defaults); 7.6 UUIDv7 (`uuidv7` in TypeScript, `UuidCreator.getTimeOrderedEpoch()` in Java); 10.8 k6 in CI with a p99 budget per hot route (300 ms, 100 virtual users, two minutes as the starting point); 10.13 `AbortSignal.timeout(2000)` and three jittered attempts (200 ms) in TypeScript, a 1-second connect and 2-second per-attempt timeout with `@Retry(maxRetries = 3, jitter = 200)` in Java, an idempotency key on every retried POST; 14.3 a platform support SLA of four business hours and 90 percent of services on the current major; 15.2 the coverage floors of 4.4's row (100 core, 80 glue) with an untested file counted at 0; 16.4 a 7-day window, alert at a 0.15 change-failure rate held 24 hours; 16.5 alert at 50 percent week-over-week growth over a 7-day window held 24 hours; 17.7 44 px tap targets, `check-bundle-size.sh` with a 180 kB gzipped JavaScript budget and 400 kB total.

Cascade if accepted: dos-and-donts (ten sections, comment lines and one Do); both canon pins (dos-and-donts, profiles) re-pinned; citations re-locked if a pinned dos-and-donts line moves (7.6's Do is not pinned; 4.4's is and does not change); the reverse matrix's row 35 note flips to "landed in row B"; matrix rows stay COVERED with their evidence unchanged. No count change, no id change.

**Ruling.** ACCEPTED as drafted by the canon owner, 2026-09-03. Applied: eighteen policy numbers tagged as profile values across the ten sections, 7.6's Do restated as the obligation with UUIDv7 in the example comment, eleven rows added to the atelier profile (1.2 with rule 35's cap among them), both canon pins re-pinned, the reverse matrix's row 35 note closed. Count 119, ids untouched, matrix rows unchanged.

---

## 4.9 Run the tests in random order (proposed 2026-09-06, status: ACCEPTED 2026-09-06)

**Gap.** Pillar 4 asks for layered, fast, behaviour-facing, mutation-proven tests (4.1 to 4.5) and never says that the order they run in must not matter. A suite green only in declaration order hides a dependency between tests and fails the day a file is renamed, a runner shuffles, or a test is deleted. The atelier reference carried the idea as one smells-table row and enforced nothing.

**Proposed revision.** One new sub-concept, 4.9, under pillar 4 (Proof over hope): Do "Run the suite in a random order on every run, in the inner loop and in the pipeline, and print the seed so a failing order can be replayed. Each test builds what it needs and tears down what it made." Don't "Let one test depend on another's leftovers, or rely on declaration order, file order, or a run-this-first convention." With a TypeScript pair (a counter read across tests versus a counter per test) and a Java pair (`@Order` sequencing versus the random orderers in `junit-platform.properties`).

Cascade if accepted: index line for pillar 4, pillar prose bullet, count 119 to 120, the drift checker's PER_PILLAR pillar-4 count 8 to 9, forward matrix row 4.9 (COVERED by atelier hard rule 36: `bun test --randomize` as the test script, the CI step and Stryker's runner, the JUnit random orderers in Java), reverse matrix row 36 as CANON-ROW 4.9, both prose pins.

**Ruling.** ACCEPTED as drafted by the canon owner, same day; the cascade above is applied in the same change.

---
