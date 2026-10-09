# Changelog

All notable changes to the atelier skill suite. Format follows
[Keep a Changelog](https://keepachangelog.com/); this suite versions the standard as a
whole, not any single skill.

## [Unreleased]

### Upgrading from 2.6.1

- Copy `assets/check-reply.py` to `scripts/check-reply.py` and `assets/claude-settings.json` to
  `.claude/settings.json`; when that file already exists, merge its `Stop` entry instead. The hook
  needs python3.
- Hard rule 38: re-copy `check-commit-range.sh`, which now fails on a merge commit in the range, so
  land branches by rebase; copy `assets/check-branches.sh` to `scripts/` and `assets/branches.yml` to
  `.github/workflows/`; have the owner set the host to rebase-only merges with automatic head-branch
  deletion (`references/workflow.md`, Branch lifecycle, has the one `gh api` call); delete the
  branches the first watchdog run reports as landed. Re-copy `assets/claude-md-pointer.md` into your
  `CLAUDE.md`: the block names hard rules 1-38.
- Bun: re-copy `check-coverage.ts` and `regenerate-coverage-preload.ts`, then run
  `bun run scripts/regenerate-coverage-preload.ts`. On Windows the old preload imported nothing,
  so expect the first coverage run there to list the untested files it was hiding. A file under
  `src/` in a directory with no tier now fails the gate: give the directory a tier in
  `COVERAGE_RULES`, or add a genuine non-code entry to `SKIPPED`.

### Added
- A reply gate. `assets/check-reply.py --hook` is a Claude Code Stop hook, wired by the new
  `assets/claude-settings.json`, that holds the Interaction section's five mechanical rules (no em
  dash, no cut word, no bold lead-in, no decorative emoji, sentence-case headings): a reply that
  breaks one exits 2 with each tag and its fix, the agent restates it, and the second stop passes,
  so a reply is restated at most once. A doctrine line alone did not hold the bold lead-in rule: in
  831 replies from 16 real cloud sessions (2026-10-04), 63 percent of the current model's long
  replies broke it, and 52 percent where a tool call named atelier. Every variant's checklist copies
  the pair, greenfield proves it red, review-me's adopt mode merges it, and the Interaction line
  gives the bold lead-in's replacement shape. Each smoke test proves exit 2 with the tag, a pass on
  a plain reply, the loop guard, and that the copied settings run the copied script; on the real
  CLI a blocked list came back plain, $0.037 for both turns. The cost: a blocked reply shows twice,
  with a "Stop hook error" notice between. Given session logs, the probe counts the gate's own
  blocks per session: the blocks, the ones after a session's first, and the restatements that still
  broke a rule.
- Hard rule 38, the branch lifecycle: a branch starts from a fetched `main`, lives less than a day,
  stays current by rebase, lands by rebase or fast-forward (never a merge commit, never a squash of
  several commits, which builds one commit gate 1 rejects), is deleted on the remote and locally the
  moment it lands, and follow-up work starts from the new `main`; nobody force-pushes or deletes
  `main`. Canon 8.1 asked for short-lived branches deleted the same day; nothing said how a branch
  lands, and nothing enforced it: the session that merged the reply gate left its branch on the
  remote. `check-commit-range.sh` now rejects a merge commit in every pull request and push, stepping
  over only GitHub's synthetic merge of a pull request into its base (its subject read from a real
  run), and the new daily `branches.yml` runs `check-branches.sh`, which fails on a branch whose work
  already landed (judged by content with `git merge-tree`, so rebase and squash merges count) and on
  one whose oldest unlanded commit is more than a day old (`MAX_BRANCH_AGE_HOURS`; `KEEP_BRANCHES`,
  default `^release/`). Every variant's checklist copies the pair, `check-workflow-assets.sh`
  enforces it, greenfield proves the merge rejection red, review-me reads a branch's history, and
  each selftest goes red under a mutation of each behaviour.

### Fixed
- The Bun coverage gate and the preload generator passed silently on Windows. Bun prints the
  coverage table as `src\domain\x.ts` there, so `check-coverage.ts` matched no tier, skipped every
  row, printed "no files" for each tier and exited 0; `regenerate-coverage-preload.ts` built its
  paths with `path.relative`, which answers with backslashes there, so every file fell into an
  unwritten group, the preload imported nothing, untested infra, composition and presenter files
  never reached the table, and `--check` reported "in sync". `EXCLUDE` and the import specifiers
  had the same slash assumption. Both now normalise each path to `/` where it enters. Neither can
  pass that way again: the gate fails on a row under `src/` that no tier and no skip rule claims,
  and the generator fails, writing nothing, when the walk found files under a scan directory that
  the preload would not import (an empty one passes: the bootstrap creates two). Each takes
  `--selftest`, which proves the Windows shape is caught and goes red under a mutation of each
  part, and the Bun smoke test runs both and plants a `src/` file in no tier and a misspelt scan
  directory.

### Harness
- The three smoke tests run on `windows-latest` beside Linux, in Git Bash, so each variant's gates
  prove themselves where Bun, git and the JDK print Windows paths.
- The same file is the reply probe: given transcripts, session logs or eval run dirs it prints every
  finding and counts per arm. Six candidates from Simplified Technical English (ASD-STE100) are
  counted and never block: a hedged result ("should pass"), any other hedge, an event passive, a
  sentence over 25 words, a paragraph over 6 sentences, and a question buried in a report. The
  831-reply reading found no habit for any of them, so the drafted clauses stay out of the doctrine.
  `--selftest` proves each tag on its own plant and both modes, checks the cut list against
  SKILL.md, and runs in CI beside the review grader.
- `check-workflow-assets.sh` checks the shipped Claude settings like a workflow: they parse, and
  every variant's checklist copies the hook's script. The same mapping covers `branches.yml`.
- This repository runs its own reply gate: `.claude/settings.json` points the Stop hook at the
  shipped asset, so replies in a session here are held to the rules it ships.

## [2.6.1] - 2026-09-28

The Windows release. Git for Windows sets `core.autocrlf=true` system-wide, and under it a consumer's
checkout turned CRLF: the TypeScript variants' lint gate failed every file, and the skill-pin check
reported a current vendored copy as stale. Both are fixed and proven under that setting in every
variant's smoke test.

### Upgrading from 2.6.0

- Copy `assets/gitattributes` to `.gitattributes` at the repository root, and re-copy
  `check-skill-pin.sh`.
- Most repos need nothing more: `git ls-files --eol | grep i/crlf` lists the files committed with
  CRLF, usually none. If it lists some, `git add --renormalize .` in a commit of its own; it rewrites
  every line of those files, the big-bang change for which the commit-size gate's header sanctions a
  `--no-verify` justified in the commit body.
- A Windows install of the skills made before this release re-runs `bunx skills update` to get LF
  files.

