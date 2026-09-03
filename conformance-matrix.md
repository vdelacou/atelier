# Atelier conformance matrix (Phase 1)

Static audit of the `atelier` Agent Skill against the Global Rules canon. One row per
sub-concept, verdict with file-level evidence. Diagnosis first; Phase 2 then resolves each
collision, and the rows resolved so far carry a resolution note. Produced by session prompt
C1 of the Atelier vs Global Rules conformance plan.

## Pinned inputs

- Audit date: 2026-07-19 (Phase 1). Phase 2 resolutions applied the same day.
- Skill audited: this repo at commit `430c740` (Phase 1 baseline). Phase 2 resolved 15.1, 4.6,
  and the five gaps 5.10, 7.7, 10.14, 12.1, 17.7, and opened a P6 revision for 5.3; those rows
  and the tally reflect the post-Phase-2 state, every other row is as audited at `430c740`.
- Canon, vendored into this repo at `docs/global-rules/`. The dos-and-donts and pillar-prose docs
  carry the accepted P6 revisions (2026-07-20; see proposed-revisions.md): 5.3 in both the dos-and-donts
  and the pillar prose; 11.3 in the pillar prose; and 10.3, 12.7, and 15.5 in the dos-and-donts. 12.7 is a
  new sub-concept, so the canonical count is now 116. They differ from the original source only in those
  rows. Canon revised again 2026-08-30 by the rules owner, adding sub-concept 1.3 One grammar for the
  history to pillar 1 in both documents, so the canonical count is now 117 and both hashes are re-pinned.
  P6 row 1.3 was then accepted the same day, setting that row's subject limit to 100 to agree with the
  commitlint config it prescribes. P6 row 13.5 (agent working agreements, from the reverse-matrix
  audit) was accepted 2026-08-30 as well, so the canonical count is 118 and both pins moved again. P6 rows 15.10 (Prove the gate can fail, distilled from this repo's own
  smoke-test discipline) and the 10.2 catch-placement strengthening were accepted 2026-08-30 too,
  taking the count to 119.
  The drift check pins the hashes below and runs against these copies:

| Canon document | Vendored path | SHA-256 | Lines |
|---|---|---|---|
| Do and Don't, with Examples (normative) | docs/global-rules/global-rules-dos-and-donts.md | 2b44bdaf1238f3e703d69347f213c560228238cfbc94e7ee3cf85708653f54f9 | 3489 |
| Every New Project Should Have (pillar prose) | docs/global-rules/global-rules-every-new-project.md | 2ab24a108d291023991b7810e19ad54c3b489990158504d584a58073de01dc90 | 285 |
| Core Values behind the Global Rules | docs/global-rules/core-values-one-pager.md | 1ffd172f81b00c35a669c05783c9b0477bf0ec6789d11b3e98478c24ac34cdd1 | 48 |

- IDs and titles are imported verbatim from the "Every sub-concept" index of the
  dos-and-donts document (its lines 44-82). That document declares this the rule: the numbers
  and titles are "the canonical rule identifiers. External checklists and scorecards import
  them verbatim; a renumbered or retitled copy is doc drift under 12.1, and a defect"
  (docs/global-rules/global-rules-dos-and-donts.md:46). This matrix holds itself to that.

## How to read a verdict

Precedence, highest wins: CONTRADICTS > OUT-OF-SCOPE > GAP > COVERED > STRICTER.

- **COVERED**: every clause of the sub-concept's Do sentence has evidence in the skill.
  Doctrine prose counts as implementation; whether a clause is machine-enforced or only
  written down is recorded in the Enforcement column, not the verdict.
- **STRICTER**: COVERED on every clause, and at least one clause is verifiably exceeded
  (a tighter threshold, a wider scope, or a harder enforcement tier than the canon asks).
- **CONTRADICTS**: the skill actively mandates or permits something the sub-concept's Do or
  Don't forbids. A single contradicted clause sets the whole row, even when other clauses are
  covered. Absence is never CONTRADICTS (that is GAP).
- **GAP**: in scope for a code-generation skill but at least one Do clause is absent. Partial
  coverage lands here, with a Note prefixed "Partial gap:" that credits what is present. Every
  GAP row is carried into the work list.
- **OUT-OF-SCOPE**: no clause of the Do could be expressed by a code-generation skill as a
  rule, a gate, a tripwire, or doctrine, and its absence is confirmed. The Note names the
  pillar family (infra, org, product, or privacy machinery).

Enforcement column, strongest tier present: **gate** (a pre-commit or CI check that blocks:
tests, coverage, mutation, lint, a check-*.sh), **tripwire** (a staged-diff discipline guard,
the repo's own term for the check-*.sh production-discipline scripts), **rule** (a SKILL.md
hard rule 1-34 the agent applies at generation time with no machine check), **doctrine** (a
reference-file prescription), or **none**.

Evidence is repo-root-relative: a `path:line` or `path:line-range`, a `gate N` address into
`skills/atelier/assets/pre-commit`, or a `rule N` into SKILL.md. Line numbers are anchored to
commit `430c740`.

