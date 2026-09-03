#!/usr/bin/env python3
"""Grade conformance runs: mechanical assertions over the code each run produced.

Reads tasks.json (declarative assertions: regex + present/absent + a `rule`, the
global-rules sub-concept the check proves, + optional exclude paths and extension
globs) and applies them to every run directory under the given workspace (default:
the newest conformance workspace). The scorecard reports pass rates per task and
per rule, so a rule id maps straight to its conformance-matrix.md row.

Usage:
    python3 scripts/conformance-eval/grade.py [runs-dir]

A run directory is <runs-dir>/<task-id>-<arm>/ where arm is with_skill or
baseline. Missing directories are reported as ungraded, not failed.
"""

import hashlib
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
FIXTURE_DIR = HERE / "fixture"
FROZEN_DEFAULT = HERE / "baseline-arm.json"
# Content of every scaffolding file a run STARTS with. Grading is a property of
# the agent's contribution only: a run-dir file whose bytes equal its fixture
# original was never touched by the agent, so it must neither satisfy nor violate
# any assertion. Keying on content (not path) still credits files the agent
# MODIFIES. This makes the verdict depend on the produced diff, not on which model
# produced it, and not on scaffolding the fixture happened to ship.
FIXTURE_BASELINE = {
    str(p.relative_to(FIXTURE_DIR)): p.read_text(errors="replace")
    for p in FIXTURE_DIR.rglob("*")
    if p.is_file()
}


COMMENT_PATTERNS = {
    # Strip comments before matching, so prose about a discipline is never
    # credited as its implementation. The line-comment pattern requires the //
    # not be preceded by ':' so URL literals (https://...) survive; a block
    # comment is removed wherever it spans. .sql uses -- to end of line.
    ".ts": (re.compile(r"/\*.*?\*/", re.DOTALL), re.compile(r"(?<!:)//[^\n]*")),
    ".tsx": (re.compile(r"/\*.*?\*/", re.DOTALL), re.compile(r"(?<!:)//[^\n]*")),
    ".java": (re.compile(r"/\*.*?\*/", re.DOTALL), re.compile(r"(?<!:)//[^\n]*")),
    ".sql": (re.compile(r"/\*.*?\*/", re.DOTALL), re.compile(r"--[^\n]*")),
}


def strip_comments(text: str, suffix: str) -> str:
    for pattern in COMMENT_PATTERNS.get(suffix, ()):
        text = pattern.sub("", text)
    return text


def read_sources(run_dir: Path, exts: tuple[str, ...], exclude: set[str]) -> dict[str, str]:
    out = {}
    for p in run_dir.rglob("*"):
        if not p.is_file() or p.suffix not in exts:
            continue
        rel = str(p.relative_to(run_dir))
        # skills/ guards against older run dirs copied from a transiently polluted
        # fixture, which nested whole other-task run trees under skills/.
        if rel.startswith((".claude/", "node_modules/", "skills/")) or rel in exclude:
            continue
        text = p.read_text(errors="replace")
        if FIXTURE_BASELINE.get(rel) == text:
            continue  # unmodified scaffolding, not the agent's work
        # The path is part of the artifact (a 003_contract_*.sql filename IS the
        # contract-phase evidence), so it joins the matchable corpus; comments
        # do not, so prose about a discipline is never credited as code.
        out[rel] = rel + "\n" + strip_comments(text, p.suffix)
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
        marks.append((a["desc"], a.get("rule"), passed))
    return marks


