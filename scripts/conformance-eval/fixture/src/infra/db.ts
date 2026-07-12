// drizzle-style stub for the fixture; the real repo wires a driver here
export type OrderRow = { id: string; totalCents: number; createdAt: Date };
export const orders = { id: 'id', totalCents: 'total_cents', createdAt: 'created_at' } as const;
export const eq = (col: unknown, value: unknown): { col: unknown; value: unknown } => ({ col, value });
export const db = {
  update: (_table: unknown) => ({ set: (_v: unknown) => ({ where: async (_c: unknown) => [] }) }),
  delete: (_table: unknown) => ({ where: async (_c: unknown) => [] }),
  select: () => ({ from: (_t: unknown) => ({ where: async (_c: unknown) => [] as OrderRow[] }) }),
  insert: (_table: unknown) => ({ values: async (_v: unknown) => [] }),
};
