# Lessons (committed)

Append-only institutional memory for this codebase. See the atelier skill's `references/lessons.md` for the format and rules.

Each entry is one of `[mistake]`, `[decision]`, or `[gotcha]`. Newest first.

---

## [decision] 2026-09-18 | csv export streams rows instead of building the file in memory

The monthly export reached 180k orders and the process hit 1.4 GB building one string before writing it. The exporter now writes each row through a `WritableStream` as it reads the page from the repository port, and the use-case returns the row count in its `Result`. Memory stays flat at about 60 MB on the same month. Applies to: any export over a few thousand rows.

## [gotcha] 2026-09-16 | bun test --randomize surfaced two tests sharing the orders fixture

Two tests in `src/use-cases/refund-order.test.ts` passed in declaration order and failed under six seeds of eight: the second read a refund the first had written into the shared in-memory fake. Each test now builds its own fake through `makeOrdersFake()`. A red run prints `--seed=<n>`, and `bun test --randomize --seed=<n>` replays it. Rule for next time: a fake shared across tests is shared state.

## [decision] 2026-09-15 | SUPERSEDES 2026-08-02 decision on the webhook queue

Stripe webhooks no longer go through the in-process queue. They land in the `webhook_events` table in the same transaction as the idempotency key, and a worker drains the table every five seconds. The queue lost events on every deploy restart, which the table does not. Supersedes: "stripe webhooks go through an in-process queue" (2026-08-02).

## [gotcha] 2026-09-12 | the stripe CLI signs test events with a different secret than the dashboard

`stripe listen` prints its own `whsec_` signing secret at startup, and events it forwards fail signature verification against the dashboard endpoint's secret. Local runs read `STRIPE_WEBHOOK_SECRET` from the CLI's output, CI uses the dashboard one. We lost an afternoon to "No signatures found matching the expected signature". Affects: every local webhook test.

## [mistake] 2026-09-10 | wrote the currency as a float in the refund total

I summed refunds as `number` dollars and the total drifted by a cent on 3 of 200 orders in the fixture. Money in this repo is `{ cents, currency }` with integer cents, and the conversion to display happens only in the presenter. The user rewrote the reducer over cents. Rule for next time: every amount is integer cents until the presenter formats it.

## [gotcha] 2026-09-09 | eslint --cache keeps a stale result after a config change

After adding the layer zones to `eslint.config.ts`, `bun run lint` still passed on a file that imported infra from the domain, because `.eslintcache` held the old verdict for the unchanged file. Deleting the cache showed the violation. The lint script now passes `--cache-strategy content`, which keys on file content and config. Affects: anyone changing the lint config locally.

## [decision] 2026-09-05 | order ids are branded at the CLI boundary

The CLI accepted any string as an order id and three use-cases re-validated it differently. `parseOrderId(raw)` now returns `Result<OrderId, OrderIdError>` at the argument parser and every use-case takes the branded `OrderId`. The re-validation in the use-cases is gone. Applies to: any new command that takes an order id.

## [gotcha] 2026-09-03 | bun build drops the shebang unless the entry file keeps it on line one

The compiled `orders` binary failed with "exec format error" on the CI runner. `bun build --compile` keeps the shebang only when it is the first line of `src/main.ts`, and a license header had pushed it to line three. The header moved below it. Affects: the release build.

## [gotcha] 2026-08-29 | the orders API paginates with a cursor that expires after ten minutes

A slow export read page 40 of 60 and got 410 Gone: the cursor had expired mid-run. The repository adapter now re-requests from the last seen `updated_at` when it gets a 410, and the export test covers the resume. Affects: any long read through the orders API.

## [decision] 2026-08-27 | the export command lives in this repo, not in the admin monorepo

We debated moving the export into the admin monorepo beside the dashboard. It stays here: different deploy target (a cron runner, not the web app), different secrets, different failure mode. The monorepo calls the published binary. Applies to: any "should this job move into the monorepo" question.

## [gotcha] 2026-08-25 | bun install rewrites bun.lock on drift, CI needs --frozen-lockfile

A CI run silently updated `bun.lock` because plain `bun install` reconciles the lockfile when `package.json` drifted. CI must run `bun install --frozen-lockfile` so drift fails the build instead of mutating the lockfile. Affects: every CI pipeline in this repo.

