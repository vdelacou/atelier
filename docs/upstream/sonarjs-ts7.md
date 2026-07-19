> Status: FILED 2026-07-12 to the Sonar Community forum (https://community.sonarsource.com/, Report a Bug); SonarJS has GitHub issues disabled. This file is the record of the posted text.

# Draft issue: eslint-plugin-sonarjs (SonarSource/SonarJS or eslint-plugin-sonarjs repo)

Title: ESLint crashes at startup under TypeScript 7 (SyntaxKind read at rule-module load)

## Summary
With typescript@7.x installed, loading eslint-plugin-sonarjs crashes ESLint before any
file is linted:

    TypeError: Cannot read properties of undefined (reading 'FunctionType')
        at Object.<anonymous> (node_modules/eslint-plugin-sonarjs/cjs/S2201/rule.js:244:62)

(the property name varies by which rule module loads first; also seen: 'Intrinsic')

## Cause
Rule modules read TypeScript API values at module scope, e.g. cjs/S2201/rule.js:

    const FunctionTypeNodeKind = typescript_1.default.SyntaxKind.FunctionType;

Under TypeScript 7 the module shape changed, so the transpiled CJS default-import interop
(`typescript_1.default`) no longer yields the namespace and `.SyntaxKind` is undefined.
The plugin declares `typescript: '>=5'` in dependencies, which resolves to 7.x on a fresh
install.

## Repro
    bun add -d eslint@10.7.0 eslint-plugin-sonarjs@4.1.0 typescript-eslint typescript@7.0.2
    # eslint.config.js: export default [sonarjsPlugin.configs.recommended, ...tsPlugin.configs.recommended]
    bunx eslint src/   # crashes at load; with typescript@5.9.3 the same setup lints clean

## Suggested fixes
- Constrain the typescript dependency below the breaking major until supported, and/or
- Import the TS namespace with interop-safe access (namespace import or `require('typescript')`
  without the default unwrap) and read SyntaxKind lazily inside rule create().

Environment: eslint 10.7.0, eslint-plugin-sonarjs 4.1.0, typescript 7.0.2, bun 1.x, linux + macOS.
