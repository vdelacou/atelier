# Plan: rule 26 blocks in a public repository and warns in a private one (2026-10-18)

The previous plan (TypeScript 7 beside the 6.0 API) closed with PR #12 rebase-merged on 2026-10-18
(main d10e519), all 11 checks green on Linux and Windows. The owner then asked that rule 26 (no
person, employer or client named in file contents) block only in a public repository and only warn
in a private one, and chose the mechanism: a committed declaration the hook reads, which CI checks
against the host.

## The design

- `check-identity.sh` decides by visibility: CI's `REPO_VISIBILITY` (the host's own answer, `private`
  or `public`, from `github.event.repository.private`) when set, else `.github/visibility` (one
  committed line reading `private`); neither, or any other word, is public. Public: a hit exits 1, as
  today. Private: a hit prints a warning naming each hit and rule 26 (a `::warning::` annotation under
  GitHub Actions) and exits 0. A file saying private while the host says public exits 1 with or
  without a hit, so a repository made public cannot keep warning.
- Every shipped CI workflow's identity step passes `REPO_VISIBILITY`, and so does this repository's
  own CI. Both of their triggers (push and pull_request) carry `github.event.repository`.
- Doctrine: rule 26's line in SKILL.md and its enforcement row, workflow.md's Commit identity (a
  "public blocks, private warns" paragraph with the going-public steps) and its two gate tables, the
  three variant references, atelier-greenfield (declare a private repository at bootstrap) and
  atelier-review-me (adopt mode declares it; the judgment's severity). atelier-grill-me and
  atelier-distill do not mention rule 26.

## Steps and definition of done

1. [x] The gate: `check-identity.sh` and the four CI workflows. DoD: by hand in a scratch repo, public
   blocks, private warns with the rule named, the host's answer wins, and a stale declaration is red
   with no hit.
2. [x] The proofs: the Bun smoke test plants each case (private warns with the rule's tag, a public
   host outranks the file, another word in the file blocks, a private host warns, a stale declaration
   is red with no hit) and checks that ci.yml hands the identity step the host's answer; the Next and
   Java smoke tests plant the private warning and check their CI workflow the same way. DoD: the three
   smoke tests green under Bun 1.4.2.
3. [x] The doctrine and its cascade (SKILL.md rule 26 and its row, workflow.md, the variant references,
   greenfield, review-me), keeping the pinned openings of `SKILL.md:62` and `check-identity.sh:3`.
   DoD: fast gates green, citations re-anchored where lines moved, no lock snippet changed.
4. [x] CHANGELOG (an upgrade line and a Changed entry) and a LESSONS `[decision]` entry. DoD: no em
   dash, the fast gates green.
5. [ ] Land after PR #12 merges, on the owner's yes: commits under gate 1, a pull request, CI green on
   Linux and Windows, rebase merge. Tier 1 per the selector, the owner's call.

## Status

Steps 1-4 done 2026-10-18. Step 1: by hand, 14 cases right (public blocks, private warns naming the
rule, the host's answer wins, a stale file is red with no hit, CRLF and capitals read, a subfolder
finds the file, the Actions annotation). Step 2: under Bun 1.4.2 the Bun smoke test passed 160 of 160,
Next.js 57 of 57 and Java 87 of 87, and five broken copies of the gate each turned one or two of the
planted cases red. Steps 3-4: fast gates green, ten citations moved by two lines, no lock snippet
changed; the tier-1 selector picks 0 of 21 tasks. Step 5: the owner said yes on 2026-10-18 (commit,
push, PR, merge on green); five commits, PR #13.
