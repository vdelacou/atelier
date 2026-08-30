# Plan: four open atelier items (2026-08-30)

3. [ ] Conformance re-baseline on current doctrine (3 passes, opus, local only).
   Running: pass 1 (tag rebase1). DoD: baseline.md rewritten with the new numbers
   and the date, old numbers kept as the superseded reference.
1. [ ] Java staleness + CVE placement parity with the Bun variant.
   Ship assets/audit-java.yml (schedule + pom-scoped PR runs: OWASP dependency-check
   plus check-skill-pin.sh); drop the OWASP step from ci-java.yml's gates job for the
   same reason bun audit left ci.yml. Cascade: java-quarkus.md copy list + prose,
   workflow-assets gate mapping. DoD: gate green, java smoke green.
2. [ ] check-commit-range.sh --selftest (parity with the other three new gates):
   temp git repo fixtures, small commit passes, oversized fails, merge excluded.
   DoD: selftest green, and it fails when the thresholds are broken.
4. [ ] Phase 5 second pass against the consumer's caught-up tree: pin gate in situ,
   hook shape, CI gates, ADR bylines, test flag. Read-only. DoD: short delta report.
5. [ ] Gates + both smokes, then propose slices. Land on confirmation only.
