import { describe, expect, test } from 'bun:test';
import { shippingCents } from './shipping.ts';

describe('shipping price', () => {
  test('when a parcel weighs 500g, shipping costs 4.99 EUR', () => {
    expect(shippingCents(500)).toEqual({ ok: true, value: 499 });
  });

  test('when a parcel weighs 2.5kg, shipping costs 8.99 EUR', () => {
    expect(shippingCents(2500)).toEqual({ ok: true, value: 499 });
  });

  test('when a parcel has negative weight, the price is refused', () => {
    expect(shippingCents(-1)).toEqual({ ok: false, error: { kind: 'negative-weight', message: 'weight cannot be negative' } });
  });
});
