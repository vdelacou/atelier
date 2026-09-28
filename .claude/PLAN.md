# Plan: a consumer's checkout is LF on Windows too (2026-09-28)

The previous plan (check-skill-pin on Windows) landed in 63244b5, CI green. Its open case: a
consumer repo with no .gitattributes, checked out under Git for Windows' system-wide
core.autocrlf=true, gets CRLF text. Probed: prettier's endOfLine 'lf' (both TypeScript configs)
fails a CRLF file, so that consumer's lint gate fails on every file, and check-skill-pin.sh reads
the vendored copy as stale. Chosen fix: the bootstrap ships a .gitattributes, not a gate that reads
the index (that would fix the pin check only). Commits and the push each need the owner's yes.

## Steps and definition of done

1. [x] Asset `assets/gitattributes` (`* text=auto eol=lf`, CRLF for Windows batch files such as
   mvnw.cmd). DoD: the file exists with a comment saying why.
2. [x] Every variant's bootstrap copies it (Bun, Next, Java; workflow.md if it lists copies).
   DoD: one copy line per checklist; citations re-anchored and intact.
3. [x] Companion cascade: greenfield's scaffold and review-me's adopt install (renormalize in its
   own commit on a brownfield tree). DoD: each names the file; frontmatter valid.
4. [x] Smoke tests: each variant's fixture copies it, and a checkout under core.autocrlf=true is
   LF; seen CRLF with the file removed. DoD: the three smoke tests green.
5. [x] Tier-1 selector dry run; tier 1 if it selects a task. CHANGELOG Unreleased (Added, Upgrading).
6. [ ] Land in slices on the owner's yes, then push on its own yes.

## Status
Steps 1-5 done 2026-09-28. Probe: prettier with endOfLine 'lf' fails a CRLF file. The asset ships;
the Bun, Next and Java checklists copy it; greenfield and review-me carry it (review-me lands it
before the hooks, renormalizing in its own commit). scripts/smoke-eol-checkout.sh: red on a
.gitattributes without the rule, green on the asset; all three smoke tests green with it (Bun 141,
Next 45, Java 75). The Next insertion moved three citations; the re-anchor surfaced a pre-existing
mis-citation (the matrix's 3.5 note cited the static-export line for the gateway sentence), now the
gateway line, 239 citations. Tier-1 selector: 0 of 21 tasks. Next: land in four slices on the yes.
