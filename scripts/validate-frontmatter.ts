#!/usr/bin/env bun
// Validate every skill's YAML frontmatter: each skills/<name>/SKILL.md must open
// with a `---` block that parses as a YAML mapping carrying a non-empty `name` and
// `description`, within the documented Agent Skills limits (name ≤ 64 chars,
// lowercase kebab-case; description ≤ 1024 chars). Catches the colon-space class
// of bug, and the over-limit description that silently breaks skill loading (the
// longest descriptions run close to the limit). A skill's `name` must also match its
// directory, the name the loader and the install CLI know it by.
// Run by the pre-commit hook and in CI: `bun run scripts/validate-frontmatter.ts`;
// `--selftest` proves each check can fail. The scan is anchored to the repo root and
// zero skills found is a failure: from another directory it once printed "valid (0/0)".
import { Glob } from 'bun';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { basename, dirname, join } from 'node:path';

type Problem = { readonly file: string; readonly reason: string };

const REQUIRED_KEYS = ['name', 'description'] as const;

// Documented Agent Skills frontmatter limits (Claude Code skill loader).
const MAX_NAME_LENGTH = 64;
const MAX_DESCRIPTION_LENGTH = 1024;
const NAME_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;

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
    return { file, reason: `invalid YAML: ${e instanceof Error ? e.message.split('\n')[0] : 'parse error'}` };
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    return { file, reason: 'frontmatter is not a YAML mapping' };
  }
  const record = parsed as Record<string, unknown>;
  const missing = REQUIRED_KEYS.find((key) => {
    const value = record[key];
    return typeof value !== 'string' || value.trim().length === 0;
  });
  if (missing !== undefined) return { file, reason: `\`${missing}\` is missing or empty` };
  const name = record['name'] as string;
  const description = record['description'] as string;
  if (name.length > MAX_NAME_LENGTH) return { file, reason: `\`name\` is ${name.length} chars; the limit is ${MAX_NAME_LENGTH}` };
  if (!NAME_PATTERN.test(name)) return { file, reason: '`name` must be lowercase kebab-case (a-z, 0-9, hyphens)' };
  const directory = basename(dirname(file));
  if (name !== directory) return { file, reason: `\`name\` is '${name}' but the skill directory is '${directory}'` };
  if (description.length > MAX_DESCRIPTION_LENGTH) {
    return { file, reason: `\`description\` is ${description.length} chars; the limit is ${MAX_DESCRIPTION_LENGTH}` };
  }
  return null;
};

const validate = async (root: string): Promise<{ readonly problems: Problem[]; readonly count: number }> => {
  const problems: Problem[] = [];
  let count = 0;
  for await (const file of new Glob('skills/*/SKILL.md').scan(root)) {
    count += 1;
    const problem = problemWith(file, await Bun.file(join(root, file)).text());
    if (problem !== null) problems.push(problem);
  }
  return { problems, count };
};

const selftest = async (): Promise<void> => {
  const root = await mkdtemp(join(tmpdir(), 'frontmatter-selftest-'));
  const skill = async (dir: string, body: string): Promise<void> => {
    await mkdir(join(root, 'skills', dir), { recursive: true });
    await writeFile(join(root, 'skills', dir, 'SKILL.md'), body);
  };
  const cases: readonly (readonly [string, string, string])[] = [
    ['colon-space', 'a colon-space in the description', '---\nname: colon-space\ndescription: Use it when: always\n---\n'],
    ['too-long', 'a description over 1024 chars', `---\nname: too-long\ndescription: ${'x'.repeat(1025)}\n---\n`],
    ['Bad_Name', 'a name that is not kebab-case', '---\nname: Bad_Name\ndescription: ok\n---\n'],
    ['no-block', 'no frontmatter block', '# just a heading\n'],
    ['elsewhere', 'a name that differs from its directory', '---\nname: other\ndescription: ok\n---\n'],
  ];
  try {
    for (const [dir, what, body] of cases) {
      await rm(join(root, 'skills'), { recursive: true, force: true });
      await skill('good', '---\nname: good\ndescription: A clean skill.\n---\n');
      await skill(dir, body);
      const { problems } = await validate(root);
      if (problems.length !== 1) throw new Error(`selftest FAIL: ${what} was accepted`);
    }
    await rm(join(root, 'skills'), { recursive: true, force: true });
    await skill('good', '---\nname: good\ndescription: A clean skill.\n---\n');
    if ((await validate(root)).problems.length !== 0) throw new Error('selftest FAIL: a clean skill was rejected');
    await rm(join(root, 'skills'), { recursive: true, force: true });
    if ((await validate(root)).count !== 0) throw new Error('selftest FAIL: an empty tree found skills');
  } finally {
    await rm(root, { recursive: true, force: true });
  }
  process.stdout.write('selftest OK: rejects a colon-space description, an over-long one, a non-kebab name, a missing block and a name that differs from its directory; accepts a clean skill; an empty tree counts zero\n');
};

const main = async (): Promise<void> => {
  if (Bun.argv.includes('--selftest')) return selftest();
  const root = join(import.meta.dir, '..');
  const { problems, count } = await validate(root);
  if (count === 0) {
    process.stderr.write(`✗ no skills/*/SKILL.md under ${root}; nothing was validated\n`);
    process.exit(1);
  }
  if (problems.length > 0) {
    process.stderr.write(`✗ skill frontmatter invalid (${problems.length}/${count}):\n`);
    for (const p of problems) process.stderr.write(`  ${p.file}, ${p.reason}\n`);
    process.exit(1);
  }
  process.stdout.write(`✓ skill frontmatter valid (${count}/${count})\n`);
};

await main();
