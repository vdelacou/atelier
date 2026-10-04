#!/usr/bin/env python3
"""Reply probe: does an agent's reply to a person read the way the Interaction section asks?

skills/atelier/SKILL.md, Interaction, says how a reply reads. Five of its rules are mechanical
enough to match, and they are the doctrine tags; any one of them exits 1:

  em-dash         U+2014 in the reply's own prose
  cut-word        the section's cut list: delve, leverage, robust, seamless, nuanced, "it's worth noting"
  bold-lead-in    a list item that opens on a bold phrase and carries on past it
  emoji           a pictograph or dingbat (U+1F000-1FAFF, U+2600-27BF)
  heading-case    a Title Case heading: two or more capitalised content words, none lowercase

The candidate tags come from Simplified Technical English (ASD-STE100 Issue 7, read through the
0xpili/simplified-technical-english skill on 2026-10-04). They are not doctrine: the probe counts
them so an Interaction edit lands only where the skill arm misses, and they never fail a run.

  unverified-claim  a result stated as a hedge: "should pass", "probably fixed", "might be green"
  hedge             any other should, would, might, may, could, probably, likely, possibly,
                    perhaps, presumably, hopefully, seem(s), appear(s) to; STE keeps only can,
                    must and will ("could not" is a past fact, and a question asks rather than
                    claims: both pass)
  passive           an event passive: was, were, been or being plus a participle ("the tests
                    were updated"); "is disconnected" names a state and passes, as in STE
  long-sentence     over 25 words, STE's cap for descriptive text; a parenthesis counts as one word
  long-paragraph    over 6 sentences
  buried-ask        a question in a prose paragraph that also carries two or more report sentences

Inputs, any mix; no argument reads one reply from stdin:
  - a text or Markdown file is one reply (review-eval's .review.txt, a pasted answer)
  - a .jsonl transcript: each assistant text block is one reply, from the claude -p stream-json the
    conformance and distill evals keep or a Claude Code session log under ~/.claude/projects/;
    thinking, tool calls, user turns and subagent messages are not replies and are skipped
  - a directory is walked for both; a .result.txt beside a .transcript.jsonl is skipped (it is
    derived from it), and so are the skills/, subagents/, node_modules/ and .git/ subtrees

Code, block quotes, URLs and double-quoted text (a mention, not a use) are never read, emphasis
markers are dropped, and a table row gets the doctrine character checks only.
The conformance prompt asks for a bare file list as the final reply, so its transcripts carry
prose only in the narration between tool calls: review-eval's reviews, distill-eval's summaries
and real session logs are the inputs that say most. Counts roll up per arm, read from a run dir's
with_skill or baseline suffix ("-" elsewhere). Each tag is a pattern, not a parser: read the
findings before the counts (.claude/LESSONS.md, 2026-09-26).

    python3 scripts/check-reply.py <file-or-dir>...    # findings, then the counts per arm
    python3 scripts/check-reply.py --selftest          # each tag fires on its plant and nowhere else
"""

from __future__ import annotations  # `X | None` hints under the Python 3.9 macOS ships

import contextlib
import io
import json
import os
import re
import shutil
import sys
import tempfile
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SKILL = REPO / "skills/atelier/SKILL.md"

DOCTRINE = ("em-dash", "cut-word", "bold-lead-in", "emoji", "heading-case")
CANDIDATE = ("unverified-claim", "hedge", "passive", "long-sentence", "long-paragraph", "buried-ask")
CUT_WORDS = ("delve", "leverage", "robust", "seamless", "nuanced", "it's worth noting")
MAX_WORDS = 25
MAX_SENTENCES = 6

EM_DASH = "\u2014"
CUT_WORD = re.compile(r"\b(?:delv\w*|leverag\w*|robust\w*|seamless\w*|nuanced|it['\u2019]s worth noting)\b", re.IGNORECASE)
EMOJI = re.compile("[\U0001F000-\U0001FAFF\u2600-\u27BF]")
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")
BOLD_LEAD_IN = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+(?:\*\*[^*\n]+\*\*|__[^_\n]+__)[:.]?\s*\S")
HEADING = re.compile(r"^\s{0,3}#{1,6}\s+(.*?)[\s#]*$")
RULE_LINE = re.compile(r"^\s{0,3}([-*_])(?:\s*\1){2,}\s*$")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")
SMALL_WORDS = {"a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into", "is", "it",
               "nor", "of", "on", "or", "per", "the", "to", "via", "vs", "with"}

