# The Global Rules: Profiles

The eighteen pillars and their sub-concepts state the obligation; a profile states the tools and the thresholds one stack uses to meet it. A sub-concept that says "a number exists and the pipeline enforces it" points here for the number. The values below belong to a profile, never to the principle: a team on another stack writes its own section and inherits every rule unchanged, and a team that cannot meet a profile's number on day one is out of profile, not out of the rules.

## atelier (Bun/TypeScript, Next.js, Java/Quarkus)

The profile encoded by the atelier Agent Skill, which is also the executable form of these rules for those three stacks.

| Sub-concept | Obligation (the rule) | This profile's tools and values |
|---|---|---|
| 4.4 Treat mutation testing as the real coverage KPI | core logic gates on a mutation threshold and a line-coverage floor; glue and adapters on an explicit looser floor; a hard gate restructures the code, never lowers the threshold | Stryker (TypeScript) and PIT (Java); core (`domain`, `use-cases`) 100 percent line coverage with the mutation break at 90; glue (`infra`, `composition`, `presenter`; Java `infra`, `api`, `composition`) 80 percent line; mutation runs on the changed files per pull request and push (`mutate:changed`, `pit-changed.sh`), the full sweep on a daily schedule (`mutation.yml`, `mutation-java.yml`), never on a commit |
| 1.2 Cap complexity and duplication | a complexity ceiling exists and the pipeline enforces it | cyclomatic complexity at most 10 per function (atelier hard rule 35): ESLint `complexity: ['error', 10]`, PMD `CyclomaticComplexity` at report level 11 |
| 1.3 One grammar for the history | Conventional Commits, linted in the fast hook and re-checked in CI | a 100-character header; the shipped dependency-free `commit-msg` hook in the fast hook, `check-commit-messages.sh` over the pushed range in CI |
| 5.9 Cap what a caller can spend | a per-caller spend guard before the metered call, refuse rather than bill | 100 requests a minute and 200,000 tokens a day per org as the shipped defaults, metered per tenant |
| 7.6 Make identifiers unguessable, and never the authorization | an identifier scheme nothing can enumerate and the index still likes | UUIDv7 (`uuidv7` in TypeScript, `UuidCreator.getTimeOrderedEpoch()` in Java); v4 where creation time is itself sensitive |
| 10.8 Meet performance targets under load | a p99 budget per hot route, proven by a load test in the pipeline | k6 in CI; p99 under 300 ms, 100 virtual users for two minutes as the starting point |
| 10.13 Every network call has a deadline | a deadline on every outbound call, bounded jittered retries, an idempotency key on a retried POST | `AbortSignal.timeout(2000)` and three attempts with 200 ms jitter in TypeScript; a 1-second connect and 2-second per-attempt timeout with `@Retry(maxRetries = 3, jitter = 200)` in Java |
| 14.3 Treat the platform as a product | real docs, a maintenance owner, a feedback loop, an adoption metric | a first response within four business hours; 90 percent of services on the current major |
| 15.2 Prefer failing loud to passing quietly | an untested file counts at 0 and drags the number down; the floors are the coverage tiers | the 4.4 row's floors (100 core, 80 glue) with the preload counting every file (`check-coverage.ts`, `regenerate-coverage-preload.ts`; JaCoCo counts all classes natively) |
| 16.4 Watch the trend, not the snapshot | alert on a sustained change over a window, never on a snapshot | a 7-day window, change-failure rate above 0.15 held 24 hours |
| 16.5 Treat cost as a first-class metric | spend per service, an alert on unexplained growth | growth above 50 percent week over week on a 7-day window, held 24 hours |
| 17.7 Mobile first, and a light interface | smallest screen first, finger-sized targets, a weight budget the pipeline enforces | 44 px tap targets; `check-bundle-size.sh` with 180 kB gzipped JavaScript and 400 kB total as the budgets |

Rows A and B of the 2026-09-03 revision moved these here; the sub-concepts keep the obligation and tag each example number as a profile value.

## See also

- [The Global Rules Every New Project Should Have](global-rules-every-new-project.md): the eighteen pillars.
- [The Global Rules: Do and Don't, with Examples](global-rules-dos-and-donts.md): the sub-concepts the profile values attach to.
