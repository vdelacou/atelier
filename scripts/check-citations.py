#!/usr/bin/env python3
"""Gate: file:line evidence citations must still point at the content they pin.

The conformance and reverse matrices cite evidence as `file.md:N` or `file.md:N-M`.
Editing a cited file shifts lines and silently rots the evidence (the 2026-08-30
audit found 38 rotten citations from one day's insertions). This gate pins each
citation's target line content in citations-lock.json and fails when it changes.

Usage:
  python3 scripts/check-citations.py             # verify against the lock
  python3 scripts/check-citations.py --reanchor  # an edit shifted cited lines: move every
                                                 # pinned citation to the line that now holds
                                                 # its snippet (both ends of a range), re-lock
  python3 scripts/check-citations.py --lock      # the pinned content itself changed on purpose
  python3 scripts/check-citations.py --selftest  # prove the gate can fail

A citation suffixed with @<sha> (e.g. pre-commit:21@430c740) is historical by
declaration and skipped. Prose-form references ("lines 153-217") are not scanned.
Scanned extensions: md, sh, ts, yml, yaml, json, py, js, java, xml, properties (the
Java assets joined on 2026-09-08, when a `.java:18` citation had sat unpinned).
A citation whose target line is blank is a failure, and --lock refuses to pin it: an
empty snippet pins nothing, and three range citations had sat on the blank line after
a heading since the lock was created (found 2026-09-08).
A range `file.md:N-M` pins both N and M (since 2026-09-08): a range guards a section,
and a section has two ends. Before, only N was pinned, and re-anchoring by hand moved
starts and never ends, so three ranges had inverted (end before start) unseen.
--reanchor (since 2026-09-09) does that job: a pinned snippet found on exactly one line
moves the citation there; a snippet that is gone or ambiguous is reported and left for a
human, and nothing is locked until every move resolved.
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
    r"(?:md|sh|ts|yml|yaml|json|py|js|java|xml|properties)|pre-commit-java|pre-commit|commit-msg)"
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
                if m.group("end"):
                    starts.append(int(m.group("end")))
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
        elif current == "":
            print(f"FAIL {where}: {key} cites a blank line, not evidence (re-anchor to the line the row quotes)", file=sys.stderr)
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
        if s == "":
            print(f"FAIL {where}: {target}:{start} is a blank line, not locking (re-anchor it first)", file=sys.stderr)
            bad += 1
            continue
        entries[f"{target}:{start}"] = s
    if bad:
        return 1
    LOCK.write_text(json.dumps({"entries": dict(sorted(entries.items()))}, indent=2) + "\n")
    print(f"check-citations: locked {len(entries)} citations")
    return 0


def run_reanchor() -> int:
    """Move each pinned citation whose line drifted to the unique line that now holds
    its snippet, rewrite the citation tokens in every source, then re-lock."""
    lock = json.loads(LOCK.read_text())["entries"] if LOCK.exists() else {}
    moves: dict[tuple[str, int], int] = {}
    stuck = 0
    for key, locked in lock.items():
        target, ln_s = key.rsplit(":", 1)
        ln = int(ln_s)
        path = ROOT / target
        if not path.is_file():
            print(f"FAIL {key}: target file is gone; re-anchor by hand", file=sys.stderr)
            stuck += 1
            continue
        lines = path.read_text().splitlines()
        if 1 <= ln <= len(lines) and lines[ln - 1].strip()[:SNIPPET_LEN] == locked:
            continue
        hits = [i + 1 for i, l in enumerate(lines) if l.strip()[:SNIPPET_LEN] == locked]
        if len(hits) == 1:
            moves[(target, ln)] = hits[0]
        elif not hits:
            print(f"FAIL {key}: the pinned content is gone from {target}; re-anchor by hand, then --lock", file=sys.stderr)
            stuck += 1
        else:
            print(f"FAIL {key}: the pinned content appears {len(hits)} times in {target} (lines {', '.join(map(str, hits))}); re-anchor by hand, then --lock", file=sys.stderr)
            stuck += 1
    if not moves and not stuck:
        print("check-citations: nothing to re-anchor")
        return 0

    def rebuild(m: re.Match) -> str:
        if m.group("hist"):
            return m.group(0)
        target = resolve(m.group("name"))
        if target is None:
            return m.group(0)
        t = str(target)
        start = int(m.group("start"))
        out = f"{m.group('name')}:{moves.get((t, start), start)}"
        if m.group("end"):
            end = int(m.group("end"))
            out += f"-{moves.get((t, end), end)}"
        for x in m.group("more").strip("/").split("/"):
            if x:
                out += f"/{moves.get((t, int(x)), int(x))}"
        return out

    for src in SOURCES:
        text = (ROOT / src).read_text()
        new_text = CITE.sub(rebuild, text)
        if new_text != text:
            (ROOT / src).write_text(new_text)
    for (t, old), new in sorted(moves.items()):
        print(f"  {t}:{old} -> {new}")
    if stuck:
        print(f"check-citations: moved {len(moves)} citation line(s); {stuck} left for a human, not locking", file=sys.stderr)
        return 1
    print(f"check-citations: moved {len(moves)} citation line(s); re-locking")
    return run_lock()


def run_selftest() -> int:
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        target = root / "doc.md"
        target.write_text("alpha\nbeta\ngamma\n")
        java = root / "Layer.java"
        java.write_text("package x;\n@AnalyzeClasses\nfinal class Layer {}\n")
        src = root / "matrix.md"
        src.write_text("| row | doc.md:2; Layer.java:2 | evidence |\n")
        global ROOT, SOURCES, LOCK, CANDIDATE_DIRS
        ROOT, SOURCES, LOCK = root, ["matrix.md"], root / "lock.json"
        CANDIDATE_DIRS = [""]
        assert run_lock() == 0
        assert run_verify() == 0, "clean tree must verify"
        target.write_text("alpha\nCHANGED\ngamma\n")
        assert run_verify() == 1, "changed cited line must fail"
        target.write_text("alpha\nbeta\ngamma\n")
        java.write_text("package x;\n@Deprecated\nfinal class Layer {}\n")
        assert run_verify() == 1, "a changed cited .java line must fail (the asset kinds are scanned)"
        java.write_text("package x;\n@AnalyzeClasses\nfinal class Layer {}\n")
        src.write_text("| row | doc.md:2 | e |\n| row | doc.md:3 | new cite |\n")
        assert run_verify() == 1, "citation missing from lock must fail"
        src.write_text("| row | doc.md:99 | e |\n")
        assert run_verify() == 1, "out-of-range citation must fail"
        src.write_text("| row | doc.md:1@430c740 | historical, skipped |\n")
        (root / "lock.json").write_text('{"entries": {}}')
        assert run_verify() == 0, "historical @sha citation must be skipped"
        target.write_text("alpha\nbeta\ngamma\n")
        src.write_text("| row | doc.md:1-3 | a range |\n")
        assert run_lock() == 0
        assert run_verify() == 0, "an intact range must verify"
        target.write_text("alpha\nbeta\nCHANGED\n")
        assert run_verify() == 1, "a drifted range END must fail: both ends of a range are pinned"
        # --reanchor: an inserted line shifts a citation and a range; both move by snippet
        target.write_text("alpha\nbeta\ngamma\ndelta\n")
        src.write_text("| row | doc.md:2; doc.md:3-4 | e |\n")
        assert run_lock() == 0
        target.write_text("zero\nalpha\nbeta\ngamma\ndelta\n")
        assert run_verify() == 1, "a shifted tree must fail before --reanchor"
        assert run_reanchor() == 0, "--reanchor must resolve a clean shift"
        assert src.read_text() == "| row | doc.md:3; doc.md:4-5 | e |\n", f"citations not rewritten: {src.read_text()!r}"
        assert run_verify() == 0, "the re-anchored tree must verify"
        assert run_reanchor() == 0, "--reanchor on an intact tree is a no-op"
        # an ambiguous snippet (the same line twice) is left for a human and nothing is locked
        target.write_text("alpha\nbeta\ngamma\n")
        src.write_text("| row | doc.md:2 | e |\n")
        assert run_lock() == 0
        target.write_text("zero\nalpha\nbeta\ngamma\nbeta\n")
        assert run_reanchor() == 1, "an ambiguous snippet must be refused"
        assert src.read_text() == "| row | doc.md:2 | e |\n", "an ambiguous citation must not be rewritten"
        # a snippet that is gone is refused too
        target.write_text("alpha\nCHANGED\ngamma\n")
        assert run_reanchor() == 1, "a vanished snippet must be refused"
        target.write_text("alpha\n\ngamma\n")
        src.write_text("| row | doc.md:2 | a blank line |\n")
        assert run_lock() == 1, "a citation to a blank line must be refused by --lock"
        (root / "lock.json").write_text('{"entries": {"doc.md:2": ""}}')
        assert run_verify() == 1, "a citation to a blank line must fail verify even when the lock holds the empty snippet"
    print("selftest OK: gate rejects a drifted line (in a .md and in a .java), a drifted range end, an unlocked citation, an out-of-range one, and a blank line; --reanchor moves a shifted citation and range and refuses an ambiguous or vanished snippet")
    return 0


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "--selftest":
        sys.exit(run_selftest())
    if mode == "--lock":
        sys.exit(run_lock())
    if mode == "--reanchor":
        sys.exit(run_reanchor())
    sys.exit(run_verify())
