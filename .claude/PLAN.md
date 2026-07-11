# PLAN: encode the 18 global-rules pillars into the atelier skill suite + Java variant

Status: DONE. Completed 2026-07-11. Landed as 12 slices on main (user chose commit only, no push). Kept until the next task overwrites it.

## Goal
Make the atelier skill suite the LLM-executable version of the two source articles
(`~/Downloads/global-rules-every-new-project.md` + `global-rules-dos-and-donts.md`):
every pillar 1-18 sub-concept is encoded where an agent will act on it (hard rule,
reference, checklist, red flag, or companion skill). Add a Java (Quarkus-flavoured)
variant alongside the kept Bun and Next.js variants. Iterate gap-check until no
sub-concept is unmapped.

## Definition of done (whole task)
- A pillar-by-pillar coverage map (below) shows every sub-concept 1.1-18.4 mapped to
  a concrete home in the suite; no `MISSING` rows remain.
- New references exist and are indexed in SKILL.md: privacy, isolation, reliability,
  observability, delivery, ai, governance, product, java-quarkus.
- SKILL.md: new hard rules (privacy-in-logs, tenant isolation, deadlines,
  data lifecycle, no lost updates, AI-as-dependency, rented auth/crypto, no prod
  data in dev), Java variant detection + matrix column, updated reference index,
  red flags, checklists. Description <= 1024 chars, mentions Java.
- Existing references extended without breaking their current content
  (security.md, workflow.md, architecture.md, result-type.md, testing.md,
  nextjs-monorepo.md/atomic-design.md for a11y + error copy).
- Companion skills updated: greenfield (Java bootstrap + golden-path artifacts),
  review-me (new rule map), grill-me (pillar-18 validate-before-build awareness).
- README.md reflects the new surface (rules, references, Java variant).
- `bun run scripts/validate-frontmatter.ts` green; no em dashes in new prose.
- Final self-review pass re-reads both articles and re-checks the map; repeat
  until clean.
- Commit proposed only (rule 25); nothing committed or pushed without user yes.

## Steps
1. [x] Read both source articles in full.  DoD: all 18 pillars + every Do/Don't sub-concept known. [met]
2. [x] Recon existing references. DoD met: coverage map evidence-based (greps + reads).
3. [x] Write the 9 new reference files. DoD met: privacy, isolation, reliability, observability, delivery, ai, governance, product, java-quarkus written, 0 em dashes, cross-linked.
4. [x] Edit SKILL.md. DoD met: rules 27-34, 4th commitment, Production disciplines section, Java detection + matrix column + reference index, red flags, checklists; validator green, description 1022 chars.
5. [x] Extend existing references. DoD met: security (auth rented, baseline, supply chain, LLM category, FP nuance, checklist), workflow (verification discipline, CI line), architecture (API shape + 3 model boundaries + gateway, ADR tier, red flags), result-type (jitter + deadline + idempotency), testing (perf, regression, bypass, mistakes rows), complexity (defer the seam), clean-code (Money/UTC), atomic-design (a11y), nextjs-monorepo (catalog/a11y pointers).
6. [x] Companion skills. DoD met: greenfield Java path + paved-road note; review-me disciplines step + Java mapping; grill-me validate-before-build + ADR/go-no-go output.
7. [x] README.md. DoD met: intro, use-when, commitments rows, reference list (pipe separators on new entries), greenfield/review-me blurbs, layout tree, variants, credits.
8. [x] Verify. DoD met: frontmatter 4/4, cross-refs all resolve, authored text em-dash-free, descriptions within limits.
9. [x] Self-review loop. DoD met: pass 1 found 7 fixes (applied), pass 2 found 3 (one-working-language 12.1, nextjs gateway pointer, applied), passes 3 and 4 clean (frontmatter 4/4, cross-refs resolve, no authored em dashes, no placeholders, no stale rule counts). Every sub-concept 1.1-18.4 mapped; coverage map below is final.
10. [x] Final report + commit split delivered; user reviewed section by section and confirmed. 12 slices committed to main on explicit confirmation ("commit only, no push"); nothing pushed.
11. Interactive review round (2026-07-11): user confirmed rules 27-34 tier, Quarkus-only flavour, two-tier ADR scheme; requested metrics.md split out of delivery.md (done, cross-refs moved) and Java gate assets (done: assets/pre-commit-java + assets/check-pom.sh, tested on 4 pom cases, wired into java-quarkus.md, greenfield, README). Declined for now: Java CI smoke test, trigger-eval run, LESSONS.md seed. Working tree: 17 modified + 12 new files, unstaged.

