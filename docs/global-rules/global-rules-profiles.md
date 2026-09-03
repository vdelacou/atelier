# The Global Rules: Profiles

The eighteen pillars and their sub-concepts state the obligation; a profile states the tools and the thresholds one stack uses to meet it. A sub-concept that says "a number exists and the pipeline enforces it" points here for the number. The values below belong to a profile, never to the principle: a team on another stack writes its own section and inherits every rule unchanged, and a team that cannot meet a profile's number on day one is out of profile, not out of the rules.

## atelier (Bun/TypeScript, Next.js, Java/Quarkus)

The profile encoded by the atelier Agent Skill, which is also the executable form of these rules for those three stacks.

| Sub-concept | Obligation (the rule) | This profile's tools and values |
|---|---|---|
| 4.4 Treat mutation testing as the real coverage KPI | core logic gates on a mutation threshold and a line-coverage floor; glue and adapters on an explicit looser floor; a hard gate restructures the code, never lowers the threshold | Stryker (TypeScript) and PIT (Java); core (`domain`, `use-cases`) 100 percent line coverage with the mutation break at 90; glue (`infra`, `composition`, `presenter`; Java `infra`, `api`, `composition`) 80 percent line; mutation runs on the changed files per pull request and push (`mutate:changed`, `pit-changed.sh`), the full sweep on a daily schedule (`mutation.yml`, `mutation-java.yml`), never on a commit |

Row B of the 2026-09-03 revision, once accepted, moves 15.2, 1.3, 10.8, 5.9, 17.7, 7.6, 10.13, 16.4, 16.5 and 14.3 here the same way, together with this profile's cyclomatic-complexity cap (atelier hard rule 35: at most 10 per function).

## See also

- [The Global Rules Every New Project Should Have](global-rules-every-new-project.md): the eighteen pillars.
- [The Global Rules: Do and Don't, with Examples](global-rules-dos-and-donts.md): the sub-concepts the profile values attach to.
