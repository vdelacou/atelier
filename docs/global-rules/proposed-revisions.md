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
`references/workflow.md:427-437` requires a committed lockfile and `bun update` in the same
commit; `references/security.md:66` requires `bun install --frozen-lockfile` in CI. This is
the more precise expression of the rule's real goal, so the skill is not amended.

**Matrix disposition.** Accepted 2026-07-20. The vendored canon 5.3 (both the dos-and-donts Do,
Don't, and TS example, and the pillar-prose sentence) now carries this revision; the proposed text
above is the text that landed. `conformance-matrix.md` pins the revised canon hashes and records
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

