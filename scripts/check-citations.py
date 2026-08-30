#!/usr/bin/env python3
"""Gate: file:line evidence citations must still point at the content they pin.

The conformance and reverse matrices cite evidence as `file.md:N` or `file.md:N-M`.
Editing a cited file shifts lines and silently rots the evidence (the 2026-08-30
audit found 38 rotten citations from one day's insertions). This gate pins each
citation's target line content in citations-lock.json and fails when it changes.

Usage:
  python3 scripts/check-citations.py             # verify against the lock
  python3 scripts/check-citations.py --lock      # re-pin after a deliberate re-anchor
  python3 scripts/check-citations.py --selftest  # prove the gate can fail

A citation suffixed with @<sha> (e.g. pre-commit:21@430c740) is historical by
declaration and skipped. Prose-form references ("lines 153-217") are not scanned.
"""
from __future__ import annotations

import json
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ["conformance-matrix.md", "reverse-matrix.md"]
LOCK = ROOT / "citations-lock.json"
SNIPPET_LEN = 72

CITE = re.compile(
    r"(?P<name>[A-Za-z0-9._/-]*[A-Za-z0-9_-]\."
    r"(?:md|sh|ts|yml|yaml|json|py|js)|pre-commit-java|pre-commit|commit-msg)"
    r":(?P<start>\d+)(?:-(?P<end>\d+))?(?P<hist>@[0-9a-f]{7,40})?"
    r"(?P<more>(?:/\d+)*)"
)

CANDIDATE_DIRS = [
    "", "skills/", "skills/atelier/", "skills/atelier/references/",
    "skills/atelier/assets/", "docs/global-rules/", "scripts/",
]


def resolve(name: str) -> Path | None:
    for d in CANDIDATE_DIRS:
        p = ROOT / d / name
        if p.is_file():
            return p.relative_to(ROOT)
    return None


def snippet(path: Path, line: int) -> str | None:
    lines = (ROOT / path).read_text().splitlines()
    if line < 1 or line > len(lines):
        return None
    return lines[line - 1].strip()[:SNIPPET_LEN]


def collect(root: Path) -> list[tuple[str, str, int]]:
    """(source description, target name, line) for every non-historical citation."""
    out = []
    for src in SOURCES:
        text = (root / src).read_text()
        for lineno, line in enumerate(text.splitlines(), 1):
            for m in CITE.finditer(line):
                if m.group("hist"):
                    continue
                starts = [int(m.group("start"))]
                starts += [int(x) for x in m.group("more").strip("/").split("/") if x]
                for s in starts:
                    out.append((f"{src}:{lineno}", m.group("name"), s))
    return out


def run_verify() -> int:
    lock = json.loads(LOCK.read_text())["entries"] if LOCK.exists() else {}
    fails = 0
    seen = set()
    for where, name, start in collect(ROOT):
        target = resolve(name)
        if target is None:
            print(f"FAIL {where}: cannot resolve citation target '{name}'", file=sys.stderr)
            fails += 1
            continue
        key = f"{target}:{start}"
        if key in seen:
            continue
        seen.add(key)
        current = snippet(target, start)
        if current is None:
            print(f"FAIL {where}: {key} is beyond end of file", file=sys.stderr)
            fails += 1
        elif key not in lock:
            print(f"FAIL {where}: {key} not in citations-lock.json (run --lock after verifying it)", file=sys.stderr)
            fails += 1
        elif lock[key] != current:
            print(f"FAIL {where}: {key} content changed\n  locked : {lock[key]}\n  current: {current}", file=sys.stderr)
            fails += 1
    if fails == 0:
        print(f"check-citations: {len(seen)} pinned citations intact")
    return 1 if fails else 0


def run_lock() -> int:
    entries: dict[str, str] = {}
    bad = 0
    for where, name, start in collect(ROOT):
        target = resolve(name)
        if target is None:
            print(f"FAIL {where}: cannot resolve '{name}', not locking", file=sys.stderr)
            bad += 1
            continue
        s = snippet(target, start)
        if s is None:
            print(f"FAIL {where}: {target}:{start} beyond end of file, not locking", file=sys.stderr)
            bad += 1
            continue
        entries[f"{target}:{start}"] = s
    if bad:
        return 1
    LOCK.write_text(json.dumps({"entries": dict(sorted(entries.items()))}, indent=2) + "\n")
    print(f"check-citations: locked {len(entries)} citations")
    return 0


def run_selftest() -> int:
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        target = root / "doc.md"
        target.write_text("alpha\nbeta\ngamma\n")
        src = root / "matrix.md"
        src.write_text("| row | doc.md:2 | evidence |\n")
        global ROOT, SOURCES, LOCK, CANDIDATE_DIRS
        ROOT, SOURCES, LOCK = root, ["matrix.md"], root / "lock.json"
        CANDIDATE_DIRS = [""]
        assert run_lock() == 0
        assert run_verify() == 0, "clean tree must verify"
        target.write_text("alpha\nCHANGED\ngamma\n")
        assert run_verify() == 1, "changed cited line must fail"
        target.write_text("alpha\nbeta\ngamma\n")
        src.write_text("| row | doc.md:2 | e |\n| row | doc.md:3 | new cite |\n")
        assert run_verify() == 1, "citation missing from lock must fail"
        src.write_text("| row | doc.md:99 | e |\n")
        assert run_verify() == 1, "out-of-range citation must fail"
        src.write_text("| row | doc.md:1@430c740 | historical, skipped |\n")
        (root / "lock.json").write_text('{"entries": {}}')
        assert run_verify() == 0, "historical @sha citation must be skipped"
    print("selftest OK: gate rejects a drifted line, an unlocked citation, and an out-of-range one")
    return 0


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "--selftest":
        sys.exit(run_selftest())
    if mode == "--lock":
        sys.exit(run_lock())
    sys.exit(run_verify())
