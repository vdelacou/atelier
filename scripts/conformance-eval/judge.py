#!/usr/bin/env python3
"""Pairwise LLM judging for the conformance eval: conforming vs excellent.

The mechanical grader in `grade.py` saturated. Once the skill arm scores 24/24 on
tasks whose prompts actively ask for the violation, a regex can no longer tell a
conforming answer from an excellent one, and the eval measures only regression.
This judges the same paired outputs on depth instead of presence.

Every design choice here defends against a known failure mode of LLM judging:

  pairwise      absolute scores drift between runs; a comparison does not.
  blind         arms are relabeled A/B, so the judge cannot reward the label. The
                order comes from a hash of the task id: reproducible, and not
                aligned with arm identity.
  order-swapped every pair is judged twice, A/B and B/A. A verdict that flips with
                position is INCONSISTENT and scores for nobody. Position bias is
                the single most reported judge pathology; this measures it rather
                than hoping it is absent.
  grounded      the judge reads the doctrine and must cite file plus rule for each
                claim. A verdict whose winner carries no citation is discarded.
  tie allowed   forced choice manufactures a signal that is not there.

Usage:
  python3 scripts/conformance-eval/judge.py <runs-dir> [<runs-dir> ...]
  python3 scripts/conformance-eval/judge.py --selftest      # offline, no API
Env:
  JUDGE_MODEL   model for the nested `claude -p` (default: the configured model)
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
ARMS = ("with_skill", "baseline")
EXTS = (".ts", ".tsx", ".sql", ".java", ".json", ".md")
SKIP_PREFIX = (".claude/", "node_modules/", "skills/", ".git/")
MAX_CHARS = 60_000


def collect(run_dir: Path) -> dict[str, str]:
    """The agent's produced files, path-keyed. Mirrors grade.py's diff-only scope."""
    out: dict[str, str] = {}
    for p in sorted(run_dir.rglob("*")):
        if not p.is_file() or p.suffix not in EXTS:
            continue
        rel = str(p.relative_to(run_dir))
        if rel.startswith(SKIP_PREFIX) or rel.startswith("."):
            continue
        out[rel] = p.read_text(errors="replace")
    return out


def render(files: dict[str, str]) -> str:
    body, total = [], 0
    for rel, text in files.items():
        chunk = f"--- {rel}\n{text}\n"
        total += len(chunk)
        if total > MAX_CHARS:
            body.append(f"--- {rel}\n[omitted: submission exceeds the size budget]\n")
            continue
        body.append(chunk)
    return "".join(body) or "[no files produced]"


def blind_order(task: str, swapped: bool, arms: tuple[str, str] = ARMS) -> tuple[str, str]:
    """Which arm is shown as A. Deterministic per task, then swapped for pass two."""
    first = arms[int(hashlib.sha256(task.encode()).hexdigest(), 16) % 2]
    second = arms[1] if first == arms[0] else arms[0]
    return (second, first) if swapped else (first, second)


PROMPT = """You are judging two answers to the same engineering task against a written standard.

The standard is in ./skills/atelier/SKILL.md (hard rules 1-34) with detail under
./skills/atelier/references/. Read what the task touches before judging.

THE TASK GIVEN TO BOTH:
{task_prompt}

SUBMISSION A:
{a}

SUBMISSION B:
{b}

Judge which submission a senior engineer holding this standard would rather land, on
depth rather than presence: does it satisfy the DISCIPLINE the rules exist for, or does
it merely contain the tokens a checker looks for? Weigh, in this order:

1. Correctness and completeness of the disciplines the task triggers, including the
   clauses that are easy to drop (the second enforcement layer, the failing test, the
   idempotency key, the eval gate, the spend cap).
2. Whether the layering is real: does the port exist because the design needs it, with a
   usable hand-written double, or is it a shell around the same coupling?
3. Test quality: asserted through the primary port on observable behavior, not internals;
   a regression test for anything a bug would reach.
4. Restraint: no speculative abstraction, no ceremony the task did not need. More code is
   not better.
5. Whether it resists a bad instruction in the task itself, if there is one.

Every claim you make must cite a file from that submission, and name the rule number or
canon id it turns on. A verdict with no citations is worthless.

Answer with ONE json object and nothing else:
{{"winner": "A" | "B" | "tie",
  "margin": 1 | 2 | 3,
  "why": "<=60 words, the decisive difference",
  "citations": [{{"submission": "A"|"B", "file": "path", "rule": "17 or 7.5", "point": "<=20 words"}}]}}

