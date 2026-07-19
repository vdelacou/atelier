# Proposed canon revisions (P6 rows)

When the atelier skill and the Global Rules canon collide, the rule is canon and the skill
amends. The one exception: when the skill exposes a defect in the rule itself, the
resolution is a proposed revision to the canon, recorded here, not a change to the skill.
Each row names the rule, quotes the current canon text with a line reference into the
vendored copy, states the defect, and proposes replacement text. Status stays "proposed"
until the canon maintainer accepts or rejects it.

This file is the P6 output of Phase 2 of the conformance plan. It is a proposal against the
canon vendored at `docs/global-rules/`, not an edit to it: the vendored documents remain
byte-identical to their audited source so `conformance-matrix.md` stays reproducible.

---

## 5.3 Control your dependencies (proposed 2026-07-19, status: proposed)

**Current canon** (global-rules-dos-and-donts.md:928-938):
- Do: "Pin every dependency to a fixed version, scan continuously for known
  vulnerabilities, and let automated updates keep you current."
- Don't: "Float on version ranges, or leave advisories unread until an incident."
- TypeScript example brands `{ "hono": "^4.0.0" }` the DON'T ("caret ranges resolve to
  unknown code on every install") and `{ "hono": "4.6.14" }` the DO, and annotates the DO
  with "a committed lockfile, and a scanner in CI ... bun install --frozen-lockfile in CI".

**Defect.** The rule conflates two separable things and requires both, though only one
serves its stated goal. The goal is a deterministic install. Determinism is delivered by a
committed lockfile plus a frozen-lockfile install, which the Do's own example already
mandates. Once the lockfile is committed and CI runs `--frozen-lockfile`, the installed
version is fixed by the lockfile, not by the manifest range, so whether the manifest reads
`^4.0.0` or `4.6.14` makes no difference to what installs. The rule's stated reason for
banning carets, "caret ranges resolve to unknown code on every install", is therefore false
under the very conditions the rule itself requires. Requiring exact pins in the manifest on
top of the lockfile adds no determinism, fights the package manager (`bun add` and npm both
write `^X.Y.Z`, so exact pins mean hand-editing and re-pinning after every `bun update`),
and erases the semver-compatibility intent a range documents. The genuine footguns are
`"*"` and `"latest"` and bare dist-tags, which signal unconstrained or always-upgrade
resolution; a caret backed by a committed lockfile is not one of them.

**Proposed revision.**
- Do: "Make every install deterministic with a committed lockfile and a frozen-lockfile
  install in CI, keep version declarations constrained (a caret or tilde range, never `*`
  or `latest`), scan continuously for known vulnerabilities, and let automated updates keep
  you current."
- Don't: "Declare `*`, `latest`, or a bare dist-tag, leave the lockfile uncommitted, or
  install without `--frozen-lockfile` in CI, so an install can silently drift; or leave
  advisories unread until an incident."
- TypeScript example: keep `{ "zod": "*" }` as the DON'T (unconstrained updates), move
  `{ "hono": "^4.0.0" }` to the DO alongside the committed lockfile and the CI scanner, and
  drop the "resolve to unknown code on every install" annotation.

**Skill evidence (unchanged, correct).** `assets/check-package-json.sh:31` bans exactly
`*`, `latest`, and bare dist-tags while permitting `^X.Y.Z` / `~X.Y.Z` / `>=X.Y.Z`;
`references/workflow.md:427-437` requires a committed lockfile and `bun update` in the same
commit; `references/security.md:66` requires `bun install --frozen-lockfile` in CI. This is
the more precise expression of the rule's real goal, so the skill is not amended.

**Matrix disposition.** `conformance-matrix.md` keeps 5.3 as CONTRADICTS against the current
canon text (the audit is honest about the letter of the pinned canon), annotated that a P6
revision is proposed here. The verdict flips to COVERED only if and when the canon accepts
this revision.
