import type { Result } from './result.ts';
import { err, ok } from './result.ts';

export type ShippingError = { readonly kind: 'negative-weight'; readonly message: string };

export const shippingCents = (weightGrams: number): Result<number, ShippingError> => {
  if (weightGrams < 0) return err({ kind: 'negative-weight', message: 'weight cannot be negative' });
  return ok(weightGrams > 2000 ? 899 : 499);
};
