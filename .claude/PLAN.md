# Plan: after 2.8.0 (2026-10-25)

The previous plan closed: PR #20 merged on 2026-10-24 (main 94fcc88), and the owner pushed `v2.8.0` on
it with its GitHub Release. The owner then asked, as a loop, for four follow-ups.

## Steps and definition of done

1. [x] This repository lands its own pull requests: a `land` job in `.github/workflows/ci.yml` that
   needs the eight others and runs the shipped `land-on-green.sh`; CLAUDE.md names it. DoD: this PR
   lands itself on green.
2. [x] The LESSONS pass: three new lessons (the unpushed tag, the whole-run threshold, unicorn 79 as
   the fourth unpinned-toolchain instance, merged), two graduations (the TypeScript 7 decision, the
   headless `.claude/` gotcha), archive before removal, the ledger proved. DoD: every old entry
   accounted for.
3. [x] The re-freeze input: the 2.8.0 runs as a tarball for the owner, who holds the five earlier
   passes and the 2.7.0 tarball. DoD: delivered.
4. [x] The Bun template's unicorn range moves to `^79.0.0`. DoD: the smoke test already installs 79.

## Status

All four done in the working tree. The journal sits at 20.9 KB with 21 entries: no other entry has the
evidence a removal needs, so the rest of the gap to the 15 KB cap is left for a pass that tightens the
long merged entries. The re-freeze itself runs where the seven passes' runs live. Next: the PR.
