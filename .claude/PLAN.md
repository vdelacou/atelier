# Plan: the reply gate reads and writes UTF-8 on Windows (2026-10-09)

The previous plan (the coverage gate and the preload generator on Windows paths) closed with PR #3
merged by rebase into main (a38c9e0): eight commits, all eleven checks green, the three smoke tests
green on windows-latest. The remote main-f7v4vj still waits on the owner's delete button. The
proposal for rule 38's host side (main as the default branch, rebase-only, auto-delete, a ruleset
protecting main, a daily drift check) still waits on the owner, after this fix.

The bug, found while auditing the other assets for PR #3: `check-reply.py` reads the Stop event with
`sys.stdin.read()`, which decodes in the locale's encoding. Claude Code sends the event as raw UTF-8,
and Windows Python decodes a pipe as the ANSI code page (cp1252) unless UTF-8 mode is on, so an em
dash arrives as three other characters and the gate exits 0 on a reply it must block (reproduced
with `PYTHONIOENCODING=cp1252`: exit 0 for an em dash and for an emoji, against exit 2 under UTF-8).
The output has the mirror problem: stderr's backslashreplace kept the hook from crashing, but its
feedback quoted an emoji as `\u2705` and an em dash as a cp1252 byte, and the probe, on stdout,
crashed with UnicodeEncodeError (exit 1) printing an emoji. The smoke tests never saw any of it:
their events go through `json.dumps`, which escapes every non-ASCII character. The owner chose a
separate PR for it.

## Steps and definition of done

1. [x] Restart main-f7v4vj from origin/main. DoD: at origin/main's tip.
2. [x] check-reply.py: `main` reads stdin as UTF-8 bytes, in `--hook` and in the probe's stdin mode,
   and sets stdout and stderr to UTF-8. `--selftest` runs the script under `PYTHONIOENCODING=cp1252`
   (`PYTHONUTF8=0`) with an em dash and an emoji sent as raw UTF-8, and expects exit 2 with each
   tag. DoD: selftest green, red under each mutation (stdin read in the locale's encoding, the
   output left in it).
3. [x] The three smoke tests: one more reply-gate case sends an em dash and an emoji as raw UTF-8
   through the copied settings and expects exit 2 with both tags. On the Windows legs that is the
   real platform. DoD: green here; green on windows-latest in CI.
4. [x] workflow.md's Reply gate (the encoding, and why); the reply gate's own Unreleased Added entry
   carries the fix, since the gate has not shipped in a release. DoD: citations re-anchored once and
   intact, drift, frontmatter, em-dash gates green.
5. [ ] Land in slices on the owner's yes, push on its own yes, a pull request; CI green; rebase
   merge; the branch deleted on both sides.

## Status

Steps 1-4 done 2026-10-09. The selftest runs the script under PYTHONIOENCODING=cp1252: an em dash
and an emoji sent as raw UTF-8 block and are quoted intact, and the probe prints an emoji finding.
It goes red under four mutations (stdin in the locale's encoding, no output reconfigure, stderr
only, stdout only). The old gate measured under cp1252: exit 0 on both characters sent raw, and
the probe crashed (exit 1) printing an emoji. The new smoke case passes on the new gate and fails
the old one with exit 0. All three smoke tests green here (Bun 151, Next 52, Java 82 checks).
Citations intact (nothing moved), drift and frontmatter green. The owner said yes to landing.
Next (step 5): four slices, push over the stale remote main-f7v4vj with --force-with-lease (its
eight commits are on main), PR #4, CI green on the Windows legs, rebase merge.