def tasks_hash(tasks: list[dict]) -> str:
    """sha256 of what the baseline arm depends on: prompts and assertions, never hard_rules."""
    canon = [{"id": t["id"], "prompt": t["prompt"], "assertions": t["assertions"]} for t in tasks]
    return hashlib.sha256(json.dumps(canon, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def load_frozen(path: Path, tasks: list[dict]) -> dict | str:
    """The frozen baseline-arm fixture, or the reason it cannot be used. The baseline arm
    never reads the skill, so its results are a fixture keyed to the prompts and assertions
    it was measured against (freeze-baseline.py); a skill edit never invalidates it, an
    assertion edit always does."""
    refreeze = ("re-run the baseline arm (CONFORMANCE_ARMS=baseline bash scripts/conformance-eval/run.sh) "
                "and re-freeze it (python3 scripts/conformance-eval/freeze-baseline.py <runs-dir>)")
    if not path.is_file():
        return f"no frozen baseline at {path}; {refreeze}"
    frozen = json.loads(path.read_text())
    if frozen.get("tasks_sha256") != tasks_hash(tasks):
        return f"the frozen baseline at {path} was measured against a different tasks.json (a prompt or an assertion changed); {refreeze}"
    return frozen


def frozen_expected(frozen: dict, task_id: str, n: int) -> float | None:
    """Expected baseline passes on a task's n assertions: the sum of its frozen per-assertion
    pass rates, so two frozen passes at 1/2 on one assertion count as half a pass."""
    counts = frozen.get("tasks", {}).get(task_id, {}).get("assertions")
    if not counts or len(counts) != n:
        return None
    return sum(p / t for p, t in counts if t)


def selftest() -> None:
    """Prove the grader credits only the agent's diff. A pristine fixture copy
    (no agent work) must satisfy NO assertion in any task: present-mode has no
    agent file to match, absent-mode has no agent file in scope. This is red under
    a grader that scans unmodified scaffolding (the fixture's result.ts alone made
    three present-assertions pass) and green once such files are excluded."""
    tasks = json.loads((HERE / "tasks.json").read_text())
    credited = []
    with tempfile.TemporaryDirectory() as tmp:
        run_dir = Path(tmp) / "fixture-only"
        shutil.copytree(FIXTURE_DIR, run_dir)
        for task in tasks:
            for desc, rule, passed in grade_run(run_dir, task["assertions"]):
                if passed:
                    credited.append(f"{task['id']}: {desc}")
    if credited:
        print("SELFTEST FAILED: a pristine fixture copy was credited for work it did not do:")
        for c in credited:
            print(f"  {c}")
        sys.exit(1)

    # Second scenario: prose in comments must not satisfy code assertions. An
    # agent file whose only assertion-matching text lives in comments (a TODO
    # naming AbortSignal, a commented-out ok: false) describes the discipline
    # without implementing it; matching raw text credits it. Also pins that a
    # URL's // survives stripping and real code on such a line still matches.
    a3 = next(task for task in tasks if task["id"] == "a3-http-adapter")
    with tempfile.TemporaryDirectory() as tmp:
        run_dir = Path(tmp) / "comment-only"
        shutil.copytree(FIXTURE_DIR, run_dir)
        agent_file = run_dir / "src" / "infra" / "billing-http.ts"
        agent_file.parent.mkdir(parents=True, exist_ok=True)
        agent_file.write_text(
            "// TODO: add AbortSignal.timeout and return ok: false via Result<PlanTier, E>\n"
            "/* the adapter should sit behind ports/billing.ts with a Fake */\n"
            "export const placeholder = 1;\n"
        )
        comment_credited = [d for d, _r, passed in grade_run(run_dir, a3["assertions"]) if passed]
        if comment_credited:
            print("SELFTEST FAILED: comment-only content was credited as implementation:")
            for c in comment_credited:
                print(f"  {c}")
            sys.exit(1)
        agent_file.write_text(
            "const DOCS = 'https://example.com/api'; // per the vendor docs\n"
            "export const fetchPlan = async (s: AbortSignal): Promise<Result<PlanTier, E>> =>\n"
            "  fetch(DOCS, { signal: AbortSignal.timeout(5000) }).then((r) => ({ ok: false as const, error: r.status }));\n"
        )
        code_hits = [d for d, _r, passed in grade_run(run_dir, a3["assertions"]) if passed]
        if len(code_hits) < 2:
            print(f"SELFTEST FAILED: real code on a line carrying a URL // stopped matching: {code_hits}")
            sys.exit(1)

    # Third scenario: a file's PATH is part of the produced artifact. A staged
    # migration says "contract phase" through its filename (003_contract_*.sql);
    # after comment stripping that is the only honest evidence left, so the
    # matcher must see path + content, not content alone.
    e9 = next(task for task in tasks if task["id"] == "e9-migration")
    contract = next(a for a in e9["assertions"] if "contract" in a["pattern"])
    with tempfile.TemporaryDirectory() as tmp:
        run_dir = Path(tmp) / "path-evidence"
        shutil.copytree(FIXTURE_DIR, run_dir)
        mig = run_dir / "db" / "migrations" / "003_contract_receipts_drop_amount.sql"
        mig.parent.mkdir(parents=True, exist_ok=True)
        mig.write_text("ALTER TABLE receipts DROP COLUMN amount;\n")
        marks = {d: passed for d, _r, passed in grade_run(run_dir, [contract])}
        if not all(marks.values()):
            print(f"SELFTEST FAILED: a 003_contract_* migration filename was not accepted as contract-step evidence: {marks}")
            sys.exit(1)

    # Fourth scenario: shape over vocabulary. 4.8 credits an eval set that carries a
    # bar wherever it lives (a scripts/*.ts runner, a package.json script), never a
    # file that merely "evaluates" something and reports a score, and never an eval
    # set with no bar. 7.5 credits the list-endpoint shape (a forged or other-owner
    # scenario) as well as the single-resource 404, never a same-owner-only test.
    # The 2026-09-03 reruns lost an hour per pass to the word-boundary version of
    # 4.8 (`evals/` + `run-evals.ts --min-score` scored 0) and to a 404 demanded of
    # a list endpoint that cannot produce one.
    h6 = next(task for task in tasks if task["id"] == "h6-ai-full")
    eval_gate = next(a for a in h6["assertions"] if a["rule"] == "4.8")
    h4 = next(task for task in tasks if task["id"] == "h4-trap-tenant")
    absence = next(a for a in h4["assertions"] if a["rule"] == "7.5")
    shapes = [
        ("4.8 runner with a bar", "scripts/run-evals.ts",
         "const bar = minScoreFrom(process.argv);\nif (passed / cases.length < bar) process.exit(1);\n", eval_gate, True),
        ("4.8 package.json script with a bar", "package.json",
         '{ "scripts": { "evals": "bun run scripts/check-summaries.ts --min-score 0.9" } }\n', eval_gate, True),
        ("4.8 evaluate plus score, no eval set", "src/use-cases/summarize.ts",
         "export const evaluate = (score: number): boolean => score >= 0.5;\n", eval_gate, False),
        ("4.8 eval set with no bar", "evals/cases.json",
         '[{ "thread": "t1", "expected": "gist" }]\n', eval_gate, False),
        ("7.5 forged-owner scenario", "src/infra/http/invoices.test.ts",
         "it('when the caller forges another organisation id, only their own invoices come back', () => {});\n", absence, True),
        ("7.5 single-resource 404", "src/infra/http/invoices.test.ts",
         "it('returns 404 for an invoice of a different organisation', () => {});\n", absence, True),
        ("7.5 same-owner only", "src/infra/http/invoices.test.ts",
         "it('lists the invoices of the signed-in organisation', () => {});\n", absence, False),
    ]
    for label, rel, body, assertion, want in shapes:
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp) / "shape"
            shutil.copytree(FIXTURE_DIR, run_dir)
            artifact = run_dir / rel
            artifact.parent.mkdir(parents=True, exist_ok=True)
            artifact.write_text(body)
            ((_d, _r, got),) = grade_run(run_dir, [assertion])
            if got != want:
                print(f"SELFTEST FAILED: {label}: expected {'pass' if want else 'fail'}, got {'pass' if got else 'fail'}")
                sys.exit(1)

    # Fifth scenario: the frozen baseline arm is keyed to the assertions it was measured
    # against. A fixture frozen against another tasks.json is refused with the re-freeze
    # command; a matching one yields the expected count as the sum of per-assertion rates.
    with tempfile.TemporaryDirectory() as tmp:
        fx = Path(tmp) / "baseline-arm.json"
        fx.write_text(json.dumps({"tasks_sha256": "0" * 64, "tasks": {}}))
        verdict = load_frozen(fx, tasks)
        if not isinstance(verdict, str) or "re-freeze" not in verdict:
            print("SELFTEST FAILED: a frozen baseline measured against another tasks.json was accepted")
            sys.exit(1)
        fx.write_text(json.dumps({"tasks_sha256": tasks_hash(tasks), "passes": 2,
                                  "tasks": {"h4-trap-tenant": {"assertions": [[2, 2], [1, 2], [0, 2]]}}}))
        frozen = load_frozen(fx, tasks)
        if isinstance(frozen, str) or frozen_expected(frozen, "h4-trap-tenant", 3) != 1.5 or frozen_expected(frozen, "h6-ai-full", 5) is not None:
            print("SELFTEST FAILED: the frozen expected count is not the sum of per-assertion rates")
            sys.exit(1)

    print("selftest OK: a pristine fixture copy scores 0, comments are not implementation, URLs survive stripping, paths count as evidence, 4.8 and 7.5 credit shape over vocabulary, the frozen baseline is keyed to its assertions")


def _flag_val(args: list[str], name: str) -> int | None:
    """Read --name=N or --name N as an int, or None if absent."""
    for i, a in enumerate(args):
        if a == name and i + 1 < len(args):
            return int(args[i + 1])
        if a.startswith(name + "="):
            return int(a.split("=", 1)[1])
    return None


def main() -> None:
    args = sys.argv[1:]
    if "--selftest" in args:
        selftest()
        return
    # Phase 4 eval gate: block below the recorded baseline (scripts/conformance-eval/baseline.md).
    min_ws = _flag_val(args, "--min-with-skill")
    min_delta = _flag_val(args, "--min-delta")
    # --frozen-baseline[=path]: compare the skill arm to the frozen baseline arm instead of
    # (or next to) baseline run dirs; the default fixture is baseline-arm.json here.
    frozen_path = None
    for a in args:
        if a == "--frozen-baseline":
            frozen_path = FROZEN_DEFAULT
        elif a.startswith("--frozen-baseline="):
            frozen_path = Path(a.split("=", 1)[1])
    positional = [a for a in args if not a.startswith("--") and not a.lstrip("-").isdigit()]
    runs_dir = Path(positional[0]) if positional else None
    if runs_dir is None:
        workspaces = sorted(Path("skills/atelier-workspace").glob("conformance-*/runs"))
        if not workspaces:
            sys.exit("no conformance workspace found; pass the runs dir explicitly")
        runs_dir = workspaces[-1]

    tasks = json.loads((HERE / "tasks.json").read_text())
    frozen = None
    if frozen_path is not None:
        frozen = load_frozen(frozen_path, tasks)
        if isinstance(frozen, str):
            sys.exit(f"FROZEN BASELINE UNUSABLE: {frozen}")
    grand = {"with_skill": [0, 0], "baseline": [0, 0]}
    frozen_grand = [0.0, 0]  # expected baseline passes, assertions covered by the fixture
    # by_rule[rule][arm] = [passed, total], so the scorecard maps to conformance-matrix rows
    by_rule: dict[str, dict[str, list[int]]] = {}
    for task in tasks:
        rows = []
        for arm in ("with_skill", "baseline"):
            run_dir = runs_dir / f"{task['id']}-{arm}"
            if not run_dir.is_dir():
                rows.append((arm, None))
                continue
            marks = grade_run(run_dir, task["assertions"])
            grand[arm][0] += sum(1 for _, _, p in marks if p)
            grand[arm][1] += len(marks)
            for _, rule, passed in marks:
                if rule is None:
                    continue
                slot = by_rule.setdefault(rule, {"with_skill": [0, 0], "baseline": [0, 0]})
                slot[arm][0] += 1 if passed else 0
                slot[arm][1] += 1
            rows.append((arm, marks))
        if all(marks is None for _, marks in rows):
            continue
        print(f"\n{task['id']}:")
        for arm, marks in rows:
            if marks is None:
                print(f"  {arm:<11} (no run)")
                continue
            score = sum(1 for _, _, p in marks if p)
            detail = "  ".join(("PASS" if p else "fail") + f"[{r}]:{d[:30]}" for d, r, p in marks)
            print(f"  {arm:<11} {score}/{len(marks)}  {detail}")
            if frozen is not None and arm == "with_skill":
                expected = frozen_expected(frozen, task["id"], len(marks))
                if expected is None:
                    print(f"  {'frozen-bl':<11} (no frozen data for this task)")
                else:
                    frozen_grand[0] += expected
                    frozen_grand[1] += len(marks)
                    print(f"  {'frozen-bl':<11} {expected:.1f}/{len(marks)}")

    print("\nTOTALS (graded runs only):")
    for arm, (p, t) in grand.items():
        print(f"  {arm:<11} {p}/{t}")
    if frozen is not None:
        print(f"  {'frozen-bl':<11} {frozen_grand[0]:.1f}/{frozen_grand[1]}  "
              f"({frozen.get('passes', '?')} pass(es) frozen {frozen.get('frozen', '?')}, {frozen.get('model', '?')})")

    if by_rule:
        print("\nBY RULE (the global-rules sub-concept each check proves; with_skill vs baseline):")
        for rule in sorted(by_rule, key=lambda r: [int(n) for n in r.split(".")]):
            ws, bl = by_rule[rule]["with_skill"], by_rule[rule]["baseline"]
            print(f"  {rule:<6} with_skill {ws[0]}/{ws[1]}   baseline {bl[0]}/{bl[1]}")

    # Phase 4 eval gate: exit non-zero below the recorded baseline (see baseline.md).
    if min_ws is not None or min_delta is not None:
        ws_p, bl_p = grand["with_skill"][0], grand["baseline"][0]
        # A live baseline arm wins when it was graded; otherwise the frozen arm stands in,
        # over the assertions it covers.
        if grand["baseline"][1] == 0 and frozen is not None:
            bl_p = frozen_grand[0]
            ws_p = sum(1 for task in tasks for _d, _r, p in (
                grade_run(runs_dir / f"{task['id']}-with_skill", task["assertions"])
                if (runs_dir / f"{task['id']}-with_skill").is_dir() and frozen_expected(frozen, task["id"], len(task["assertions"])) is not None else []) if p)
        delta = ws_p - bl_p
        fails = []
        if min_ws is not None and ws_p < min_ws:
            fails.append(f"with_skill {ws_p} < required {min_ws}")
        if min_delta is not None and delta < min_delta:
            fails.append(f"delta +{delta:g} < required +{min_delta}")
        if fails:
            print("\nEVAL GATE FAILED:")
            for f in fails:
                print(f"  {f}")
            sys.exit(1)
        source = "vs the frozen baseline arm" if grand["baseline"][1] == 0 and frozen is not None else "vs the live baseline arm"
        print(f"\nEVAL GATE OK: with_skill {ws_p}, delta +{delta:g} {source}")


if __name__ == "__main__":
    main()
