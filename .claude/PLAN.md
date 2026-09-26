# Plan: clear the skills.sh security warnings on the atelier skill (2026-09-26)

Reproduced with the skills CLI in a scratch HOME: `atelier` rates Gen "Med Risk", Socket "1 alert",
Snyk "Low Risk"; the three companions are Safe / 0 alerts / Low. Details on skills.sh:
- Socket, medium: `assets/check-docs.sh` "deliberately executes README-controlled shell code with the
  CI runner's privileges" (it runs the README's `## Verify` block through `bash -eu -c`).
- Gen: COMMAND_EXECUTION (the same script), EXTERNAL_DOWNLOADS (the shipped CI workflows download
  gitleaks and the atelier repo), PROMPT_INJECTION (a literal payload quoted in `references/ai.md`,
  which Gen itself calls benign teaching text).
Real gaps behind them: README text is a second code channel into CI; the gitleaks tarball is pinned
by version but installed with `sudo` without a checksum.

Definition of done:
1. `check-docs.sh` still runs the Verify commands (canon 12.1's Do: "actually run them") but only
   repo entry points: `bun run <script in package.json>`, `bun test`, `bash scripts/<file>` or
   `./scripts/<file>`, `./mvnw <args>`, and the path assertion `test -f|-d|-e <path>`; every token
   from a strict character set (no pipe, redirect, `;`, `&`, `$`, backtick, quote, glob, bracket);
   every line validated before any runs; each run as an argv array, never `bash -c` or eval. The
   smoke test proves a legitimate block green, a missing script and a missing file red, a pipe and an
   arbitrary command rejected, and a rejected `touch` line leaving no file (nothing ran).
2. governance.md's docs-check section says so, and its example workflow gains
   `permissions: contents: read`; matrix row 12.1's note follows.
3. The three shipped CI workflows verify the gitleaks tarball's SHA-256 before `sudo install`; the
   workflow-asset gate still passes; the digest comes from GitHub's release metadata.
4. `ai.md` describes the injected order instead of quoting a payload; meaning unchanged.
5. README: the install paragraph had the CLI's scope backwards (default is project-level, `-g` is
   user-level); fix the command and the pointer path. Separate commit.
6. Gates (em dash, identity, frontmatter, citations reanchored, drift, workflow assets), the Bun smoke
   test, tier 1 dry run, CHANGELOG, LESSONS; commits on the yes; after the push, reinstall in a
   scratch HOME to read the new assessment (third-party auditors; re-audit timing is theirs).

Status 2026-09-26 17:1x: 1-5 done. Probe on bash 3.2: the new check-docs runs every legitimate entry
point and refuses every hostile block unrun; the old one ran six of them. Asset gate rule 2b
(release download needs sha256sum -c before first use) selftested red with the rule removed.
Smoke: Bun (8 new docs-check proofs), Next and Java all green. Tier 1 (e10, h6): 8/8 vs frozen
6.3/8; h6's final message was a 403 refusal after 71 turns of work on disk, scored as produced.
Citations re-anchored (235), drift, frontmatter, em dash, identity green. Five commits pushed on the
yes; after the push, reinstall in a scratch HOME to read the new assessment.