UNVERIFIED = re.compile(
    r"\b(?:should|would|might|may|could|probably|likely|presumably|hopefully)\s+"
    r"(?:(?:now|also|still|all|then|already|just)\s+)?"
    r"(?:pass(?:es)?|works?|build|compile|succeed|resolve|fix|"
    r"(?:be\s+)?(?:green|fine|ok|okay|correct|good|clean|fixed|resolved|working|stable|done))\b",
    re.IGNORECASE,
)
HEDGE = re.compile(
    r"\b(?:(?:should|would)(?:n['\u2019]t)?|might|may(?!\s+\d)|could(?!\s+not\b)|probably|likely|"
    r"possibly|perhaps|presumably|hopefully|seems?|appears?\s+to)\b",
    re.IGNORECASE,
)
PARTICIPLE = (r"\w{2,}ed|done|made|written|run|built|set|put|kept|held|taken|given|found|left|lost|"
              r"sent|shown|told|broken|chosen|known|seen|thrown|begun|drawn|driven|hidden|read|cut|"
              r"split|bound|caught|gotten|laid|led|meant|met|paid|said|sold|taught|thought|"
              r"understood|won|rewritten|overwritten|rebuilt|rerun|reset")
PASSIVE = re.compile(rf"\b(?:was|were|been|being)\s+(?:\w+ly\s+)?({PARTICIPLE})\b", re.IGNORECASE)
NOT_PARTICIPLE = {"embed", "feed", "hundred", "indeed", "naked", "need", "sacred", "seed", "shed", "speed", "wicked"}

SENTENCE_END = re.compile(r"(?<=[.!?])\s+(?=[\"'(\[*_]?[A-Z0-9])")
WORD = re.compile(r"[A-Za-z0-9](?:[A-Za-z0-9'\u2019./_-]*[A-Za-z0-9])?")
ARM = re.compile(r"(?:^|-)(with_skill|baseline)(?:-\d+)?$")
SKIP_DIRS = {".git", "node_modules", "skills", "subagents"}


def clean(line: str) -> str:
    """A line's own prose: inline code, a bare URL and a quotation become one word each (the
    quotation keeps a closing full stop, so a sentence still ends there), a link becomes its
    text, and emphasis markers go, so "**Done.** Next" still splits."""
    line = re.sub(r"`[^`\n]+`", "CODE", line)
    line = re.sub(r"\[([^\]\n]*)\]\([^)\n]*\)", r"\1", line)
    line = re.sub(r"https?://\S+", "URL", line)
    line = re.sub(r'"[^"\n]*?([.!?]?)"', r"QUOTED\1", line)
    return line.replace("**", "").replace("__", "")


def parse(reply: str) -> tuple[list[str], list[tuple[str, str, str]]]:
    """The lines the character checks read, and the (kind, text, first raw line) blocks the
    sentence checks read, kind being heading, item or para. Fenced code and block quotes are in
    neither; a table row or a horizontal rule is a line, never a block."""
    lines: list[str] = []
    blocks: list[tuple[str, str, str]] = []
    kind, buf, first, fence = "", [], "", ""

    def close() -> None:
        nonlocal kind, buf, first
        if buf:
            blocks.append((kind, " ".join(buf), first))
        kind, buf, first = "", [], ""

    for raw in reply.splitlines():
        if fence:
            fence = "" if raw.strip().startswith(fence) else fence
            continue
        opened = FENCE.match(raw)
        if opened:
            close()
            fence = opened.group(1)[:3]
            continue
        if raw.lstrip().startswith(">"):
            close()
            continue
        line = clean(raw)
        lines.append(line)
        heading = HEADING.match(raw)
        if not raw.strip() or heading or raw.lstrip().startswith("|") or RULE_LINE.match(raw):
            close()
            if heading:
                blocks.append(("heading", clean(heading.group(1)), raw))
            continue
        if LIST_ITEM.match(raw):
            close()
            kind, first, buf = "item", raw, [LIST_ITEM.sub("", line, count=1)]
            continue
        if not buf:
            kind, first = "para", raw
        buf.append(line.strip())
    close()
    return lines, blocks