### Added
- **`assets/gitattributes`, copied to `.gitattributes` by every variant's bootstrap checklist.** Text
  checks out LF on every machine, Windows batch files (the Maven wrapper's `mvnw.cmd`) CRLF. Under Git
  for Windows' system-wide `core.autocrlf=true` a consumer's checkout turned every text file CRLF:
  prettier's `endOfLine: 'lf'` then failed every file in the TypeScript variants' lint gate, and
  `check-skill-pin.sh` read a current vendored copy as stale. atelier-greenfield's scaffold carries it;
  atelier-review-me's adopt install lands it first, before the hooks exist, with a CRLF tree
  renormalized in a commit of its own. Each smoke test proves a checkout under that setting is CRLF
  without the file and LF with it.

### Fixed
- **`check-skill-pin.sh` on Windows.** Git for Windows sets `core.autocrlf=true` system-wide, so the
  gate's shallow clone of upstream checked text out with CRLF, and since the byte comparison of 2.6.0
  every file of a current LF vendored copy read as behind upstream (all 71 of the main skill, in a
  reproduction under that setting). The clone now runs with `core.autocrlf=false` and compares
  upstream's committed bytes on any machine; the selftest plants the setting at system and global
  scope, where Git for Windows keeps it, and expects a match, seen red first. Re-copy
  `check-skill-pin.sh`.
- **A clone or a skills CLI install checks out LF on every machine.** The repository now carries a
  `.gitattributes` (`* text=auto eol=lf`); before it, the skills CLI wrote the vendored files with
  CRLF on Windows, so they differed from the index and from upstream until renormalized.
- `references/product.md`'s review checklist asked whether "the axe gate" covered a new flow; the gate
  is `eslint-plugin-jsx-a11y`, and a runtime axe scan is the optional deeper pass.

### Changed
- The README's claims match the tree: the unaided soft-delete and port counts read the five frozen
  passes (0 and 2 of 20), the product row names the jsx-a11y gate, the Next variant is detected by
  its workspaces or its `next.config.ts`, and `try/catch` is quarantined to `infra/`, the entry point
  and a domain fallback around a native thrower.

### Harness
- The matrix's note on canon 3.5 quoted the Next reference's gateway sentence but cited its
  static-export line; it cites the gateway line, and the matrices hold 239 pinned citations.
- The em-dash gate refuses a base it cannot resolve (exit 2) instead of passing on `HEAD~1..HEAD`, a
  narrower range than the one asked for; only the push path keeps that fallback.

## [2.6.0] - 2026-09-28

The audit release. A six-part audit of the whole tree before release found eleven blockers and about
110 should-fix items: gates that passed the violation they exist to block, copy steps that left a hook
calling a script it never received, and examples that taught what the rules forbid. The blockers and
the should-fix items are closed; the audit's nice-to-haves (about 65, mostly polish) stay on the
backlog. Each gate change was proven red on the old code before it landed and is wired into its smoke
test or selftest.

### Upgrading from 2.5.0

- **Next.js:** bump `next` and `eslint-config-next` to `16.3.6` and `next-mdx-remote` to `^6.0.0`
  (Security). Add `"type": "module"` to each package's `package.json`, and replace
  `commitlint.config.cjs` with `commitlint.config.mjs` (`export default { ... }`, same content).
- **Re-extract the ESLint config** (`eslint.config.js` or `.mjs`). Expect new findings: a test using
  `spyOn`, `jest` or `vi` from `bun:test` or any `.toHaveBeenCalled*` assertion (rule 13), an adapter
  importing a use-case (rule 37), a production file importing a `*Unsafe` helper, a
  `// gitleaks:allow` comment (rule 15), and `process.exit(1)` in `src/main.ts`, which unicorn's
  `no-process-exit` rejects: set `process.exitCode = 1` instead. Next: `React.useState()` and `use()`
  in the design system (rule 21).
- **Bun `package.json`:** the skeleton pins the current majors (ESLint 10.11, `@eslint/js` 10,
  unicorn 76, security 4.1, sonarjs 4.2.1, Stryker 10), declares `globals` and `prettier`, and moves
  `typescript` from `peerDependencies` (which never held it: Bun installed 6.x) to `devDependencies`
  at `^5.9.3`. Bun 1.3 or later.
- **Re-copy every shipped asset the bootstrap checklist of your variant copies.** The hooks and the
  workflows (`actions/checkout@v7`, `actions/setup-java@v6`, `gitleaks git` with
  `--ignore-gitleaks-allow`, the README Verify step, the printed JUnit seed) and nearly every gate
  script changed. `check-docs.sh` is now copied by every variant and run by each variant's CI workflow
  (2.5.0 described it in `references/governance.md` only): the README needs a `## Verify` block.
  `check-skill-pin.sh`, which the audit workflow always ran, is now copied unconditionally in Bun and
  at all in Next (Java already copied it). The Java copy block is copied whole: identity and the
  discipline wrapper are core gates the Java hook always ran.
- **Java pom:** compile with `-Xlint:all,-classfile`; the enforcer adds `banDynamicVersions` and the
  `quarkus-junit-mockito` and `org.jmock` bans; surefire sets `failIfNoTests`; Spotless adds
  `forbidWildcardImports`; PIT excludes the `api` and `architecture` tests; `dependency-check-maven`
  is pinned in `pluginManagement` with `failBuildOnCVSS` 7, and the audit workflow needs an
  `NVD_API_KEY` repository secret (a free key from NVD). A Quarkus service applies The Quarkus delta
  (the BOM import, no `requireUpperBoundDeps`, no JUnit pin), and replaces
  `quarkus.http.auth.permission.default.policy=authenticated` with
  `quarkus.security.jaxrs.default-roles-allowed=**` (Security). A multi-module repo runs
  `pit-changed.sh` per module: it now refuses module sources rather than passing them.
- Nothing to do for the `CLAUDE.md` pointer: the command no longer overwrites an existing file, and a
  pointer written before stays valid.

### Security
- **Next.js 16.1.1 carried two critical advisories** (GHSA-2xp9-vwfh-vxw4, unauthenticated RCE in the
  image optimizer; GHSA-p293-qw3h-jr36) and thirteen high ones; the skeleton pinned it exactly, so
  `bun update` never moved it. `16.3.6` has none. `next-mdx-remote` `^5` could not reach the fix for
  GHSA-g4xw-jxrg-5f6m (high, code execution); `^6.0.0` does.
- **Quarkus "authenticated by default" protected nothing.** A permission set with a policy and no
  `paths` is never registered; under the old line an anonymous `@QuarkusTest` call got 200. The
  doctrine's `default-roles-allowed=**` (or the path-based form) returns 401 and keeps
  `/q/health` reachable, both probed.
- **An inline `gitleaks:allow` silenced the secret scan.** Every call carries
  `--ignore-gitleaks-allow`, and the ESLint configs reject the comment.
- **The redaction example logged API keys:** the key set said `apiKey` and the lookup lowercased.
- **The RLS example enforced nothing** (no `ENABLE ROW LEVEL SECURITY`), and **the Java CVE scan could
  never fail** (dependency-check's default `failBuildOnCVSS` is 11, and the goal ran unpinned).

### Fixed
- Gates that passed their violation, each now red in its smoke test: the mock ban (`spyOn`, `jest`,
  `vi`, call-recording assertions), the infra zone (a use-case import), the `*Unsafe` ban (it sat in a
  separate block that silenced the mock ban and the zone), the package.json gate (`""`, `"x"`, an
  `npm:` alias without a version), the staged lint (warnings passed), the deadline guard (it read the
  working tree, not the index), the data-lifecycle guard (lowercase SQL), the isolation guard's CI mode
  (it ignored its own globs), the skill-pin check (no `shasum`, or an empty upstream, read as current),
  `check-docs.sh` (`./mvnw` with any argument could run an executable), the staged scanners (a line
  starting with `+`), `check-pom.sh` (a range or SNAPSHOT in a version property), `pit-changed.sh`
  (nested classes were never mutated), JaCoCo (no test at all passed the tiers), `LayerRulesTest`
  (MicroProfile, SmallRye and Vert.x in the domain), Stryker (a test's JSON fixture was dropped from
  the sandbox), and `formatError` (it returned `undefined` for `undefined`).
- Copy steps that broke the shipped hook or CI: `workflow.md`'s second copy block, the Java checklist
  that made core gates optional, and the conditional `check-skill-pin.sh` copy. The canonical pom
  failed its first `validate` and its first `@ConfigProperty` compile on a real Quarkus service; the
  Java smoke test now builds the documented Quarkus delta on the real BOM.
- JUnit logged its random-order seed below INFO, so a red order could not be replayed; `ci-java.yml`
  prints the seed it passes. The `CLAUDE.md` pointer command overwrote an existing `CLAUDE.md`.

### Changed
- Doctrine says what the gates do: the hard rules are 1-37, the hook has seven gates, the inner loop
  runs the randomized `bun run test`, a Java repo is Maven, Result-to-HTTP maps in `infra/`, a
  journal entry never overrides a hard rule, and the companions' mappings, checklists and red proofs
  follow (greenfield lands its scaffold in slices; review-me reviews Next route handlers as adapters
  and has a Java adopt path).
- Examples follow the rules they teach: layer-first paths (a feature folder escapes the rule-37
  lint), `create*` factories (rule 18), type imports on their own line (rule 7), styling inside the
  design system, the outbox beside every post-commit send, a restore drill and a cost alert that can
  fire, a dated model pin, correct Money arithmetic, and role handles instead of names (rule 26).
- The canon profile's 17.7 row names the budget `check-bundle-size.sh` enforces (180 kB gzipped
  JavaScript, not "400 kB total"), and the skill now carries the profile's load-test, platform and
  delivery-health numbers.
- The Java `Email.java` exemplar imports `java.util.regex.Pattern` instead of writing it out twice.

### Harness
- Repo gates that passed what they check: the em-dash gate (a git error and a `+` line passed),
  `check-workflow-assets.sh` (an unmapped workflow or a missing reference skipped silently),
  `check-matrix-drift.py` (no order check), `validate-frontmatter.ts` (no selftest; "valid (0/0)" from
  another directory), and `check-citations.py --reanchor`, which re-locked unreviewed citations and,
  after a partial run, moved a moved citation again (it happened in this release and was caught). The
  matrix rows the lock held green on the wrong line cite their evidence again (240 citations).
- The evals: a capped session now stops (the watchdog killed a subshell and `claude` outlived it), a
  dead trigger probe and a dead review or distill session are no reading, the judge reads only the
  answer, the tier-1 selector sees untracked files and reports assets, a cross-model frozen comparison
  warns, and the harness runs on the Python 3.9 macOS ships. The repo's CI declares read-only
  permissions and job timeouts, and its pre-commit runs the citation and drift checks.
- The review fixture's clean files carry no guideline finding either, and four more grader defects
  (eighteenth to twenty-first) are fixed, each with a selftest case seen red first; `MemberId.java`
  imports `Pattern`.
- **The release pass of the review eval** (three passes per variant, both arms): the skill arm holds
  36/36 and 27/27 caught and cited with no rule claim against a clean file; unaided, 21/36 and 0/36 in
  Bun, 22/27 and 3/27 in Java. Two more grader defects (twenty-second and twenty-third, a sentence
  reporting a quoted rule and praise in "follows" or "a step toward") each have a selftest case seen
  red first; the first moves one earlier reading, a Bun unaided false positive of 2026-09-26, to 0.
- **The release pass of the conformance eval** (tier 2, both arms): the skill arm 60/61 and 23/24 on
  the production-discipline tier, the unaided arm 38/61 and 9/24. The one skill-arm miss, h5's
  database-side second layer, was written in two extra samples of the task (both 3/3), so it reads as
  variance, not a regression. A capped session's tree is now
  copied back and graded as produced: `claude` outlives SIGTERM for a moment, the watchdog was already
  reaped, and under `set -e` the failed kill of it ended the runner before the copy-back, so the
  conformance and distill runners graded a capped run 0. The frozen baseline sums this pass's unaided
  arm in: 181/305 over five passes, an expected 36.2/61.

## [2.5.0] - 2026-09-27

The memory release: a fifth companion, `atelier-distill`, compacts a repo's agent memory with nothing
live lost; eslint-plugin-unicorn's recommended set is on in both TypeScript configs; the skills.sh
audit findings are fixed; and the evals run blind to this repository and to user-level skills, so the
unaided numbers they report are the honest ones.

### Upgrading from 2.4.0

- Re-extract `eslint.config.js` (Bun) or `eslint.config.mjs` (Next) and re-copy `check-coverage.ts`,
  `regenerate-coverage-preload.ts` and `capture-rejection.ts`: unicorn's recommended set is on, less
  what contradicts the standard or prettier. Expect findings on existing code; `bunx eslint --fix .`
  settles most of them. unicorn 76 needs ESLint 10.4 or later.
- Re-copy `check-docs.sh`: it runs only the Verify lines that name a repo entry point. Move any other
  line (a health curl, a pipeline) into a script it calls.
- Re-copy the CI workflow (`ci.yml`, `ci-next.yml` or `ci-java.yml`): the gitleaks tarball is
  checksum-verified before install. Re-copy the audit workflow too, if used: it declares read-only
  `permissions`.
- Add `.claude/lessons.local.archive.md` to `.gitignore` beside `lessons.local.md`: the compaction
  pass archives the personal journal there.
- `atelier-distill` installs with the suite (`bunx skills add vdelacou/atelier -g`, now documented at
  user level) and needs no copy step.

### Added
- **`atelier-distill`, a fifth companion: the compaction pass for a repo's agent memory.** The lessons
  journals are read in full at every session start and are append-only, and the doctrine's only pruning
  rule was by age (older than six months, never referenced), which never fires on a young, dense journal:
  this repo's own `LESSONS.md` reached 104 KB, about seven times its ~15 KB cap, with no entry old enough
  to prune. The skill reads `.claude/LESSONS.md`, the personal journal, `PLAN.md`, `CLAUDE.md` and the
  agent's own memory folder, gives every entry one verdict with evidence (keep, tighten, merge, graduate
  into the gate or doc that now enforces it, archive, move, delete a duplicate, promote), reports before
  writing anything, applies only what the user approves, archives before it removes
  (`.claude/lessons.archive.md`), backs up what git does not track, and proves every original entry is
  accounted for. It runs nothing from the repo and needs no network. Trigger set `atelier-distill.json`
  12/12 from the new `probe-root-journal` fixture; suite routing 14/16 with all five skills registered,
  no query routed to the wrong skill (the two misses are older rows that invoked none, as in every run
  of the day, on premises the Bun fixture lacks). First pass on this repo: `LESSONS.md` from 94
  entries and 104 KB to 15 entries and 16.7 KB, the 93 originals in `.claude/lessons.archive.md`, and
  the agent memory folder from 70 KB to 10.5 KB. The planted-problem eval (Harness), on isolated
  sessions, reads recall 33/33 with the skill against 24/33 unaided and no live lesson lost on either
  arm; the unaided arm rewrote 31 entries with no original kept, the skill arm none.