## Watchlist

The six collisions the plan pre-declared, resolved first and owned directly rather than
delegated. Each carries evidence from both sides.

**1. The pre-commit hook runs the slow gates locally (15.1, CONTRADICTS; note on 15.3).**
The plan predicted this collision and it holds. Canon 15.1's Do puts only the fast gates in
the hook (its own list: "format, staged lint, secret scan") and every gate in CI, "so a
violation blocks the merge while the hook stays quick enough that nobody routes around it";
its example spells out that "the full suite, coverage, and slow scans run in CI only" because
"a gate's home is chosen by its speed, not its importance, and a multi-minute hook trains
--no-verify (15.3)" (global-rules-dos-and-donts.md:2888, 2897-2898). The skill's hook does the
opposite. `assets/pre-commit` runs eight gates in sequence, and gates 4 through 8 are the full
test suite, the type-aware strict lint (workflow.md:367@430c740 self-times it at about 25 seconds),
per-tier coverage, and Stryker mutation, which workflow.md:370@430c740 self-reports at "1-3 min per
staged file". The skill knows this creates bypass pressure and answers it with prose ("Bypass
with git commit --no-verify is reserved for genuine big-bang changes ... Do not normalise
bypassing", assets/pre-commit:21-23@430c740), which is exactly the mitigation 15.1 rejects in favor of
a fast hook. Verdict CONTRADICTS, on the hook-stays-quick clause. Two qualifiers. The
secret-scan clause is satisfied: gate 3 is `gitleaks protect --staged` (assets/pre-commit:40@430c740),
matching the canon's fast-gate list. And 15.3 as its own sub-concept (no line-by-line
suppressions) is not dragged into the contradiction, because the skill covers it separately
with a no-inline-ignore discipline; only 15.1 carries the CONTRADICTS. Resolved in Phase 2 by amending
the skill (the canon is right here: the skill's own mutation gate is multi-minute, and a slow
hook trains bypass). The hook now runs only the five fast gates (commit size, package.json,
gitleaks protect, staged lint, typecheck), and a shipped CI workflow (assets/ci.yml) runs the
full suite, coverage, and mutation as the required merge check. This row is now COVERED, and
4.6 with it.

**2. The logger redacts personal data (6.3, COVERED, tripwire).** Present and precise. Canon
6.3's Do has three clauses: personal data and free text travel in a POST body, redaction
happens at the logger before anything is written, and opaque internal ids may be logged while
natural identifiers never are (global-rules-dos-and-donts.md:1273 and the Do sentence). The
skill meets all three. POST-body-not-query-string: "Personal data and any free text the user
typed travel in a POST body ... Searching by someone's name is a POST, not a GET"
(privacy.md:44). Redact-at-the-logger: a Winston `redactFormat` whose key set is
`['password', 'token', 'authorization', 'apiKey', 'secret', 'email', 'phone']` with the note
"secrets plus natural identifiers (rule 27)" (security.md:206), applied "once, at the logger
adapter, not at every call site" (privacy.md:47). Opaque-versus-natural: "Opaque internal
identifiers are loggable ... Natural identifiers are not: email, phone, name, token, national
id" (privacy.md:46). It goes beyond doctrine to a staged-diff tripwire,
`assets/check-pii-channels.sh`, which flags personal data added to a URL, query string, or log
field, so the Enforcement tier is tripwire rather than doctrine.

**3. Coverage and mutation tiers match the canon numbers (4.4 and 15.2, COVERED, gate).**
Canon 4.4 asks core code at "100 percent line coverage and a mutation score of at least 90,
glue at an explicit looser floor (80 percent line)" using Stryker for TS
(global-rules-dos-and-donts.md:745 Do). The skill's `assets/check-coverage.ts` sets
`domain` and `use-cases` to threshold 100 and `infra`, `composition`, `presenter` to 80
(check-coverage.ts:34-38), and `assets/stryker.conf.json` sets the mutation break at 90. The
numbers line up exactly. On mechanics the skill is if anything tighter than the canon's
per-module framing: it enforces per-file against a path-prefix tier, so one weak file fails
rather than a module average, and it ships a coverage-preload that forces untested files to
appear at 0 percent, which is precisely canon 15.2's Do ("an untested file reports as 0 percent
and drags the number down", 15.2 Do; workflow.md:159-197). Both verdicts COVERED, enforced by
the coverage and mutation gates; the per-file tightening is noted but not scored as STRICTER
because the canon's clauses are all met rather than exceeded in kind.

