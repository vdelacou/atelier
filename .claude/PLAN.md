# Plan: Phase 5 follow-up (2026-08-30)

Field test on a real consumer repo found 4 atelier defects. Fix each; the gate change
ships a violation fixture first (canon 15.10). Scorecard lands anonymized.

1. [x] check-package-json.sh walks every workspace manifest (adopt the consumer's fix).
   RED FIRST: smoke-test.sh case planting "latest" in packages/x/package.json must fail
   before the gate change and pass after. DoD: both smoke cases green, gate red on fixture.
2. [x] ADR guidance vs rule 26: governance.md warns the MADR Deciders field must carry a
   role or handle, never a person; authorship lives in commit metadata.
3. [x] Skeleton defines "test": "bun test" (consumers invented one, with a flag that made
   the gate unable to fail). DoD: bun-typescript.md skeleton + step 2 script list.
4. [x] Vendored-standard staleness: doctrine that a pinned skill copy is a dependency and
   goes stale like one; name the re-sync ritual. DoD: governance.md + pointer block line.
5. [x] field-test.md (anonymized: "a real Bun monorepo consumer", no product name/domain),
   sibling to conformance-matrix.md and reverse-matrix.md; LESSONS entry.
6. [ ] Gates: frontmatter, drift, citations, workflow-assets, bun smoke. Land on confirmation.
