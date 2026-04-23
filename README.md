# Atelier

A personal engineering standard for Bun/TypeScript repos, packaged as an [Agent Skill](https://github.com/anthropics/skills) for AI coding agents. Turns generic code generation into senior-engineer output that follows a consistent toolchain, TDD workflow, SOLID design, and class-free functional style.

## Available skills

### atelier

A single, opinionated skill covering the whole coding loop. Applies to every code task in a Bun/TypeScript repo — writing, editing, scaffolding, testing, refactoring, reviewing, debugging.

**Use when:**

- Writing or editing TypeScript for a Bun project
- Scaffolding a new Next.js monorepo or Bun-script repo
- Refactoring existing code to a class-free functional style
- Setting up ESLint, Prettier, TypeScript configuration
- Writing or reviewing tests
- Discussing architecture, design patterns, or code smells
- Capturing cross-session lessons (`.claude/LESSONS.md`)

**Core commitments:**

| Area | Rule |
|------|------|
| Toolchain | Bun only — never `npm`, `pnpm`, `yarn`, `node`, or `vite` directly |
| Language | `const` arrow functions, no `class`, no `function` declaration, no `interface` |
| Typing | Branded types for every domain primitive (IDs, emails, money, dates, URLs) |
| Logging | Winston logger — never `console.*` |
| Tests | Strict TDD, Red-Green-Refactor, tests next to source, `bun test` |
| Architecture | Vertical slices, dependency rule, function-type contracts |
| Design | SOLID expressed through typed records and arrow functions, object calisthenics |
| Complexity | YAGNI, KISS, DRY after Rule of Three, Tell-Don't-Ask, Law of Demeter |
| Memory | Append-only `.claude/LESSONS.md` and `.claude/lessons.local.md` across sessions |

**Reference documentation included:**

- `architecture.md` — vertical slices, dependency rule, hexagonal and clean architecture, walking skeleton
- `bun-typescript.md` — feature-per-folder Bun script repos, ESLint config, logger setup
- `class-to-module.md` — translation table for classical OO patterns (value object, interface, service, strategy, factory, decorator, observer, command, entity)
- `clean-code.md` — naming priorities, object calisthenics in a class-free world, comments, formatting
- `code-smells.md` — detection catalogue and the refactorings that clean each smell
- `complexity.md` — essential vs accidental complexity, YAGNI, DRY + Rule of Three, KISS
- `design-patterns.md` — full GoF catalogue rewritten as modules of arrow functions
- `lessons.md` — session memory format, triggers, extraction heuristics, worked examples
- `nextjs-monorepo.md` — Next.js 16 + Atomic Design + Tailwind v4 + i18n route groups
- `object-design.md` — responsibility-driven design, stereotypes, tell-don't-ask, value objects vs entities, aggregates
- `solid-principles.md` — SRP, OCP, LSP, ISP, DIP expressed as typed records and function contracts
- `tdd.md` — Red-Green-Refactor, Three Laws, triangulation, transformation priority
- `testing.md` — testing pyramid, AAA, test doubles, test builders, contract tests

## Installation

```bash
npx skills add vdelacou/atelier
```

The skill becomes available automatically in Claude Code the next time the agent looks at your repo.

## Usage

Once installed, the agent consults `atelier` on every code task in a Bun/TypeScript project — you do not need to mention it by name. It will:

- Refuse generated code that uses `class`, `function` declarations, `interface`, `console.*`, or `npm`/`pnpm`/`yarn` and rewrite it in the class-free style.
- Write a failing test before production code when implementing a feature.
- Promote raw domain primitives to branded types with validating factories.
- Read `.claude/LESSONS.md` and `.claude/lessons.local.md` at session start and propose new entries at session end.

**Example prompts:**

- "Add a CSV export use case for the orders feature."
- "Refactor `user-service.ts` to follow SOLID principles."
- "Scaffold a new Bun script repo for a Firebase admin job."
- "Review this module for code smells."
- "Wrap the `email`, `userId`, and `money` primitives as branded types."

## Repository layout

```
atelier/
├── LICENSE
├── README.md
└── skills/
    └── atelier/
        ├── SKILL.md           # Main skill instructions
        └── references/        # Supporting documentation
            ├── architecture.md
            ├── bun-typescript.md
            ├── class-to-module.md
            ├── clean-code.md
            ├── code-smells.md
            ├── complexity.md
            ├── design-patterns.md
            ├── lessons.md
            ├── nextjs-monorepo.md
            ├── object-design.md
            ├── solid-principles.md
            ├── tdd.md
            └── testing.md
```

## Variant references

The skill covers two repo shapes and picks the right reference automatically:

- **Next.js monorepo** — Bun workspaces, Atomic Design, Tailwind v4, i18n route groups, static export. Identifiable by `packages/*` and `next.config.ts`.
- **Bun TypeScript script** — feature-per-folder, simpler ESLint, Winston logger. Identifiable by `"module": "src/index.ts"` in `package.json`.

## Credits

Inspired by the layout of [ramziddin/solid-skills](https://github.com/ramziddin/solid-skills). The engineering substance encodes patterns from Clean Code (Robert C. Martin), Test-Driven Development (Kent Beck), Domain-Driven Design (Eric Evans), and Refactoring (Martin Fowler), adapted to a class-free Bun/TypeScript codebase.

## License

[MIT](./LICENSE)
