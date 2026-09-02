# Class-to-Module Translation Catalogue

Since `class` and `interface` are banned in this codebase, classical OO patterns must be expressed as typed records and factory functions. Learn these translations once, apply everywhere.

The `references/design-patterns.md` file contains the full GoF catalogue in this style. `references/object-design.md` covers value objects, entities, aggregates, and polymorphism-via-dispatch in depth. This page is the quick lookup table.

> **Note on examples.** Port and use-case signatures in this file are sometimes elided to `Promise<T>` (or throw on business failure) for brevity where error handling is not the lesson. In real code every IO port returns `Promise<Result<T, PortError>>` and every use-case returns `Promise<Result<Summary, StepError>>`: hard rule 16, see `references/result-type.md`.

## Value object

`class Money { ... }` becomes a readonly record plus operation functions:

```ts
// integer minor units, never a float; the full canonical Money (parseMoney, scaleMoney,
// subMoney) lives in references/object-design.md, Value objects
export type Currency = 'EUR' | 'USD';
export type Money = { readonly cents: number; readonly currency: Currency };

export const money = (cents: number, currency: Currency): Money => {
  if (!Number.isSafeInteger(cents)) throw new Error('invalid Money.cents');
  return { cents, currency };
};

export const addMoney = (a: Money, b: Money): Money => {
  if (a.currency !== b.currency) throw new Error('CurrencyMismatch');
  return money(a.cents + b.cents, a.currency);
};

export const moneyEquals = (a: Money, b: Money): boolean => a.cents === b.cents && a.currency === b.currency;
```

The factory function (`money`) is the assertion gate for cents already proven; `parseMoney` (object-design.md) is the boundary tier that turns a decimal string from outside into a `Result`. Downstream code trusts anything with type `Money` without re-checking.

## Interface / contract

`interface UserRepo { ... }` becomes a function-type alias:

```ts
export type UserRepo = {
  save: (user: User) => Promise<void>;
  findById: (id: UserId) => Promise<User | null>;
};
```

## Service with injected dependencies

`class UserService { constructor(repo) { ... } }` becomes a factory that closes over its dependencies:

```ts
export type UserService = { getUser: (id: UserId) => Promise<User | null> };

export const createUserService = (repo: UserRepo): UserService => ({
  getUser: async (id) => repo.findById(id),
});
```

## Strategy

`interface ShippingMethod` plus multiple `class ... implements` becomes a contract plus exported records:

```ts
export type ShippingMethod = { calculateCost: (orderValue: number) => number };

export const standardShipping: ShippingMethod = { calculateCost: (v) => (v < 50 ? 5 : 0) };
export const expressShipping: ShippingMethod = { calculateCost: () => 15 };
export const overnightShipping: ShippingMethod = { calculateCost: () => 25 };
```

New shipping methods arrive as new exported consts, never as edits to existing ones.

## Factory

`class NotificationFactory` becomes a plain function:

```ts
export const createNotification = (kind: NotificationKind): Notification => {
  if (kind === 'email') return emailNotification;
  if (kind === 'sms') return smsNotification;
  return pushNotification;
};
```

## Decorator

`class SMSDecorator implements Notifier` becomes a higher-order function:

```ts
export const withSms = (wrapped: Notifier): Notifier => ({
  send: async (message) => {
    await wrapped.send(message);
    await sendSms(message);
  },
});
```

Compose decorators with function application: `withSlack(withSms(emailNotifier))`.

## Observer

`class EventEmitter` becomes a closure factory:

```ts
export type Emitter<T> = {
  subscribe: (observer: (event: T) => void) => () => void;
  emit: (event: T) => void;
};

export const createEmitter = <T>(): Emitter<T> => {
  let observers: ((event: T) => void)[] = [];
  return {
    subscribe: (observer) => {
      observers.push(observer);
      return (): void => {
        observers = observers.filter((x) => x !== observer);
      };
    },
    emit: (event) => observers.forEach((o) => o(event)),
  };
};
```

## Command

`class AddItemCommand implements Command` becomes a typed record with action functions:

```ts
export type Command = { execute: () => void; undo: () => void };

// addToCart/removeFromCart are immutable (they return new carts), so the
// command closes over a mutable holder; execute/undo swap the current cart.
export const addItemCommand = (cart: Cart, item: Item): Command & { getCart: () => Cart } => {
  let current = cart;
  return {
    execute: () => {
      current = addToCart(current, item);
    },
    undo: () => {
      current = removeFromCart(current, item);
    },
    getCart: () => current,
  };
};
```

## Entity with state transitions

`class Order` becomes an immutable record plus transform functions:

```ts
export type Order = {
  readonly id: OrderId;
  readonly items: readonly OrderItem[];
  readonly status: OrderStatus;
};

export const createOrder = (id: OrderId): Order => ({ id, items: [], status: 'pending' });

export const addItemToOrder = (order: Order, item: OrderItem): Order => ({
  ...order,
  items: [...order.items, item],
});

export const payOrder = (order: Order): Order => ({ ...order, status: 'paid' });
```

Transformations take the record in, return a new record out, and enforce invariants in between. Aggregate roots follow the same pattern: every mutation goes through a root function that returns a new root.

## Quick reference

| OO concept | Class-free expression |
|:---|:---|
| Value object | Readonly record + validating factory |
| Interface / contract | `type Foo = { method: (...) => ... }` |
| Service with deps | Factory function returning the contract |
| Strategy | Contract + exported implementation records |
| Factory | Plain function that returns the right variant |
| Decorator | Higher-order function wrapping the contract |
| Observer | Closure factory over an observer array |
| Command | Record with `execute` / `undo` functions |
| Entity | Immutable record + transform functions |
| Aggregate root | Root function is the only mutation path |