def title_case(heading: str) -> bool:
    words = re.findall(r"[A-Za-z][A-Za-z'\u2019.-]*", heading.replace("*", " ").replace("_", " "))[1:]
    content = [w for w in words if w.lower() not in SMALL_WORDS and not w.isupper()]
    return len(content) >= 2 and all(w[0].isupper() for w in content)


def word_count(sentence: str) -> int:
    """Words as STE counts them: a parenthesis is one word, and so is a path or a number."""
    while True:
        folded = re.sub(r"\([^()]*\)", " PAREN ", sentence)
        if folded == sentence:
            return len(WORD.findall(folded))
        sentence = folded


def passive(sentence: str) -> bool:
    return any(m.group(1).lower() not in NOT_PARTICIPLE for m in PASSIVE.finditer(sentence))


def check(reply: str) -> tuple[list[tuple[str, str]], int, int]:
    """The (tag, evidence) findings of one reply, with its sentence and word counts."""
    lines, blocks = parse(reply)
    found: list[tuple[str, str]] = []
    for line in lines:
        if EM_DASH in line:
            found.append(("em-dash", line))
        cut = CUT_WORD.search(line)
        if cut:
            found.append(("cut-word", f"{cut.group(0)}: {line}"))
        if EMOJI.search(line):
            found.append(("emoji", line))
    n_sentences = n_words = 0
    for kind, text, first in blocks:
        if kind == "heading":
            if title_case(text):
                found.append(("heading-case", text))
            continue
        if kind == "item" and BOLD_LEAD_IN.match(first):
            found.append(("bold-lead-in", first))
        said = [s for s in SENTENCE_END.split(text) if WORD.search(s)]
        n_sentences += len(said)
        if len(said) > MAX_SENTENCES:
            found.append(("long-paragraph", f"{len(said)} sentences: {text}"))
        asks = [s for s in said if s.rstrip("*_)\"' ").endswith("?")]
        if kind == "para" and asks and len(said) - len(asks) >= 2:
            found.append(("buried-ask", asks[0]))
        for sentence in said:
            n = word_count(sentence)
            n_words += n
            if n > MAX_WORDS:
                found.append(("long-sentence", f"{n} words: {sentence}"))
            claim = sentence not in asks  # a question asks, it does not claim
            if claim and UNVERIFIED.search(sentence):
                found.append(("unverified-claim", sentence))
            elif claim and HEDGE.search(sentence):
                found.append(("hedge", sentence))
            if passive(sentence):
                found.append(("passive", sentence))
    return found, n_sentences, n_words


def arm_of(path: Path) -> str:
    for part in reversed(path.parent.parts):
        named = ARM.search(part)
        if named:
            return named.group(1)
    return "-"


def transcript_replies(path: Path) -> list[str]:
    """Each assistant text block of a stream-json transcript or a session log, in order."""
    replies: list[str] = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict) or event.get("type") != "assistant":
            continue
        if event.get("isSidechain") or event.get("parent_tool_use_id"):
            continue  # a subagent talking to its parent, not a reply to the person
        message = event.get("message")
        content = message.get("content") if isinstance(message, dict) else None
        for block in content if isinstance(content, list) else []:
            if isinstance(block, dict) and block.get("type") == "text" and str(block.get("text", "")).strip():
                replies.append(block["text"])
    return replies


def files_in(root: Path) -> list[Path]:
    """The reply files under a directory: transcripts, reviews, and a .result.txt with no transcript."""
    found: list[Path] = []
    for here, dirs, names in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        for name in sorted(names):
            if name.endswith(".jsonl") or name == ".review.txt" or (name == ".result.txt" and ".transcript.jsonl" not in names):
                found.append(Path(here) / name)
    return found


def collect(args: list[str]) -> list[tuple[str, str, str]]:
    """(arm, label, reply) for every reply the arguments name."""
    replies: list[tuple[str, str, str]] = []
    for arg in args:
        root = Path(arg)
        if not root.exists():
            print(f"check-reply.py: no such file or directory: {arg}", file=sys.stderr)
            sys.exit(2)
        for path in files_in(root) if root.is_dir() else [root]:
            if path.suffix == ".jsonl":
                replies += [(arm_of(path), f"{path}#{i}", text) for i, text in enumerate(transcript_replies(path), 1)]
            else:
                replies.append((arm_of(path), str(path), path.read_text(encoding="utf-8", errors="replace")))
    return replies


