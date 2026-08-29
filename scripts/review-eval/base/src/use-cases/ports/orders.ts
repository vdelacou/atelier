import type { Result } from '../../domain/result.ts';

export type OrderSummary = { readonly id: string; readonly totalCents: number };
export type OrdersError = { readonly kind: 'io'; readonly message: string };

export type Orders = {
  readonly listRecent: (limit: number) => Promise<Result<readonly OrderSummary[], OrdersError>>;
  readonly remove: (id: string) => Promise<Result<void, OrdersError>>;
};
