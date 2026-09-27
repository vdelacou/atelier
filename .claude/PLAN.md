# Plan: a weekly canary for Oxlint parity (2026-09-27)

The owner asked whether Oxlint can replace ESLint with the same function and plugins. The probe of
2026-09-27 (oxlint 1.85.0, both TypeScript variants, every smoke fixture through both linters) matched
ESLint everywhere but two gaps: Oxlint has no `noInlineConfig`, so a disable directive silently switches
rules off (rule 15), and JS plugins get no type information, so the typed sonarjs rules go silent (57 of
the 231 recommended). Decision (owner, option 1): stay on ESLint and watch the two gaps weekly.

## Steps and definition of done

1. [x] `scripts/oxlint-parity-probe.sh`: installs the latest Oxlint and eslint-plugin-sonarjs in a
   scratch folder and reads each gap as open or closed. Controls make an open reading mean the gap
   only (the violation is reported without the directive, JS plugins load, types flow), and a stand-in
   that is closed today (`respectEslintDisableDirectives: false` on an `eslint-disable`) proves the
   gap-1 verdict can read closed. The header keeps what the 2026-09-27 probe matched and the migration
   traps. DoD: a local run reads both gaps open with every control and the stand-in passing, exit 0;
   a broken control exits 1.
2. [x] `canary.yml`: an `oxlint-parity-probe` job in the existing shape (weekly, continue-on-error),
   with Node for Oxlint's engines; the header comment lists the third probe. DoD: the YAML parses.
3. [x] CLAUDE.md's canary sentence and a CHANGELOG Harness entry; the em-dash gate on the diff; commit
   and push on the owner's yes.

## Status
Done 2026-09-27, awaiting the owner's yes to commit and push. Real run (oxlint 1.85.0, oxlint-tsgolint
7.0.2003, eslint-plugin-sonarjs 4.2.1): both gaps open, controls and stand-in pass, exit 0 in 22s, the
lines also written to the step summary. Every branch seen through a stubbed Oxlint on PATH: both gaps
closed (three PROBE lines, exit 0), noInlineConfig accepted with the oxlint-* form still silencing
(named), an option unseen on 2026-09-27 (named), and four broken controls (plain file silent, stand-in
not closed, sonarjs not loaded, types not flowing), each exit 1. canary.yml parses (three jobs); the
em-dash grep over the diff finds none; check-citations 235 intact; check-identity --all ok.
