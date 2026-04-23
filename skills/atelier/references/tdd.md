# Test-Driven Development

## The core loop

```
RED -> GREEN -> REFACTOR -> RED -> ...
```

### RED phase

Write a failing test that describes the behaviour you want. The test should:

- Use domain language, not technical jargon.
- Describe WHAT, not HOW.
- Be a concrete example, not an abstract statement.

```ts
// BAD - abstract
it('can add numbers', () => { /* ... */ });

// GOOD - concrete example
it('when adding 2 + 3, returns 5', () => { /* ... */ });
```

### GREEN phase

Write the simplest possible code to make the test pass. Two strategies:

**Fake It** - return a hardcoded value.
```ts
export const add = (a: number, b: number): number => 5;
```

**Obvious Implementation** - if you know the solution.
```ts
export const add = (a: number, b: number): number => a + b;
```

Prefer Fake It when learning or unsure. Let more tests drive the real implementation.

### REFACTOR phase

This is where design happens. Look for:

- Duplication (wait for Rule of Three).
- Functions longer than 10 lines to extract.
- Poor names to improve.
- Complex conditions to simplify.
- Raw primitives in domain positions to promote to branded types.

## The Three Laws of TDD

1. No production code unless it makes a failing test pass.
2. No more test code than sufficient to fail (compilation failures count).
3. No more production code than sufficient to pass the one failing test.

## The Rule of Three

Only extract duplication when you see it THREE times.

Why? A wrong abstraction is more expensive to undo than duplication is to tolerate.

```
Duplication #1 - leave it.
Duplication #2 - note it, leave it.
Duplication #3 - NOW extract it.
```

## Triangulation

Each new test sculpts the solution toward a general implementation.

Think of degrees of freedom: a car needs forward/back, left/right, rotation. Each test carves out one degree of freedom until the implementation handles all cases.

Example. You implement `isPalindrome`:

1. Test `'mom'` -> fake it: `return true`.
2. Test `'hello'` -> now the fake fails. Generalise: compare halves.
3. Test `''` -> edge case forces explicit handling.
4. Test `'racecar'` -> confirms the general case.

## Transformation Priority Premise

When going from RED to GREEN, prefer simpler transformations:

| Priority | Transformation |
|:---|:---|
| 1 | `{}` to `null` |
| 2 | `null` to constant |
| 3 | constant to variable |
| 4 | unconditional to conditional |
| 5 | scalar to collection |
| 6 | statement to recursion |
| 7 | value to mutated value |

Higher priority = simpler. Do not jump to complex transformations too early.

## Arrange-Act-Assert

Every test follows the same shape:

```ts
it('calculates total with discount', () => {
  // ARRANGE - set up the world
  const cart = addItem(emptyCart(), item({ price: money(100, 'EUR') }));
  const discount = percentDiscount(10);

  // ACT - execute the behaviour
  const total = calculateCartTotal(cart, discount);

  // ASSERT - verify the outcome
  expect(moneyEquals(total, money(90, 'EUR'))).toBe(true);
});
```

## Writing tests backwards

When stuck, flip the order:

1. Write the ASSERT first. What do you want to verify?
2. Write the ACT. What action produces that result?
3. Write the ARRANGE. What setup is needed?

## Test naming principles

- Use behaviour-driven names with domain language.
- Provide concrete examples, not abstract statements.
- One example per test for easy debugging.
- Do not leak implementation details.

```ts
// BAD - technical, implementation-focused
it('should set the data property to 1', () => { /* ... */ });

// GOOD - behaviour-focused, domain language
it('should recognise "mom" as a palindrome', () => { /* ... */ });
```

## Classic vs Mockist TDD

**Classic (Detroit/Chicago) TDD.**
- Test with real collaborators.
- Higher confidence, slower tests.
- Best for pure functions, value objects, integration tests.

**Mockist (London) TDD.**
- Replace collaborators with test doubles.
- Faster tests, more isolated.
- Best for modules with infrastructure dependencies.

Start Classic when learning. Add doubles (stubs, fakes, spies) when testing modules that depend on databases, APIs, clocks.

## TDD for a pure arrow-function module

Example. Build a `calculateDiscount` function.

**Test file** `src/pricing/calculate-discount.test.ts`:

```ts
import { describe, expect, it } from 'bun:test';
import { calculateDiscount } from './calculate-discount';
import { money } from '../money/money';

describe('calculateDiscount', () => {
  it('when standard customer buys 100 EUR, returns 0', () => {
    const subtotal = money(100, 'EUR');
    const result = calculateDiscount(subtotal, 'standard');
    expect(result.amount).toBe(0);
  });

  it('when premium customer buys 100 EUR, returns 20', () => {
    const subtotal = money(100, 'EUR');
    const result = calculateDiscount(subtotal, 'premium');
    expect(result.amount).toBe(20);
  });
});
```

**RED.** Test 1 fails (no `calculate-discount.ts` yet).

**GREEN.** Fake it:

```ts
import type { Money } from '../money/money';
import { money } from '../money/money';

type CustomerTier = 'standard' | 'premium';

export const calculateDiscount = (subtotal: Money, tier: CustomerTier): Money => money(0, subtotal.currency);
```

Test 1 passes. Test 2 fails. Generalise:

```ts
export const calculateDiscount = (subtotal: Money, tier: CustomerTier): Money => {
  if (tier === 'premium') return money(subtotal.amount * 0.2, subtotal.currency);
  return money(0, subtotal.currency);
};
```

**REFACTOR.** At this point: no duplication to extract, names are clear, function is 4 lines. Nothing to clean. Move on to the next test. When a third tier appears (`vip`), resist extracting until after the third `if` branch exists (Rule of Three). Then promote the logic to a dispatch record:

```ts
const tierRates: Record<CustomerTier, number> = {
  standard: 0,
  premium: 0.2,
  vip: 0.3,
};

export const calculateDiscount = (subtotal: Money, tier: CustomerTier): Money =>
  money(subtotal.amount * tierRates[tier], subtotal.currency);
```

This is what "design happens during refactor" looks like.

## Common mistakes

1. Writing code before tests. Violates the fundamental principle.
2. Writing too much test. Just enough to fail.
3. Writing too much code. Just enough to pass.
4. Skipping refactor. Design lives here.
5. Testing implementation. Test behaviour, not how it is done.
6. Abstract test names. Use concrete examples.
7. Extracting too early. Wait for Rule of Three.
8. Reaching for doubles too soon. Start with real collaborators.
9. Asserting on multiple unrelated behaviours in one test. One behaviour per test.
