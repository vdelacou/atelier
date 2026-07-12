#!/usr/bin/env python3
"""Grade conformance runs: mechanical assertions over the code each run produced.

Reads tasks.json (declarative assertions: regex + present/absent + optional
exclude paths and extension globs) and applies them to every run directory
under the given workspace (default: the newest conformance workspace).

Usage:
    python3 scripts/conformance-eval/grade.py [runs-dir]

A run directory is <runs-dir>/<task-id>-<arm>/ where arm is with_skill or
baseline. Missing directories are reported as ungraded, not failed.
"""

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
FIXTURE_FILES = {
    str(p.relative_to(HERE / "fixture"))
    for p in (HERE / "fixture").rglob("*")
    if p.is_file()
}


def read_sources(run_dir: Path, exts: tuple[str, ...], exclude: set[str]) -> dict[str, str]:
    out = {}
    for p in run_dir.rglob("*"):
        if not p.is_file() or p.suffix not in exts:
            continue
        rel = str(p.relative_to(run_dir))
        if rel.startswith((".claude/", "node_modules/")) or rel in exclude:
            continue
        out[rel] = p.read_text(errors="replace")
    return out


def grade_run(run_dir: Path, assertions: list[dict]) -> list[tuple[str, bool]]:
    marks = []
    for a in assertions:
        exts = tuple(a.get("globs", [".ts", ".tsx", ".sql", ".java"]))
        exclude = set(a.get("exclude", []))
        files = read_sources(run_dir, exts, exclude)
        rx = re.compile(a["pattern"])
        hit = any(rx.search(text) for text in files.values())
        passed = hit if a["mode"] == "present" else (not hit if files else False)
        if not files:
            passed = False  # nothing produced in scope = not conforming
        marks.append((a["desc"], passed))
    return marks


def main() -> None:
    runs_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if runs_dir is None:
        workspaces = sorted(Path("skills/atelier-workspace").glob("conformance-*/runs"))
        if not workspaces:
            sys.exit("no conformance workspace found; pass the runs dir explicitly")
        runs_dir = workspaces[-1]

    tasks = json.loads((HERE / "tasks.json").read_text())
    grand = {"with_skill": [0, 0], "baseline": [0, 0]}
    for task in tasks:
        rows = []
        for arm in ("with_skill", "baseline"):
            run_dir = runs_dir / f"{task['id']}-{arm}"
            if not run_dir.is_dir():
                rows.append((arm, None))
                continue
            marks = grade_run(run_dir, task["assertions"])
            grand[arm][0] += sum(1 for _, p in marks if p)
            grand[arm][1] += len(marks)
            rows.append((arm, marks))
        if all(marks is None for _, marks in rows):
            continue
        print(f"\n{task['id']}:")
        for arm, marks in rows:
            if marks is None:
                print(f"  {arm:<11} (no run)")
                continue
            score = sum(1 for _, p in marks if p)
            detail = "  ".join(("PASS" if p else "fail") + f":{d[:36]}" for d, p in marks)
            print(f"  {arm:<11} {score}/{len(marks)}  {detail}")

    print("\nTOTALS (graded runs only):")
    for arm, (p, t) in grand.items():
        print(f"  {arm:<11} {p}/{t}")


if __name__ == "__main__":
    main()
