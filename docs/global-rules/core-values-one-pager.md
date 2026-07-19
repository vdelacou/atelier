# Core Values behind the Global Rules

The through-line: decide how you build before what you build with, protect the people you build for, and make quality something the system enforces rather than something you hope for.

## The five core values

**1. Rigor enforced by tooling, not willpower.**
The loudest, most repeated theme. "Production-ready" means the pipeline blocks bad code automatically: linters, formatters, strict type checks, pre-commit hooks, and scanners. Commit the lockfile, pin tool versions, fail fast. I don't trust discipline; I trust the gate.

**2. Protect the system and the user by default.**
Security and privacy are reflexes, not phases. No hardcoded secrets, dependency and secret scanning, env-var discipline, and protection extended to people's data and access: data minimization and consent.

**3. Efficient, correct, and resilient at scale.**
I reach for the solution that stays fast as data grows, not the easy one: keyset over OFFSET pagination, native bulk streaming, lean functions with no bloat, deploys close to the user, autoscaling. And the system stays up on purpose: reliability is a number, failure is planned for, recovery is rehearsed. Minimalism is a value, not an accident.

**4. Transparency and measurability.**
Real-time access to everything, and commitments in numbers, not adjectives. "Fast" and "secure" mean nothing until they are thresholds anyone can check.

**5. User experience is the entire product.**
UX is broad: onboarding, billing, trust, and customer service, not just the interface. Trust beats short-term sales, risk reduction earns loyalty, and technology should augment the human touch rather than replace it.

## Supporting values

Pragmatism and speed to ship (managed, low-fixed-cost building blocks, small scripts that get things working). Reproducibility through a portable, reused toolchain. A human-centric skepticism of hype.

## The one-line version

I build for people, protect their data by default, and make quality something the system enforces, not something the team remembers to do.

## Values to pillars

Each value is served by a subset of the [eighteen pillars](global-rules-every-new-project.md); the rest are structural enablers that serve them all.

| Value | Pillars |
|---|---|
| 1. Rigor enforced by tooling, not willpower | 1 Consistency, 4 Proof over hope, 8 Delivery should be boring, 15 Enforce and verify |
| 2. Protect the system and the user by default | 5 Secure by default, 6 Private by default, 7 Isolate by default |
| 3. Efficient, correct, and resilient at scale | 2 Simplicity by default, 9 Run as little as possible yourself, 10 Design for failure |
| 4. Transparency and measurability | 11 Make it observable, 12 No black boxes, 16 Measure whether you are improving |
| 5. User experience is the entire product | 17 Obsess over the whole experience, 18 Validate before you build |

Pillars 3 (keep clean boundaries), 13 (clear ownership), and 14 (pave the road) are structural enablers: boundaries, ownership, and paved roads that make every value above cheaper to hold, rather than serving any single one.

---
## See also

- [The Global Rules Every New Project Should Have](global-rules-every-new-project.md): the eighteen pillars that put these values to work.
- [The Global Rules: Do and Don't, with Examples](global-rules-dos-and-donts.md): a Do/Don't with code for every sub-concept.
