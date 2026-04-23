# Software Architecture

## The goal

Enable the team to:

1. **Add** features with minimal friction.
2. **Change** existing features safely.
3. **Remove** features cleanly.
4. **Test** features in isolation.
5. **Deploy** independently when possible.

## Architectural principles

### 1. Vertical slices (feature-first)

Organise by feature, not by technical layer.

```
BAD - layer-first
src/
  controllers/
    userController.ts
    orderController.ts
  services/
    userService.ts
    orderService.ts
  repositories/
    userRepository.ts
    orderRepository.ts

GOOD - feature-first
src/
  users/
    user-controller.ts
    user-service.ts
    user-repository.ts
  orders/
    order-controller.ts
    order-service.ts
    order-repository.ts
```

**Why.** Changes to the "users" feature stay in `users/`. High cohesion within features, low coupling between them.

### 2. Horizontal boundaries (layers)

Separate concerns into layers with clear dependencies.

```
+--------------------------------------+
|           Presentation               |  UI, controllers, CLI entry
+--------------------------------------+
|           Application                |  Use cases, orchestration
+--------------------------------------+
|             Domain                   |  Business logic, value objects, entities
+--------------------------------------+
|          Infrastructure              |  Database, APIs, external integrations
+--------------------------------------+
```

### 3. The dependency rule

**Dependencies point INWARD.**

```
Infrastructure -> Application -> Domain
      outer          middle         inner
```

- Inner layers know NOTHING about outer layers.
- Domain has zero dependencies on infrastructure.
- Use function-type contracts to invert dependencies.

```ts
// Domain defines the contract (inner)
export type UserRepo = {
  save: (user: User) => Promise<void>;
  findById: (id: UserId) => Promise<User | null>;
};

// Infrastructure implements it (outer)
export const createPostgresUserRepo = (db: Database): UserRepo => ({
  save: async (user) => {
    /* SQL here */
  },
  findById: async (id) => {
    /* SQL here */
  },
});

// Domain use-case depends on the contract, never on the postgres implementation
export const createGetUser = (repo: UserRepo) => async (id: UserId): Promise<User | null> => repo.findById(id);
```

### 4. Contracts

Function-type aliases define boundaries between components.

```ts
// The contract
export type PaymentGateway = {
  charge: (amount: Money, card: CardDetails) => Promise<ChargeResult>;
  refund: (chargeId: ChargeId) => Promise<RefundResult>;
};

// Multiple implementations possible
export const stripeGateway: PaymentGateway = { /* ... */ };
export const payPalGateway: PaymentGateway = { /* ... */ };
export const mockGateway: PaymentGateway = { /* ... */ }; // for tests
```

### 5. Cross-cutting concerns

Concerns that span multiple features: logging, auth, validation, error handling.

Options in our style:
- Middleware / interceptors.
- Higher-order functions that wrap other functions.
- Decorator functions (from `references/design-patterns.md`).

```ts
// Higher-order function wraps a handler with logging
export type Handler<Req, Res> = (request: Req) => Promise<Res>;

export const withLogging = <Req extends { path: string }, Res extends { status: number }>(
  handler: Handler<Req, Res>
): Handler<Req, Res> =>
  async (request) => {
    logger.info('request', { path: request.path });
    const response = await handler(request);
    logger.info('response', { status: response.status });
    return response;
  };
```

### 6. Conway's Law

> "Organisations design systems that mirror their communication structure."

**Implication.** Team structure affects architecture. Align both intentionally.

---

## Common architectural styles

### Layered architecture

Traditional layers: Presentation -> Business -> Persistence.

**Pros.** Simple, well-understood.
**Cons.** Can become a "big ball of mud" without discipline. No clear story about dependency direction.

### Hexagonal architecture (Ports and Adapters)

Domain at the centre, adapters around the edges.

```
        +---------------------+
        |    HTTP adapter     |
        +----------+----------+
                   |
+------------------v------------------+
|              DOMAIN                  |
|   +--------------------------+      |
|   |     business logic        |      |
|   |     use cases             |      |
|   +--------------------------+      |
+------------------+------------------+
                   |
        +----------v----------+
        |  database adapter   |
        +---------------------+
```

- **Ports** | function-type contracts defined by the domain.
- **Adapters** | concrete implementations that connect to the outside world.

### Clean architecture

Similar to hexagonal, with explicit layers:

1. **Entities** | enterprise business rules.
2. **Use cases** | application business rules.
3. **Interface adapters** | controllers, presenters, gateways.
4. **Frameworks and drivers** | web, DB, external interfaces.

---

## Feature-driven structure (frontend)

Aligns with the Next.js variant:

```
src/
  components/
    atoms/      | (Atomic Design: no internal composition)
    molecules/  | (import atoms only)
    organisms/  | (import atoms + molecules)
  page/         | page shells
  features/
    auth/
      components/
      hooks/
      services/
      types/
      index.ts  | public API
    checkout/
      components/
      hooks/
      services/
      types/
      index.ts
  lib/          | truly shared
    hooks/
    i18n/
    utils/
```

See `references/nextjs-monorepo.md` for the full layout and rules.

---

## Feature-driven structure (backend)

Aligns with the Bun-script variant:

```
src/
  users/
    domain/
      user.ts                 | type + transforms
      user-repo.ts            | function-type contract
    application/
      create-user.ts          | use case
      get-user.ts             | use case
    infrastructure/
      postgres-user-repo.ts
    presentation/
      user-controller.ts
      user-dto.ts
  orders/
    domain/
    application/
    infrastructure/
    presentation/
  shared/
    domain/                   | shared value objects (Money, Email, etc.)
    infrastructure/           | shared infra utilities
```

See `references/bun-typescript.md` for the canonical Bun-script layout.

---

## The walking skeleton

Start with a minimal end-to-end slice:

1. Thinnest possible feature that touches all layers.
2. Deployable from day one.
3. Proves the architecture works.

Example walking skeleton for e-commerce:
- User can view ONE product (hardcoded).
- User can add it to a cart.
- User can "checkout" (just logs the attempt).

From there, flesh out each feature fully with TDD.

---

## Testing architecture

```
+--------------------------------------------+
|       E2E / acceptance tests               |  few, slow, high confidence
+--------------------------------------------+
|       Integration tests                    |  some, medium speed
+--------------------------------------------+
|       Unit tests                           |  many, fast, isolated
+--------------------------------------------+
```

Test by layer:
- **Domain** | unit tests (most tests here).
- **Application** | integration tests with faked infrastructure.
- **Infrastructure** | integration tests with real dependencies.
- **E2E** | critical paths only.

See `references/testing.md` for the full strategy.

---

## Architecture Decision Records (ADRs)

Document significant decisions:

```markdown
# ADR 001 | Use PostgreSQL for persistence

## Status
Accepted

## Context
We need a database. Options: PostgreSQL, MongoDB, MySQL.

## Decision
PostgreSQL, because:
- ACID compliance
- Team familiarity
- JSON support for flexibility

## Consequences
- Need PostgreSQL expertise.
- Schema migrations required.
- Excellent query capabilities.
```

Store ADRs under `docs/adr/` in the repo. One file per decision, numbered.

---

## Red flags in architecture

- Circular dependencies between modules.
- Domain depending on infrastructure.
- Framework code in business logic.
- No clear boundaries between features.
- Shared mutable state across modules.
- "utils" or "common" packages that grow forever.
- Database schema driving the domain model (domain should drive the schema, not the other way).
