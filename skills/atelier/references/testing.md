# Testing Strategy

## The testing pyramid

```
         /\
        /  \        E2E / Acceptance tests (FEW)
       /----\       full system, slow, brittle
      /      \
     /--------\
    /          \    Integration tests (SOME)
   /            \   multiple components, medium speed
  /--------------\
 /                \  Unit tests (MANY)
/                  \ single function or module, fast, isolated
--------------------
```

## Test types

### Unit tests

Test one function or one module in isolation.

- Fast (milliseconds).
- No external dependencies (use fakes or stubs).
- Most of your tests should be unit tests.

```ts
import { describe, expect, it } from 'bun:test';
import { addItemToOrder, emptyOrder, orderTotal } from './order';
import { money } from '../money/money';
import { orderItem } from './order-item';

describe('order', () => {
  it('when an empty order gets two items at 100 and 50, total is 150', () => {
    const order = addItemToOrder(
      addItemToOrder(emptyOrder(), orderItem({ price: money(100, 'EUR') })),
      orderItem({ price: money(50, 'EUR') })
    );
    expect(orderTotal(order).amount).toBe(150);
  });
});
```

### Integration tests

Test multiple components together.

- Slower (may use real DB, real queue).
- Test boundaries between components.
- Fewer than unit tests.

```ts
describe('orderService integration', () => {
  let db: Database;
  let service: OrderService;

  beforeAll(async () => {
    db = await connectDatabase();
    service = createOrderService(createPostgresOrderRepo(db));
  });

  it('saves and retrieves an order', async () => {
    const order = createOrder(orderId('ord-1'));
    await service.save(order);
    const retrieved = await service.findById(order.id);
    expect(retrieved).toEqual(order);
  });
});
```

### E2E / acceptance tests

Test the entire system from the user's perspective.

- Slowest, most brittle.
- Critical paths only.

```ts
describe('checkout flow', () => {
  it('user can complete purchase', async () => {
    await page.goto('/products');
    await page.click('[data-testid="add-to-cart"]');
    await page.click('[data-testid="checkout"]');
    await page.fill('[name="card"]', '4242424242424242');
    await page.click('[data-testid="pay"]');

    expect(await page.textContent('h1')).toBe('Order Confirmed');
  });
});
```

---

## Arrange-Act-Assert

Structure EVERY test this way:

```ts
it('applies 20% discount to premium users', () => {
  // ARRANGE
  const user = premiumUser(userId('u-1'));
  const cart = addItemToCart(emptyCart(user), item({ price: money(100, 'EUR') }));

  // ACT
  const total = cartTotal(cart);

  // ASSERT
  expect(total.amount).toBe(80);
});
```

### Writing AAA backwards

When stuck:
1. Assert first. What do you want to verify?
2. Act. What action produces that result?
3. Arrange. What setup is needed?

---

## Test naming

### Bad | abstract, technical

```ts
it('should work correctly', () => { /* ... */ });
it('handles the edge case', () => { /* ... */ });
it('sets the data property', () => { /* ... */ });
```

### Good | concrete examples, domain language

```ts
it('calculates 20% discount for premium users', () => { /* ... */ });
it('returns error when cart is empty', () => { /* ... */ });
it('recognises "racecar" as a palindrome', () => { /* ... */ });
```

### Format options

```ts
// option 1 | should + behaviour
it('should apply tax based on shipping state', () => { /* ... */ });

// option 2 | when + then
it('when adding 2 + 3, then returns 5', () => { /* ... */ });

// option 3 | given/when/then (complex scenarios)
describe('given a premium user', () => {
  describe('when they checkout', () => {
    it('then they receive 20% discount', () => { /* ... */ });
  });
});
```

---

## Test doubles

### Dummy

A record passed but never used.

```ts
const dummyLogger = {} as Logger;
const service = createUserService(realRepo, dummyLogger);
```

### Stub

Returns predefined values.

```ts
const stubRepo: UserRepo = {
  findById: async () => buildUser({ name: name('Test'), email: email('t@t.com') }),
  save: async () => {},
};
```

### Spy

Records how it was called.

```ts
type EmailSpy = { sentEmails: Email[]; send: (to: Email, message: string) => Promise<void> };

export const createEmailSpy = (): EmailSpy => {
  const sentEmails: Email[] = [];
  return {
    sentEmails,
    send: async (to) => {
      sentEmails.push(to);
    },
  };
};

// later in test
expect(spy.sentEmails).toContain(email('user@example.com'));
```

### Mock