margin 1 is a hair, 3 is decisive. Use "tie" when neither is better on the substance;
a stylistic preference is a tie. Do not reward length."""


def ask_judge(task_prompt: str, a: str, b: str, model: str | None, cwd: Path) -> dict:
    prompt = PROMPT.format(task_prompt=task_prompt, a=a, b=b)
    cmd = ["claude", "-p", prompt]
    if model:
        cmd += ["--model", model]
    env_cmd = ["env", "-u", "CLAUDECODE"] + cmd
    res = subprocess.run(env_cmd, cwd=cwd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    raw = res.stdout.strip()
    m = re.search(r"\{.*\}", raw, re.S)
    if not m:
        return {"winner": "error", "margin": 0, "why": raw[:200], "citations": []}
    try:
        return json.loads(m.group(0))
    except json.JSONDecodeError:
        return {"winner": "error", "margin": 0, "why": "unparseable json", "citations": []}


def unblind(verdict: dict, shown: tuple[str, str]) -> str:
    """Map the judge's A/B answer back to an arm name."""
    w = verdict.get("winner")
    if w == "A":
        return shown[0]
    if w == "B":
        return shown[1]
    return w if w in ("tie", "error") else "error"


def cited_for(verdict: dict, letter: str) -> bool:
    return any(c.get("submission") == letter for c in verdict.get("citations") or [])


def score_pair(task: str, verdicts: list[tuple[dict, tuple[str, str]]],
               arms: tuple[str, str] = ARMS) -> dict:
    """Two order-swapped verdicts collapse to one outcome."""
    winners = []
    for v, shown in verdicts:
        w = unblind(v, shown)
        if w in arms and not cited_for(v, v["winner"]):
            w = "uncited"          # a winner with no evidence for itself does not count
        winners.append(w)
    if "error" in winners:
        return {"task": task, "outcome": "error", "winners": winners}
    if winners[0] != winners[1]:
        return {"task": task, "outcome": "inconsistent", "winners": winners}
    return {"task": task, "outcome": winners[0], "winners": winners}


def selftest() -> None:
    # Unblinding must invert with the swap, or every result is a position artifact.
    first, second = blind_order("h1-trap-mock", swapped=False)
    assert (first, second) == blind_order("h1-trap-mock", swapped=False), "order must be deterministic"
    assert blind_order("h1-trap-mock", swapped=True) == (second, first)
    assert set(blind_order("h4-trap-tenant", False)) == set(ARMS)

    cited_a = {"winner": "A", "margin": 3, "citations": [{"submission": "A", "file": "x.ts", "rule": "17"}]}
    cited_b = {"winner": "B", "margin": 2, "citations": [{"submission": "B", "file": "x.ts", "rule": "17"}]}
    tie = {"winner": "tie", "margin": 1, "citations": []}

    # Same arm wins under both orders -> a real win.
    r = score_pair("t", [(cited_a, ("with_skill", "baseline")), (cited_b, ("baseline", "with_skill"))])
    assert r["outcome"] == "with_skill", r
    # The judge picks whichever is shown first both times -> position bias, not a win.
    r = score_pair("t", [(cited_a, ("with_skill", "baseline")), (cited_a, ("baseline", "with_skill"))])
    assert r["outcome"] == "inconsistent", r
    # A winner that cites nothing for itself is discarded, not counted.
    uncited = {"winner": "A", "margin": 3, "citations": [{"submission": "B", "file": "x.ts", "rule": "17"}]}
    r = score_pair("t", [(uncited, ("with_skill", "baseline")), (uncited, ("baseline", "with_skill"))])
    assert r["outcome"] == "uncited", r
    r = score_pair("t", [(tie, ("with_skill", "baseline")), (tie, ("baseline", "with_skill"))])
    assert r["outcome"] == "tie", r
    # Custom labels: the instrument's real use is A/B-ing two skill VERSIONS, so
    # the arm names cannot be hardcoded and the unblinding must follow the labels.
    doctrine = ("current", "candidate")
    d1, d2 = blind_order("h5-isolation-full", False, doctrine), blind_order("h5-isolation-full", True, doctrine)
    assert set(d1) == set(doctrine) and d1 == (d2[1], d2[0]), (d1, d2)
    r = score_pair("t", [(cited_a, ("candidate", "current")), (cited_b, ("current", "candidate"))], doctrine)
    assert r["outcome"] == "candidate", r
    # And a label that is not one of the two arms is never invented by the scorer.
    r = score_pair("t", [(tie, ("current", "candidate")), (tie, ("candidate", "current"))], doctrine)
    assert r["outcome"] == "tie", r

    err = {"winner": "error", "margin": 0, "citations": []}
    r = score_pair("t", [(err, ("with_skill", "baseline")), (tie, ("baseline", "with_skill"))])
    assert r["outcome"] == "error", r

    # An inverted unblinding must be caught, which is what makes this a gate.
    def inverted(v, shown):
        return shown[1] if v.get("winner") == "A" else shown[0]
    assert inverted(cited_a, ("with_skill", "baseline")) != unblind(cited_a, ("with_skill", "baseline"))
    print("selftest OK: order is deterministic and swaps, a position-flipped verdict scores "
          "inconsistent, an uncited winner is discarded, ties and errors survive collapse")


