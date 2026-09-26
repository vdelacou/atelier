# CLAUDE.md

Orders CLI: reads orders from the orders API, exports CSV, applies Stripe webhooks.

- Before every commit: `bun test --randomize`, `bun run lint`, `bun run typecheck`.
- Money is `{ cents, currency }` in integer cents; only the presenter formats it.
- Logging goes through the injected `Logger`; `no-console` is on in `eslint.config.js`.
- Deploy: `bun run deploy:legacy` pushes the binary to the old deploy host (`deploy/legacy.sh`).
- Journals: `.claude/LESSONS.md` (append-only memory), `.claude/PLAN.md` (current plan).
