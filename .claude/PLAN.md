# Plan: the coverage gate and the preload generator on Windows paths (2026-10-09)

The previous plan (hard rule 38) closed: PR #2 merged by rebase into main (26b15bc) and main-f7v4vj
was deleted on the remote. A proposal for rule 38's host side (main as the default branch,
rebase-only, auto-delete, a ruleset protecting main, and a daily drift check) was researched on
2026-10-05 but never written up. It waits on the owner, after this fix.

The bug, as reported: on Windows, Bun prints the coverage table as `src\domain\x.ts`, so
`check-coverage.ts` matches no tier prefix, skips every row, prints "no files" for every tier and
exits 0. `regenerate-coverage-preload.ts` builds paths with `path.relative`, which returns
backslashes there, so every file groups under the unwritten 'other' key: the preload imports
nothing, untested infra, composition and presenter files never reach the table, and `--check`
reports "in sync". `EXCLUDE` and the import specifiers share the slash assumption. Only the Bun
variant ships the two files (Next has no coverage gate; Java uses JaCoCo).

The fix normalises each path once, where it enters: `rowAt` in check-coverage, `rel` and
`fromOut` in the generator (`p.replaceAll('\\', '/')`). The guards make the gate prove it can fail
(canon 15.10). One deviation from the request: the bootstrap checklist creates `src/presenter` and
`src/composition` empty (bun-typescript.md step 8) and generates the preload at step 12, so "a scan
directory exists but nothing was emitted" would fail every fresh scaffold. The guard fires when the
walk found files under a scan directory and the preload imports fewer of them.

## Steps and definition of done

1. [x] Restart main-f7v4vj from origin/main. DoD: at origin/main's tip.
2. [x] check-coverage.ts: normalise in `rowAt`; a row under `src/` in no tier and no skip rule
   fails the run by name; `--selftest` feeds planted table lines: a Windows row under its tier's
   gate is a violation, a `src/` row in no tier falls through, skipped and non-`src/` rows pass,
   both column layouts parse. DoD: selftest green, and red under each mutation (no normalisation,
   no fall-through check, a broken skip rule, the `src/` scope dropped, layout 1 dropped).
3. [x] regenerate-coverage-preload.ts: normalise `rel` and `fromOut`; the walk counts each scan
   directory's files, and the generator fails, writing and comparing nothing, when the preload
   imports fewer; `--selftest` with `path.win32`: the unnormalised Windows shape trips the guard,
   the normalised one groups and imports `'../src/infra/x.ts'`. DoD: selftest green, red under each
   mutation (no normalisation on `fromOut`, no guard); the smoke fixture's preload unchanged.
4. [x] Bun smoke test: runs both selftests, and a covered `src/jobs/` file makes `bun run coverage`
   exit 1 naming it. ci.yml runs all three smoke tests on windows-latest beside ubuntu-latest (the
   owner's choice), in Git Bash, with `python3` copied from `python.exe`. DoD: the Linux smoke green
   here; the Windows legs green in CI before merge.
5. [x] Doctrine: workflow.md's coverage sections (the normalisation, the fall-through failure, the
   guard, the selftests); the matrix 15.2 note; citations re-anchored. DoD: citations intact, drift,
   frontmatter, workflow-asset and em-dash gates green.
6. [x] CHANGELOG Unreleased (Fixed, Upgrading: re-copy both assets, regenerate the preload), CLAUDE.md
   CI line. DoD: read.
7. [ ] Land in slices on the owner's yes, push on its own yes, a pull request; drive the Windows leg
   green; rebase merge; the branch deleted on both sides.

## Status

Steps 1-6 done 2026-10-09. Both selftests green, and red under each of nine mutations (check-coverage:
no normalisation, no fall-through, a broken skip rule, the src/ scope dropped, layout 1 dropped, the
threshold inverted; the generator: no normalisation on rel, none on fromOut, the guard disabled). On a
fixture the generator's output is byte-identical to the old one, an empty src/presenter passes, and a
SCAN_DIRS entry spelt ./src/infra stops the run with nothing written. The Bun smoke test: 150 checks
green on Linux (the first run caught six unicorn/prefer-string-raw errors in the selftest literals).
Citations re-anchored (16), 239 intact; drift, frontmatter, workflow assets and the em-dash scan green.
The owner said yes to landing, Windows legs for all three smoke tests, pushing CI fixes without asking
until green, and the reply gate's Windows stdin bug (cp1252 hides an em dash) as a separate PR after.
Next (step 7): seven slices, push, the pull request, the Windows legs green.
