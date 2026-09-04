# Atelier six-pack

The `atelier-six-packs` branch is a [SwarmForge](https://github.com/unclebob/swarm-forge) pack: six Claude Code agents that take an operator's card from a grilled specification to a rule-cited conformance verdict under the atelier coding standard, each in its own git worktree, exchanging committed work through SwarmForge's durable handoffs while the operator approves the spec, answers clarifications, and watches a local dashboard. It is the standard's four skills arranged as a pipeline: `atelier-grill-me` specifies, `atelier` and `atelier-greenfield` build, three roles refactor, restructure, and harden under the main skill's references, and `atelier-review-me` closes the card.

SwarmForge's `main` branch supplies the runtime (launcher, handoff daemon, dashboard, board) and the three shared transport articles; this branch supplies the pack: the launcher stub, the role table, the constitution, and the six role prompts. Read the [SwarmForge README](https://github.com/unclebob/swarm-forge/blob/main/README.md) for the runtime model and the [handoff protocol](https://github.com/unclebob/swarm-forge/blob/main/swarmforge/handoff-protocol.md) for message format, audit, retry, and merge details. This file covers only the atelier pack.

## Structure

This branch contributes the pack-owned half of an installation, plus its installer and its gate:

```text
get-atelier-six-pack               installer (compose, link the skills, seed the pointer)
swarm                              launcher stub
swarmforge/
  swarmforge.conf                  the six roles, backends, worktrees, receive modes, propagation
  constitution.prompt              entry point; the standard wins on conflict, no Gherkin tooling
  constitution/articles/
    project.prompt                 shape, file conventions, ownership, untrusted input
    local-engineering.prompt       where the skills live, startup install, the inner loop per variant
    local-workflow.prompt          rules 24 and 25 in a swarm, commits, plan and lessons, handbacks
  roles/
    specifier.prompt  coder.prompt  cleaner.prompt  architect.prompt  hardener.prompt  reviewer.prompt
scripts/check-six-pack.sh          the gate: conf, prompts, handoff chain, README table (--selftest)
skills/                            the four atelier skills, linked into ~/.claude/skills by the installer
```

`get-atelier-six-pack` composes the shared runtime from SwarmForge `main` with this pack, the same composition `get-swarm-forge six-pack` performs. Generated transport state lives in `.swarmforge/`; generated role checkouts live in `.worktrees/`.

## Roles

[`swarmforge/swarmforge.conf`](swarmforge.conf) is the authority for the active roles, backends, worktrees, receive modes, and propagation; `scripts/check-six-pack.sh` keeps this table equal to it.

| Role | Skill | Worktree | Receive mode | Propagation |
|---|---|---|---|---|
| `specifier` | `atelier-grill-me`, `references/product.md` | project root (`master`) | task | forward only |
| `coder` | `atelier`, `atelier-greenfield` on an empty tree | `.worktrees/coder` | task | forward only |
| `cleaner` | `atelier` (clean code, code smells, complexity) | `.worktrees/cleaner` | batch | back one |
| `architect` | `atelier` (architecture, object design, SOLID, patterns, Result) | `.worktrees/architect` | batch | back all |
| `hardener` | `atelier` (testing, gates, tripwires, disciplines, security) | `.worktrees/hardener` | batch | forward only |
| `reviewer` | `atelier-review-me` | `.worktrees/reviewer` | batch | back all |

Every role is a `claude` backend; the launcher adds `--permission-mode bypassPermissions`, so the agents run unattended inside the role worktrees. `master` means the project's main checkout on its current branch; the branch does not need to be named `master`. The specifier keeps that name and that worktree on purpose: the handoff daemon holds a `git_handoff` for operator approval only when the sender is the master-worktree role and a role named `specifier` exists.

## Workflow

```text
New Task -> specifier -> Attention -> coder -> cleaner -> architect -> hardener -> reviewer -> Done
```

- `specifier` grills the card (one question at a time through the dashboard, each led by a recommendation, the tree explored first) and writes `docs/specs/<task-name>.md`: the goal, the scenarios as complete business scenarios in the order they should pass, the production disciplines (rules 27-34) the card triggers with their concrete checks, what is out of scope, and each decision with its rationale. A new product or feature is grilled for whether to build it before how. Consequential decisions become ADRs under `docs/adr/`.
- `coder` makes the scenarios pass test-first under the main skill: the primary port as the SUT, hand-written fakes, `Result` at every IO boundary, branded types at trust boundaries, the lazy ladder, and the inner loop green before handoff. On an empty tree it runs the `atelier-greenfield` checklist for the variant the spec names, proves the gates green and then red, and commits the one sanctioned big-bang scaffold.
- `cleaner` does the refactor step: names in domain language, functions under 10 lines, complexity at most 10, no `else`, duplication extracted on the third occurrence only, coverage held at the tiers, test scenarios readable. Behaviour is preserved.
- `architect` owns structure: the Clean Architecture layers, dependencies pointing inward, ports as injected function types, branded value objects with two-tier factories, dispatch maps over conditionals, adapters that never re-answer a domain question, and the lint rules that pin each boundary with a fixture that proves they fire.
- `hardener` proves the tests bite: mutation on the task's domain and use-case files at 90 or above, a test seam on every infra adapter, the four discipline tripwires where the spec triggered them, the disciplines' concrete checks, the security source-to-sink lens, and a fixture for every gate the task added.
- `reviewer` runs `atelier-review-me` over the whole task diff, cites a rule number for every finding, fixes the narrow ones itself, escalates the rest to the operator, writes `docs/reviews/<task-name>.md`, appends the task's lessons to `.claude/LESSONS.md`, and broadcasts the terminal handoff that marks the card Done.

Because the specifier is the project-root role, its forward handoff is held in **Attention** for operator approval before delivery to the coder. That approval is where the standard's two confirmation gates land in a swarm (below). Later handoffs move the board automatically. Cleaner and architect results propagate back to earlier roles as configured, so every role works on the restructured tree. The reviewer's terminal result propagates to all five earlier roles and moves the card to Done.

Batch mode lets the four downstream roles process compatible queued handoffs together while specification and implementation stay task-focused.

## Install and run

Prerequisites: `zsh`, `git`, `tmux`, Babashka (`bb`), the `claude` CLI (Claude Code, signed in), and the variant's toolchain, Bun for a Bun-script repo or a Next.js package, JDK 21 with the Maven wrapper for Java. `gitleaks` on PATH serves the hooks' secret gate; the hook degrades without it and says so.

From the project that should receive the pack (an existing repo, or an empty directory that the first card will turn into one):

```sh
git clone -b atelier-six-packs https://github.com/vdelacou/atelier.git ~/code/atelier
cd ~/code/my-project
~/code/atelier/get-atelier-six-pack
```

The installer composes the pack (the shared runtime and articles from SwarmForge `main`, this branch as the pack, through `get-swarm-forge`, downloaded for the run when it is not on PATH), links the four skills into `~/.claude/skills/` (`--copy-skills` copies instead, `--skip-skills` leaves that directory alone), and seeds three files when they are missing: the atelier pointer block in `CLAUDE.md`, the `.claude/LESSONS.md` header, and `tmp/` in `.gitignore`. It writes files and never commits (rule 25). Commit what it seeded before starting the swarm: role worktrees are cut from `HEAD` and carry only committed files.

```sh
git add CLAUDE.md .claude/LESSONS.md .gitignore swarm swarmforge
git commit -m "chore(swarm): install the atelier six-pack"
./swarm
```

`./swarm` starts the configured agents, the handoff daemon, and the local dashboard. The roles run in invisible tmux sessions; open their live panes from the dashboard. Use **New Task** to give the specifier a card: write the card as intent (what and why, the users, the constraints), not as a design; the specifier grills it. **Attention** holds the specification for your approval (approve, or reject with comments the specifier reads as findings) and surfaces clarifications from any role. **Teardown** stops the swarm without deleting the project.

Environment for offline or forked installs: `SWARMFORGE_BASE_DIR` (a local SwarmForge `main` checkout instead of a download), `SWARMFORGE_REPO_URL` (a fork), `GET_SWARM_FORGE` (an existing helper), `CLAUDE_SKILLS_DIR` (another skills directory).

## The standard in a swarm

The atelier standard assumes a user in the conversation; the swarm has an operator on a board. `local-workflow.prompt` reads the two behavioural gates for that setting, and the rest of the standard applies unchanged.

- Rules 24 and 25. The card authorises the task; the operator's Attention approval of the spec is the rule 24 yes for the scenarios it names and the rule 25 yes for every commit the task's pipeline produces on the role worktrees. Commits are sanctioned; pushes are not: no role pushes, the operator pushes from the project checkout.
- Tests. A test created inside the task's pipeline may be renamed or tightened downstream as long as its scenario survives. A test that predates the task is frozen; a role that cannot proceed without touching one asks the operator through the dashboard and waits. A failing pre-existing test means fix the code.
- No Gherkin, no APS. SwarmForge's shared engineering article and the launcher's startup lines ask for Acceptance Pipeline tools and CRAP or DRY analysers; the constitution takes precedence and turns them off. Verification is the standard's gate set for the variant: `bun test`, `bun run lint`, `bun run typecheck`, `bun run coverage`, and mutation with Stryker for a Bun-script repo; test, lint, typecheck, and `bun run build` for a Next.js package; `./mvnw spotless:check verify` and PIT for Java.
- Hooks. `core.hooksPath=.githooks` is repository-wide, so the atelier pre-commit and commit-msg hooks run in every role worktree; dependencies are per worktree and each role installs them at startup. The swarm launcher rewrites `.git/hooks/commit-msg` with its byline hook at every start: inert under `core.hooksPath`, but a Next.js package on `simple-git-hooks` must re-run `bunx simple-git-hooks` after `./swarm` to restore commitlint (CI's `check-commit-messages.sh` catches the gap either way).
- Plan and lessons. Each role keeps its plan untracked in `./tmp/plan.md`, never in `.claude/PLAN.md`, because six roles merging one file would conflict on every handoff. `.claude/LESSONS.md` has one writer, the reviewer; the other roles propose entries as `Lesson: [kind] ...` lines in their commit bodies.
- Commits. Conventional Commits with the swarm byline `By <role>.` in the body, at most 10 files and 300 lines each (several commits then one handoff of the last SHA is the normal shape), no person or employer named in file contents. The coder's initial scaffold is the one justified big-bang.
- Review fixes. `atelier-review-me` reports and never edits because a user is there to say "apply the fixes"; in the swarm the reviewer applies only the narrow, rule-cited fixes that fit in one commit without a design decision, and escalates everything else to the operator with a proposed follow-up card.

## Changing this branch

- Change `swarmforge/swarmforge.conf` to change the six active roles, their backends, worktrees, or queue behaviour; update the role table above in the same change, the gate compares them.
- Change `swarmforge/roles/` to change the division of work. Keep every role's receive/send/done loop and the handoff to the next role in conf order; the gate checks both.
- Keep six-pack additions in `project.prompt` or `local-*.prompt`. Never name a pack article `engineering.prompt`, `workflow.prompt`, or `handoffs.prompt`: those come from SwarmForge `main` and the installer drops a pack file of that name.
- Doctrine lives in `skills/`; the role prompts point at it and do not restate it. A doctrine change on `main` reaches the swarm through the skills, not through the prompts.
- Put runtime, dashboard, terminal, installer, or shared-constitution changes on SwarmForge `main`, not here.
- `bash scripts/check-six-pack.sh --selftest && bash scripts/check-six-pack.sh` before proposing a commit.
