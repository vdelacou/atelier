# Plan: Java tripwire wiring + review-eval fixture coverage (2026-08-30)

1. [ ] Java tripwires: all four guards are Java-aware but java-quarkus.md never names them,
   so a Java bootstrap never copies one. Add to the asset list + bootstrap step with the
   Java-specific triggers, and prove each in smoke-test-java (red on a Java violation,
   green on the conforming case), matching what smoke-test.sh does for the Bun side.
2. [ ] review-eval: plant the two violation classes review-me gained today.
   - gate-file change with no violation fixture (canon 15.10 mapping row)
   - a legitimate pure-domain catch around a native thrower, as a CLEAN case, so the
     rule 17 carve-out is measured as a false-positive lens, not a catch.
   Update violations.json / clean-files.json + fixtures for the bun variant; java too if
   the shape carries. Then one eval pass to confirm the planted cases behave.
3. [ ] Gates + java smoke, then propose slices. Land on confirmation only.
