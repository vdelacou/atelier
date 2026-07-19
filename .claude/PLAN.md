# PLAN: Phase 1 conformance matrix (atelier vs Global Rules canon)

Deliverable: `conformance-matrix.md` at repo root. One verdict row per Global-Rules
sub-concept (115 rows), IDs and titles verbatim from the canonical index; six-item
watchlist first, CONTRADICTS+GAP work list last, pinned header. Rules are canon; this
phase only diagnoses. Scope: Phase 1 only (user decision). Canon vendored (user decision).

Pins (step 0, recorded 2026-07-19): atelier HEAD 430c740, tree clean at start.
Canon sha256: core-values 1ffd172f..., every-new-project 63f7b8d8..., dos-and-donts 5d9eb10c...
(48 / 283 / 3403 lines). Vendored byte-identical to docs/global-rules/.

Verdict conventions (precedence CONTRADICTS > OUT-OF-SCOPE > GAP > COVERED > STRICTER-upgrade):
- CONTRADICTS: skill mandates what canon forbids; any contradicted clause dominates. Absence is never CONTRADICTS.
- COVERED: every Do clause has verified evidence; doctrine prose counts; gate-vs-doctrine lives in Enforcement column.
- Partial (>=1 clause met, >=1 absent) = GAP, Notes "Partial gap:" crediting what exists; goes to work list.
- STRICTER: COVERED on all clauses plus a verified exceeded clause. Stricter-one-clause-silent-another = GAP.
- OUT-OF-SCOPE: no clause expressible as rule/gate/tripwire/doctrine AND absence grep-confirmed; name pillar family.

Row schema: `| ID | Sub-concept | Verdict | Evidence | Enforcement | Notes |`.
Enforcement = gate | tripwire | rule | doctrine | none (strongest present).
Hyphens only, no em/en dashes anywhere (repo authoring rule).

Watchlist verdicts (FIXED orchestrator-owned, both-sides evidence gathered step 2):
- 15.1 CONTRADICTS: skill hook runs gates 4-8 (tests, lint:strict ~25s, coverage, mutation 1-3min/file) locally; canon 2827/2842 wants only fast gates (format, staged lint, secret scan) in hook, "full suite, coverage, slow scans run in CI only". Gate 3 gitleaks DOES satisfy the secret-scan clause. 15.3-the-subconcept (inline suppressions) stays COVERED; the --no-verify tension rides on 15.1. Secondary: no shipped consumer ci.yml asset (clause 2 doctrine-only).
- 5.3 CONTRADICTS: canon 933-938 DON'T example is `"^4.0.0"`, DO is exact pins `"4.6.14"`; skill check-package-json.sh permits caret ranges and workflow.md:427/436 mandates/generates `^X.Y.Z`. Scan (bun audit CI) + auto-update (Renovate, Java-only) clauses covered as doctrine, but pin-clause contradicted; CONTRADICTS dominates.
- 4.4 COVERED (gate): check-coverage.ts domain/use-cases=100, infra/composition/presenter=80; stryker break=90. Numbers match canon exactly. Note: per-file enforcement + coverage-preload (tighter than per-module framing).
- 15.2 COVERED (gate): coverage-preload forces untested files to 0% (workflow.md:170-197); exactly canon 2871.
- 6.3 COVERED (tripwire): POST body (privacy.md:44,55), logger redactFormat incl email/phone (security.md:192,209), opaque-vs-natural (privacy.md:46), check-pii-channels.sh tripwire.
- 5.5 COVERED (rule+doctrine): branded checkpoint source-to-sink (security.md:11,13); server-side authz (isolation.md, ai.md:60).
- 5.8 COVERED (rule 32): prompt-injection fencing + server-side action authz + allow-list + least privilege (ai.md:53-60,91).
- 3.5 COVERED (doctrine): gateway port + real client + canned fake + Result + DTO map (nextjs-monorepo.md:562).
- 17.6 COVERED (gate): semantic/keyboard/contrast-tokens (atomic-design.md:234-236) + jsx-a11y error-level build-failing gate (atomic-design.md:239, product.md:62); axe optional.
- 17.7 GAP: mobile-first / smallest-screen-first / one-primary-action / progressive-disclosure all absent (0 hits across skills/); `md:*`/`lg:*` responsive tooling only (atomic-design.md:206). Enforcement none.

Steps:
0. [x] Preflight, pins, 115-row index+section maps  DoD: 115/115, counts match, 0 mismatch, no pipes  DONE
1. [x] Vendor canon to docs/global-rules/ (byte-identical), overwrite this PLAN.md  DoD: sha equal, links resolve  DONE
2. [x] Six watchlist verdicts fixed with both-sides cites (above)  DoD: done; 15.3 not dragged, gate-3 gitleaks confirmed  DONE
3. [x] Fan out 7 Explore clusters; clause-accounting schema  DoD: 115/115 well-formed  DONE
4. [x] Adjudicate: grep -nF quotes, window reads, recompute verdicts, absence greps, risk-subset re-audit  DoD: zero unverified quotes; downgrade log above  DONE
5. [x] Assemble conformance-matrix.md (header, legend, watchlist, 18 tables, work list, tally)  DoD: complete, 401 lines  DONE
6. [x] Self-check 1-9  DoD: nine green (row count 115, ID+title byte-diff clean, cite grammar, work-list==CONTRADICTS+GAP, no dashes, tally 115, no cited file drifted since 430c740)  DONE
7. [ ] Deliver summary + tally + work list, ask about landing (rule 25); slice commit1=canon, commit2=matrix  DoD: nothing committed without confirmation

Downgrade log (step 4), subagent proposal -> adjudicated:
- 3.2 STRICTER -> COVERED (mock-ban strictness credited to 4.5; 3.2 core practice met). Enforcement gate.
- 3.3 STRICTER -> COVERED (canon 3.3 already mandates forbid-raw-literals; skill matches not exceeds). gate.
- 3.9 STRICTER -> COVERED (eval-gate/spend-cap extras map to 4.8/5.9, not 3.9 clauses). rule.
- 15.2 STRICTER -> COVERED (0%-report clause met not exceeded; per-tier is 4.4). gate.
- 15.3 STRICTER -> COVERED (comprehensive same no-inline-suppression mandate; conservative). gate.
- 10.14 OUT-OF-SCOPE -> GAP (OLTP/OLAP read-split is expressible doctrine and absent; 7.7 depends on it).
- KEPT STRICTER: 4.5 (absolute lint mock-ban vs canon advisory prefer), 7.5 (forged-trust-header test + gate beyond cross-tenant test), 15.4 (gates proven to fail-loud via smoke tests).
- Convention applied: STRICTER only for a verified higher bar or materially wider mandate, not merely "gated" (enforcement lives in its column). Absolute-where-canon-is-advisory counts (4.5).
Quote verification: spot-checked SKILL.md:165, workflow.md:317, observability.md:12-15, metrics.md:7-10, privacy.md:65, delivery.md:37, governance.md:12, canon 12.1/7.7 Do; all confirmed verbatim. Consumer CI workflow asset absent (assets .yml count 0) -> 4.6 GAP + 15.1 secondary.

Verdict tally: COVERED 104, STRICTER 3, GAP 6, CONTRADICTS 2, OUT-OF-SCOPE 0 (= 115).
Work list (CONTRADICTS+GAP, 8): 5.3, 15.1 (contradicts); 4.6, 5.10, 7.7, 10.14, 12.1, 17.7 (gap).
