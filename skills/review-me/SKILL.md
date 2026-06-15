---
name: review-me
description: Review a diff against the atelier standard before it lands — a rule-aware conformance audit that maps each changed file to the hard rules that bind it, cites the exact rule and red-flag numbers a change violates, applies the security false-positive filter, and defers generic correctness bugs to /code-review and mechanical cleanups to /simplify. Use to pre-land-review staged changes, a feature branch, or a PR, to check a diff for rule violations, or when the user says "review me" / "review my changes against the standard".
---

# Review me

Audit a change against the atelier standard before it lands. This is the conformance lens the always-on standard and the generic review tools do not give you on their own: a whole-diff pass that checks every changed file against the hard rules it is bound by, in domain language, citing rule numbers — so a violation is caught at review cost, not in production or three rounds into a reviewer's comment thread.

The third on-demand companion to the always-on atelier standard: grill-me owns the pre-decision moment, bootstrap owns repo-birth, review-me owns the pre-land moment.

## When to use

- The user asks to "review me", to review a diff / branch / PR against the standard, or to check changes for rule violations before committing.
- A change is staged or a feature branch is ready to land and you want a conformance checkpoint.

Match intensity to stakes — a one-line typo fix does not need the full rule sweep; say so and skip it. And review-me does not replace the built-ins, it complements them (as the security reference complements `/security-review`): defer generic correctness bugs to `/code-review` and mechanical reuse/simplification/altitude cleanups to `/simplify`. review-me owns rule conformance.

## How to run

1. **Resolve the diff scope — one question, with a recommendation.** Staged (`git diff --cached`), the working tree, the branch vs `origin/main` (`git diff origin/main...`), or a PR. Default recommendation: the current branch vs `origin/main`. Confirm, then read the actual diff before judging.
2. **Map each changed file to its rule subset.** The rules are layer-specific — audit only what applies:
   - `src/domain/**`, `src/use-cases/**` → rules 1-3, 6, 10, 12, 14, 16-18: branded types at trust boundaries, primary-port SUT, `Result` returns, no `try/catch`, no custom error classes.
   - `src/infra/**` → 13, 17, 20: the test seam (a `createXFromApi`/custom-fetch/sync-builder seam, never `mock`), `try/catch` quarantined here, `Bun.file` not `node:fs`, `Result` translation via `formatError`.
   - `src/components/**`, `src/page/**`, `app/**` → 21-22: design-system purity and the styling seal — no hooks, no `src/lib`/`next/*` imports in components, no Tailwind outside `src/components/**`, typed variants not `className`.
   - `*.test.ts`, `src/test-helpers/**` → 24, 13, 14: test integrity (was a test created/edited/weakened without sign-off?), no `mock` from `bun:test`, primary-port SUT, domain-language scenario names.
   - `package.json` → 19 (no `"latest"`/`"*"`). Any commit → 23 (Conventional Commits) and small (≤10 files / ≤300 lines).
3. **Check the universal hard rules on every file** — no `class` / `function` declaration / `interface` / `console.*` (1-4), explicit return types on exports (6), single-arrow not curried (18), zero inline ignores of any tool (15).
4. **Run the security source-to-sink lens.** Does any untrusted source reach a sink (SQL, shell, filesystem, HTTP, HTML, redirect) without crossing a branded-type checkpoint? Apply the strict false-positive filter — only concrete, exploitable findings with a clear attack path; skip DoS, defence-in-depth hardening, and theoretical concerns.
5. **Note, do not re-run, the mechanical gates.** Lint / typecheck / coverage / mutation are enforced by pre-commit gates 4-8 — remind the user to run them rather than checking by eye. review-me is for the judgment rules the gates cannot catch.

## Output

A rule-cited verdict: each finding names the file, the exact rule or red-flag number it breaks, why, and the fix — grouped by severity, in domain language, the single most important fix first. End with a one-line verdict: conformant, or N violations across M files.

Report only — never edit the tree. Offer to apply the fixes on request, hand mechanical cleanups to `/simplify`, and pass correctness bugs to `/code-review`. Review toward the *simplest* conforming change: a finding that demands more code than the rule requires is itself a smell.

In a repo that keeps an `.claude/LESSONS.md` journal, a violation that keeps recurring is a candidate `[mistake]` entry — propose it on approval so the next session inherits the correction.
