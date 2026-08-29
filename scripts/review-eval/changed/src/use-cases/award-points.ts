import type { Result } from '../domain/result.ts';
import { err, ok } from '../domain/result.ts';
import { LoyaltyCalculator } from '../domain/loyalty.ts';
import type { Orders } from './ports/orders.ts';

export type AwardError = { readonly kind: 'io'; readonly message: string };

export const awardPoints = async (orders: Orders, tierName: string): Promise<Result<number, AwardError>> => {
  try {
    const recent = await orders.listRecent(10);
    if (!recent.ok) return err({ kind: 'io', message: recent.error.message });
    const calculator = new LoyaltyCalculator();
    const total = recent.value.reduce((sum, o) => sum + calculator.points(o.totalCents, tierName), 0);
    console.log('awarded points', total);
    return ok(total);
  } catch (e) {
    return err({ kind: 'io', message: String(e) });
  }
};
