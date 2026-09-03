#!/usr/bin/env python3
"""Select the conformance tasks a skill diff can affect (tier 1 of the harness).

A full conformance pass is hours of `claude -p` sessions, and most of a doctrine
edit touches a handful of rules. This maps the diff of skills/atelier/ since a
ref to the tasks whose assertions exercise the touched rules:

  - a changed line inside the SKILL.md hard-rules section names its rule (the
    `NN. **...**` line the hunk lands on);
  - an explicit reference anywhere in a changed line names rules too: `rule 28`,
    `rules 27-34`, `(28)`, `(29, 31)`;
  - a changed reference file maps to rules through the trigger table in SKILL.md
    (its "read when" cell says `rule 28` or `rules 29-31`); a reference whose row
    names no rule selects nothing and is reported, so tier 2 is a conscious call;
  - a canon id in a changed line (`7.5`, `4.8`) selects the assertions tagged with it.

Each task in tasks.json carries `hard_rules`, the atelier rules its assertions
exercise; a task is selected when one of those rules or one of its assertion ids
was touched. Output: one task id per line on stdout, the reasoning on stderr.

Usage:
    python3 scripts/conformance-eval/select-tasks.py --since <ref>
    python3 scripts/conformance-eval/select-tasks.py --diff-file <unified-diff> --skill-file <SKILL.md>
    python3 scripts/conformance-eval/select-tasks.py --selftest

run.sh calls it when CONFORMANCE_SINCE is set; calling it directly is the dry run. The file
name carries a hyphen on purpose: a module named select.py shadows the stdlib select that
subprocess needs.
"""

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
REPO_ROOT = HERE.parent.parent
SKILL_DIR = Path("skills/atelier")
RULE_LINE = re.compile(r"^(\d{1,2})\. \*\*")
RULE_REF = re.compile(r"\brules? (\d{1,2}(?:-\d{1,2})?(?:, ?\d{1,2}(?:-\d{1,2})?)*)")
PAREN_REF = re.compile(r"\((\d{1,2}(?:-\d{1,2})?(?:, ?\d{1,2}(?:-\d{1,2})?)*)\)")
CANON_ID = re.compile(r"\b(\d{1,2}\.\d{1,2})\b")
HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")
MAX_RULE = 35


def expand(spec: str) -> set[int]:
    out: set[int] = set()
    for part in re.split(r", ?", spec):
        if "-" in part:
            lo, hi = (int(x) for x in part.split("-"))
            out.update(range(lo, hi + 1))
        else:
            out.add(int(part))
    return {n for n in out if 1 <= n <= MAX_RULE}


def hard_rule_lines(skill_text: str) -> dict[int, int]:
    """Line number (1-based) -> rule number, for the hard-rules section only."""
    out: dict[int, int] = {}
    inside = False
    for i, line in enumerate(skill_text.split("\n"), start=1):
        if line.startswith("## "):
            inside = line.lower().startswith("## hard rules")
            continue
        m = RULE_LINE.match(line)
        if inside and m:
            out[i] = int(m.group(1))
    return out


def trigger_table(skill_text: str) -> dict[str, set[int]]:
    """reference file name -> rules named in its trigger-table row."""
    out: dict[str, set[int]] = {}
    for line in skill_text.split("\n"):
        m = re.match(r"^\| `([a-z0-9-]+\.md)` \|(.*)$", line)
        if m:
            out[m.group(1)] = set().union(*(expand(s) for s in RULE_REF.findall(m.group(2)))) if RULE_REF.search(m.group(2)) else set()
    return out


def parse_diff(diff: str) -> dict[str, tuple[list[tuple[int, int]], list[str]]]:
    """file -> (new-line ranges, changed line texts) from a unified diff."""
    files: dict[str, tuple[list[tuple[int, int]], list[str]]] = {}
    current = None
    for line in diff.split("\n"):
        if line.startswith("+++ "):
            name = line[4:].strip()
            current = name[2:] if name.startswith("b/") else name
            files.setdefault(current, ([], []))
            continue
        if current is None:
            continue
        m = HUNK.match(line)
        if m:
            start, count = int(m.group(1)), int(m.group(2) or "1")
            files[current][0].append((start, start + max(count, 1) - 1))
            continue
        if (line.startswith("+") or line.startswith("-")) and not line.startswith(("+++", "---")):
            files[current][1].append(line[1:])
    return files


def touched(diff: str, skill_text: str, canon_ids: set[str]) -> tuple[set[int], set[str], list[str]]:
    rules: set[int] = set()
    canon: set[str] = set()
    unmapped: list[str] = []
    rule_lines = hard_rule_lines(skill_text)
    table = trigger_table(skill_text)
    for name, (ranges, lines) in parse_diff(diff).items():
        rel = Path(name)
        if rel.name == "SKILL.md" and rel.parent == SKILL_DIR:
            for lo, hi in ranges:
                rules.update(r for ln, r in rule_lines.items() if lo <= ln <= hi)
        elif rel.parent == SKILL_DIR / "references":
            mapped = table.get(rel.name)
            if mapped:
                rules.update(mapped)
            else:
                unmapped.append(rel.name)
        for text in lines:
            for spec in RULE_REF.findall(text) + PAREN_REF.findall(text):
                rules.update(expand(spec))
            canon.update(c for c in CANON_ID.findall(text) if c in canon_ids)
    return rules, canon, unmapped


def pick(tasks: list[dict], rules: set[int], canon: set[str]) -> list[str]:
    out = []
    for t in tasks:
        by_rule = set(t.get("hard_rules", [])) & rules
        by_canon = {a["rule"] for a in t["assertions"]} & canon
        if by_rule or by_canon:
            out.append(t["id"])
    return out


