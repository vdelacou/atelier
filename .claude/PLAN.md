# PLAN: Phase 2 finish, close the five conformance gaps

Close the remaining matrix work-list GAPs by adding faithful doctrine to the reference files
(doctrine counts as COVERED per the matrix convention, consistent with the org-pillar rows).
Each cites its rule id. 5.3 stays CONTRADICTS (P6 filed, awaiting canon maintainer, not mine
to close). Pinned: atelier HEAD b0d801a.

Gaps -> fix (all reach COVERED as doctrine):
- 5.10 -> security.md, new section after 5.6: single filtering edge (WAF) inspects/rate-limits/blocks
  before code; origin locked to the edge only (private, never public); x-edge-secret header as
  defense-in-depth (return 404 on mismatch). Cite 5.10.
- 7.7 -> isolation.md, new section after 7.6: every API call carries the user/tenant token; no
  anonymous service-key route returning everyone's rows (the /internal/all-orders anti-pattern);
  bulk/analytical volume comes from the data platform (10.14), never the user API. Cite 7.7.
- 10.14 -> reliability.md, new section at end: OLTP for the live app; ETL/CDC copy to a warehouse/lake
  for reads at volume; no reporting/exports against production; the pipeline is the one sanctioned
  bulk reader (narrow db grant, not the user API); the copy inherits erasure (pillar 6). Cite 10.14.
- 12.1 -> governance.md, extend the doc-drift doctrine: a docs-check CI job that runs the README's
  documented commands so drift fails the build; the atelier smoke-test.sh (follows the README install
  steps) is the exemplar. Cite 12.1.
- 17.7 -> product.md new section + atomic-design.md note: design the smallest screen first, one clear
  primary action per view, only the controls that view needs (overflow menu / progressive disclosure),
  ~44px tap targets, primary action in thumb reach; plus a bundle weight budget the pipeline enforces
  (size-limit or Lighthouse CI, on a throttled mid-range profile). Cite 17.7.

Steps:
0. [x] Canon bodies read (5.10, 7.7, 10.14, 12.1, 17.7), chapter marked  DONE
1. [x] Added five doctrine sections (security.md 5.10, isolation.md 7.7, reliability.md 10.14, governance.md 12.1, product.md + atomic-design.md 17.7)  DONE
2. [x] conformance-matrix.md: five rows GAP -> COVERED (doctrine); tally COVERED 111 / STRICTER 3 / CONTRADICTS 1 / GAP 0; work list just 5.3; self-check 9-green  DONE
3. [x] LESSONS [decision] entry for the five-gap closure  DONE
4. [x] Verify: frontmatter 4/4; em-dash diff 0; cross-refs resolve; self-check green  DONE
5. [ ] Commit (one commit: 6 reference files + matrix + lessons + plan = 9 files), cite rule ids; ask before commit (rule 25)  DoD: nothing committed without confirmation

Deferred (flag, do not auto-expand): the Java pre-commit-java hook has the same 15.1 slow-gate shape
(needs its own Java CI asset); shipping fixture-tested gates for 12.1 (docs-check) and 17.7 (bundle
budget) would strengthen those from doctrine to gate. Phases 3-5 unchanged.