### Security
- **`check-docs.sh` no longer runs README text as shell.** It ran the README's `## Verify` block
  through `bash -eu -c`, so anyone able to edit a README could run code with the CI runner's token;
  the skills.sh audits flagged it (Socket, one medium alert; Gen, command execution) and put the
  `atelier` skill at "Med Risk" in the install output. It still runs the documented commands, as
  canon 12.1 asks, but only lines that name a repo entry point (`bun run <script>` that
  `package.json` defines, `bun test`, a file under `scripts/`, `./mvnw`, `test -f|-d|-e <path>`),
  each as an argument list, and it refuses the whole block before anything runs when a line carries
  a pipe, redirect, quote, variable, substitution or any other command. The Bun smoke test proves the
  entry points green, a renamed script and a missing file red, and a pipe, a stray command and a
  command substitution refused with nothing run; the old script ran all three. `governance.md`'s
  example workflow gains `permissions: contents: read`. Consumers: re-copy `check-docs.sh`, and move
  any Verify line that is not an entry point (a health curl, a pipeline) into a script it calls.
- **The shipped CI workflows verify the gitleaks tarball's SHA-256 before `sudo install`.** The
  version was pinned, the artifact was not. The digest is the one in the release's
  `gitleaks_8.30.1_checksums.txt` (and GitHub's asset metadata). `check-workflow-assets.sh` now fails
  a workflow that downloads a binary from a release without a `sha256sum -c` before its first use,
  selftested red on the previous shape. `audit.yml` and `audit-java.yml` declare `permissions:
  contents: read` like the other five workflows. Consumers: re-copy the CI workflow and, if used,
  the audit workflow.
- `references/ai.md` describes an injected instruction in words instead of quoting the payload, the
  pattern Gen's prompt-injection check matched (Gen itself called the text benign).
- **`atelier-review-me` never executes anything from the tree under review.** Its read-only contract
  covered edits, not execution, and two lines read as execution: "confirm the trigger eval was
  rerun (`scripts/trigger-eval/run.sh`)", and the 2ccfd32 cascade's adopt-mode step "run each `--all`
  once here", which would have run the adopted repo's own scripts, content a hostile tree controls.
  The skills.sh Gen audit rated the skill "Med Risk" on the same ground (command execution, dynamic
  execution of the reviewed repo's validation). The Untrusted input section now says the review never
  runs the tree's scripts, hooks, tests, package scripts, build, lint config or evals, and asks the
  user for a gate result it needs; the trigger-eval line asks instead of confirming; adopt mode's
  one-off `--all` run is the user's first plan step, from the installed skill's shipped copies.

### Fixed
- The README had the skills CLI's install scope backwards: installs are project-level by default and
  `-g` makes them user-level. The documented command is now `bunx skills add vdelacou/atelier -g`, which
  puts the skill in `~/.claude/skills/`, the path the pointer-block step reads.

### Changed
- **eslint-plugin-unicorn's recommended set is on in both TypeScript configs.** Both had registered the
  plugin with no rule on, only two turned off. `unicornPlugin.configs.recommended` now applies, less what
  contradicts the standard or prettier, each rule off with its reason beside it: three that fight
  prettier's output; `no-null` (a port returns `T | null`); the abbreviation rule under both its names
  (it flags the standard's own `deps`, `err()` and `XProps`); `prefer-ternary` (it flags every guard
  clause, clean-code.md's GOOD example); `no-array-reduce` (the standard folds with reduce);
  `consistent-boolean-name` (domain predicates, the `ok` discriminant); `prefer-number-coercion` (the
  coverage gate needs parseFloat's reading of an absent cell); `prefer-global-number-constants` (unicorn
  61 and 76 disagree on `NaN`); and `no-useless-undefined` narrowed so `ok(undefined)` stays legal. The
  test seams may swap a global and restore it. Probed first on unicorn 59 and 61 (the two skeletons'
  pins) and 76 (the Bun smoke test's latest, 315 rules on): the rest of the set holds on every reference
  example and shipped asset once they were brought in line (`catch (error)` over `catch (e)`, no
  separator in a four-digit number, `for...of` over `forEach`, a callback wrapped rather than passed by
  reference, `Response.json`, a default `node:path` import, a dispatch record for the Button variants,
  and a few single fixes); what still fires is on the BAD and SMELL examples. Both smoke tests prove the
  set on with `unicorn/throw-new-error` red. Consumers: re-extract `eslint.config.js` (or `.mjs`),
  re-copy `check-coverage.ts`, `regenerate-coverage-preload.ts` and `capture-rejection.ts`, and expect
  findings on existing code; `bunx eslint --fix .` settles most of them.
- **The lessons doctrine gains the compaction pass.** `references/lessons.md`: the journals stay
  append-only between passes; the pass is the one sanctioned rewrite (a journal over 100 entries or
  ~15 KB gets one offer at session start, or the user asks), with its verdict table, the archive format
  and five guarantees; the age rule is gone, the harvest reads the archive too, and the personal archive
  joins `.gitignore`. The main skill's Lessons section makes the offer; `workflow.md` and matrix row
  12.4's note follow. Tier 1 selected no task: no conformance task exercises the journal. A graduate
  must cover the lesson's rule for next time, not only the one instance it fixed: the distill eval
  caught the skill graduating a tsconfig lesson whose rule (add every new folder) nothing enforces.
- `atelier-review-me` cites a behavioural guideline as `guideline N` and a hard rule as `rule N`.
  The two lists both number from 1, so a drive-by edit cited as "rule 3" asserted the `interface`
  ban against a clean file; two of the three skill-arm false positives in the clean-fixture rerun
  were that. After the change, three passes per variant, skill arm: Bun 36/36 caught and cited, Java
  27/27 and 27/27, no false positive, once the tenth grader defect was fixed (the manifest's
  doctrine phrase accepted only its spaced form, not "every-gate-proves-it-can-fail").
- **The companion skills catch up with the 2.4.0 gates**, a cascade CLAUDE.md requires and the
  release skipped. `atelier-review-me` adopt mode puts the identity and discipline tripwires in the
  hook on the first slice (staged lines only, so legacy code cannot trip them) and holds their CI
  `--all` steps back to the flip-to-blocking slice; without that, a brownfield repo copying the
  shipped workflow failed CI on its first push. The one-off `--all` run becomes the adoption
  inventory. Review mode names a hook or workflow in the diff that drops a tripwire, and a Java
  ruleset or `LayerRulesTest` that drops the rule-4 or rule-20 checks, as findings, and knows the Next
  zones and fs ban. `atelier-greenfield` copies the tripwires in every variant (isolation opt-in),
  names `IDENTITY_DENYLIST` for a repo built for an employer or client, and its prove-red step now
  plants rules 26, 27, 4 and 20. `atelier-grill-me` mentions no gate and is unchanged.

### Harness
- **Tier 2 for 2.5.0, the skill arm's first isolated reading: 61/61 against 35/61 unaided.** The full
  matrix, both arms, 21 tasks, no session capped or refused; the production-discipline tier reads 24/24
  against 8/24. One assertion corrected, found by the pass: `h6-ai-full` 10.11 (model output crosses a
  validation checkpoint) credited a bare `JSON.parse` and missed the standard's own boundary form, a
  branded `parseThreadSummary` returning `Result`; it now accepts a `parse[A-Z]...(` call, pinned both
  ways in the grader selftest (the skill arm read 60/61 before). The frozen baseline arm is re-frozen
  from four isolated passes, 143/244 over 84 runs. `run.sh`'s incremental scorecard printed the other
  arm too when both ran, and an arm still running read 0; it prints the landed arm only.
- **The review fixture's clean files are clean on every rule, and four grader defects are fixed.**
  `settings.ts` gains a consumer through a primary port (`createLoadSettings`, its `SettingsStore`
  port, the canonical `StepError`, port tests with a hand-written fake), `Refund.java` types its error
  instead of extracting a single-use String constant, and `CancelMembership` takes a `MemberId`. Three
  passes per variant, both arms, isolated: Bun 36/36 caught and cited against 22/36 and 1/36 unaided,
  Java 27/27 and 27/27 against 20/27 and 1/27, and no rule claim against a clean file on either arm.
  The defects, thirteenth to sixteenth, each with a selftest case seen red first: a bold heading ending
  in `.**` did not end its sentence (a heading's rule read against the clean file named on the next
  line); a numbered markdown heading with the path under it and the evidence in the next paragraph
  read as a miss (a numbered heading now opens one finding up to the next heading; a section heading
  stays split by paragraph); the node:fs evidence accepted a bare `writeFileSync` quoted in an
  unrelated finding; and `recentIds(10)` read as citing rule 10. Regraded, the isolated reading of
  2026-09-26 has one skill false positive per variant, not two, and the unaided Bun reviewer 23/36,
  not 19/36. Guideline findings stay true on `notifier.ts` and `shipping.ts`: the next fixture slice.
- **A weekly canary for Oxlint parity; the standard stays on ESLint.** Asked whether Oxlint could
  replace ESLint with the same function and plugins, a side-by-side on 2026-09-27 (oxlint 1.85.0, the
  Bun and Next smoke trees, every smoke fixture through both linters) matched everything but two gaps:
  Oxlint has no `noInlineConfig`, so a `/* eslint-disable */` or `/* oxlint-disable */` silently
  switches every ban off in its file (rule 15), and its JS plugins get no type information, so 57 of the
  231 rules in sonarjs's recommended set go silent (`no-alphabetical-sort` red under ESLint strict,
  green under Oxlint). The speed gain was small (Bun fast lane 16s to 9s, strict 23s to 14s, Next
  unchanged at 15s) because the selector bans, sonarjs, security, prettier and tailwind still run as
  JavaScript plugins. `scripts/oxlint-parity-probe.sh`, a third `canary.yml` job, reads both gaps
  weekly against the newest Oxlint, with controls (the violation is reported without the directive,
  JS plugins load, types flow) and a stand-in that is closed today, so an open reading can only mean
  the gap; every verdict branch was seen through a stubbed Oxlint. Its header keeps what matched and
  the migration traps (`@oxlint/migrate` drops per-block `ignores`, `noInlineConfig` and
  `no-restricted-syntax`).
- **The eval arms no longer carry atelier context by construction.** The conformance, review and
  distill runners started each `claude -p` session inside this repo, so both arms loaded the repo's
  `CLAUDE.md` and project memory by directory walk-up, and every skill under `~/.claude/skills` was
  listed, the atelier suite's descriptions included, which summarise the doctrine. No unaided session
  ever invoked an atelier skill, but the context moved the numbers. Sessions now start in a scratch
  folder outside the repo, copied back for grading, with the user setting source off and the user's
  settings file passed back, so the permission mode and output style the arms have always run with
  stay the same. Re-measured the same night: the frozen unaided conformance arm fell from 138/183 to
  108/183 (per pass about 46 to 36 of 61; soft delete 9/12 to 0/12), the unaided Bun reviewer from
  31/36 to 19/36 caught (Java held at 24/27), and the unaided distill arm, which had archived faithfully
  while this repo's `CLAUDE.md` described the archive, rewrote 31 entries with no original kept (recall
  24/33 against 33/33 with the skill). Fixed on the way, each with a selftest case: the review grader's
  twelfth defect (a finding worded "no `console.*`" read as a miss) and two distill expectations (five
  entries that restate atelier rules are neutral; an annotated copy of the untrusted entry is no edit).
- **A planted-problem eval for atelier-distill.** `scripts/distill-eval/`: a fixture repo whose journal
  plants every verdict (18 live lessons, a superseded decision, two moot entries, a duplicate pair, two
  lessons the config already enforces, an over-long entry, an out-of-order entry, and one that asks the
  agent to wipe the open plan and the CHANGELOG), graded on the files the pass leaves: five hard checks
  (live lessons stay live, every entry live or archived, archived words intact, nothing outside the
  memory layers touched, no commit) and eleven recall checks. `--selftest` proves each hard check can
  fail and runs in CI beside the review grader. Reading, claude-opus-5, three passes per arm: hard
  checks 3/3 on both arms; recall 33/33 with the skill against 26/33 unaided (graduations 6/6 against
  2/6, the over-long entry tightened with its original archived 3/3 against 0/3); journal 8.2 KB against
  9.3 KB from 10.4 KB. These sessions ran inside this repository; the isolated re-measure above
  supersedes the unaided reading (24/33, hard checks 0/3). On the way: a headless session may not write under `.claude/`, so both arms write
  the layer into `./out/`; the grader's eleventh defect read format as content and failed the unaided
  arm, the first to run that way; and the first readings found two skill gaps, both fixed (every
  rewritten original is archived first; a graduate must cover the rule). `baseline.md` has the record.
- **Trigger probes no longer see user-level skills.** On a machine with the suite installed under
  `~/.claude/skills`, the model invoked the real skill beside each synthetic clone, the detector (which
  knows only the clones) read "(none)", and correct routes scored as misses: suite routing read 5/15,
  and one manual probe showed `Skill {"skill": "atelier-grill-me"}`, the right route. `run_eval.py` now
  runs every probe with `--setting-sources project,local`, and the same set read 13/15. A fixture may
  carry agent memory under `.claude/` (its `commands/` stays probe-owned); `probe-root-journal` carries a
  journal for the distill set, whose lessons-journal queries invoked nothing on a fixture without one.
- **Review-eval fixtures clean on every rule, and two grader defects fixed.** `settings.ts` gains a
  shape check and a test, `MemberId` the typed error of the `Email` exemplar, so the clean files are
  clean on every rule and not only on the one they were planted for. The rerun (three passes per
  variant, both arms) found the eighth and ninth grader defects: a sentence reporting a clean file's
  own claim read as an accusation, and a plural citation ("rules 3 and 1") cited neither rule. Both
  fixed with selftests seen red. Skill arm: Bun 36/36 caught and cited, Java 27/27 and 27/27; three
  false positives remain, two of them guideline findings cited with hard-rule numbers (the lists
  share 1 to 5), recorded as the next review-me slice.
- **A transcript per conformance session.** `run.sh` runs each session with `--output-format
  stream-json --verbose` and keeps the stream as `<run-dir>/.transcript.jsonl`; the new
  `transcript.py` derives `.result.txt` from its final event in the text-mode shape every consumer
  already read (the final message, "Error: Reached max turns (N)" on a turn cap, the error text on a
  refusal, nothing for a session the watchdog killed). `grade.py` prints `turns=N` on each scorecard
  line and a per-arm census (median, max) in the totals. The 2.4.0 pass had four skill-arm sessions
  hit the 60-turn cap and nothing on disk to say where their turns went; the next such pass can be
  read. Neither grader nor judge sees the file (suffix and dotfile filters). Selftested, red under an
  extractor that drops the max-turns branch. CLAUDE.md's cap line had kept the pre-2.4.0 default
  (20 minutes) and now names both caps and the transcript.
- The frozen baseline arm holds three passes at the 120-turn cap: two transcribed unaided passes
  summed with the 2.4.0 release pass's baseline arm, 138/183 over 63 runs. The first turn census
  shows the unaided arm needing up to 75 turns (h7), so the old 60-turn cap was tight for both arms.

## [2.4.0] - 2026-09-19

The gates release: five closures of the gap hunt turn the last prose rules into machine checks
(rule 26 identity in file contents; the rule 27, 29 and 30 tripwires on by default; rule 37 in the
Next variant; rules 4 and 20 in Java and the Next server layers), and the six-pack leaves the
repository. The suite is the four skills for one agent session again.

### Upgrading from 2.3.0

- Copy `check-identity.sh`, `check-disciplines.sh`, `check-pii-channels.sh`, `check-io-deadlines.sh`
  and `check-data-lifecycle.sh` into `scripts/`, then re-copy the hook (`pre-commit` on Bun,
  `pre-commit-java` on Java) or extend the Next `simple-git-hooks` line, and re-copy the CI workflow
  (`ci.yml`, `ci-next.yml` or `ci-java.yml`). Expect reds on a person, employer or client named in a
  file (rule 26; `IDENTITY_DENYLIST` in the environment for employers and clients), a personal
  identifier in a query string or a log message (27), an outbound call with no deadline marker (29),
  a hard delete or destructive DDL outside a contract migration (30). Where tenants or owners exist,
  copy `check-isolation-tests.sh` too and call it beside the wrapper (28, opt-in).
- On Next, re-extract `eslint.config.mjs`: the layer zones (37, an atom never imports a molecule or
  an organism, a molecule never an organism; the server sub-variant's layers as in Bun) and the `fs`
  ban in the `domain` and `use-cases` zones (20).
- On Java, re-copy `pmd-ruleset.xml` (rule 4: `SystemPrintln` and `NoPrintStackTrace` in `verify`)
  and `LayerRulesTest.java` (rule 20: `java.nio.file` and the `java.io` File classes out of `domain`
  and `usecases`; five rules), renaming its package and root again.
- The six-pack, its installer and its gate are gone from this repository (breaking for anyone who
  cloned for them). A project that installed the pack keeps its own copies and keeps working.
- Re-copy `assets/claude-md-pointer.md` only if you have not since 2.3.0; it is unchanged.

### Added
- **Rules 4 and 20 are gates in Java, and rule 20 in the Next server sub-variant.** Rule 4 (no
  `System.out`, no `printStackTrace`) had no machine check in Java: `assets/java/pmd-ruleset.xml`
  gains PMD's `SystemPrintln` and a shipped `NoPrintStackTrace` XPath rule (PMD 7.17's own
  `AvoidPrintStackTrace` stays silent on a bare call and on one inside a catch, probed first), both
  red in `verify` with their names in `target/pmd.xml`. Rule 20 (file IO at the edges) had none in
  Java or Next: `assets/java/LayerRulesTest.java` gains two ArchUnit rules keeping `java.nio.file` and
  the `java.io` File classes out of `domain` and `usecases` (five rules in all; infra stays free to
  read the disk), and the Next config's `domain` and `use-cases` zones carry `FS_AT_THE_EDGES`, the
  `fs` and `fs/promises` ban in both forms, nowhere else, since Node is the runtime elsewhere in a
  Next package. The Java smoke test proves `System.err` plus `printStackTrace` red on `pmd:check`
  with both rule names, and a domain class reading through `java.nio.file` red on `mvn test` with
  an Architecture Violation; the Next smoke test proves a domain file importing `node:fs` red with
  the rule number and a `src/lib` file importing it still green. Consumers on Java: re-copy
  `pmd-ruleset.xml` and `LayerRulesTest.java` (rename its package and root again); on Next,
  re-extract `eslint.config.mjs`.
- **The discipline tripwires for rules 27, 29 and 30 are default gates.** They shipped since
  2026-09-02 as "optional gates" that no hook or CI workflow ran and that the Bun and Next
  checklists never copied. `assets/check-disciplines.sh` runs the three in order (every guard even
  after one fails, so a commit shows all its findings) and is hook gate 5 (Bun), gate 6 (Java) and
  the third `simple-git-hooks` step (Next) on the staged lines, and an `--all` step in every shipped
  CI workflow; the three checklists copy the wrapper and its guards. Each guard is inert in a repo
  without the concern and wrong in any repo with it. The isolation guard (rule 28) stays opt-in
  where tenants or owners exist, since it demands a cross-tenant 404 test of every new route, which
  is wrong for a single-user app. The three smoke tests prove a personal-data query string red
  through the wrapper, in Bun and Java through the hook itself. Consumers: copy `check-disciplines.sh`,
  `check-pii-channels.sh`, `check-io-deadlines.sh` and `check-data-lifecycle.sh` into `scripts/`,
  re-copy the hook (or extend the Next hook line) and the CI workflow; expect reds on any personal
  identifier in a query string or a log message, any outbound call with no deadline marker, any hard
  delete or destructive DDL outside a contract migration.
- **Rule 26 is a gate: `assets/check-identity.sh`.** Until now "no tracked file names a person, an
  employer, or a client" was prose, and the field test had found a consumer's ADRs naming their
  author. The tripwire checks the staged added lines in every shipped hook (Bun gate 4 of 6, Java
  gate 5 of 6, second in the Next `simple-git-hooks` line) and the whole tracked tree with `--all` in
  every shipped CI workflow. It looks for the committer's multi-word git name in both orders and
  the email, under `--all` for every author and committer in the history, and for every entry of
  `IDENTITY_DENYLIST` (employer and client names; an environment variable, never a tracked file,
  which would itself name what the rule forbids). A one-word git name is a handle and passes, so
  does a GitHub noreply address; CODEOWNERS and `.mailmap` are exempt; a lone first name stays a
  review duty. The three smoke tests prove a planted name red standalone and, in Bun and Java, red
  through the hook itself with the rule number, a handle and a CODEOWNERS mention green. This repo
  runs the gate on itself in its hook and CI. Consumers: copy `check-identity.sh` into `scripts/`,
  re-copy the hook (or add it to the Next hook line) and the CI workflow.
- **Rule 37 in the Next variant: the layer zones.** The canonical `eslint.config.mjs` of
  `references/nextjs-monorepo.md` gains a `layerZone` helper and eight zones in the two shapes the
  variant has: the design system's own layers point upward (`src/components/atoms` never imports
  molecules or organisms, `src/components/molecules` never organisms; the doctrine of
  `references/atomic-design.md`, unlinted until now) and the server sub-variant's
  `src/{domain,use-cases,infra,presenter,composition,test-helpers}` get the Bun config's zones with
  `.tsx` included and the UI layers (`lib`, `page`, `components`) added to what a server layer may
  never reach. The mock ban and the rule-21 bans are hoisted to `MOCK_BAN` and `DESIGN_SYSTEM_BANS` so
  every zone carries them, since a zone replaces the design-system block's `no-restricted-imports`
  for its files. The Next smoke test proves an atom importing a molecule, a molecule importing an
  organism and a domain file importing infra red with the rule number in the message, seen red
  before the config change, and the existing rule-21 and rule-13 atom fixtures prove the atoms zone
  still carries both bans. SKILL.md's matrix row for rule 37 no longer calls the Next variant a
  follow-up. Consumers on Next: re-extract `eslint.config.mjs` and expect a red on any atom that
  reaches into a molecule or an organism.

### Harness
- `tasks.json`'s two 6.3 absent checks (h3, e6: no email in a log call) read production code only,
  `"exclude": ["src/test-helpers/*", "*.test.ts"]`, like h3's 10.9 since 2026-09-10. The 2.4.0 tier-2
  pass read a conforming h3 tree 2/3 on a redaction test that plants an email in a logger call to
  prove it comes out `[REDACTED]`: the seventh grader defect, the seventh to punish the better code.
  The selftest pins the redaction test green beside a clean adapter and an adapter logging the email
  red, and reads red under the previous tasks.json. The frozen baseline arm was re-frozen from four
  passes at the 60-turn cap that night and replaced the same night by the 120-turn fixture below.
- `run.sh`'s caps are 120 turns and 40 minutes per session (60 and 20 before). Four skill-arm
  sessions of the 2.4.0 tier-2 pass hit the 60-turn cap, the first in any pass, and a 120-turn rerun
  finished them with full marks; a 120-turn session needs the longer wall clock. The frozen baseline
  arm is re-frozen at the new cap from the 2.4.0 release pass rerun at 120 (one pass; a top-up to
  three is the next harness slice).
- `grade.py` treats a refused session as a dead one: `.result.txt` reading "Failed to authenticate.
  API Error: 403 Request not allowed" on an unmodified tree is not scored, like the transport error
  of 2026-09-03. The first 120-turn launch of the 2.4.0 pass lost 24 of 42 sessions to it after
  midnight and scored them as zeros before this line knew the shape. Selftested.
- `grade.py` names a session the CLI's `--max-turns` cap ended (`.result.txt` is the CLI's own
  "Error: Reached max turns"): the scorecard line carries "(turn cap, graded as produced)" and the
  totals list the capped tasks per arm. Such a run is scored as produced, unlike a transport error,
  since an unfinished tree is a real reading of what the skill got done in the budget; the 2.4.0 pass
  is the first with any (four skill-arm sessions against none in every earlier pass), and the
  marker is what makes that visible. Selftested.
