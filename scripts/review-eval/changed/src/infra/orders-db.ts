import type { Result } from '../domain/result.ts';
import { err, ok } from '../domain/result.ts';
import type { Orders, OrdersError, OrderSummary } from '../use-cases/ports/orders.ts';
import { db, eq, orders } from './db.ts';

export const createOrdersFromDb = (): Orders => ({
  listRecent: async (limit: number): Promise<Result<readonly OrderSummary[], OrdersError>> => {
    try {
      const rows = await db.select().from(orders).where(eq(orders.id, limit));
      return ok(rows.map((r) => ({ id: r.id, totalCents: r.totalCents })));
    } catch (e) {
      return err({ kind: 'io', message: String(e) });
    }
  },
  remove: async (id: string): Promise<Result<void, OrdersError>> => {
    try {
      await db.delete(orders).where(eq(orders.id, id));
      return ok(undefined);
    } catch (e) {
      return err({ kind: 'io', message: String(e) });
    }
  },
});
