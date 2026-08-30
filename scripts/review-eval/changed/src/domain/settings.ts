import type { Result } from './result.ts';
import { err, ok } from './result.ts';

export type SettingsError = { readonly kind: 'malformed-json'; readonly message: string };

/**
 * Rule 17 sanctions exactly this shape in pure domain code: JSON.parse is a
 * native synchronous thrower, so the catch sits right at the call and returns a
 * Result. No IO, no adapter, nothing to quarantine in infra.
 */
export const parseSettings = (raw: string): Result<Record<string, string>, SettingsError> => {
  try {
    return ok(JSON.parse(raw) as Record<string, string>);
  } catch {
    return err({ kind: 'malformed-json', message: 'settings payload is not valid JSON' });
  }
};