## Coverage map (article sub-concept -> home in the suite)
Legend: OK existing, NEW planned home, EXT extend existing file.

- 1.1 one committed config          OK SKILL rule 8/15 + workflow.md + bun-typescript.md
- 1.2 cap complexity/duplication    OK clean-code numbers + Rule of Three
- 2.1 least that works              OK lazy ladder (BG#2, complexity.md)
- 2.2 delete before add             OK BG#2
- 2.3 rule of three                 OK
- 2.4 defer build, not the seam     EXT complexity.md (name the principle) [verify in recon]
- 2.5 simplicity is not negligence  OK BG#2
- 3.1 dependencies inward           OK architecture.md
- 3.2 everything behind a port      OK rule 13 seams + architecture.md
- 3.3 design-system seal            OK rules 21-22
- 3.4 client-agnostic resource API  EXT architecture.md NEW reliability/delivery? -> architecture.md
- 3.5 frontend against a contract   EXT architecture.md / nextjs-monorepo.md (server-app data gateway)
- 3.6 internal model owns its shape EXT architecture.md (DTO mapping at gateway/presenter)
- 3.7 domain model is not DB model  EXT architecture.md (repo maps row->domain)
- 3.8 boundary testable             OK rule 22 tests + architecture.md
- 3.9 AI model is a dependency      NEW ai.md + SKILL hard rule
- 4.1 test in layers                EXT testing.md (unit/integration/e2e/perf taxonomy)
- 4.2 unit tests in ms              OK testing.md fakes
- 4.3 bug -> permanent test         EXT testing.md/tdd.md (regression naming)
- 4.4 mutation as coverage KPI      OK Stryker >=90 + tiers; Java: PIT (NEW java-quarkus.md)
- 4.5 behavior not internals        OK classicist school
- 4.6 gate every merge              OK 8 gates + CI
- 4.7 generated code same bar       EXT SKILL (one line) + workflow.md
- 4.8 evals for non-determinism     NEW ai.md
- 5.1 secrets out of codebase       OK gitleaks + config module; EXT security.md (rotation, central mgmt)
- 5.2 no hand-rolled auth/crypto    NEW SKILL rule + EXT security.md
- 5.3 control dependencies          OK rule 19 + bun audit; EXT workflow.md (renovate note)
- 5.4 supply chain (SBOM/signing)   EXT security.md + delivery.md
- 5.5 validate boundary/authz srv   OK branded types + security.md
- 5.6 private by network default    NEW delivery.md
- 5.7 one security baseline         EXT security.md (auth-by-default, rate limit, TLS)
- 5.8 untrusted content != orders   NEW ai.md + EXT security.md pointer
- 5.9 spend caps per caller         NEW ai.md
- 6.1-6.7 privacy pillar            NEW privacy.md + SKILL hard rule (PII in logs/URLs) + rule (no prod data in dev)
- 7.1-7.6 isolation pillar          NEW isolation.md + SKILL hard rule + cross-tenant test in checklists
- 8.1 trunk-based small commits     OK workflow step 6 + gate 1
- 8.2 pipeline/canary/rollback      NEW delivery.md
- 8.3 IaC                           NEW delivery.md
- 8.4 vertical slices               OK architecture.md
- 8.5 expand-contract               NEW reliability.md (+ SKILL data-lifecycle rule)
- 8.6 ephemeral environments        NEW delivery.md
- 9.1-9.5 run little yourself       NEW delivery.md (managed, no-SSH, auto TLS, pipeline-only infra, open standards + compose portability gate)
- 10.1 SLOs                         NEW observability.md
- 10.2 errors as values             OK result-type.md
- 10.3 explicit read paths          NEW reliability.md
- 10.4 keyset pagination/stream     NEW reliability.md
- 10.5 outbox + idempotency         NEW reliability.md
- 10.6 restore drills               NEW delivery.md
- 10.7 stateless scale + cache      NEW reliability.md
- 10.8 perf targets + load tests    NEW reliability.md (+ testing.md layer)
- 10.9 soft delete + migrations     NEW reliability.md + SKILL data-lifecycle rule
- 10.10 blameless postmortems       EXT workflow.md or NEW delivery.md (template; ties to LESSONS.md)
- 10.11 parse don't validate        OK rule 12 + EXT SKILL value-objects (money integer cents, UTC instants)
- 10.12 no lost updates             NEW reliability.md + SKILL rule
- 10.13 deadlines + bounded retry   NEW reliability.md + SKILL rule; EXT result-type.md (retryOnErr cross-ref)
- 11.1 correlated traces (OTel)     NEW observability.md
- 11.2 behavior metrics             NEW observability.md
- 11.3 alert on what matters        NEW observability.md
- 12.1 README + doc drift defect    OK BG#5
- 12.2 API docs from contract       NEW governance.md (+ architecture.md pointer)
- 12.3 ADRs                         NEW governance.md (ties to grill-me decision records)
- 12.4 institutional memory         OK LESSONS.md + PLAN.md
- 12.5 live access + numbers        NEW governance.md
- 12.6 one honest backlog           NEW governance.md
- 13.1-13.4 ownership pillar        NEW governance.md (CODEOWNERS/RACI, separation of duties, audit trail, safe reporting + owner verification)
- 14.1 golden paths as artifacts    OK greenfield + assets; EXT greenfield mention of principle
- 14.2 self-service                 NEW delivery.md (light)
- 14.3 platform as product          OK repo CI; EXT README/governance light
- 15.1 executable standard          OK 8 gates
- 15.2 fail loud (0% discovery)     OK coverage-preload
- 15.3 no silent opt-out            OK rule 15
- 15.4 test the bypass              EXT testing.md + security.md (+ isolation.md 7.5)
- 15.5 compliance is not proof      EXT workflow.md (runnable verification)
- 15.6 audit seams between systems  EXT security.md/testing.md
- 15.7 fix the class not instance   EXT workflow.md (grep + CI guard pattern)
- 15.8 re-checkable proof           EXT workflow.md
- 15.9 judgment where it counts     OK (machines own gates) + review-me
- 16.1-16.5 DORA/flow/cost          NEW metrics.md (split out of delivery.md on user review)
- 17.1 error copy + stable codes    NEW product.md + EXT atomic-design/nextjs (error states)
- 17.2 earn trust (honest exits)    NEW product.md
- 17.3 real behavior per market     NEW product.md
- 17.4 human path                   NEW product.md
- 17.5 i18n catalog                 OK nextjs-monorepo.md translations [verify]
- 17.6 accessible by default       EXT atomic-design.md + NEW product.md (axe gate) [verify]
- 18.1-18.4 validate before build   NEW product.md + EXT grill-me (go/no-go, interviews, flags+adoption)

## Notes / breadcrumbs
- Sources: /Users/pa2bra/Downloads/global-rules-every-new-project.md (18 pillars prose),
  /Users/pa2bra/Downloads/global-rules-dos-and-donts.md (per-sub-concept Do/Don't, TS + Java).
- Frontmatter limit: description exactly 1024 max; atelier currently AT 1024 -> must trim to add Java.
- House style: no em dashes in new prose; terse; atelier idiom (const arrows, Result, branded types, ports).
- Java flavour: mirror the article (Quarkus, JAX-RS, Panache writes/native reads, Flyway, JaCoCo, PIT,
  REST Assured, records + sealed Result, hand-written fakes, no Mockito). Maven wrapper ./mvnw.
- New-rule numbering starts at 27 (26 existing).
- Never commit/push without explicit user confirmation (memory + rule 25).