def git_diff(ref: str) -> str:
    return subprocess.run(
        ["git", "diff", "-U0", ref, "--", str(SKILL_DIR / "SKILL.md"), str(SKILL_DIR / "references")],
        cwd=REPO_ROOT, capture_output=True, text=True, check=True,
    ).stdout


def selftest() -> None:
    tasks = json.loads((HERE / "tasks.json").read_text())
    canon_ids = {a["rule"] for t in tasks for a in t["assertions"]}
    skill = "\n".join([
        "# x", "## Guidelines", "1. **Think before coding.** a", "2. **Simple.** b", "",
        "## Hard rules", "1. **No class.** a", "27. **No PII.** b", "28. **Tenant isolation.** c",
        "32. **AI port.** d", "", "## Reference files", "| Reference | Read when | Skip when |", "|---|---|---|",
        "| `ai.md` | an LLM SDK import; rule 32 | no model call |", "| `architecture.md` | new dir | one module |", "",
    ])
    diff = "\n".join([
        "--- a/skills/atelier/SKILL.md", "+++ b/skills/atelier/SKILL.md",
        "@@ -9,1 +9,1 @@", "-28. **Tenant isolation.** c", "+28. **Tenant isolation.** c, d",
        "--- a/skills/atelier/references/architecture.md", "+++ b/skills/atelier/references/architecture.md",
        "@@ -5,0 +6,1 @@", "+a new paragraph naming nothing", "",
    ])
    rules, canon, unmapped = touched(diff, skill, canon_ids)
    if rules != {28} or canon or unmapped != ["architecture.md"]:
        sys.exit(f"SELFTEST FAILED: a hunk on the rule-28 line should touch {{28}} and report architecture.md unmapped, got {rules} {canon} {unmapped}")
    picked = pick(tasks, rules, canon)
    if not {"h4-trap-tenant", "h5-isolation-full"} <= set(picked) or "h6-ai-full" in picked:
        sys.exit(f"SELFTEST FAILED: rule 28 should select the isolation tasks and not h6, got {picked}")
    # A guideline line numbered like a hard rule must not select rule 1's tasks: only the
    # hard-rules section is rule territory.
    guideline = "\n".join(["--- a/skills/atelier/SKILL.md", "+++ b/skills/atelier/SKILL.md",
                           "@@ -3,1 +3,1 @@", "-1. **Think before coding.** a", "+1. **Think before coding.** a b", ""])
    rules, canon, _ = touched(guideline, skill, canon_ids)
    if rules or canon:
        sys.exit(f"SELFTEST FAILED: a guideline hunk touched rules {rules}")
    # Explicit references and canon ids in changed text count wherever they appear, and a
    # reference file maps through the trigger table.
    refs = "\n".join(["--- a/skills/atelier/references/workflow.md", "+++ b/skills/atelier/references/workflow.md",
                      "@@ -1,0 +2,1 @@", "+the disciplines (29, 31) and the eval gate 4.8, unlike 0.9 or 3.28.0", "",
                      "--- a/skills/atelier/references/ai.md", "+++ b/skills/atelier/references/ai.md",
                      "@@ -1,0 +2,1 @@", "+pin the snapshot", ""])
    rules, canon, unmapped = touched(refs, skill, canon_ids)
    if rules != {29, 31, 32} or canon != {"4.8"} or unmapped != ["workflow.md"]:
        sys.exit(f"SELFTEST FAILED: expected rules {{29, 31, 32}}, canon {{'4.8'}}, workflow.md unmapped; got {rules} {canon} {unmapped}")
    picked = pick(tasks, rules, canon)
    if "h6-ai-full" not in picked or "h7-reliability-full" not in picked or "h4-trap-tenant" in picked:
        sys.exit(f"SELFTEST FAILED: rules 29/31/32 plus 4.8 should select h6 and h7, not h4; got {picked}")
    missing = [t["id"] for t in tasks if not t.get("hard_rules")]
    if missing:
        sys.exit(f"SELFTEST FAILED: tasks without hard_rules cannot be selected: {missing}")
    print("selftest OK: rule lines select by section, guideline numbers do not, explicit refs and canon ids count, unmapped references are reported")


def main() -> None:
    args = sys.argv[1:]
    if "--selftest" in args:
        selftest()
        return
    tasks = json.loads((HERE / "tasks.json").read_text())
    canon_ids = {a["rule"] for t in tasks for a in t["assertions"]}
    if "--diff-file" in args:
        diff = Path(args[args.index("--diff-file") + 1]).read_text()
        skill_text = Path(args[args.index("--skill-file") + 1]).read_text()
    elif "--since" in args:
        diff = git_diff(args[args.index("--since") + 1])
        skill_text = (REPO_ROOT / SKILL_DIR / "SKILL.md").read_text()
    else:
        sys.exit(__doc__)
    rules, canon, unmapped = touched(diff, skill_text, canon_ids)
    picked = pick(tasks, rules, canon)
    print(f"touched hard rules: {sorted(rules) or 'none'}; canon ids: {sorted(canon) or 'none'}", file=sys.stderr)
    if unmapped:
        print(f"references with no rule in the trigger table (select nothing; consider tier 2): {', '.join(unmapped)}", file=sys.stderr)
    print(f"selected {len(picked)} of {len(tasks)} tasks", file=sys.stderr)
    for tid in picked:
        print(tid)


if __name__ == "__main__":
    main()
