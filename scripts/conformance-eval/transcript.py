#!/usr/bin/env python3
"""A session's transcript: the CLI's --output-format stream-json output, one event per line.

run.sh writes it to <run-dir>/.transcript.jsonl and derives .result.txt from it, so every
consumer of .result.txt reads what it read in text mode:

  - a finished session: the final message (the `result` field of the last `result` event)
  - a turn-capped one: "Error: Reached max turns (N)", N the cap run.sh passed, the text-mode
    form grade.py's turn_capped() recognizes (the stream's own event carries no `result` field,
    only `subtype: error_max_turns` and an `errors` list)
  - anything else: the event's `result` text, else its `errors`, else whatever non-JSON lines the
    CLI printed (a refusal such as "Failed to authenticate. API Error: 403" may arrive either way),
    else nothing (a session the wall-clock watchdog killed mid-stream)

num_turns() is the turn census the harness lacked until 2026-09-26: four skill-arm sessions hit
the 60-turn cap in the 2.4.0 pass and nothing on disk could say where their turns went.

    python3 scripts/conformance-eval/transcript.py <transcript.jsonl> <max-turns>   # prints the result text
"""

import json
import sys
from pathlib import Path


def _events(path: Path) -> tuple[list[dict], list[str]]:
    events: list[dict] = []
    raw: list[str] = []
    if not path.is_file():
        return events, raw
    for line in path.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            raw.append(line)
            continue
        if isinstance(obj, dict):
            events.append(obj)
    return events, raw


def _final(events: list[dict]) -> dict | None:
    results = [e for e in events if e.get("type") == "result"]
    return results[-1] if results else None


def result_text(path: Path, max_turns: str) -> str:
    events, raw = _events(path)
    final = _final(events)
    if final is not None:
        if final.get("subtype") == "error_max_turns":
            return f"Error: Reached max turns ({max_turns})"
        if isinstance(final.get("result"), str) and final["result"].strip():
            return final["result"]
        errors = final.get("errors")
        if isinstance(errors, list) and errors:
            return "\n".join(str(e) for e in errors)
    return "\n".join(raw)


def num_turns(path: Path) -> int | None:
    final = _final(_events(path)[0])
    if final is None or not isinstance(final.get("num_turns"), int):
        return None
    return final["num_turns"]


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: transcript.py <transcript.jsonl> <max-turns>")
    text = result_text(Path(sys.argv[1]), sys.argv[2])
    if text:
        print(text)