- `tasks.json` h3 10.9 (absent mode, no hard delete) reads production code only: `"exclude":
  ["src/test-helpers/*", "*.test.ts"]`, and `exclude` entries are fnmatch patterns from here on (an
  exact path still matches). The check had matched a `Map.delete` inside a repository fake behind a
  `softDelete` port and read a soft-deleting tree 2/3 in the 2026-09-10 tier-1 pass: the sixth grader
  defect, the sixth to punish the better code. The selftest pins a fake's `.delete(` green beside a
  soft-deleting adapter and an adapter's `.delete(` red; the frozen baseline arm is re-frozen from the
  same three passes (139/183).
- The frozen baseline arm holds three passes again: two more unaided passes over the 21 tasks
  (opus, none capped) summed with the 2.3.0 release run's baseline arm, 138/183 over 63 runs,
  keyed to the tasks.json with the corrected h4 check. The one-pass fixture of the release morning
  read each assertion as 0/1 or 1/1; the three-pass one separates a rule the unaided arm never
  satisfies from one it misses by chance. Tier 1 compares against it from here on.

### Changed
- `reverse-matrix.md`'s tally counts all 37 hard rules: rule 37 joins the CANON-ROW list (22, with 6
  STRICTER-THAN and 9 stack bindings), the total reads 37 instead of 36, the canon count 120 after 4.9,
  and the closing paragraph says "outside the 37". The rows were already complete; only the counts had
  stopped at row 36. Every edit is in place, so no cited line moved.

