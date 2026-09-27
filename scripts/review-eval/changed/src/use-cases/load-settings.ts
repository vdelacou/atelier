import type { Result } from '../domain/result.ts';
import { err } from '../domain/result.ts';
import { parseSettings } from '../domain/settings.ts';
import type { SettingsStore } from './ports/settings-store.ts';
import type { StepError } from './ports/step-error.ts';

export type LoadSettings = () => Promise<Result<Record<string, string>, StepError>>;

export const createLoadSettings =
  (store: SettingsStore): LoadSettings =>
  async () => {
    const raw = await store.load();
    if (!raw.ok) return err({ step: 'loadSettings', cause: raw.error.kind, message: raw.error.message });
    const settings = parseSettings(raw.value);
    if (!settings.ok) return err({ step: 'loadSettings', cause: settings.error.kind, message: settings.error.message });
    return settings;
  };
