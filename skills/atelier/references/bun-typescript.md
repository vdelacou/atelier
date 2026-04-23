# Bun TypeScript Script Variant

Applies to repos that are plain Bun + TypeScript (no Next.js, no React, no Tailwind). Used for CLIs, integration scripts, Firebase Admin jobs, CSV/PDF processing, batch jobs.

Identifiable by `"module": "src/index.ts"` in `package.json` and a flat `src/<feature>/` layout.

## Runtime

- **Runtime**: Bun (`bun init`, Bun v1.2.2 or newer).
- **Package manager**: Bun. `bun.lock` is committed.
- **Module system**: ESM. `"type": "module"` and `moduleDetection: "force"`.
- **Entry point**: `src/index.ts` (`"module": "src/index.ts"` in package.json).
- **Install**: `bun install`.
- **Run**: `bun run src/index.ts`.
- **TypeScript**: peer dep `^5.0.0`.

Never call `node`, `tsc`, `ts-node`, `vite`, `npm`, `pnpm`, or `yarn`.

## `package.json`

Minimal skeleton:

```json
{
  "name": "<project>",
  "module": "src/index.ts",
  "type": "module",
  "scripts": {
    "lint": "eslint"
  },
  "devDependencies": {
    "@eslint/js": "^9.28.0",
    "@types/bun": "latest",
    "eslint": "^9.28.0",
    "eslint-plugin-prettier": "^5.4.1",
    "eslint-plugin-security": "^3.0.1",
    "eslint-plugin-unicorn": "^59.0.1",
    "typescript-eslint": "^8.33.1"
  },
  "peerDependencies": {
    "typescript": "^5.0.0"
  }
}
```

Common runtime deps in this class of repo (install only what you need):
`@google/genai`, `axios`, `canvas`, `chardet`, `csv-writer`, `firebase-admin`, `iconv-lite`, `jsonwebtoken` (+ `@types/jsonwebtoken`), `papaparse`, `pdf-extract-image`, `pdf-to-png-converter`, `pdfjs-dist`, `winston`, `xlsx`.

## `tsconfig.json`

```jsonc
{
  "compilerOptions": {
    "lib": ["ESNext", "DOM"],
    "target": "ESNext",
    "module": "ESNext",
    "moduleDetection": "force",
    "jsx": "react-jsx",
    "allowJs": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "strict": true,
    "skipLibCheck": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noPropertyAccessFromIndexSignature": false
  }
}
```

Notes:

- `strict: true` covers `noImplicitAny`, `strictNullChecks`, `strictFunctionTypes`, `strictPropertyInitialization`, `alwaysStrict`, `useUnknownInCatchVariables`.
- `verbatimModuleSyntax: true` forces `import type` for type-only imports.
- `allowImportingTsExtensions: true` + `moduleResolution: "bundler"` allow `import ... from './foo.ts'` directly (idiomatic in Bun).
- `noEmit: true`: TypeScript is type-check only; Bun handles execution.

## `eslint.config.js`

Flat config, ESM, filename is `.js` (not `.mjs`) in this variant.

```js
import pluginJs from '@eslint/js';
import prettier from 'eslint-plugin-prettier';
import securityPlugin from 'eslint-plugin-security';
import unicornPlugin from 'eslint-plugin-unicorn';
import globals from 'globals';
import tsPlugin from 'typescript-eslint';

/** @type {import('eslint').Linter.Config[]} */
export default [
  securityPlugin.configs.recommended,
  {
    files: ['**/*.ts'],
  },
  {
    languageOptions: { globals: globals.node },
  },
  {
    rules: {
      'func-style': ['error', 'expression'],
      'no-restricted-syntax': ['off', 'ForOfStatement'],
      'no-console': ['error'],
      'prefer-template': 'error',
      quotes: ['error', 'single', { avoidEscape: true }],
    },
  },
  {
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'error',
      '@typescript-eslint/consistent-type-definitions': ['error', 'type'],
    },
  },
  {
    plugins: { prettier },
    rules: {
      'prettier/prettier': [
        1,
        {
          endOfLine: 'lf',
          printWidth: 180,
          semi: true,
          singleQuote: true,
          tabWidth: 2,
          trailingComma: 'es5',
        },
      ],
    },
  },
  {
    plugins: { unicorn: unicornPlugin },
    rules: {
      'unicorn/empty-brace-spaces': 'off',
      'unicorn/no-null': 'off',
    },
  },
  pluginJs.configs.recommended,
  ...tsPlugin.configs.recommended,
];
```

Key difference from the Next.js variant: **`no-console` is `error`**. Always use the Winston logger.

