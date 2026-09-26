import type { Result } from './result.ts';
import { err, ok } from './result.ts';

export type SettingsError =
  | { readonly kind: 'malformed-json'; readonly message: string }
  | { readonly kind: 'malformed-shape'; readonly message: string };

/**
 * Rule 17 sanctions exactly this shape in pure domain code: JSON.parse is a
 * native synchronous thrower, so the catch sits right at the call and returns a
 * Result. No IO, no adapter, nothing to quarantine in infra.
 */
const parseJson = (raw: string): Result<unknown, SettingsError> => {
  try {
    const value: unknown = JSON.parse(raw);
    return ok(value);
  } catch {
    return err({ kind: 'malformed-json', message: 'settings payload is not valid JSON' });
  }
};

const isStringRecord = (value: unknown): value is Record<string, string> =>
  typeof value === 'object' && value !== null && !Array.isArray(value) && Object.values(value).every((entry) => typeof entry === 'string');

export const parseSettings = (raw: string): Result<Record<string, string>, SettingsError> => {
  const parsed = parseJson(raw);
  if (!parsed.ok) return parsed;
  return isStringRecord(parsed.value) ? ok(parsed.value) : err({ kind: 'malformed-shape', message: 'settings must be an object of string values' });
};