def excerpt(text: str, width: int = 110) -> str:
    flat = " ".join(text.split())
    return flat if len(flat) <= width else flat[: width - 3] + "..."


def report(replies: list[tuple[str, str, str]]) -> int:
    """Print every finding, then the counts per arm; 1 when any doctrine tag fired."""
    counts: dict[str, Counter] = {}
    for arm, label, reply in replies:
        found, n_sentences, n_words = check(reply)
        tally = counts.setdefault(arm, Counter())
        tally.update(replies=1, sentences=n_sentences, words=n_words)
        for tag, evidence in found:
            tally[tag] += 1
            print(f"{label}: {tag}: {excerpt(evidence)}")
    for arm in sorted(counts):
        tally = counts[arm]
        per = max(tally["sentences"], 1) / 100
        print(f"\narm {arm}: {tally['replies']} replies, {tally['sentences']} sentences, {tally['words']} words")
        print("  doctrine: " + ", ".join(f"{tag} {tally[tag]}" for tag in DOCTRINE))
        print("  candidate (per 100 sentences): " + ", ".join(f"{tag} {tally[tag]} ({tally[tag] / per:.1f})" for tag in CANDIDATE))
    doctrine = sum(tally[tag] for tally in counts.values() for tag in DOCTRINE)
    print(f"\n{doctrine} doctrine finding(s): the Interaction section already bans these" if doctrine
          else "\nno doctrine finding; the candidates are counts, never a failure")
    return 1 if doctrine else 0


CLEAN = (
    "## What changed in the adapter\n\n"
    "I moved the deadline into the adapter (`src/infra/http.ts`), and the suite passes: "
    "`bun test` ran 41 tests and none failed.\n\n"
    "The old path is disconnected, so nothing reads it. The cache was indeed empty. "
    "I could not reproduce the timeout, and the ticket keeps the flag until May 2026.\n\n"
    "I replaced \"should pass\" with the command that proved it, since \"the tests were updated\" hides "
    "who did it. The review said \"the retry is bounded.\" I read the diff myself, line by line, and "
    "agreed with every point it made about the adapter, the retry and the flag.\n\n"
    "**The deadline sits in the adapter now, where the client is built, with the bounded and jittered "
    "retry right beside it.** It stops after three tries with jitter.\n\n"
    "```ts\n// robust \u2014 code is not prose, and it should pass\n```\n\n"
    "> A quoted line keeps its own punctuation \u2014 robust or not.\n\n"
    "| Check | Result |\n|:---|:---|\n| Lint | 0 warnings |\n\n"
    "- The first item is plain.\n"
    "- The second names `should pass` inside code, and [a link](https://example.com/robust).\n\n"
    "---\n\n"
    "Which branch should it land on? Commit the two staged files?\n"
)

PLANTS = {
    "em-dash": "I moved the deadline \u2014 the adapter owns it now.",
    "cut-word": "I chose a robust retry for the adapter.",
    "bold-lead-in": "- **Deadline.** The adapter owns it now.",
    "emoji": "The suite is green \u2705",
    "heading-case": "## What Changed In The Adapter",
    "unverified-claim": "The suite should pass now.",
    "hedge": "The cache might hold a stale entry.",
    "passive": "The flaky test was updated.",
    "long-sentence": "I moved the deadline into the adapter and the retry into the use case and the logger "
                     "into the composition root and the flag into the config module today.",
    "long-paragraph": "I read the plan. I ran the suite. I fixed the hook. I moved the flag. I ran lint. "
                      "I ran the types. I staged it.",
    "buried-ask": "I fixed the hook. The suite passes. Commit the change?",
}