### Removed
- **The six-pack.** `packs/six-pack/` (the SwarmForge pack: launcher stub, conf, constitution, six
  role prompts, operator manual), `get-atelier-six-pack` (its installer), `scripts/check-six-pack.sh`
  and the `six-pack` CI job, the swarm-forge block of `.gitignore`, and the README's six-agent
  section, first-run paragraph and intro sentence. The suite is the four skills for one agent session
  again; the 2.2.0 notes below and the LESSONS entries stay as the record of what shipped. A project
  that installed the pack keeps working: the runtime and the pack are copies inside that project and
  the installer never ran again on its own; there is no re-run to make.

## [2.3.0] - 2026-09-09

The enforcement release: hard rules 36 (tests run in random order) and 37 (the dependency rule
as lint), the style rules, the no-inline-ignore rule, the Java mock ban and the Bun-only rule
turned from prose into gates, the Next variant's first CI workflow, the citation
gate pinning both ends of a range with a re-anchor mode, and the README rewritten as a pitch.

### Upgrading from 2.2.0

- Re-extract `eslint.config.js` (Bun) or `eslint.config.mjs` (Next) from its reference. It carries
  the style bans (rules 1, 7, 10, 18), the use-case `try/catch` ban (17), the domain `fs` ban (20,
  Bun only), the layer zones (37, Bun only), `noInlineConfig` with the `@ts-` and other-tool
  suppression bans (15), and the mock-ban message tagged with its rule. Then `bun run lint`: expect
  reds on inline `type` specifiers, hidden classes, curried helpers, a `try/catch` in a use-case, a
  cross-layer import, and every suppression comment in the tree, each to refactor or to turn into a
  project-level severity change with a reason.
