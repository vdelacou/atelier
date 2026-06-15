#!/usr/bin/env bun
// Validate every skill's YAML frontmatter: each skills/<name>/SKILL.md must open
// with a `---` block that parses as a YAML mapping carrying a non-empty `name` and
// `description`. Catches the colon-space class of bug that silently breaks skill
// loading. Run by the pre-commit hook and on demand: `bun run scripts/validate-frontmatter.ts`.
import { Glob } from 'bun';

type Problem = { readonly file: string; readonly reason: string };

const REQUIRED_KEYS = ['name', 'description'] as const;

const frontmatterOf = (text: string): string | null => {
  if (!text.startsWith('---\n')) return null;
  const end = text.indexOf('\n---', 4);
  return end === -1 ? null : text.slice(4, end);
};

const problemWith = (file: string, text: string): Problem | null => {
  const block = frontmatterOf(text);
  if (block === null) return { file, reason: 'missing or unterminated `---` frontmatter block' };
  let parsed: unknown;
  try {
    parsed = Bun.YAML.parse(block);
  } catch (e) {
    return { file, reason: `invalid YAML — ${e instanceof Error ? e.message.split('\n')[0] : 'parse error'}` };
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    return { file, reason: 'frontmatter is not a YAML mapping' };
  }
  const record = parsed as Record<string, unknown>;
  const missing = REQUIRED_KEYS.find((key) => {
    const value = record[key];
    return typeof value !== 'string' || value.trim().length === 0;
  });
  return missing === undefined ? null : { file, reason: `\`${missing}\` is missing or empty` };
};

const main = async (): Promise<void> => {
  const problems: Problem[] = [];
  let count = 0;
  for await (const file of new Glob('skills/*/SKILL.md').scan('.')) {
    count += 1;
    const problem = problemWith(file, await Bun.file(file).text());
    if (problem !== null) problems.push(problem);
  }
  if (problems.length > 0) {
    process.stderr.write(`✗ skill frontmatter invalid (${problems.length}/${count}):\n`);
    for (const p of problems) process.stderr.write(`  ${p.file} — ${p.reason}\n`);
    process.exit(1);
  }
  process.stdout.write(`✓ skill frontmatter valid (${count}/${count})\n`);
};

await main();