## `.vscode/settings.json`

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit",
    "source.addMissingImports": "explicit",
    "source.fixAll.eslint": "explicit"
  },
  "search.exclude": { "**/node_modules": true, "**/.vscode": true },
  "search.useGlobalIgnoreFiles": true,
  "search.useParentIgnoreFiles": true,
  "git.autofetch": true,
  "editor.trimAutoWhitespace": true,
  "files.encoding": "utf8",
  "files.trimFinalNewlines": true,
  "files.trimTrailingWhitespace": true,
  "editor.quickSuggestions": { "strings": true },
  "editor.detectIndentation": false,
  "editor.tabSize": 2,
  "eslint.enable": true,
  "eslint.format.enable": true,
  "editor.defaultFormatter": "dbaeumer.vscode-eslint",
  "editor.formatOnType": true,
  "typescript.format.insertSpaceAfterOpeningAndBeforeClosingEmptyBraces": false,
  "[typescript]": { "editor.defaultFormatter": "vscode.typescript-language-features" },
  "[javascript]": { "editor.defaultFormatter": "vscode.typescript-language-features" },
  "[jsonc]": { "editor.defaultFormatter": "vscode.json-language-features" },
  "[json]": { "editor.defaultFormatter": "vscode.json-language-features" }
}
```

## `.vscode/extensions.json`

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "eamodio.gitlens",
    "usernamehw.errorlens",
    "lacroixdavid1.vscode-format-context-menu",
    "kisstkondoros.vscode-codemetrics",
    "snyk-security.snyk-vulnerability-scanner",
    "sonarsource.sonarlint-vscode"
  ]
}
```

## `.gitignore`

Base: GitHub's Node.gitignore, used unmodified. Covers logs, caches, diagnostic reports, coverage, `node_modules`, `.env*`, build output, IDE/OS files, Yarn v2.

If you use Firebase Admin, add `*-service-account*.json` to keep credentials out of git.

## Source architecture: two acceptable shapes

### Layered (use for non-trivial features)

```
src/<feature>/
├── config/
│   └── env.ts          # reads process.env, exports a typed config object
├── services/           # thin API/IO wrappers, one file per external call
│   ├── auth-token.ts
│   ├── find-files.ts
│   └── download-files.ts
├── use-cases/          # orchestration that composes services
│   └── <business-workflow>.ts
├── utils/              # feature-local helpers
└── index.ts            # entry point, calls a use-case
```

### Flat (throwaway scripts)

A single `index.ts` is acceptable. Add `#!/usr/bin/env node` shebang if it's meant to run as a CLI. Typical uses: one-off CLIs, migration scripts, small automation jobs.

## Shared utilities

`src/utils/` is project-wide. Keep only truly shared code there. In practice this holds exactly one thing: the Winston logger.

## What not to create

- No top-level `lib/`, `types/`, or path aliases.
- Types live next to the code that uses them. Prefer `type` over `interface` (enforced).
- No `interface`, no `class`, no `function` declarations, no custom error classes.

## Naming

- Folders and filenames: `kebab-case` (e.g. `find-url-not-secure/`, `auth-token.ts`).
- Functions, variables: `camelCase` (e.g. `getAuthTokens`, `findFilesToScan`).
- Types: `PascalCase` (e.g. `SearchResult`, `TokenResponse`).

## Imports

- ESM only (`import ... from ...`, `export const ...`).
- `.ts` extensions in import specifiers are allowed and idiomatic.
- Bun-specific APIs (`Bun.file()`, `import.meta.dir`) are fine.

## Testing

No tests today. If you add them:

- Filename convention: `*.test.ts` next to the source.
- Runner: `bun test`.

## Secrets & config hygiene

No credentials in source. Load everything via `process.env`, centralised in a `config/env.ts` per feature.

```ts
// src/<feature>/config/env.ts
const required = (name: string): string => {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env var: ${name}`);
  return v;
};

export const env = {
  apiToken: required('MY_API_TOKEN'),
  endpoint: required('MY_API_ENDPOINT'),
};
```

`.env*` is git-ignored. For service-account JSON files: load the path via env var, never commit the JSON. Add `*-service-account*.json` to `.gitignore` if using Firebase Admin.

## Winston logger

Location: `src/utils/logger.ts`.

```ts
import { createLogger, format, transports } from 'winston';

export const logger = createLogger({
  level: 'info',
  format: format.json(),
  transports: [new transports.Console()],
});
```

Import as named export: `import { logger } from '../../utils/logger';`. One logger per app. Never create per-module loggers.

## Error handling pattern

```ts
try {
  await doThing();
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  logger.error('doThing failed', { message });
}
```

- Narrow `unknown` before reading `.message`.
- `process.exit(1)` only at top-level entry points. Never inside a service or use-case.
- No custom error classes.

## Bootstrap checklist (fresh Bun script repo)

1. `mkdir <new-repo> && cd <new-repo> && bun init -y`.
2. Replace `package.json` devDependencies and scripts with the skeleton above.
3. Create `tsconfig.json` with the block above.
4. Create `eslint.config.js` with the block above.
5. Create `.vscode/settings.json` and `.vscode/extensions.json`.
6. Drop in a Node `.gitignore`, plus `*-service-account*.json` if Firebase is in play.
7. `bun install`.
8. `mkdir -p src/utils && ` create `src/utils/logger.ts` with the logger block above.
9. Verify: `bun run lint` exits clean on an empty `src/index.ts`.
10. Commit, push, follow the feature-per-folder convention for all new code.