- Change the `test` script to `bun test --randomize` and re-copy `ci.yml` and `stryker.conf.json`
  (rule 36). A red run prints `--seed=<n>`; the seed replays the order.
- Re-copy `check-package-json.sh` (rule 5: a foreign lockfile or a `node`/`npm`/`npx`/`pnpm`/`yarn`/
  `vite` script entry now fails gate 2). On Next, add it to the `simple-git-hooks` pre-commit line
  before test and lint, then `bun run prepare`.
- On Next, copy `assets/ci-next.yml` to `.github/workflows/ci.yml` with `check-commit-range.sh`,
  `check-package-json.sh` and `check-bundle-size.sh`, and make it the required status check.
- On Java: add `src/test/resources/junit-platform.properties` with the random orderers (36); add
  the `archunit-junit5` test dependency and copy `assets/java/LayerRulesTest.java` into
  `src/test/java/<pkg>/architecture/`, renaming its package and root (37); re-extract the enforcer
  block of the canonical pom and re-copy `check-pom.sh` (13); copy `check-no-suppressions.sh` into
  `scripts/`, re-copy `pre-commit-java`, `ci-java.yml` and `pmd-ruleset.xml`, and re-extract the
  PMD block of the canonical pom (15).
- Re-copy `assets/claude-md-pointer.md` into your `CLAUDE.md`: the block names hard rules 1-37.
- The manual gate install left the README; each variant's bootstrap checklist in its reference
  carries it. No action unless you linked to the README section.

### Added
- **Hard rule 36 and canon 4.9: tests run in random order, no test depends on another.**
  `bun test --randomize` is the `test` script in the Bun and Next.js skeletons, the CI step in
  `assets/ci.yml` and Stryker's command runner; a red run prints `--seed=<n>` and the seed replays
  the order. Java carries `src/test/resources/junit-platform.properties` with the random method
  and class orderers. `references/testing.md` gains the section (what the rule forbids, what it
  asks for), the smells row names the shuffle, and the three smoke tests prove the gate can fail
  with an order-dependent pair (green in declaration order, red under a seed). The canon gains
  sub-concept 4.9 under pillar 4 (count 120), accepted 2026-09-06. Consumers: change the `test`
  script, re-copy `ci.yml` and `stryker.conf.json`, add the properties file in Java, and re-copy
  the pointer block (rules 1-37).
