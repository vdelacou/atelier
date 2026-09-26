# CLAUDE.md

Orders CLI: reads orders from the orders API, exports CSV, applies Stripe webhooks.

- Before every commit: `bun test --randomize`, `bun run lint`, `bun run typecheck`.
- Deploy: `bun run deploy:legacy` pushes the binary to the old deploy host (`deploy/legacy.sh`).
- Journals: `.claude/LESSONS.md` (append-only memory), `.claude/PLAN.md` (current plan).
