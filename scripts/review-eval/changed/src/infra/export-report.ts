import { writeFileSync } from 'node:fs';
import type { Result } from '../domain/result.ts';
import { ok } from '../domain/result.ts';

export const exportReport = (path: string, lines: readonly string[]): Result<void, never> => {
  writeFileSync(path, lines.join('\n'), 'utf8');
  return ok(undefined);
};
