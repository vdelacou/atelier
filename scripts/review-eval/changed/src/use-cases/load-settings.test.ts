import { describe, expect, test } from 'bun:test';
import { createLoadSettings } from './load-settings.ts';
import type { SettingsStore } from './ports/settings-store.ts';

const storeHolding = (payload: string): SettingsStore => ({ load: async () => ({ ok: true, value: payload }) });

describe('loading the settings', () => {
  test('when the store holds an object of strings, its entries are the settings', async () => {
    expect(await createLoadSettings(storeHolding('{"theme":"dark"}'))()).toEqual({ ok: true, value: { theme: 'dark' } });
  });

  test('when the store cannot be read, the step reports the store failure', async () => {
    const unreadable: SettingsStore = { load: async () => ({ ok: false, error: { kind: 'io', message: 'disk unavailable' } }) };
    expect(await createLoadSettings(unreadable)()).toEqual({ ok: false, error: { step: 'loadSettings', cause: 'io', message: 'disk unavailable' } });
  });

  test('when the stored payload is not JSON, the step reports it as malformed', async () => {
    expect(await createLoadSettings(storeHolding('{theme'))()).toEqual({
      ok: false,
      error: { step: 'loadSettings', cause: 'malformed-json', message: 'settings payload is not valid JSON' },
    });
  });
});
