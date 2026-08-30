# Plan: harder conformance tasks (2026-08-30)

Problem: with_skill has scored 37/37 in six straight passes, so the eval can only
detect regression. Add tasks with real headroom, then re-validate the instrument.

Design: the prompt ASKS for the violation ("use a mock", "catch it in the use-case",
"log the email", "the client passes the org id"). A conforming answer has to refuse the
instruction and do the right thing, which is a harder test than a neutral prompt.

1. [ ] Add h1-h4 to tasks.json: trap-mock (4.5), trap-catch (10.2 placement, 3.2),
   trap-log-delete (6.3, 10.9), trap-tenant (7.1, 7.5).
2. [ ] Validate both arms on h1-h4 only. Fair means: baseline can fail it, with_skill
   CAN fail it too (headroom), and no assertion is impossible or rewards the weaker arm
   (the 2026-08-30 correction of e10/a3 is the precedent).
3. [ ] Fix any assertion that measures the wrong thing, re-run the affected task.
4. [ ] baseline.md: document the new tier and its first reading. Land on confirmation.
