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
5. [ ] Owner, locally: the probe over session logs from an atelier consumer repo, and over the
   latest review-eval and distill-eval runs, both arms. DoD: a per-arm count per candidate, and the
   findings read by hand.
6. [ ] Apply only the clauses whose tags show a skill-arm habit; the mechanics below. DoD: per
   CLAUDE.md (tier 1, the companion sweep, CHANGELOG Unreleased).
7. [ ] Land in slices on the owner's yes; push on its own yes.

## Draft Interaction edit (held until step 5)

One bullet after "Prose:" in `skills/atelier/SKILL.md`, Interaction. Each clause ships only if the
probe shows the skill arm missing it; its tag is in brackets and comes out of the shipped text.

    - Reports and asks: state a result beside the command that proved it, or say it was not run,
      never "should pass" [unverified-claim]; name who acted, "I edited `foo.test.ts`", never "the
      tests were updated" [passive]; an ask (a commit or test proposal, a question) stands apart
      from the report, one action per sentence, numbered when there are several [buried-ask]; one
      name per thing across a reply, and the noun wherever "it" or "this" could point at two [no
      tag, review only]; at most 25 words a sentence and 6 sentences a paragraph [long-sentence,
      long-paragraph].

Companion cascade: the four echoes at line 12 of atelier-distill, atelier-greenfield,
atelier-review-me and atelier-grill-me gain "results with their proof, asks set apart" inside the
parenthesis, after "answer first".

Mechanics when it ships: the insertion shifts every later SKILL.md line and citations-lock.json pins
21 SKILL.md citations, so `check-citations.py --reanchor`, then `--lock` after reading the moved
evidence; the adopted tags move from CANDIDATE to DOCTRINE in check-reply.py, and its selftest's
drift check names the new phrases; `select-tasks.py --since` dry run, tier 1 if it selects a task.

How to read step 5: the eval prompts fix a reply's shape (conformance a file list, review findings
grouped by severity, distill a short summary), so they read reports, not chat; a consumer repo's
session logs (`python3 scripts/check-reply.py ~/.claude/projects/<slug>/`) are the closest reading of
a real session. To credit a clause, run review-eval and distill-eval from a worktree with the draft
applied and probe both sides, three passes per side (LESSONS 2026-09-26: credit by ablation, read
against variance).

## Status

Steps 1-4 done 2026-10-04. The probe: five doctrine tags, six candidates, `--selftest` green on
Python 3.10 to 3.13 and red under ten mutations, one per behaviour (the could-not exemption, the
sidechain skip, the derived .result.txt skip, the cut-list drift, the buried-ask paragraph rule, the
participle stoplist, quote stripping, a quote's closing full stop, emphasis markers, questions as
claims). First reading, this session's own log: 10 bold lead-ins in one answer (real misses), plus
one hedge, one passive and one 27-word sentence (real by the candidates' definitions). Three false
positives found and fixed on the way: a quoted mention read as a claim, a `**` after a full stop
stopped the sentence split, and a question read as a hedge. CI step, CLAUDE.md and CHANGELOG
written; citations (239), drift, frontmatter (5/5) and the em-dash scan of the diff green. Steps 1-4
approved to land 2026-10-04, three slices committed and pushed to main-f7v4vj. Next: step 5, locally.
