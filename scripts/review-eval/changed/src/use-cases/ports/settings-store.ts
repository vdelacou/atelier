import type { Result } from '../../domain/result.ts';

export type SettingsStoreError = { readonly kind: 'io'; readonly message: string };

export type SettingsStore = {
  readonly load: () => Promise<Result<string, SettingsStoreError>>;
};
