#!/usr/bin/env python3
"""The reply gate: does an agent's reply to a person read the way the Interaction section asks?

The atelier skill's SKILL.md, Interaction, says how a reply reads. Five of its rules are
mechanical enough to match, and they are the doctrine tags:

  em-dash         U+2014 in the reply's own prose
  cut-word        the section's cut list: delve, leverage, robust, seamless, nuanced, "it's worth noting"
  bold-lead-in    a list item that opens on a bold phrase and carries on past it
  emoji           a pictograph or dingbat (U+1F000-1FAFF, U+2600-27BF), less the check and
                  cross marks U+2713-2718, which a status table uses as glyphs
  heading-case    a Title Case heading: two or more capitalised content words, none lowercase

The gate, --hook, is a Claude Code Stop hook (assets/claude-settings.json wires it). It reads the
Stop event on stdin and checks the reply in its last_assistant_message field, or the transcript's
last reply where an older Claude Code sends no such field (the docs warn the transcript can lag).
A doctrine finding exits 2 with each tag and its fix on stderr: Claude Code hands that text back to
the agent, which sends the reply again, fixed. The second stop carries stop_hook_active and passes,
so a reply is restated at most once and the gate never loops. Exit 0 passes; exit 1 is stdin that
is not a Stop event, a visible hook error and never a silent pass. It needs only python3.

The probe, file or directory arguments, reads replies after the fact and counts every tag; a
doctrine finding exits 1. Its candidate tags come from Simplified Technical English (ASD-STE100
Issue 7, read through the 0xpili/simplified-technical-english skill on 2026-10-04). They are not
doctrine and never block or fail: they are counted so an Interaction edit lands only where agents
miss, and 831 real replies showed no habit for any of them (2026-10-04).

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
    thinking, tool calls, user turns, subagent messages and the harness's own notices (model
    <synthetic>: an API error, a /context table) are not replies and are skipped
  - a directory is walked for both; a .result.txt beside a .transcript.jsonl is skipped (it is
    derived from it), and so are the skills/, subagents/, node_modules/ and .git/ subtrees

Code, block quotes, URLs and double-quoted text (a mention, not a use) are never read, emphasis
markers are dropped, and a table row gets the doctrine character checks only. In the skill's own
evals the conformance prompt asks for a bare file list as the final reply, so its transcripts carry
prose only in the narration between tool calls: review-eval's reviews, distill-eval's summaries
and real session logs are the inputs that say most. Counts roll up per arm, read from a run dir's
with_skill or baseline suffix ("-" elsewhere). Each tag is a pattern, not a parser: read the
findings before the counts.

    python3 scripts/check-reply.py --hook < stop-event.json   # the gate: 2 blocks, 0 passes
    python3 scripts/check-reply.py <file-or-dir>...            # the probe: findings, then counts per arm
    python3 skills/atelier/assets/check-reply.py --selftest    # in the skill tree: every tag, both modes
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

SKILL = Path(__file__).resolve().parent.parent / "SKILL.md"  # in the skill tree, assets/ sits beside it

DOCTRINE = ("em-dash", "cut-word", "bold-lead-in", "emoji", "heading-case")
CANDIDATE = ("unverified-claim", "hedge", "passive", "long-sentence", "long-paragraph", "buried-ask")
CUT_WORDS = ("delve", "leverage", "robust", "seamless", "nuanced", "it's worth noting")
MAX_WORDS = 25
MAX_SENTENCES = 6

EM_DASH = "\u2014"
CUT_WORD = re.compile(r"\b(?:delv\w*|leverag\w*|robust\w*|seamless\w*|nuanced|it['\u2019]s worth noting)\b", re.IGNORECASE)
EMOJI = re.compile("[\U0001F000-\U0001FAFF\u2600-\u2712\u2719-\u27BF]")
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
        if isinstance(message, dict) and message.get("model") == "<synthetic>":
            continue  # the harness's notice (an API error, a /context table), not the agent's words
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


FIXES = {
    "em-dash": "a comma, a colon, parentheses or a period",
    "cut-word": "the plain word, or nothing",
    "bold-lead-in": "open the item with a plain sentence; labelled items go in a table",
    "emoji": "words (pass, fail, done)",
    "heading-case": "sentence case, a capital for the first word and proper nouns only",
}


def hook(stdin: str) -> int:
    """The Stop hook: 2 blocks with the doctrine findings on stderr, 0 passes, 1 is bad input."""
    try:
        event = json.loads(stdin)
    except json.JSONDecodeError:
        event = None
    if not isinstance(event, dict) or event.get("hook_event_name") != "Stop":
        print("check-reply.py --hook: stdin is not a Claude Code Stop event", file=sys.stderr)
        return 1
    if event.get("stop_hook_active"):
        return 0  # the restated reply passes: one restatement per reply, never a loop
    reply = event.get("last_assistant_message")
    if not isinstance(reply, str):  # an older Claude Code: the transcript's last reply
        path = Path(str(event.get("transcript_path", "")))
        replies = transcript_replies(path) if path.is_file() else []
        reply = replies[-1] if replies else ""
    found: dict[str, list[str]] = {}
    for tag, evidence in check(reply)[0]:
        if tag in DOCTRINE:
            found.setdefault(tag, []).append(evidence)
    if not found:
        return 0
    print("This reply breaks the atelier Interaction rules. Send it again in full, fixed, with no preface:",
          file=sys.stderr)
    for tag, evidence in found.items():
        print(f"- {tag} ({len(evidence)}): {excerpt(evidence[0], 80)}; fix: {FIXES[tag]}", file=sys.stderr)
    return 2


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
    "| Check | Result |\n|:---|:---|\n| Lint | 0 warnings |\n| Types | \u2713 |\n\n"
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
    # rule reworded away, fails here until this file follows. A copy outside the skill tree has
    # no SKILL.md beside it, and that is a failure too, never a skipped check.
    text = SKILL.read_text(encoding="utf-8") if SKILL.is_file() else ""
    interaction = text.partition("## Interaction")[2].split("\n## ", 1)[0]
    if not interaction:
        failures.append(f"the drift check needs the skill tree: no Interaction section at {SKILL}")
    else:
        listed = re.search(r"\bcut (.+?)\.(?:\s|$)", interaction)
        cut = tuple(w.strip().strip('"') for w in listed.group(1).split(",")) if listed else ()
        if cut != CUT_WORDS:
            failures.append(f"SKILL.md cuts {cut}, this file {CUT_WORDS}")
        failures += [f"the Interaction section no longer names {rule!r}"
                     for rule in ("em dash", "bold lead-in", "sentence-case headings", "decorative emoji")
                     if rule not in interaction]
    failures += [f"CUT_WORD misses {w!r}" for w in CUT_WORDS if not CUT_WORD.search(w)]

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
            {"type": "assistant", "message": {"id": "m5", "model": "<synthetic>", "content": [
                {"type": "text", "text": PLANTS["em-dash"]}]}},
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

        # The gate: a doctrine finding blocks with its tag and fix, a candidate never blocks, the
        # restated reply passes, an older Claude Code's transcript is read, bad input is an error.
        (tmp / "session.jsonl").write_text(json.dumps(
            {"type": "assistant", "message": {"content": [{"type": "text", "text": PLANTS["em-dash"]}]}}) + "\n")
        stop = {"hook_event_name": "Stop", "stop_hook_active": False}
        cases = [
            ("a bold lead-in", {**stop, "last_assistant_message": PLANTS["bold-lead-in"]}, 2, "- bold-lead-in (1): "),
            ("the clean reply", {**stop, "last_assistant_message": CLEAN}, 0, ""),
            ("a candidate", {**stop, "last_assistant_message": PLANTS["hedge"]}, 0, ""),
            ("the restated reply", {**stop, "stop_hook_active": True,
                                    "last_assistant_message": PLANTS["bold-lead-in"]}, 0, ""),
            ("a turn with no text", {**stop, "last_assistant_message": ""}, 0, ""),
            ("an older Claude Code", {**stop, "transcript_path": str(tmp / "session.jsonl")}, 2, "- em-dash (1): "),
            ("another event", {"hook_event_name": "SubagentStop", "last_assistant_message": PLANTS["em-dash"]},
             1, "not a Claude Code Stop event"),
            ("stdin that is not JSON", "not json", 1, "not a Claude Code Stop event"),
        ]
        for name, event, want_code, want_text in cases:
            with contextlib.redirect_stderr(io.StringIO()) as said:
                code = hook(event if isinstance(event, str) else json.dumps(event))
            told = said.getvalue()
            if code != want_code or (want_text not in told if want_text else told):
                failures.append(f"the gate gave {name} exit {code} and {told!r}")
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
          "the clean reply passes, transcripts and run dirs read as replies, the gate blocks a doctrine finding "
          "once and nothing else, the cut list matches SKILL.md")
    return 0


def main(argv: list[str]) -> int:
    if argv == ["--selftest"]:
        return selftest()
    if argv == ["--hook"]:
        return hook(sys.stdin.read())
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
