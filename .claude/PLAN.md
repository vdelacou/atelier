# Plan: probe the replies before any Interaction edit (2026-10-04)

The previous plan (the shipped .gitattributes) landed in four slices, 82215fa to 48729c2, and 2.6.1
shipped in 47e68a5. This one: the owner asked what atelier's replies can learn from the Simplified
Technical English skill (0xpili/simplified-technical-english, after ASD-STE100 Issue 7). Five lessons
carry over: an ask stands apart from the report; only can, must and will, so never "should pass";
the agent as the subject; one name per item and a noun where a pronoun could point at two; numeric
caps (25 words a sentence, 6 sentences a paragraph). The dictionary, the contraction ban, the kept
articles, the -ing ban and US spelling do not. Probe before doctrine: count first, then edit the
Interaction section only where the skill arm misses. Commits and the push each need the owner's yes.

## Steps and definition of done

1. [x] `scripts/check-reply.py`: doctrine tags (the Interaction section's em dash, cut words, bold
   lead-in, decorative emoji, sentence-case headings) fail the run; candidate tags (unverified-claim,
   hedge, passive, long-sentence, long-paragraph, buried-ask) are counted per arm and never fail it.
   Inputs: text files, stream-json and session-log transcripts, run dirs. DoD: `--selftest` green;
   each tag fires on its own plant and nowhere else; the clean reply passes; code, quotes, thinking,
   tool calls, user turns and subagent text are skipped; the cut list equals SKILL.md's.
2. [x] CI runs the selftest (review-grader-selftest job); CLAUDE.md lists the command; CHANGELOG
   Unreleased, Harness. DoD: the frontmatter, em-dash, citation, drift and YAML checks green.
3. [x] A real reading on this session's own log. DoD: findings read by hand; each false positive
   fixed or named.
4. [x] The draft Interaction edit and its companion cascade, below, not in SKILL.md. DoD: drafted
   and held.
5. [x] The reading, done in the cloud session because the owner could not run locally: 16 of the
   owner's recent cloud coding sessions across 7 consumer repos, the latest 1,000 events of each,
   read from the raw pages the MCP client saved (nothing retyped), 831 replies. DoD: a count per
   tag, the findings read by hand. Result under Status.
6. [x] Decide the follow-up with the owner: the reading shelves the draft and points at the
   enforcement of a rule the section already has. DoD: the choice recorded here. Chosen
   2026-10-04: a reply gate, the next plan.
7. [ ] Land in slices on the owner's yes; push on its own yes.

## Draft Interaction edit (shelved by the step 5 reading)

One bullet after "Prose:" in `skills/atelier/SKILL.md`, Interaction; each clause was to ship only if
the probe showed the skill arm missing it (its tag in brackets). None did; see Status.

    - Reports and asks: state a result beside the command that proved it, or say it was not run,
      never "should pass" [unverified-claim]; name who acted, "I edited `foo.test.ts`", never "the
      tests were updated" [passive]; an ask (a commit or test proposal, a question) stands apart
      from the report, one action per sentence, numbered when there are several [buried-ask]; one
      name per thing across a reply, and the noun wherever "it" or "this" could point at two [no
      tag, review only]; at most 25 words a sentence and 6 sentences a paragraph [long-sentence,
      long-paragraph].

## Status

Steps 1-4 landed 2026-10-04 (9fd53a0, 8a62dc5, cc8efdc on main-f7v4vj). Step 5, 831 replies (632 from
the current model in 13 sessions, 199 from the previous model in 3), 3,941 sentences:

- Doctrine: a bold lead-in in 42 of the current model's 67 replies over 1,000 characters (63%), and in
  none of the previous model's 41. Split by whether a tool call named atelier: 17 of 33 (52%) where it did,
  25 of 34 (74%) where it did not; too few to credit the skill, enough to say the rule does not
  hold. 8 em dashes, all from the previous model, in one session. No cut word, emoji or Title Case heading.
- Candidates, per 100 sentences: unverified-claim 0.1, both hits false (a mutant that "would still
  pass", a post a fan "would pass along"); hedge 2.7, 30 read by hand: 15 conditionals, counterfactuals
  or politeness, 7 honest uncertainty in a diagnosis, 5 unchecked predictions, 3 unclear; passive
  1.9, mostly harmless, a few hide who acted; long-sentence 5.1, one repo at 10.9; buried-ask 0.1,
  all 5 in one repo; long-paragraph 0.0.
- Verdict: no STE clause shows a habit, and a can/must/will rule would push honest uncertainty
  toward false certainty, against "never fabricate". The miss is an existing rule that a doctrine
  line alone does not hold on the current model: per Writing a gate, it needs a gate.
- Probe fixes from the reading, each selftested and red under a mutation: the harness's own notices
  (model `<synthetic>`, an API error or a /context table) are skipped, and a check or cross mark
  (U+2713-2718) passes as a status glyph.
- Limits: atelier's presence is inferred from tool inputs, not proven; 21 assistant events came
  back inline and were skipped rather than retyped; two sessions yielded nothing.

Next: the reply gate, planned when this file is overwritten for it.
