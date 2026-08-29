import { describe, expect, mock, test } from 'bun:test';
import { awardPoints } from './award-points.ts';

describe('award points', () => {
  test('when two orders total 30 EUR, a gold customer earns 60 points', async () => {
    const listRecent = mock(async () => ({
      ok: true as const,
      value: [
        { id: 'a', totalCents: 1000 },
        { id: 'b', totalCents: 2000 },
      ],
    }));
    const result = await awardPoints({ listRecent, remove: mock(async () => ({ ok: true as const, value: undefined })) }, 'gold');
    expect(result).toEqual({ ok: true, value: 60 });
    expect(listRecent).toHaveBeenCalledTimes(1);
  });
});