**4. Dependency pins: caret plus committed lockfile, reconciled by the accepted P6 revision (5.3, COVERED).** This
one flipped on a close read. Canon 5.3's Do is "Pin every dependency to a fixed version, scan
continuously for known vulnerabilities, and let automated updates keep you current", and its
TypeScript example is unambiguous: the Don't is `{ "dependencies": { "hono": "^4.0.0", "zod":
"*" } }` with the comment "caret ranges resolve to unknown code on every install", and the Do
is `{ "hono": "4.6.14", "zod": "3.24.1" }`, exact pins (global-rules-dos-and-donts.md:933-938@edb98a7).
The skill permits and generates exactly the forbidden shape. `assets/check-package-json.sh`
bans only `latest`, `*`, and bare dist-tags, and its own comment lists what it "Permits: 'x':
'^1.2.3' / '~1.2.3' / '>=1.0.0'" (check-package-json.sh:37), while `bun add` "pins to ^X.Y.Z
automatically" (check-package-json.sh:71) and workflow.md:374 requires "a concrete version
(X.Y.Z) or a real range (^X.Y.Z ...)". The scan clause is covered as doctrine (`bun audit` in
CI daily and on dependency PRs, security.md:67, workflow.md:669) and the automated-update
clause is covered thinly (Renovate is named, but only in the Java reference, java-quarkus.md:19;
the Bun side leans on a manual `bun update` cadence and ships no Renovate or dependabot config).
But the pin clause is contradicted, and CONTRADICTS dominates. The skill's rationale (a
committed lockfile plus `--frozen-lockfile` makes caret ranges reproducible) is defensible and
arguably modern consensus. Resolved in Phase 2 as a P6 revision (docs/global-rules/proposed-revisions.md):
the skill is judged right and the canon's exact-pins mandate defective, because the committed
lockfile the canon itself requires already delivers the determinism, so the manifest range is
irrelevant to what installs. Accepted 2026-07-20: the vendored canon 5.3 now allows a constrained range
plus a committed lockfile and a frozen-lockfile CI install, exactly what the skill's gate enforces, so the
row is COVERED and this matrix pins the revised canon hash. The finding above is kept as the record of
what the collision was.

**5. The security model and the LLM-injection defense are both present (5.5 and 5.8, COVERED).**
Canon 5.5's Do is validate every untrusted value at one checkpoint before a query, command, or
file path, and authorize on the server. The skill's `security.md` is built on exactly this: a
source-to-sink model where "a source must cross a checkpoint before reaching a sink"
(security.md:13) and the checkpoint is "a branded type with a validating factory that sits
between source and sink" (security.md:11), with server-side authorization carried in
`isolation.md` and reinforced at security.md:33-37. Canon 5.8's Do is treat everything an AI model
reads as untrusted and authorize every action it requests server-side. The skill's `ai.md`
matches clause for clause: content is "fenced as data" so "when the email says 'delete
everything', the correct output is that the email says so" (ai.md:59), and "Every tool call or
action the model requests is validated at the boundary ... and authorized server-side against
the rights of the human or tenant it runs for" from an allow-list at least privilege
(ai.md:60). Both COVERED; 5.8 is additionally a SKILL.md hard rule (rule 32), so its
Enforcement tier is rule rather than doctrine.

**6. Frontend: the contract gateway and accessibility hold, mobile-first is missing (3.5 and
17.6 COVERED, 17.7 GAP).** Three sub-concepts, split verdicts. Canon 3.5 wants the frontend's
data access behind an interface with a real client and an in-memory fake; the skill prescribes
exactly that, "a gateway port in src/lib/ with a real client and a canned fake, returning
Result and mapping the wire DTO into the frontend's own model at that one point"
(nextjs-monorepo.md:565): COVERED. Canon 17.6's Do has four clauses (semantic elements,
keyboard-workable flows, contrast in tokens, and a gate on automated accessibility checks); the
skill meets all four, with "Semantic elements first" and "Keyboard everywhere" and "Contrast
lives in the tokens" (atomic-design.md:234-236) and a real gate, "eslint-plugin-jsx-a11y runs
error-level ... it fails the build" with the Next smoke test proving the rules fire
(atomic-design.md:239): COVERED, and gate-enforced, with a runtime axe scan noted as the
optional deeper pass. Canon 17.7 is the gap. Its Do is "Design the smallest screen first with
one clear primary action per view, and let each screen carry only the controls that view
needs", and none of those three clauses appears anywhere in the skill: greps across the whole
tree for mobile-first, smallest-screen, one-primary-action, and progressive-disclosure return
nothing on point, and the only responsive material is Tailwind `md:*`/`lg:*` shift tooling
(atomic-design.md:206@430c740), which was direction-agnostic and not a mobile-first default. 17.7 is a
GAP. Resolved in Phase 2: product.md now carries the mobile-first, one-primary-action, and
progressive-disclosure doctrine plus a bundle-budget gate prescription, and atomic-design.md
states that breakpoints scale up from the smallest screen; this row is now COVERED.


## Pillar tables

### Pillar 1: Consistency

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 1.1 | One committed config for style | COVERED | workflow.md:55; assets/pre-commit gate 5 | gate | One flat eslint.config.js embeds prettier; lint:strict is gate 5 |
| 1.2 | Cap complexity and duplication | COVERED | SKILL.md:86; SKILL.md:59; SKILL.md:57 | gate | Size caps and Rule-of-Three are generation-time rules; rule 35 gates cyclomatic complexity at 10 in every variant (ESLint `complexity`, PMD `CyclomaticComplexity`); sonarjs cognitive stays off, one metric |
| 1.3 | One grammar for the history | COVERED | SKILL.md:59; assets/commit-msg; assets/check-commit-messages.sh | gate | Conventional Commits grammar enforced by the commit-msg hook and re-checked in CI over the pushed range, so a --no-verify bypass is still caught (gate added 2026-08-30 with the canon row). The 72-vs-100 divergence closed the same day: P6 1.3 ACCEPTED 2026-08-30, canon now states 100, the documented default of @commitlint/config-conventional, which the row's own gate snippet prescribes |

### Pillar 2: Simplicity by default

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 2.1 | Do the least that works | COVERED | complexity.md:123; behavioural-examples.md:42 | rule | Lazy ladder orders stdlib and platform before a dependency |
| 2.2 | Delete before you add | COVERED | behavioural-examples.md:48; complexity.md:129 | rule | Delete-before-add stated as an explicit reflex |
| 2.3 | Earn abstractions with the Rule of Three | COVERED | SKILL.md:57; complexity.md:158 | rule | Duplication 1 leave, 2 note, 3 extract |
| 2.4 | Defer the build, not the seam | COVERED | complexity.md:135 | rule | Port and smallest adapter today; heavy implementation waits |
| 2.5 | Simplicity is not negligence | COVERED | complexity.md:144-146; behavioural-examples.md:50 | rule | Validation, Result errors, security never trimmed |
| 2.6 | Every field must earn its place | COVERED | privacy.md:7; clean-code.md:109 | rule | Name the feature that reads a field now, else omit (YAGNI plus minimize) |

### Pillar 3: Keep clean boundaries

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 3.1 | Point dependencies inward | COVERED | architecture.md:96; SKILL.md:90 | rule | Domain has zero infra dependencies; imports point inward |
| 3.2 | Put every external thing behind a port | COVERED | architecture.md:257-258; SKILL.md:49 | gate | Port plus real adapter plus in-memory fake at composition root; mock ban lint-enforced |
| 3.3 | Seal the presentation behind a design system | COVERED | SKILL.md:57; atomic-design.md:236 | gate | Props-in JSX-out, tokens only, no fetching; design-system eslint block |
| 3.4 | The backend is a client-agnostic API | COVERED | architecture.md:321 | doctrine | Resource-shaped API every client consumes the same way |
| 3.5 | Build the frontend against a contract, not a running backend | COVERED | architecture.md:331-342; nextjs-monorepo.md:565 | doctrine | Gateway port with real client and canned fake, one wiring flip (Watchlist 6) |
| 3.6 | The internal model is yours, not the API's shape | COVERED | architecture.md:325-332 | doctrine | Wire DTO mapped to own model at one point |
| 3.7 | The domain model is not the database model | COVERED | architecture.md:323 | doctrine | Repository is the single row-to-domain mapping point |
| 3.8 | Make the boundary testable | COVERED | testing.md:11; SKILL.md:57 | rule | Domain refactor never breaks tests; UI half lint-gated |
| 3.9 | The AI model is a dependency | COVERED | ai.md:7-21; behavioural-examples.md:42 | rule | Model behind port with canned fake, pinned dated snapshot (Watchlist 6; eval/spend map to 4.8/5.9) |

### Pillar 4: Proof over hope

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 4.1 | Test in layers | COVERED | testing.md:107-121 | doctrine | Unit, integration, e2e, performance layers each named |
| 4.2 | Keep unit tests in milliseconds | COVERED | testing.md:410; testing.md:140 | doctrine | In-memory fakes, no real IO in unit tests; literal ms target not stated |
| 4.3 | Have a testing philosophy | COVERED | testing.md:184-127; SKILL.md:60 | rule | Every fixed bug becomes a permanent reproducing test |
| 4.4 | Treat mutation testing as the real coverage KPI | COVERED | assets/check-coverage.ts:34-38; assets/stryker.conf.json:20 | gate | 100/100/80 tiers, Stryker break 90; matches canon numbers (Watchlist 3) |
| 4.5 | Test behavior, not internals | STRICTER | SKILL.md:49; testing.md:290 | gate | Mock ban is absolute and lint-enforced, exceeding canon advisory prefer-fakes |
| 4.6 | Gate every merge | COVERED | assets/ci.yml; governance.md:117 | gate | Resolved Phase 2: assets/ci.yml runs the full suite, coverage, and mutation on a frozen lockfile as the required merge check |
| 4.7 | Hold generated code to the same bar | COVERED | workflow.md:582 | rule | Generated code runs the identical gates and review; no --no-verify on provenance |
| 4.8 | Gate non-determinism behind evals | COVERED | ai.md:39-48; behavioural-examples.md:42 | gate | Labeled eval set gates prompt, pin, and schema changes in CI below a threshold |

### Pillar 5: Secure by default

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 5.1 | Keep secrets out of the codebase | COVERED | security.md:198; assets/pre-commit gate 3 | gate | Secret manager, rotation, central control; gitleaks gate backs the ban |
| 5.2 | Do not build authentication or crypto yourself | COVERED | security.md:35-46 | rule | OIDC plus vetted crypto, SSO and MFA on consoles (rule 33) |
| 5.3 | Control your dependencies | COVERED | assets/check-package-json.sh:37; docs/global-rules/proposed-revisions.md | gate | P6 revision ACCEPTED 2026-07-20: canon 5.3 now allows a constrained range plus a committed lockfile, which check-package-json.sh enforces (Watchlist 4) |
| 5.4 | Secure the supply chain | COVERED | delivery.md:71-73 | doctrine | Immutable digest-addressed artifacts, SBOM, cosign signatures |
| 5.5 | Validate at the boundary, authorize on the server | COVERED | security.md:13; SKILL.md:92 | rule | Branded checkpoint before sink; server-side authZ is the only one that matters (Watchlist 5) |
| 5.6 | Expose only what has to be public | COVERED | security.md:232 | doctrine | Datastores, queues, admin panels on a private network only |
| 5.7 | One security baseline everywhere | COVERED | security.md:227-217 | rule | Auth, TLS, rate limits, allow/deny default on every route (rule 33) |
| 5.8 | Untrusted content is not instructions | COVERED | ai.md:60; behavioural-examples.md:42 | rule | Model input untrusted, every action authorized server-side (rule 32) (Watchlist 5) |
| 5.9 | Cap what a caller can spend | COVERED | behavioural-examples.md:42; ai.md:74 | rule | Per-caller spend budget before the call, refuse over bill (rule 32) |
| 5.10 | One inspectable edge, no reachable origin | COVERED | security.md; delivery.md | doctrine | Resolved Phase 2: single filtering edge plus origin-lock doctrine, with the x-edge-secret origin check as defense in depth |

### Pillar 6: Private by default

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 6.1 | Know the law that follows the user | COVERED | privacy.md:13 | doctrine | Design to the strictest regime you serve; policyFor code example |
| 6.2 | Minimize and justify collection | COVERED | privacy.md:7-38 | doctrine | Collect only stated-purpose fields; explicit consent for sensitive and minors |
| 6.3 | Keep personal data out of logs and URLs | COVERED | privacy.md:44-47; security.md:206 | tripwire | POST body, logger redactFormat, opaque vs natural ids; check-pii-channels.sh (Watchlist 2) |
| 6.4 | Build for user rights from day one | COVERED | privacy.md:65-74 | doctrine | Five rights as first-class ops; erasure hard-deletes personal fields |
| 6.5 | Map and classify your data | COVERED | privacy.md:78-85 | doctrine | Generated data map with class, purpose, crossesBorder per field |
| 6.6 | Never copy production data into test or dev | COVERED | privacy.md:99 | rule | Deterministic synthetic fixtures, zero real subjects (rule 34) |
| 6.7 | Assess before risky processing | COVERED | privacy.md:111 | doctrine | Record a DPIA and gate the operation before risky processing |

### Pillar 7: Isolate by default

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 7.1 | Derive the tenant/owner from one trusted source | COVERED | isolation.md:9; SKILL.md:67 | rule | Owner from a verified token claim, never caller-controlled |
| 7.2 | Defend in depth | COVERED | isolation.md:28; SKILL.md:67 | rule | App filter plus row-level security in the same transaction |
| 7.3 | Fail closed | COVERED | isolation.md:48; SKILL.md:67 | rule | Missing owner context returns nothing, never everything or a 500 |
| 7.4 | Shrink the blast radius | COVERED | isolation.md:65-72 | doctrine | Narrowest runtime role; NOBYPASSRLS scoped grants |
| 7.5 | Prove isolation per endpoint | STRICTER | isolation.md:82-94; SKILL.md:67 | tripwire | Cross-tenant 404 test per endpoint plus a forged-trust-header edge test; check-isolation-tests.sh gates it |
| 7.6 | Make identifiers unguessable, and never the authorization | COVERED | isolation.md:106-108 | doctrine | UUIDv7, keys internal, id is defense-in-depth never authorization |
| 7.7 | No service-token backdoor for bulk reads | COVERED | isolation.md; SKILL.md:67 | doctrine | Resolved Phase 2: no service-key bulk route, analytical volume served from the data platform (ties 10.14) |

### Pillar 8: Delivery should be boring

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 8.1 | Trunk-based development with small commits | COVERED | workflow.md:249-324; assets/check-commit-size.sh:19 | gate | Trunk, sub-day branches, small commits; size gate 1 plus commit-msg |
| 8.2 | Automated pipeline, progressive delivery, one-step rollback | COVERED | delivery.md:7-12 | doctrine | Pipeline-only deploy, canary, one-re-run rollback |
| 8.3 | Infrastructure as code | COVERED | delivery.md:22 | doctrine | Every resource in version-controlled IaC, rebuilt with one command |
| 8.4 | Vertical slices | COVERED | architecture.md:37-46; workflow.md:256 | doctrine | Feature-cohesive slices, deploy independently or dark behind a flag; archetype src/ is layer-first |
| 8.5 | Change contracts additively / expand-contract | COVERED | reliability.md:112-114; assets/check-data-lifecycle.sh:31 | tripwire | Expand-migrate-contract; check-data-lifecycle.sh blocks DROP COLUMN/TABLE, RENAME, TRUNCATE, ALTER COLUMN TYPE outside a *contract* migration |
| 8.6 | Separate and ephemeral environments | COVERED | delivery.md:30 | doctrine | Throwaway per-branch environments keyed to the PR, destroyed on close |

### Pillar 9: Run as little as possible yourself

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 9.1 | Prefer managed over self-run | COVERED | delivery.md:37 | doctrine | Managed databases, queues, object stores; never a VM you own |
| 9.2 | No servers you SSH into | COVERED | delivery.md:38 | doctrine | Immutable container images replaced, not SSHed into |
| 9.3 | Automatic TLS certificates | COVERED | delivery.md:39 | doctrine | Automatic TLS only; the platform issues and renews |
| 9.4 | Only the pipeline touches infrastructure | COVERED | delivery.md:23 | doctrine | Humans read-only in prod; only the pipeline writes infrastructure |
| 9.5 | Rent open standards, so any cloud can run it | COVERED | delivery.md:45-57 | doctrine | Open interfaces, injected config, portability booted on generic backends in CI |

### Pillar 10: Design for failure

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 10.1 | Set explicit reliability targets | COVERED | observability.md:7-15 | doctrine | SLO-as-code: availability, latency, error-rate targets with windows |
| 10.2 | Errors as values, not exceptions | COVERED | result-type.md:3; SKILL.md:52-169 | rule | Every IO port and use-case returns Result; exceptions for bugs (rule 16); the 2026-08-30 catch-placement strengthening was already rule 17, catch quarantined to infra adapters |
| 10.3 | Keep read paths explicit | COVERED | reliability.md:30 | doctrine | Explicit, tunable hot-path reads (hand SQL or a visible-SQL query builder); the ORM owns writes. P6 ACCEPTED 2026-07-20, widened to match the canon's own 10.4 builder DO |
| 10.4 | Keep reads fast as the table grows | COVERED | reliability.md:49-50 | doctrine | Keyset cursor with composite index, never OFFSET; stream large sets |
| 10.5 | Do not fire and forget | COVERED | reliability.md:66-68 | doctrine | Transactional outbox, retrying worker, idempotent on a dedupe key |
| 10.6 | Keep backups you have actually restored | COVERED | delivery.md:79 | doctrine | Quarterly restore drill into a scratch DB, timed |
| 10.7 | Scale with demand | COVERED | reliability.md:120-121 | doctrine | Stateless replicas, explicit-TTL cache with invalidation; autoscale implied |
| 10.8 | Meet performance targets under load | COVERED | reliability.md:126 | doctrine | p95/p99 route budgets, k6 load-test gate fails the build |
| 10.9 | Treat data as sacred | COVERED | reliability.md:96-108; assets/check-data-lifecycle.sh | tripwire | Soft-delete default, versioned migrations; deliberate storage choice via the ADR discipline |
| 10.10 | Learn from every failure | COVERED | delivery.md:91-98 | doctrine | Blameless postmortem ending in owned, dated backlog tickets |
| 10.11 | Parse, don't validate | COVERED | reliability.md:130-133; security.md:183 | rule | Parse at the boundary into branded types; money cents, instants UTC (rule 12) |
| 10.12 | No lost updates | COVERED | reliability.md:82; SKILL.md:70 | rule | Version on read, required on write, stale write is a 409 (rule 31) |
| 10.13 | Every network call has a deadline | COVERED | reliability.md:9-11; assets/check-io-deadlines.sh | tripwire | Deadline on every outbound call, bounded jittered retries; check-io-deadlines.sh (rule 29) |
| 10.14 | Separate the analytical store from the operational one | COVERED | reliability.md | doctrine | Resolved Phase 2: OLTP/OLAP separation doctrine, ETL/CDC copy, the pipeline as the one sanctioned bulk reader (ties 7.7) |

### Pillar 11: Make it observable

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 11.1 | Instrument everything with correlated traces | COVERED | observability.md:21-22 | doctrine | Logs, metrics, traces share a trace id; OpenTelemetry not a vendor SDK |
| 11.2 | Watch behavior, not just health | COVERED | observability.md:60 | doctrine | Instrument product outcomes split by success and failure |
| 11.3 | Alert on what matters | COVERED | observability.md:89-92 | doctrine | Alert on error rate and p95/p99 SLO burn; page only on action; retire noisy alerts |

### Pillar 12: No black boxes

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 12.1 | Document the essentials and treat doc drift as a defect | COVERED | governance.md; scripts/smoke-test.sh | doctrine | Resolved Phase 2: docs-check CI doctrine (extract README commands and run them); smoke-test.sh is the exemplar |
| 12.2 | Generate API docs from the contract | COVERED | governance.md:72 | doctrine | API docs derived from the validating schema, example per endpoint, published |
| 12.3 | Record decisions where they cannot drift | COVERED | governance.md:49-65 | doctrine | ADR committed with the code, options rejected and reversal recorded |
| 12.4 | Build institutional memory | COVERED | workflow.md:5-7; lessons.md:177 | doctrine | Durable PLAN.md plus append-only LESSONS.md outlive the people |
| 12.5 | Give real-time access and commit to measurable thresholds | COVERED | governance.md:91; observability.md:18 | doctrine | Stakeholder live access; targets as metric, number, window |
| 12.6 | Run one visible, honest backlog | COVERED | governance.md:95-96 | doctrine | One visible tracker as source of truth, bugs first-class, no shadow list |
| 12.7 | One working language | COVERED | governance.md:5 | doctrine | One working language for docs, comments, commit messages, identifiers, chosen once and kept everywhere. P6 ACCEPTED 2026-07-20 (Option A, new sub-concept; count 115 to 116) |

### Pillar 13: Clear ownership

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 13.1 | Make ownership explicit | COVERED | governance.md:105-111 | doctrine | CODEOWNERS maps every path; RACI note, one Accountable |
| 13.2 | Separate duties | COVERED | governance.md:115-117 | doctrine | Requester never sole approver; no self-merge |
| 13.3 | Keep an audit trail | COVERED | governance.md:125-132 | doctrine | Approvals and emergency access leave a durable audit-log insert |
| 13.4 | Make finding problems safe and let the accountable verify | COVERED | governance.md:138-139 | doctrine | Reward detection; the accountable owner verifies via a re-runnable check |
| 13.5 | The agent proposes, the human disposes | COVERED | SKILL.md:60; SKILL.md:61; SKILL.md:62 | rule | Atelier hard rules 24-26 verbatim: confirmation-gated tests, no unconfirmed landings, identity in metadata only. P6 ACCEPTED 2026-08-30 (origin: the reverse-matrix audit; the skill had the rules before the canon had the row) |

### Pillar 14: Pave the road

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 14.1 | Provide golden paths as real artifacts | COVERED | atelier-greenfield/SKILL.md:8; skills/atelier/assets | rule | Greenfield scaffold starts green; assets ship real hooks, scripts, configs not docs |
| 14.2 | Make it self-service | COVERED | delivery.md:105 | doctrine | Provision env or pipeline via a declarative request the team owns, not a ticket |
| 14.3 | Treat the platform as a product | COVERED | delivery.md:105; governance.md:143 | doctrine | Platform is a product: owned, versioned, documented, with a feedback loop |

### Pillar 15: Enforce and verify

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 15.1 | Make the standard executable | COVERED | assets/pre-commit; assets/ci.yml | gate | Resolved Phase 2: hook restructured to 5 fast gates, full suite/coverage/mutation/strict-lint relocated to CI as the required merge gate (Watchlist 1) |
| 15.2 | Prefer failing loud to passing quietly | COVERED | workflow.md:159; assets/check-coverage.ts:148 | gate | Coverage-preload forces untested files to 0 percent and fails loud (Watchlist 3) |
| 15.3 | No silent opt-out | COVERED | workflow.md:62-82; SKILL.md:51 | gate | Project-level severity change with a reason; inline suppressions banned |
| 15.4 | Test the bypass, not the happy path | COVERED | testing.md:649-531 | gate | Tests assert forbidden paths refused; the gate-proving surplus that once made this row STRICTER became canon row 15.10 |
| 15.5 | Compliance is not proof | COVERED | workflow.md:581; governance.md:139 | doctrine | Proof is a re-runnable check anyone can execute, not a ticked box |
| 15.6 | Audit the gaps between systems | COVERED | workflow.md:573; testing.md:663 | rule | Test the full edge-to-DB path; the gap between correct systems is where attacks live |
| 15.7 | Fix the class, not the instance | COVERED | workflow.md:574-640 | gate | Enumerate the whole class with rg, fix every hit, add a CI guard |
| 15.8 | Make proof re-checkable | COVERED | governance.md:91-139; workflow.md:581 | doctrine | Reproducible evidence plus the access to run it; never a screenshot |
| 15.9 | Spend human judgment where it counts | COVERED | workflow.md:630; atomic-design.md:153 | gate | Machine owns mechanics so review spends on design and naming |
| 15.10 | Prove the gate can fail | COVERED | SKILL.md:126; scripts/smoke-test.sh | gate | Doctrine after the variant gate table, every gate lands with a violation fixture it must reject; the repo smoke tests are the reference implementation |

### Pillar 16: Measure whether you are improving

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 16.1 | Track the four DORA metrics | COVERED | metrics.md:7-12 | doctrine | Four DORA metrics derived from real pipeline events (doctrine-only COVERED) |
| 16.2 | Pair delivery metrics with flow metrics | COVERED | metrics.md:25 | doctrine | Cycle time, throughput, work-in-progress, not story points |
| 16.3 | Treat them as system metrics, not a stick for individuals | COVERED | metrics.md:3-36 | doctrine | Group by service or team, never a per-developer leaderboard |
| 16.4 | Watch the trend, not the snapshot | COVERED | metrics.md:40 | doctrine | Read the direction over weeks; alert only on a sustained shift |
| 16.5 | Treat cost as a first-class metric | COVERED | metrics.md:44 | doctrine | Cost per service, alert on unexplained growth, near-zero when idle |

### Pillar 17: Obsess over the whole experience

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 17.1 | Treat the whole journey as the product | COVERED | product.md:7-9 | doctrine | Whole journey is the product; error copy names cause and next step over a stable code |
| 17.2 | Earn trust rather than extract a sale | COVERED | product.md:25-28 | doctrine | Honest over conversion, symmetric cancel, no dark patterns |
| 17.3 | Design for real behavior, not the demo | COVERED | product.md:33-39 | doctrine | Ground flows in observed behavior per market, re-ranked on evidence |
| 17.4 | Let technology serve the person, not replace them | COVERED | product.md:47-48 | doctrine | Automation removes friction; the human path stays visible |
| 17.5 | Speak the user's language | COVERED | product.md:51-52; nextjs-monorepo.md:644 | rule | Every string in a meaning-keyed catalog; localization is a data change |
| 17.6 | Accessible by default | COVERED | atomic-design.md:234-239; nextjs-monorepo.md:300 | gate | Semantic, keyboard, token contrast; jsx-a11y error-level gate; axe optional (Watchlist 6) |
| 17.7 | Mobile first, and a light interface | COVERED | product.md:86; assets/check-bundle-size.sh; atomic-design.md:206 | gate | Resolved Phase 2: smallest-screen-first, one-primary-action, progressive-disclosure; the bundle budget is a shipped gate. P6 ACCEPTED 2026-08-30, canon 17.7 gained the budget clause the pillar prose already asked for (Watchlist 6) |

### Pillar 18: Validate before you build

| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |
|---|---|---|---|---|---|
| 18.1 | Talk to real users before you write code | COVERED | product.md:92; atelier-grill-me/SKILL.md:18 | doctrine | Short problem interviews before committing an engineer; grill-me operationalizes |
| 18.2 | Test demand with the cheapest thing | COVERED | product.md:93 | doctrine | Landing page, mockup, or concierge MVP as the cheapest demand test |
| 18.3 | Set a dated, honest go/no-go | COVERED | product.md:94-100 | doctrine | Dated go/no-go with criteria written before the evidence |
| 18.4 | Keep validating after launch | COVERED | product.md:103; observability.md:75 | doctrine | Ship behind a flag, instrument adoption, keep or kill on a threshold |

## Work list (Phase 2 input)

None. Every sub-concept is COVERED or STRICTER, so there is no CONTRADICTS or GAP row left to resolve. The collisions this list once held (5.3, 15.1, 4.6) and the gaps (5.10, 7.7, 10.14, 12.1, 17.7) were all closed; see the resolution notes in their rows and watchlist paragraphs.


## Verdict tally

| Verdict | Count |
|---|---|
| COVERED | 117 |
| STRICTER | 2 |
| GAP | 0 |
| CONTRADICTS | 0 |
| OUT-OF-SCOPE | 0 |
| Total | 119 |

No row is OUT-OF-SCOPE: the skill carries doctrine references for every organizational pillar (metrics.md, governance.md, delivery.md, observability.md, product.md, privacy.md), so infra, metrics, ownership, and product concerns are expressed as prose that shapes generated code rather than punted. After Phase 2 and the accepted 5.3 P6 revision, no row diverges: every sub-concept is covered, two of them more strictly than the canon asks. The last contradiction (5.3) closed when the canon accepted that a constrained range plus a committed lockfile satisfies the pin requirement (docs/global-rules/proposed-revisions.md); 15.1 and 4.6 were resolved by splitting the hook from CI (assets/ci.yml), and the five gaps by adding the missing doctrine. The 2026-08-30 canon addition, 1.3, landed COVERED: the grammar and its hook were already rule 23, and the CI re-check the row asks for shipped with it (assets/check-commit-messages.sh, proven both ways in both smoke tests). The same day, P6 rows 15.10 (Prove the gate can fail) and the 10.2 catch-placement strengthening were accepted: 15.10 lands COVERED via the new doctrine paragraph after the variant gate table (SKILL.md:126), which also slims 15.4 back to COVERED because its surplus was exactly this discipline, and 10.2 was already rule 17. The canonical count is 119 and both pins moved again.