def selftest() -> int:
    failures: list[str] = []

    def tags(reply: str) -> list[str]:
        return [tag for tag, _ in check(reply)[0]]

    if tags(CLEAN):
        failures.append(f"the clean reply drew {tags(CLEAN)}")
    if sorted(PLANTS) != sorted(DOCTRINE + CANDIDATE):
        failures.append("a tag has no plant")
    for tag, plant in PLANTS.items():
        if tags(plant) != [tag]:
            failures.append(f"the {tag} plant drew {tags(plant)}")

    # The doctrine tags mirror the Interaction section: a cut word added or dropped there, or a
    # rule reworded away, fails here until this file follows.
    interaction = SKILL.read_text(encoding="utf-8").split("## Interaction", 1)[1].split("\n## ", 1)[0]
    listed = re.search(r"\bcut (.+?)\.(?:\s|$)", interaction)
    cut = tuple(w.strip().strip('"') for w in listed.group(1).split(",")) if listed else ()
    if cut != CUT_WORDS:
        failures.append(f"SKILL.md cuts {cut}, this file {CUT_WORDS}")
    failures += [f"CUT_WORD misses {w!r}" for w in CUT_WORDS if not CUT_WORD.search(w)]
    failures += [f"the Interaction section no longer names {rule!r}"
                 for rule in ("em dash", "bold lead-in", "sentence-case headings", "decorative emoji")
                 if rule not in interaction]

    # Inputs: only the person-facing assistant text of a transcript, a run dir's arm, and nothing
    # from a copied skill or a derived .result.txt.
    tmp = Path(tempfile.mkdtemp(prefix="check-reply-"))
    try:
        run = tmp / "runs" / "t1-with_skill"
        (run / "skills" / "atelier").mkdir(parents=True)
        (run / "skills" / "atelier" / ".review.txt").write_text("A copied skill \u2014 never read.\n")
        events = [
            {"type": "system", "subtype": "init"},
            {"type": "user", "message": {"role": "user", "content": "Fix it \u2014 now."}},
            {"type": "assistant", "parent_tool_use_id": None, "message": {"id": "m1", "content": [
                {"type": "thinking", "thinking": "A robust plan \u2014 maybe."},
                {"type": "text", "text": PLANTS["unverified-claim"]},
                {"type": "tool_use", "name": "Bash", "input": {"command": "echo robust"}}]}},
            {"type": "assistant", "parent_tool_use_id": "toolu_1", "message": {"id": "m2", "content": [
                {"type": "text", "text": PLANTS["cut-word"]}]}},
            {"type": "assistant", "isSidechain": True, "message": {"id": "m3", "content": [
                {"type": "text", "text": PLANTS["emoji"]}]}},
            {"type": "assistant", "message": {"id": "m4", "content": [{"type": "text", "text": "I fixed the hook."}]}},
            {"type": "result", "result": PLANTS["em-dash"]},
        ]
        (run / ".transcript.jsonl").write_text("\n".join(json.dumps(e) for e in events) + "\nnot json\n")
        (run / ".result.txt").write_text(PLANTS["em-dash"] + "\n")
        (tmp / "runs" / "review-baseline").mkdir()
        (tmp / "runs" / "review-baseline" / ".review.txt").write_text(PLANTS["passive"] + "\n")
        got = [(arm, Path(label).name, reply) for arm, label, reply in collect([str(tmp / "runs")])]
        want = [("baseline", ".review.txt", PLANTS["passive"] + "\n"),
                ("with_skill", ".transcript.jsonl#1", PLANTS["unverified-claim"]),
                ("with_skill", ".transcript.jsonl#2", "I fixed the hook.")]
        if got != want:
            failures.append(f"the run dirs read as {got}")
    finally:
        shutil.rmtree(tmp)

    # The exit status: a candidate never fails a run, a doctrine finding always does.
    with contextlib.redirect_stdout(io.StringIO()) as printed:
        passing = report([("-", "clean", CLEAN), ("-", "hedged", PLANTS["hedge"])])
        failing = report([("-", "dashed", PLANTS["em-dash"])])
    if passing != 0 or failing != 1 or "dashed: em-dash: " not in printed.getvalue():
        failures.append(f"exit {passing} on a candidate, {failing} on a doctrine finding")

    for failure in failures:
        print(f"check-reply.py --selftest: {failure}")
    if failures:
        return 1
    print(f"check-reply.py --selftest: each of the {len(PLANTS)} tags fires on its own plant and nowhere else, "
          "the clean reply passes, transcripts and run dirs read as replies, the cut list matches SKILL.md")
    return 0


def main(argv: list[str]) -> int:
    if argv == ["--selftest"]:
        return selftest()
    if argv and argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    replies = collect(argv) if argv else [("-", "stdin", sys.stdin.read())]
    if not any(reply.strip() for _, _, reply in replies):
        print("check-reply.py: no reply found in the input", file=sys.stderr)
        return 2
    return report(replies)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
