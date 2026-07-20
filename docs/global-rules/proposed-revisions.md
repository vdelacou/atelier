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

## 10.3 Keep read paths explicit (proposed 2026-07-20, status: proposed)

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

**Matrix disposition.** 10.3 is COVERED in `conformance-matrix.md` today (the skill follows the canon's
current letter). This revision does not change that verdict; it widens what an "explicit read" admits. If
accepted, apply it to the vendored canon and update the reliability.md framing together, then re-pin the
canon hash.

---

## 11.3 Alert on what matters (proposed 2026-07-20, status: proposed)

**Current canon** (global-rules-dos-and-donts.md:2450-2451): the Do alerts on "error rate and p95/p99 latency crossing a user-visible budget", pages only when a human must act, and retires alerts that page twice without a fix. The Don't forbids "noisy static-threshold alerts that fire nightly".

**Defect (internal drift).** The pillar-11 prose (every-new-project.md:184) requires "alert on anomalies rather than only fixed thresholds, so the system tells you about a problem before your users do." Sub-concept 11.3 never mentions anomaly detection; its Do and its Prometheus example are budget-tied static thresholds only. A reader of the checklist alone builds exactly the "only fixed thresholds" the prose warns against, and misses novel problems a static threshold cannot catch.

**Proposed revision.**
- Do: add anomaly alerting alongside the budget thresholds, for example "Alert on error rate and p95/p99 latency crossing a user-visible budget, AND on anomalies (a clear deviation from the normal baseline) so a novel problem surfaces before users notice; page only when a human must act ..." (the rest unchanged).
- Example: optionally add a second alert that is anomaly-based (a burn-rate or baseline-deviation rule) next to the static budget-burn one.

**Skill note.** The skill's `references/observability.md` already alerts on symptom-based SLO burn; if 11.3 gains the anomaly clause, add an anomaly-alert line there so the skill still matches.

**Matrix disposition.** 11.3 is COVERED today and stays so; this closes a prose-vs-sub drift inside the canon.

---

## 12.7 One working language (proposed 2026-07-20, status: proposed)

**Current canon.** The pillar-12 prose (every-new-project.md:192) states "Pick one working language for the whole project and keep everything in it." No sub-concept carries this rule: zero matches for "working language" across the 115 sub-concepts.

**Defect (internal drift).** A distinct pillar-12 rule has no entry in the sub-concept checklist, so a reader following only the 115 sub-concepts never meets it. The skill's `references/governance.md` already states it, so the skill is ahead of the canon's own checklist here.

**Proposed revision (two options, maintainer's choice).**
- Option A (cleanest topically): add a new sub-concept 12.7 "One working language", Do "Pick one working language for docs, comments, commit messages, and identifiers, and keep everything in it", Don't "Let a repo drift into a mix of languages that taxes every reader". NOTE: this raises the sub-concept count from 115 to 116, which cascades to conformance-matrix.md (a new row), the canonical index, and check-matrix-drift.py's per-pillar counts (pillar 12 goes 6 to 7); update them together.
- Option B (no renumbering): fold the rule into 12.1's Do ("... and keep the project in one working language"). Cheaper structurally, but 12.1 is about README freshness so the topical fit is looser.

**Matrix disposition.** Not a matrix row today (a canon-internal gap, not a skill gap; the skill covers it). Option A adds a 116th sub-concept and a matrix row; Option B leaves the count at 115.

---

## 15.5 Compliance is not proof (proposed 2026-07-20, status: proposed)

**Current canon** (global-rules-dos-and-donts.md:2954-2959): the "DO" TLS check probes only `-tls1_1`, then prints `OK: $host refuses TLS < 1.2`.

**Defect (a bug in the canon's own example).** The script tests a single sub-1.2 protocol (TLS 1.1) but concludes the endpoint "refuses TLS < 1.2". A server still accepting TLS 1.0 or SSLv3 passes this check and prints OK, so the proof overclaims what it verifies. That is self-undermining inside a rule whose whole point is that a proof must actually check what it asserts.

**Proposed revision.** Probe every protocol below TLS 1.2 and fail if any is accepted:
```bash
for proto in ssl3 tls1 tls1_1; do
  if openssl s_client -connect "$host:443" "-$proto" </dev/null 2>/dev/null | grep -qi "Protocol.*:.*\(SSL\|TLS\)"; then
    echo "FAIL: $host accepted $proto" >&2; exit 1
  fi
done
echo "OK: $host refuses every protocol below TLS 1.2"
```
Some `openssl` builds drop `-ssl3`; skip it there. The point is to test the whole sub-1.2 range, not one protocol.

**Matrix disposition.** No matrix impact; the skill does not vendor this script, and 15.5 is COVERED via the skill's own re-runnable-proof discipline. This fixes a defect in the canon's illustrative example.
