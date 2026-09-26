import { describe, expect, test } from 'bun:test';
import { parseSettings } from './settings.ts';

describe('reading the settings payload', () => {
  test('when the payload is an object of strings, its entries are the settings', () => {
    expect(parseSettings('{"theme":"dark","locale":"fr"}')).toEqual({ ok: true, value: { theme: 'dark', locale: 'fr' } });
  });

  test('when the payload is not JSON, it is refused as malformed JSON', () => {
    expect(parseSettings('{theme')).toEqual({ ok: false, error: { kind: 'malformed-json', message: 'settings payload is not valid JSON' } });
  });

  test('when the payload is a list, it is refused as the wrong shape', () => {
    expect(parseSettings('["dark"]')).toEqual({ ok: false, error: { kind: 'malformed-shape', message: 'settings must be an object of string values' } });
  });

  test('when a setting is not a string, it is refused as the wrong shape', () => {
    expect(parseSettings('{"retries":3}')).toEqual({ ok: false, error: { kind: 'malformed-shape', message: 'settings must be an object of string values' } });
  });
});
