import type { Result } from '../domain/result.ts';
import { err, ok } from '../domain/result.ts';

export type CrmError = { readonly kind: 'io'; readonly message: string };

export const syncCustomer = async (baseUrl: string, email: string, points: number): Promise<Result<void, CrmError>> => {
  try {
    const response = await fetch(`${baseUrl}/customers?email=${encodeURIComponent(email)}&points=${points}`, {
      method: 'PUT',
    });
    if (!response.ok) return err({ kind: 'io', message: `crm responded ${response.status}` });
    return ok(undefined);
  } catch (e) {
    return err({ kind: 'io', message: String(e) });
  }
};
