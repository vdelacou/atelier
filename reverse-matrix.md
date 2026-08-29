# Atelier reverse matrix (skill rules into canon)

The forward audit (`conformance-matrix.md`) proves every canon sub-concept has a home in the
skill, 117/117. This is the other direction: one row per atelier hard rule 1-34, asking whether
the canon carries the rule's substance. Audited against the 117-row canon; 13.5's acceptance moved three rows the same day. Three verdicts:

- **CANON-ROW**: a canon sub-concept carries the substance at comparable strength.
- **STRICTER-THAN**: the canon carries the concern; atelier exceeds or quantifies it.
- **NO-COUNTERPART**: nothing in the 117 sub-concepts carries it. The category column says
  why, and the two categories mean opposite things: a *stack binding* is the deliberate
  division of labor (the canon fixes THAT a choice is made and machine-enforced, the profile
  fixes WHICH; nearest canon row named for the umbrella), while *agent discipline* is a
  candidate canon gap, because the concern is stack-agnostic and currently lives only in this
  stack profile.

Not a CI gate, deliberately: the forward drift gate already pins the canon side, and this file
cites SKILL.md rule numbers no validator parses. A stale reference here is accepted risk;
re-audit when the hard-rule list changes.

## Pinned inputs

- Skill: `skills/atelier/SKILL.md`, hard rules at lines 153-217, audited 2026-08-30.
- Canon: the vendored `docs/global-rules/` at the hashes pinned in `conformance-matrix.md`
  (118 sub-concepts after 1.3 and 13.5, both accepted 2026-08-30).

## Rows

| Rule | Substance | Verdict | Canon row(s) | Category / note |
|---|---|---|---|---|
| 1 | No `class` keyword | NO-COUNTERPART | nearest 1.1 | Stack binding; the canon mandates one enforced style, the profile fixes which |
| 2 | No `function` declarations | NO-COUNTERPART | nearest 1.1 | Stack binding |
| 3 | No `interface`, always `type` | NO-COUNTERPART | nearest 1.1 | Stack binding; inverts in the Java translation, which is the proof it is profile, not principle |
| 4 | No `console.*`, injected Logger port | STRICTER-THAN | 3.2, 6.3 | Port discipline is 3.2 and redaction is 6.3; the absolute ban plus one Winston wiring is profile excess |
| 5 | Bun-only toolchain | NO-COUNTERPART | nearest 1.1 | Stack binding; determinism rationale echoes 5.3 |
| 6 | Explicit return types on exports | NO-COUNTERPART | nearest 1.1 | Stack binding |
| 7 | Type-only imports on their own line | NO-COUNTERPART | nearest 1.1 | Stack binding |
| 8 | Quotes, semicolons, formatting values | CANON-ROW | 1.1 | This IS the committed config 1.1 demands, instantiated |
| 9 | ESM only | NO-COUNTERPART | nearest 1.1 | Stack binding |
| 10 | No custom error classes | CANON-ROW | 10.2 | Bespoke exception types are the anti-pattern both name; Java translation says it verbatim |
| 11 | No production code without a failing test | CANON-ROW | 4.3 | Test-first is the canon's stated philosophy; the conformance eval tags this 4.3 |
| 12 | Branded types at trust boundaries | CANON-ROW | 10.11, 5.5 | Parse-don't-validate plus validate-at-the-boundary |
| 13 | No `mock`, the entire namespace | STRICTER-THAN | 4.5 | Absolute, lint-enforced ban where the canon advises prefer-fakes (forward matrix STRICTER row) |
| 14 | Primary-port SUT, outside-in classicist | CANON-ROW | 4.5, 4.1 | Behavior-not-internals plus layered testing |
| 15 | Zero warnings, no inline ignores | CANON-ROW | 15.3, 15.1 | No-silent-opt-out made executable |
| 16 | `Result<T, E>` at IO boundaries | CANON-ROW | 10.2 | Errors as values |
| 17 | `try/catch` quarantined to infra | STRICTER-THAN | 10.2, 3.1 | The canon says errors are values; atelier adds WHERE catching may happen |
| 18 | No curried arrow chains | NO-COUNTERPART | nearest 1.1, 1.2 | Stack binding |
| 19 | No `latest`/`*`; constrained versions | CANON-ROW | 5.3 | Post-P6 5.3 says exactly this: constrained range plus committed lockfile |
| 20 | `Bun.file` in production, `node:fs` at edges | NO-COUNTERPART | nearest 3.1 | Stack binding |
| 21 | Design system independent and logic-free | STRICTER-THAN | 3.3 | The canon seals presentation behind a design system; Atomic Design taxonomy, no-hooks, and the import bans are profile mechanics |
| 22 | Styling sealed, no Tailwind in app code | STRICTER-THAN | 3.3 | The seal made mechanical for one styling system |
| 23 | Conventional Commits, hook-enforced | CANON-ROW | 1.3 | Added to canon 2026-08-30; the hook plus CI re-check is its gate |
| 24 | Never touch a test without explicit confirmation | CANON-ROW | 13.5 | Was NO-COUNTERPART at audit time; 13.5 accepted 2026-08-30 from this audit's finding |
| 25 | Never commit or push unconfirmed | CANON-ROW | 13.5, 13.2 | Was NO-COUNTERPART at audit time; 13.5 accepted 2026-08-30 |
| 26 | Identity in commit metadata, never file contents | CANON-ROW | 13.5 | Was NO-COUNTERPART at audit time; 13.5 accepted 2026-08-30 |
| 27 | No personal data in logs, URLs, query strings | CANON-ROW | 6.3 | |
| 28 | Tenant isolation token-derived, fail-closed, proven | STRICTER-THAN | 7.1, 7.3, 7.5 | Per-endpoint 404 plus forged-header test and a tripwire script (forward matrix STRICTER row) |
| 29 | Deadline on every outbound call; retries constrained | CANON-ROW | 10.13 | |
| 30 | Additive and reversible; soft delete | CANON-ROW | 10.9, 8.5 | |
| 31 | No lost updates; versioned writes | CANON-ROW | 10.12 | |
| 32 | AI model behind a port, pinned, eval-gated | CANON-ROW | 3.9, 4.8, 5.8 | |
| 33 | Never build auth or crypto yourself | CANON-ROW | 5.2, 9.3 | Auto-TLS clause lands in 9.3 |
| 34 | Production data never leaves production | CANON-ROW | 6.6 | |

## Tally

| Verdict | Count | Rules |
|---|---|---|
| CANON-ROW | 19 | 8, 10, 11, 12, 14, 15, 16, 19, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 34 |
| STRICTER-THAN | 6 | 4, 13, 17, 21, 22, 28 |
| NO-COUNTERPART, stack binding | 9 | 1, 2, 3, 5, 6, 7, 9, 18, 20 |
| Total | 34 | |

Counting plainly: 19 covered, 6 stricter, 9 stack bindings. The stack bindings are the point of
a profile and propose nothing back to the canon. The audit's one actionable finding, three
agent-discipline rules (24-26) with no canon home, became P6 row 13.5 and was ACCEPTED the same
day, which is why those rows read CANON-ROW with an at-audit-time note: this file caused the
row it now cites. The canon count is 118 from that acceptance.

Outside the 34: the skill's process artifacts already have canon homes. The append-only
LESSONS journal is 12.4 (institutional memory) and 10.10 (learn from every failure); PLAN.md
with a per-step definition of done is 12.3-adjacent (decisions recorded where they cannot
drift). No proposal needed there.