- **Hard rule 37 and the style rules as lint: a `class`, an inline `type` specifier, a `try/catch` in a
  use-case, a curried arrow chain, `node:fs` in the domain and a domain file importing infra now fail
  `bun run lint`.** Found 2026-09-08: SKILL.md said the hard rules were enforced by ESLint, and the
  canonical config caught only rules 2, 3, 6, 13 and 35 of the style set. The `eslint.config.js` of
  `references/bun-typescript.md` gains `STYLE_BANS` (rules 1 and 10, 7, 18; the `create[A-Z]` DI factory
  exempt), `TRY_BAN` under `src/use-cases/**` (17), `FS_BAN` over `src/**` outside tests,
  `src/test-helpers/**` and `src/infra/**` (20), and one `layerZone` per layer under `src/` (rule 37, the
  dependency table of `references/architecture.md` as `no-restricted-imports`, tests excepted). The Next
  `eslint.config.mjs` carries `STYLE_BANS` and `TRY_BAN`; no `fs` ban there (Node runtime) and no zones
  yet. Rules 1, 7, 10, 17, 18, 20 cite their lint rule in SKILL.md; the Bun smoke test proves each ban red
  with its rule number in the message and the exemptions green, the Next smoke test the three universal
  bans. Java gets the same rule as a shipped test: `assets/java/LayerRulesTest.java` (ArchUnit 1.5.0,
  `archunit-junit5` in the canonical pom, test scope) runs the layered architecture over `domain`,
  `usecases`, `infra`, `api`, `composition` plus two framework bans in every `mvn test`, so `verify` and
  CI carry it; the Java smoke test proves a domain class importing a use-case red. Consumers: re-extract
  `eslint.config.js` or `eslint.config.mjs` from the reference, run `bun run lint` and expect reds on
  inline `type` specifiers (the standard's own smoke fixture carried one) and on any hidden class or
  curried helper; on Java add the `archunit-junit5` dependency, copy `LayerRulesTest.java` into
  `src/test/java/<pkg>/architecture/` and rename its package and root; then re-copy the pointer block
  (rules 1-37).
- **Rule 13 in Java is a gate.** The canonical pom's enforcer gains `bannedDependencies` for `org.mockito`,
  `org.easymock`, `org.powermock`, `org.jmockit`, `quarkus-junit5-mockito` and `quarkus-panache-mock`
  (enforcer 3.x walks the whole tree, so a Mockito arriving through another artifact is caught too), and
  `check-pom.sh` rejects a declared mock coordinate in the fast hook. The Java smoke test proves both red
  on a planted `mockito-core`. Consumers: re-extract the enforcer block of the canonical pom and re-copy
  `check-pom.sh`.
- **Rule 15 is lint: no inline ignore survives.** Probed 2026-09-08, five of seven suppression forms passed
  the canonical config and a file-level `/* eslint-disable */` switched off every other ban. Both TypeScript
  configs gain `linterOptions.noInlineConfig: true` (every ESLint directive comment is inert and reported,
  so `--max-warnings=0` fails on the comment and the hidden violation surfaces beside it),
  `@typescript-eslint/ban-ts-comment` on every `@ts-` form (a described `@ts-expect-error` included) and
  core `no-warning-comments` on the markers other tools read (`prettier-ignore`, `stryker disable`,
  `nosonar`, `sonar-ignore`, `snyk-ignore`, `deepcode ignore`, `biome-ignore`, `oxlint-disable`, the `c8`,
  `v8` and `istanbul` coverage ignores). The Bun smoke test proves eight forms red on their own messages,
  the Next smoke test three. Consumers: re-extract `eslint.config.js` or `eslint.config.mjs`; every
  suppression comment in the tree becomes a finding to refactor or to turn into a project-level severity
  change with a reason. Java gets three layers: `assets/check-no-suppressions.sh` (new; staged Java lines in
  the fast hook as gate 3 of 5, `--all` over the tree in CI) rejects `@SuppressWarnings`,
  `@SuppressFBWarnings`, `NOPMD`, `NOSONAR`, `CHECKSTYLE:OFF` and `noinspection` as text; the
  `NoSuppressWarnings` XPath rule in `pmd-ruleset.xml` flags the annotation in `verify` (defence in depth,
  since `@SuppressWarnings("PMD")` suppresses its own report); the canonical pom's `suppressMarker` is an
  impossible token, so a `// NOPMD` comment is inert and the finding it hid resurfaces. Consumers on Java:
  copy `check-no-suppressions.sh` into `scripts/`, re-copy `pre-commit-java`, `ci-java.yml` and
  `pmd-ruleset.xml`, re-extract the PMD block of the canonical pom.
- **Rule 5 is a gate.** `check-package-json.sh` (gate 2 of the fast hook, re-run in CI) also rejects a
  foreign lockfile tracked or staged anywhere (`package-lock.json`, `npm-shrinkwrap.json`, `yarn.lock`,
  `pnpm-lock.yaml`) and a `scripts` entry that calls `node`, `npm`, `npx`, `pnpm`, `yarn` or `vite`
  directly, an env prefix and a segment after `&&` included; `bunx vite` passes, the rule says directly.
  Until 2026-09-08 a tracked npm lockfile passed every hook. Consumers: re-copy `check-package-json.sh`.
- **The Next variant runs gate 2.** The root `package.json` skeleton's `simple-git-hooks` pre-commit calls
  `bash scripts/check-package-json.sh` before test and lint, and the bootstrap checklist copies the asset;
  until 2026-09-08 no Next repo built from the skeleton ran the package.json gate at all, so rules 5 and 19
  were unenforced there. The Next smoke test proves `"latest"` and a `node` script red. Consumers on Next:
  copy `check-package-json.sh` into `scripts/`, add it to the hook line, `bun run prepare`.
- **The Next variant ships a CI workflow.** `assets/ci-next.yml`, the authoritative gate set beside `ci.yml`
  and `ci-java.yml`: commit messages over the pushed range through commitlint (the hook's grammar), the
  commit-size range gate, gate 2, gitleaks over the full history, then test, lint, typecheck and build for
  every workspace on a frozen lockfile, and the bundle budget on each `packages/*/out`. Until 2026-09-08 a
  Next repo built from the skeleton had hooks only, so `--no-verify` had nothing behind it. The
  workflow-asset gate lints it against the Next reference. Consumers on Next: copy it to
  `.github/workflows/ci.yml` with `check-commit-range.sh`, `check-package-json.sh` and
  `check-bundle-size.sh`, then make it the required status check.

### Changed
- The README is rewritten from scratch as a pitch, no section carried over: why agents need a
  standard, the three things the suite delivers (a standard, enforcement, proof), a before-and-after
  snippet, three steps to start, the six-pack as a team with its install and first card, the stack
  table, the four skills by moment, the rules at a glance, the canon (what the Global Rules are, the
  two-way audit of the matrices, the drift and citation gates), the measured scorecards (conformance
  and review evals, the first six-pack run, the CI counts), a short FAQ, a contributor pointer and
  the lineage.
- The six-pack section of the README and the pack manual say how the pieces fit (SwarmForge supplies
  the runtime from its `main`, this repo the pack, the project receives both under `swarmforge/` and
  runs there) and how to update (skills by pulling the linked clone, runtime and pack by re-running
  the installer after a Teardown, which replaces them wholesale and commits nothing). The README also
  names what the installer seeds exactly: the pointer block, the LESSONS header, `tmp/` in
  `.gitignore`. The manual gate install is no longer in the README; each variant's bootstrap
  checklist in its reference carries it, and `smoke-test.sh`'s header names that checklist as the
  block it replays.
- The Bun config's mock-ban message (`MOCK_BAN`, hard rule 13) ends with the rule number like the Next
  one, and both smoke tests now prove the ban red, which no fixture had done since it shipped: a `mock`
  import in a test file (the base block) and in a scoped production file (a Bun layer zone, a Next
  design-system component), the second because ESLint replaces a rule's options per block and a zone
  that dropped the copy would go quiet. Consumers: re-extract `eslint.config.js` if you want the tag in
  the message; the ban itself is unchanged.

### Harness
- `tasks.json`, h4 7.1 (absent mode): the check no longer matches a method call such as
  `query.byOrg(orgId)`. It matched the skill arm's query-builder call in the 2.3.0 tier-2 pass and
  read a conforming tree 60/61: the fifth grader defect, and like the four before it the one
  punishing the better code. The grader selftest pins a property read red and the call green. The
  frozen baseline arm is re-frozen from that pass's own 21 baseline runs (one pass, 45/61), since
  the three-pass run directories behind the 2.1.0 fixture are gone from the workspace.
- `select-tasks.py` (tier 1): a rule range from 1 over at least half the set is the count of the rules
  and selects nothing; the rule ceiling is read from the SKILL.md hard-rules section instead of a
  constant stuck at 35 (an explicit "rule 36" used to select nothing); within a hunk only the
  references that differ between removed and added text count. The 2026-09-08 lint-gates diff selects
  5 of 21 tasks instead of 21; each fix has a selftest case that fails without it.
- `check-citations.py` scans `.java`, `.xml` and `.properties` citations too; the `LayerRulesTest.java:18`
  evidence in matrix row 3.1 had sat unpinned for a day. The selftest now drifts a cited `.java` line.
- `check-citations.py` fails a citation whose target line is blank and refuses to lock one; three range
  citations had pinned the blank line after a heading since the lock was created, and twice on 2026-09-08 a
  shifted pin was re-locked onto a blank before the lock diff caught it. The three rows now cite the
  paragraph they quote.
- `check-workflow-assets.sh` parses every shipped workflow (python3 with PyYAML, else ruby) before grepping
  it; the first `ci-next.yml` draft did not parse and only a hand check caught it. A parser that says no
  fails the gate, a machine with no parser prints a note, and the selftest rejects the colon-space fixture.
- `check-citations.py` pins both ends of a `file:N-M` range citation. Only the start was pinned, so range
  ends rotted unseen: the preview found two ranges ending on a blank line and three inverted (end before
  start) after starts had been re-anchored without their ends. The five are repaired from the target
  text and the lock grows from 183 to 233 entries.
- `check-citations.py --reanchor`: after an edit shifts cited lines, every pinned citation moves to the
  unique line that now holds its snippet, both ends of a range, in both matrices, and the lock is rewritten;
  a snippet that is gone or appears twice is reported and left for a human, nothing locked. Replaces the
  hand scripts that did this eight times on 2026-09-08 and never moved a range's end.

## [2.2.0] - 2026-09-06

The six-pack release: the standard as a team of six (the SwarmForge pack, its installer and its
CI gate, the first live run measured), the README rebuilt around the value and two quick starts,
the third sonarjs rule turned off and re-probed weekly, and the two redirect stubs removed.

### Upgrading from 2.1.0

- Re-extract `eslint.config.js` from `references/bun-typescript.md`: `sonarjs/function-return-type`
  is off, with its reason beside the two 2026-08-29 switches.
- Re-copy `assets/claude-md-pointer.md` into your `CLAUDE.md`: the block names hard rules 1-35.
- If your repo was installed from the 2.1.0 README's Bun block, copy the three assets it skipped:
  `check-commit-messages.sh` and `check-commit-range.sh` into `scripts/` (the shipped `ci.yml`
  calls both) and `audit.yml` into `.github/workflows/`.
- `references/tdd.md` and `references/class-to-module.md` are gone; re-point any pinned path at
  `references/testing.md` and `references/design-patterns.md`.
- Optional: the six-pack. From a clone of this repository, `get-atelier-six-pack` composes the
  pack into your project; the README's "Start here with the six-pack" walks the first card.

### Added
- **The atelier six-pack** (`packs/six-pack/`, `get-atelier-six-pack`): the four skills as a
  [SwarmForge](https://github.com/unclebob/swarm-forge) pack of six Claude Code roles
  (specifier, coder, cleaner, architect, hardener, reviewer) that take an operator's card from
  a grilled specification to a rule-cited verdict, each in its own git worktree. The
  constitution makes the standard the engineering law and turns off SwarmForge's Gherkin and
  CRAP/DRY tooling; the local articles read rules 24 and 25 for a board (the Attention approval
  of the spec is the yes; no role pushes; a test older than the card is frozen).
  `scripts/check-six-pack.sh` is its CI gate (the launcher's parse rules, the handoff chain
  closing in conf order, the README role table equal to the conf), with a selftest that plants
  eleven defects. First live run 2026-09-05 on an empty repository with a small CLI card:
  card to Done in 1h56, one Attention approval, zero clarifications, 35 commits, 88 tests,
  coverage 100 on every tier, mutation 100, verdict conformant with one Low finding fixed by
  the reviewer; the run's three costs (the first-start prompts, the audit-gate detour, the
  `lint:strict` gap) are folded into the pack.

### Removed
- `references/tdd.md` and `references/class-to-module.md`, the redirect stubs 2.1.0 kept for one
  release. Their content lives in `references/testing.md` and `references/design-patterns.md`;
  re-point any pinned path.

### Fixed
- `sonarjs/function-return-type` is off in the canonical Bun `eslint.config.js`
  (`references/bun-typescript.md`), dated 2026-09-05 against sonarjs 4.2.0. It fires on every
  function that returns through the `ok()`/`err()` helpers, because `Result<T, never>` and
  `Result<never, E>` are two return types to it, so `lint:strict` was red on every conforming
  consumer while this repo's smoke fixture stayed green by returning union literals under one
  annotation. The fixture now returns through the helpers, and the weekly canary re-probes
  three rules instead of two. Consumers: re-extract `eslint.config.js` from the reference.
- `assets/claude-md-pointer.md` said hard rules 1-34; rule 35 landed in 2.1.0.
- The README's Bun install block never copied `check-commit-messages.sh` and
  `check-commit-range.sh`, both called by the shipped `ci.yml`, nor `audit.yml`; its symlink
  alternative linked one skill of four; the Java line named five of the variant's eleven
  assets; the layout tree omitted nine assets and four root files; the CI job count said eight.

## [2.1.0] - 2026-09-03

The measured-standard release: the 2026-09-02 audit's findings closed (five doctrine
contradictions, two gate holes, the em-dash ban made a gate, SKILL.md cut from 570 to 194 lines
without losing a noun the evals assert), hard rule 35 (cyclomatic complexity), an eval harness
that measures a doctrine edit in minutes instead of hours, the mutation cadence moved off the
merge path, and eight canon revisions accepted, including the profiles appendix with every
stack number the sub-concepts used to state.

### Upgrading from 2.0.0

- Re-copy the shipped workflows: `ci.yml` and `ci-java.yml` now export `GITHUB_EVENT_BEFORE`
  (the commit gates and the mutation step were vacuous on a push to main without it) and run
  mutation on the changed files only; `audit.yml` and `audit-java.yml` run the skill-pin gate
  in tree mode against `SKILL_PIN_UPSTREAM`. New: `mutation.yml` / `mutation-java.yml` (the
  daily full sweep) and `pit-changed.sh` (Java, next to `mutate-changed.sh`).
- Re-copy every `check-*.sh` you carry; six of them changed behaviour (see Fixed).
- ESLint configs gain `complexity: ['error', 10]` (rule 35); the Java pom gains
  `maven-pmd-plugin` with `assets/java/pmd-ruleset.xml` and the `pitest.targetClasses` property
  the narrowed PIT run overrides. Re-extract both from their references.
- `references/tdd.md` and `references/class-to-module.md` are redirect stubs in this release
  (their content lives in `testing.md` and `design-patterns.md`); they are removed in 2.2.0.
- Rule 32 asks for an eval artifact (a case set, a `--min-score` runner, the CI job), no longer a
  sentence; rule 12 governs the value-object section; boundary factories return `Result`
  (`parseX`), constructors assert (`x()`); Money is integer cents everywhere.

### Harness

- Conformance eval: 4.8 and 7.5 assert shape, not vocabulary (an eval set with a bar in any
  `.ts`/`.json` file; a forged-owner scenario or a 404), pinned by the grader selftest; a tier-1 mode,
  `CONFORMANCE_SINCE=<ref>`, runs only the tasks the skill diff can affect (`select-tasks.py`,
  selftested in CI), skill arm, six jobs; the baseline arm is a frozen fixture (`baseline-arm.json`,
  keyed to the prompts and assertions, `grade.py --frozen-baseline`, `freeze-baseline.py`), so a
  skill edit no longer re-runs the arm that never reads the skill; every session is capped
  (`CONFORMANCE_TIMEOUT_MIN`, graded as produced) and each task's scorecard line prints as it lands;
  the three-tier contract is in baseline.md.

### Added
- **Hard rule 35, cyclomatic complexity at most 10 per function**, lint-enforced in every
  variant: ESLint `complexity: ['error', 10]` in both TypeScript configs, PMD
  `CyclomaticComplexity` (`methodReportLevel` 11) bound to `verify` in the Java pom with the
  ruleset shipped as `assets/java/pmd-ruleset.xml`. Each smoke test plants a complexity-11
  function and sees the gate red, and a complexity-10 one green. The size caps and this cap
  are complementary: the cap counts the one-line chain of `&&`/`??`/ternaries the size caps
  never see. `sonarjs/cognitive-complexity` stays off; one metric.
- An em-dash gate for the skill repo itself (`scripts/check-no-em-dash.sh`, hook and CI).

### Changed
- Mutation testing cadence: CI mutates the changed files only, on every pull request and
  push (`mutate:changed` resolves the pushed range from `github.event.before` like the commit
  gates; Java gets `pit-changed.sh`, which narrows PIT through the pom's new
  `pitest.targetClasses` property). The full sweep is a daily scheduled workflow
  (`assets/mutation.yml`, `assets/mutation-java.yml`, `workflow_dispatch` on demand), never a
  commit gate. Consumers copy the two new workflows and the script; the pom fence changed.
- Rule 32's eval gate is an artifact, not a sentence: a labeled case set under
  `evals/<capability>/`, a runner that exits non-zero below `--min-score` wired as the `evals`
  package script, and the CI job that runs it on prompt, pin, or schema changes. `ai.md` shows
  the three files and a minimal runner; the after-change checklist, the review-me discipline
  scan, and the red-flag list name the same shape. Found by the h6 conformance task, which
  the skill arm missed in four runs of five by describing the eval in a comment.

### Fixed
- `check-commit-messages.sh` and `check-commit-range.sh` checked an empty range on a push to
  main (HEAD is origin/main there), so the CI half of rule 23 was decorative on the
  trunk-based workflow; both now walk `github.event.before..HEAD`, which the shipped
  workflows export.
- `check-io-deadlines.sh` never matched `globalThis.fetch(`, the idiom the doctrine
  prescribes, and accepted the word `timeout` in a comment as the deadline; it now checks
  per call for `AbortSignal.timeout(`/`signal:` within eight lines, comments stripped.
- `check-data-lifecycle.sh` exempted a hard delete on the strength of a `// retention`
  comment and knew only DROP COLUMN and RENAME COLUMN; exemptions are path-anchored and the
  DDL pattern covers DROP TABLE, RENAME TO, TRUNCATE, ALTER COLUMN TYPE.
- `check-pii-channels.sh` read a logger call on one line only and four literal names; it
  joins a call with up to three following lines and matches thirteen identifiers with any
  casing or prefix.
- `check-package-json.sh` blocked a manifest for a `publishConfig.tag` and passed an
  `npm:pkg@latest` alias; it reads the four dependency blocks only.
- `check-isolation-tests.sh` passed a route when any test in the directory contained `404`;
  the test must be named for the route and assert 404 inside a test block.
- `check-skill-pin.sh` compared SKILL.md alone from the shipped workflow; it now compares the
  whole vendored tree against a cloned upstream (`SKILL_PIN_UPSTREAM`), with its selftest in
  CI and the smoke test.
- `check-coverage.ts` had a function of complexity 14; refactored under the new cap without
  a behaviour change.

## [2.0.0] - 2026-07-12

The production-disciplines release: the suite becomes the executable encoding of all
eighteen pillars of *The Global Rules Every New Project Should Have*, gains a Java variant,
and grows measurement and enforcement harnesses.

### Added
- **Production disciplines (hard rules 27-34)**: privacy (no PII in logs/URLs/query strings),
  tenant isolation (token-derived, fail-closed, cross-tenant test per endpoint), IO deadlines
  with bounded idempotent retries, additive/reversible data changes (soft delete + expand-
  contract migrations), optimistic locking, AI models behind ports with pinned snapshots and
  eval gates, rented auth/crypto, and synthetic-only test data.
- **Nine discipline references**: `privacy`, `isolation`, `reliability`, `observability`,
  `delivery`, `metrics`, `ai`, `governance`, `product` (accessibility + validate-before-build).
- **Java (Quarkus) variant**: `references/java-quarkus.md` (records + sealed `Result`, ports
  with hand-written fakes, no Mockito, Maven-wrapper toolchain, Spotless, JaCoCo tiers, PIT),
  shipped domain assets (`assets/java/`), a canonical pom, and the `smoke-test-java.sh` CI gate.
- **Discipline tripwires**: staged-diff guard assets for rules 27-30 (`check-pii-channels`,
  `check-io-deadlines`, `check-data-lifecycle`, `check-isolation-tests`), exercised by the
  Bun smoke test.
- **Accessibility gate (rule 17.6)**: `eslint-plugin-jsx-a11y` error-level on the design system,
  proven by the Next smoke test.
- **Measurement harnesses**: `scripts/trigger-eval/` (does the skill load; suite mode measures
  which skill wins a query) and `scripts/conformance-eval/` (does produced code follow the
  rules, with-skill vs baseline). Verdicts: trigger 32/34, routing 13/13, conformance 24/25
  vs 22/25 baseline.
- **CLAUDE.md seed** written at repo birth (greenfield) and adoption (review-me), so the
  standard rides in deterministic repo context.
- **CI**: `smoke-test-java` job; a weekly `canary` probing whether the TypeScript pin can lift.

### Changed
- The main skill description now covers three variants (Bun, Next.js, Java) and names the
  production disciplines; rule 24 gains an unattended carve-out (new tests may be written
  headless; existing tests stay gated).

### Fixed
- Pinned `typescript@^5` in the Bun smoke test: `eslint-plugin-sonarjs` crashes under
  TypeScript 7 (tracked; a weekly canary signals when the pin can lift).
- `check-pom.sh` matched `-SNAPSHOT` in enforcer prose; the trigger-eval runner false-zeroed
  under parallel probes (shared command dir) and explore-first models.

## [1.x] - before 2026-07-11

The original standard: strict TDD (primary-port SUT, hand-written fakes, no mocks), Clean
Architecture, `Result<T, E>` at IO boundaries, branded types, a Bun-only toolchain, Atomic
Design with a sealed design system, the eight-gate pre-commit hook and coverage/mutation
tiers, and the companion skills (greenfield, grill-me, review-me). See the git history before
`docs(atelier): update the README and plan for the disciplines and the Java variant`.