Verifies expected interactions. Use the test runner's mock utilities.

```ts
import { mock } from 'bun:test';

const mockSave = mock(async (_user: User): Promise<void> => {});
const repo: UserRepo = { save: mockSave, findById: async () => null };

// after act
expect(mockSave).toHaveBeenCalledWith(expectedUser);
```

### Fake

A working in-memory implementation.

```ts
export const createInMemoryUserRepo = (): UserRepo => {
  const store = new Map<UserId, User>();
  return {
    save: async (user) => {
      store.set(user.id, user);
    },
    findById: async (id) => store.get(id) ?? null,
  };
};
```

**Use fakes over mocks when possible.** A fake lets you assert on final state rather than call sequences, which is less brittle.

---

## Testing strategies by layer

### Domain layer (most tests)

Unit tests with no doubles. Test business rules, value objects, entities.

```ts
describe('money', () => {
  it('adds amounts with the same currency', () => {
    const sum = addMoney(money(10, 'EUR'), money(20, 'EUR'));
    expect(moneyEquals(sum, money(30, 'EUR'))).toBe(true);
  });

  it('throws when adding different currencies', () => {
    expect(() => addMoney(money(10, 'EUR'), money(10, 'USD'))).toThrow('CurrencyMismatch');
  });
});
```

### Application layer

Integration tests with faked infrastructure. Test use-case orchestration.

```ts
describe('placeOrder use-case', () => {
  it('saves the order and sends confirmation', async () => {
    const repo = createInMemoryOrderRepo();
    const sender = createEmailSpy();
    const order = buildOrder({ customerId: customerId('c-1') });

    await placeOrder(order, { repo, sender });

    expect(await repo.count()).toBe(1);
    expect(sender.sentEmails.length).toBe(1);
  });
});
```

### Infrastructure layer

Integration tests with real dependencies. Test database and API adapters.

```ts
describe('postgresOrderRepo', () => {
  let repo: OrderRepo;

  beforeAll(async () => {
    repo = createPostgresOrderRepo(testDb);
  });

  it('persists and retrieves an order', async () => {
    const order = buildOrder({});
    await repo.save(order);
    const found = await repo.findById(order.id);
    expect(found).toEqual(order);
  });
});
```

---

## High-value integration tests

Focus integration tests on:

1. Boundaries | where systems meet.
2. Critical paths | money, security, core features.
3. Complex queries | database operations.

### Contract tests

Run the same test suite against every implementation of a contract.

```ts
const testUserRepoContract = (createRepo: () => UserRepo): void => {
  describe('UserRepo contract', () => {
    let repo: UserRepo;
    beforeEach(() => {
      repo = createRepo();
    });

    it('saves and retrieves a user', async () => {
      const user = buildUser({ name: name('Test'), email: email('t@t.com') });
      await repo.save(user);
      const found = await repo.findById(user.id);
      expect(found).toEqual(user);
    });

    it('returns null for a missing user', async () => {
      const found = await repo.findById(userId('nope'));
      expect(found).toBeNull();
    });
  });
};

// apply to all implementations
testUserRepoContract(() => createInMemoryUserRepo());
testUserRepoContract(() => createPostgresUserRepo(testDb));
```

This catches "I implemented the fake differently from the real one" bugs.

---

## Test builders

Create test records easily. A builder is just a factory function with sensible defaults.

```ts
export type OrderConfig = {
  readonly id?: OrderId;
  readonly customerId?: CustomerId;
  readonly items?: readonly Item[];
  readonly status?: OrderStatus;
};

export const buildOrder = (overrides: OrderConfig = {}): Order => ({
  id: overrides.id ?? orderId('ord-1'),
  customerId: overrides.customerId ?? customerId('cust-1'),
  items: overrides.items ?? [],
  status: overrides.status ?? 'pending',
});

// usage
const pending = buildOrder();
const paid = buildOrder({ status: 'paid' });
const withItems = buildOrder({ items: [item({ sku: 'ABC', price: money(100, 'EUR') })] });
```

---

## Common testing mistakes

| Mistake | Problem | Fix |
|:---|:---|:---|
| Testing implementation | Brittle tests | Test observable behaviour only |
| Too many mocks | Tests prove nothing | Prefer fakes over mocks |
| Shared state between tests | Flaky tests | Isolate each test (fresh fakes per test) |
| No assertions | False confidence | Always assert something meaningful |
| Testing trivial code | Wasted effort | Focus on logic, edge cases, boundaries |
| Slow tests | Reduced feedback | Move integration concerns to integration tests |
