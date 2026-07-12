# LESSONS

Append-only journal of mistakes, decisions, and gotchas for this repo. Never rewrite or delete entries; supersede a decision with a newer `[decision]`. Format and triggers: `skills/atelier/references/lessons.md`.

## [gotcha] 2026-07-12 | typescript 7 crashes eslint-plugin-sonarjs at rule load

The smoke test's unpinned toolchain install pulled TypeScript 7.0.2, and sonarjs (<= 4.1.0, dependency spec `typescript: '>=5'`) crashed ESLint outright: its rules read `ts.SyntaxKind.*` at module scope, and TS 7's module shape breaks the CJS default-export interop (`Cannot read properties of undefined`). `tsc` itself is fine; only programmatic API consumers break. Fix: `typescript@^5` is the one deliberate pin in the smoke-test install (matching the canonical skeleton's `^5.0.0`), lifted when sonarjs supports TS 7. Rule for next time: an unpinned-toolchain canary that fires is a success; respond by pinning the one incompatible dep with a dated reason, not by pinning everything.

## [gotcha] 2026-07-12 | setup-java cache maven requires a pom in the repo

`actions/setup-java` with `cache: maven` fails the job in seconds ("No file matched to [**/pom.xml]") when the repository holds no pom, which is exactly this repo's shape: the smoke test generates its pom at runtime from the reference doc. Drop the cache option; the probe re-downloads plugins each run and that is fine.

## [gotcha] 2026-07-11 | stock trigger-eval runner false-zeros with fable

The skill-creator `run_eval.py` scored every should-trigger case ~0/5 against a previously optimized description. Three compounding causes: it concludes False on the first non-Skill tool call (Fable explores the repo before consulting a skill), its 30s timeout straddles Fable's thinking latency, and, decisively, parallel workers share one probe root's `.claude/commands`, so each probe's model sees N uuid-suffixed clones and almost never invokes the uuid its own detector greps for. A patched runner (full-stream detection, per-probe isolated roots, 90s timeout) lives in the gitignored `skills/atelier-workspace/trigger-eval-2026-07-11/`; with it the same description scored 31/34. Rule for next time: uniform ~0 trigger rates mean harness artifact, not description failure; verify with one manual `claude -p` probe before touching the description.

## [gotcha] 2026-07-11 | pit moved incremental history behind a paid plugin

`-DwithHistory` on pitest-maven >= 1.25 fails the build outright ("no history plugin installed"); the free incremental analysis is gone. The open-source speed levers are a narrow `targetClasses` scope plus running the gate only when staged files touch it, which `assets/pre-commit-java` does. Applies to: any doc or hook that suggests PIT incremental runs.

## [gotcha] 2026-07-11 | -SNAPSHOT grep must match version elements only

`check-pom.sh` originally flagged any `-SNAPSHOT` inside dependency/plugin blocks, which false-positived on the enforcer's own `<message>No -SNAPSHOT dependencies</message>` prose in the canonical pom, blocking a fully conforming commit. The gate now matches `<version>[^<]*-SNAPSHOT` only, and scans untracked poms too (`git ls-files --others`), since a brand-new pom is otherwise invisible before its first commit. Rule for next time: a gate that greps for a token must consider the token appearing in prose about the rule itself.

## [decision] 2026-07-11 | decision records are two-tier

Every significant decision gets a one-line `[decision]` entry here; a choice with rejected alternatives and a reversal path worth keeping (vendor, storage engine, deliberate lock-in) additionally gets a full ADR in `docs/adr/NNNN-title.md`, committed with the change. The atelier-grill-me output is the natural ADR draft. Supersedes the earlier stance that the repo keeps no ADR tree. See `skills/atelier/references/governance.md`.

## [decision] 2026-07-11 | production disciplines are the diff-visible rule tier

The eighteen global-rules pillars split two ways: concerns visible in a diff became hard rules 27-34 (PII channels, tenant isolation, deadlines, data lifecycle, optimistic locking, AI ports, rented auth, synthetic fixtures); organizational pillars (observability, delivery, governance, metrics, product) stay reference doctrine that binds when the concern exists. Rationale: a hard rule must be something an agent can refuse-and-rewrite on sight.

## [decision] 2026-07-11 | java variant is quarkus-flavoured only

`references/java-quarkus.md` mirrors the source articles' Quarkus idiom (Panache, JAX-RS, MicroProfile, Flyway) with a one-line note that Spring translates one-to-one. No separate Spring reference until a real repo demands it (YAGNI).

## [decision] 2026-07-11 | pillar 16 lives in its own metrics reference

DORA, flow metrics, and cost-as-a-metric were split out of `delivery.md` into `references/metrics.md` on review, so the measurement doctrine has its own consult moment instead of hiding inside the deploy file.
