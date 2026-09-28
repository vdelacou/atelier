# Plan: check-skill-pin false alarm on Windows (2026-09-28)

A consumer report: on Windows (Git for Windows sets core.autocrlf=true system-wide) the gate's
shallow clone checks upstream out with CRLF, and since the byte comparison of 2026-09-27 every
file of a current LF vendored copy reads as behind. The skills CLI's installs are CRLF for the same
reason. Commits and the push each need the owner's yes.

## Steps and definition of done

1. [x] Red: a selftest case clones the upstream fixture under a system and global config that set
   core.autocrlf=true and expects a match. DoD: the selftest fails on the current gate with the
   reporter's message.
2. [x] Fix 1: the gate clones with `git -c core.autocrlf=false`. DoD: the selftest is green, also
   when the whole run carries autocrlf=true (the reporter's machine).
3. [x] Fix 2: a root `.gitattributes` with `* text=auto eol=lf`. DoD: renormalizing changes no
   file; a clone of a tree with it under autocrlf=true checks out LF, one without it CRLF.
4. [x] CHANGELOG Unreleased entry; fast gates green (em dash, identity, citations, drift).
5. [ ] Land: two commits (the gate, the attributes) on the owner's yes, then the push on its own yes.

## Status
Steps 1-4 done 2026-09-28. Red: the new selftest case failed on the old gate with the reporter's
message; a clone under the planted config wrote CRLF. Green: the selftest passes, also with the whole
run under autocrlf=true. Real use (this repo as upstream, an LF copy of HEAD's skill): old gate 71 of
71 files behind, new gate a match. .gitattributes renormalizes no committed file; this tree cloned
under autocrlf=true checks out 198 CRLF files without it, 199 LF with it. The skills CLI, installing
from GitHub under that config, wrote SKILL.md with 201 CR bytes: re-check after the push, expect 0.