## [gotcha] 2026-08-25 | ci silently rewrote the lockfile until we added frozen-lockfile

Same root cause as the entry above, found again from the other end: a green CI run had committed a new `bun.lock` through the release job. `bun install --frozen-lockfile` in every job fixes it. Affects: the release job too.

## [decision] 2026-08-20 | the retry policy for the orders API is three attempts with jittered backoff

Every outbound call to the orders API goes through `withRetry(fn, { attempts: 3, baseMs: 200 })` with full jitter and a 5 second deadline per attempt. 4xx responses other than 429 are not retried. The policy lives in `src/infra/orders-api/retry.ts`. Applies to: every adapter method that calls the orders API.

## [gotcha] 2026-08-18 | the csv parser treats a UTF-8 BOM as part of the first header

Imports from the finance team's spreadsheet export failed to find the `order_id` column: the first header was `﻿order_id`. The parser now strips a leading BOM before splitting headers, and the fixture set carries a BOM file. Affects: every CSV import.

## [decision] 2026-08-15 | the discount engine is a dispatch record, not a switch

Five discount kinds had grown into a switch with a default branch that silently returned zero. Each kind is now a function in a `Record<DiscountKind, (order: Order) => Cents>`, so a new kind is a type error until it has a handler. Applies to: any new discount kind.

## [mistake] 2026-08-12 | suggested npm install instead of bun add

On the csv feature I suggested `npm install papaparse`. This repo is Bun-only; the command is `bun add papaparse`. The user corrected it immediately. Rule for next time: read the package manager from the lockfile before suggesting any install command.

## [gotcha] 2026-08-10 | the staging database resets every sunday at 02:00 UTC

A Monday morning test run failed on every fixture id: staging had been reset overnight, as it is every week, and the seeded ids were gone. The e2e suite now seeds its own fixtures at start instead of relying on staging state. Affects: e2e runs on Mondays.

## [decision] 2026-08-06 | the legacy xml export is frozen, no new fields

The XML export for the old accounting tool stays as it is: no new fields, no fixes beyond security. The tool is being replaced by the CSV import in Q4. Applies to: any request to extend the XML export.

## [gotcha] 2026-08-04 | the xml export escapes ampersands twice when a note contains one

Order notes with `&` came out as `&amp;amp;` in the XML export because the note was escaped in the presenter and again by the builder. Removed the presenter escape. Affects: the legacy XML export only.

## [decision] 2026-08-02 | stripe webhooks go through an in-process queue

Webhook handlers enqueue the event in an in-process queue and return 200 at once, and a consumer applies them in order. This keeps the handler under Stripe's 10 second timeout. Applies to: every webhook route.

## [gotcha] 2026-07-30 | tsc --noEmit does not check files outside the include globs

A type error in `scripts/backfill.ts` passed `bun run typecheck` for a week because `tsconfig.json` included only `src/**`. The include now covers `scripts/**` too. Rule for next time: when adding a new top-level folder of TypeScript, add it to the include.

## [mistake] 2026-07-28 | put the refund validation inside the Order record

I added input validation to the `Order` record's transform functions. The user moved it into the `refundOrder` use-case, where orchestration lives. Entities hold invariants, not validation of external input. Rule for next time: validate at the use-case boundary, not inside the domain record.

## [gotcha] 2026-07-25 | the orders api returns amounts as strings

`amount` comes back as `"1999"`, a string of cents, not a number. `parseOrder` converts it with a check that it is an integer string, and a malformed amount is an `OrderParseError`, not a crash. Affects: every read through the orders API.

## [decision] 2026-07-22 | logs go through the Logger port, never console

Every log line goes through the injected `Logger`; the adapter is Winston in production and a capturing fake in tests. `no-console` is on in the lint config, so a stray `console.log` fails `bun run lint`. Applies to: all code under `src/`.

## [gotcha] 2026-07-20 | the orders api rate limit is per key, not per ip

Two cron jobs sharing one API key throttled each other at 100 requests per minute combined. Each job now has its own key from the secrets store. Affects: any new job calling the orders API.