def judge_pairs(pairs: list[tuple[str, str, str]], arms: tuple[str, str], model: str | None,
                tasks: dict[str, str]) -> list[dict]:
    """pairs: (task, rendered-for-arm0, rendered-for-arm1)."""
    results = []
    for task, a0, a1 in pairs:
        rendered = {arms[0]: a0, arms[1]: a1}
        verdicts = []
        for swapped in (False, True):
            shown = blind_order(task, swapped, arms)
            v = ask_judge(tasks[task], rendered[shown[0]], rendered[shown[1]], model, REPO)
            verdicts.append((v, shown))
            print(f"  {task} order{'2' if swapped else '1'}: {v.get('winner')} "
                  f"(margin {v.get('margin')}) {str(v.get('why'))[:70]}", flush=True)
        r = score_pair(task, verdicts, arms)
        r["detail"] = [v for v, _ in verdicts]
        results.append(r)
        print(f"{task}: {r['outcome']}", flush=True)
    return results


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        selftest()
        return 0
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    import os
    model = os.environ.get("JUDGE_MODEL")
    tasks = {t["id"]: t["prompt"] for t in json.loads((REPO / "scripts/conformance-eval/tasks.json").read_text())}
    argv = sys.argv[1:]

    # Doctrine A/B: the same arm, produced by two different skill versions, in two
    # run dirs. This is the comparison the mechanical grader cannot make, and the
    # reason the judge exists; skill-versus-no-skill is only its smoke test.
    if argv[0] == "--ab":
        if len(argv) < 3:
            print("usage: judge.py --ab <dir-a> <dir-b> [label-a label-b] [--arm with_skill]")
            return 2
        dir_a, dir_b = Path(argv[1]), Path(argv[2])
        rest = argv[3:]
        arm = "with_skill"
        if "--arm" in rest:
            i = rest.index("--arm")
            arm = rest[i + 1]
            rest = rest[:i] + rest[i + 2:]
        arms = (rest[0], rest[1]) if len(rest) >= 2 else (dir_a.name, dir_b.name)
        pairs = []
        for run_a in sorted(dir_a.glob(f"*-{arm}")):
            task = run_a.name[: -len(f"-{arm}")]
            run_b = dir_b / run_a.name
            if not run_b.is_dir() or task not in tasks:
                continue
            pairs.append((task, render(collect(run_a)), render(collect(run_b))))
        if not pairs:
            print(f"no {arm} runs common to both dirs", file=sys.stderr)
            return 1
        print(f"doctrine A/B on {len(pairs)} task(s): {arms[0]} vs {arms[1]} (arm: {arm})")
        results = judge_pairs(pairs, arms, model, tasks)
    else:
        arms = ARMS
        pairs = []
        for runs_dir in map(Path, argv):
            for ws in sorted(runs_dir.glob("*-with_skill")):
                task = ws.name[: -len("-with_skill")]
                bl = runs_dir / f"{task}-baseline"
                if not bl.is_dir() or task not in tasks:
                    continue
                pairs.append((task, render(collect(ws)), render(collect(bl))))
        results = judge_pairs(pairs, arms, model, tasks)

    counts: dict[str, int] = {}
    for r in results:
        counts[r["outcome"]] = counts.get(r["outcome"], 0) + 1
    print("\nJUDGE TOTALS (order-swapped, blind, citation-required):")
    for k in (arms[0], arms[1], "tie", "inconsistent", "uncited", "error"):
        if counts.get(k):
            print(f"  {k:13} {counts[k]}")
    decided = counts.get(arms[0], 0) + counts.get(arms[1], 0)
    if decided:
        print(f"  {arms[0]} wins {counts.get(arms[0], 0)}/{decided} of the pairs both orders agreed on")
    (REPO / "scripts/conformance-eval/.judge-last.json").write_text(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
