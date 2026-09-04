#!/usr/bin/env python3
"""Freeze the baseline arm into the fixture grade.py --frozen-baseline compares against.

The baseline arm never reads the skill, so its results depend only on the tasks (prompts
and assertions) and the model: a fixture to measure once, not an arm to re-run for every
skill edit. This grades every <task>-baseline run dir under the given runs dirs and writes
per-assertion [passed, total] counts to baseline-arm.json, keyed by the sha256 of the
prompts and assertions; grade.py refuses a fixture frozen against a different tasks.json.
Pass several runs dirs to sum passes; the fixture records how many it holds.

Usage:
    python3 scripts/conformance-eval/freeze-baseline.py <runs-dir> [<runs-dir> ...] \\
        [--model <name>] [--out <path>]
"""

import datetime
import json
import os
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
from grade import FROZEN_DEFAULT, grade_run, session_failed, tasks_hash  # noqa: E402


def option(args: list[str], name: str, default: str | None) -> str | None:
    return args[args.index(name) + 1] if name in args else default


def main() -> None:
    args = sys.argv[1:]
    model = option(args, "--model", os.environ.get("CONFORMANCE_MODEL", "unrecorded"))
    out_path = Path(option(args, "--out", str(FROZEN_DEFAULT)))
    dirs = [Path(a) for i, a in enumerate(args) if not a.startswith("--") and (i == 0 or args[i - 1] not in ("--model", "--out"))]
    if not dirs:
        sys.exit(__doc__)
    tasks = json.loads((HERE / "tasks.json").read_text())
    frozen_tasks = {}
    passes = 0
    graded = []
    for task in tasks:
        counts = [[0, 0] for _ in task["assertions"]]
        for d in dirs:
            run_dir = d / f"{task['id']}-baseline"
            if not run_dir.is_dir():
                continue
            if session_failed(run_dir):
                continue  # a transport error is not an unaided answer; never freeze it as one
            graded.append(str(run_dir))
            for i, (_desc, _rule, passed) in enumerate(grade_run(run_dir, task["assertions"])):
                counts[i][0] += 1 if passed else 0
                counts[i][1] += 1
        if any(total for _p, total in counts):
            frozen_tasks[task["id"]] = {"assertions": counts}
            passes = max(passes, max(total for _p, total in counts))
    if not frozen_tasks:
        sys.exit("no <task>-baseline run dir found under the given runs dirs")
    fixture = {
        "frozen": datetime.date.today().isoformat(),
        "model": model,
        "passes": passes,
        "tasks_sha256": tasks_hash(tasks),
        "runs": sorted(set(graded)),
        "tasks": frozen_tasks,
    }
    # One line per task: the fixture is read by grade.py and diffed by people, and 61
    # assertions pretty-printed as nested lists would be a 300-line file.
    header = {k: v for k, v in fixture.items() if k != "tasks"}
    body = ",\n".join(f'    {json.dumps(tid)}: {{"assertions": {json.dumps(counts["assertions"])}}}' for tid, counts in frozen_tasks.items())
    text = json.dumps(header, indent=2)[:-2] + ',\n  "tasks": {\n' + body + "\n  }\n}\n"
    json.loads(text)  # the hand-laid text must still be the same document
    out_path.write_text(text)
    p = sum(c[0] for t in frozen_tasks.values() for c in t["assertions"])
    n = sum(c[1] for t in frozen_tasks.values() for c in t["assertions"])
    print(f"frozen {len(frozen_tasks)} of {len(tasks)} tasks, baseline {p}/{n} over {passes} pass(es), model {model} -> {out_path}")


if __name__ == "__main__":
    main()
