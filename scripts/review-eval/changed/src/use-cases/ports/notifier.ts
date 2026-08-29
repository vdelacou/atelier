import type { Result } from '../../domain/result.ts';

export type NotifyError = { readonly kind: 'io'; readonly message: string };

export type Notifier = {
  readonly pointsAwarded: (orderId: string, points: number) => Promise<Result<void, NotifyError>>;
};
