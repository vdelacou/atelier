#!/usr/bin/env python3
# Trigger-eval runner for the atelier skill suite.
#
# Provenance: adapted from the skill-creator plugin's scripts/run_eval.py with
# three fixes found 2026-07-11 (see .claude/LESSONS.md, "stock trigger-eval
# runner false-zeros with fable"):
#   1. Detection watches the WHOLE stream until the result event instead of
#      concluding on the first tool call (Fable explores before consulting).
#   2. Each probe runs in an ISOLATED temp project root (fixture copied in,
#      exactly one synthetic skill), so parallel probes never see each other's
#      clones through a shared .claude/commands.
#   3. Default timeout raised; pass --timeout 90 for thinking models.
#
# Self-contained: the skill-creator import is inlined below.
# Usage: see run.sh next to this file.


import argparse
import json
import os
import select
import shutil
import subprocess
import tempfile
import sys
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path


def parse_skill_md(skill_path):
    """Minimal inline replacement for skill-creator's scripts.utils.parse_skill_md.

    Returns (name, description, content) like the original. Assumes single-line
    frontmatter values, which every skill in this repo uses.
    """
    text = (Path(skill_path) / "SKILL.md").read_text()
    if not text.startswith("---\n"):
        raise ValueError("SKILL.md has no frontmatter")
    end = text.index("\n---", 4)
    meta = {}
    for line in text[4:end].splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            meta[key.strip()] = value.strip()
    return meta.get("name", ""), meta.get("description", ""), text[end + 4 :]



def find_project_root() -> Path:
    """Find the project root by walking up from cwd looking for .claude/.

    Mimics how Claude Code discovers its project root, so the command file
    we create ends up where claude -p will look for it.
    """
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / ".claude").is_dir():
            return parent
    return current


def run_single_query(
    query: str,
    skills: list[tuple[str, str]],
    timeout: int,
    project_root: str,
    model: str | None = None,
) -> str | None:
    """Run a single query; return the base name of the first suite skill invoked, or None.

    Registers one synthetic command per (base_name, description) pair so they all
    appear in Claude's available_skills list, then runs `claude -p` with the raw
    query. With a single-entry list this is the classic does-it-trigger probe;
    with the full suite it measures ROUTING: which skill wins the query.
    Uses --include-partial-messages to detect invocation early from stream events.
    """
    unique_id = uuid.uuid4().hex[:8]
    synthetic = {f"{base}-skill-{unique_id}": base for base, _ in skills}
    # patched: isolate each probe in its own project root. With a shared
    # .claude/commands, concurrent probes see each other's synthetic skill
    # clones, the model picks another probe's copy, and every detector misses.
    isolated_root = Path(tempfile.mkdtemp(prefix="trigger-probe-"))
    fixture = Path(project_root)
    for item in fixture.iterdir():
        if item.name == ".claude":
            continue
        if item.is_dir():
            shutil.copytree(item, isolated_root / item.name)
        else:
            shutil.copy2(item, isolated_root / item.name)
    project_root = str(isolated_root)
    project_commands_dir = Path(project_root) / ".claude" / "commands"

    def invoked_in(text: str) -> str | None:
        for full_name, base in synthetic.items():
            if full_name in text:
                return base
        return None

    try:
        project_commands_dir.mkdir(parents=True, exist_ok=True)
        for (base, desc), full_name in zip(skills, synthetic.keys()):
            # Use YAML block scalar to avoid breaking on quotes in description
            indented_desc = "\n  ".join(desc.split("\n"))
            (project_commands_dir / f"{full_name}.md").write_text(
                f"---\n"
                f"description: |\n"
                f"  {indented_desc}\n"
                f"---\n\n"
                f"# {base}\n\n"
                f"This skill handles: {desc}\n"
            )

        cmd = [
            "claude",
            "-p", query,
            "--output-format", "stream-json",
            "--verbose",
            "--include-partial-messages",
        ]
        if model:
            cmd.extend(["--model", model])

        # Remove CLAUDECODE env var to allow nesting claude -p inside a
        # Claude Code session. The guard is for interactive terminal conflicts;
        # programmatic subprocess usage is safe.
        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            cwd=project_root,
            env=env,
        )

        invoked: str | None = None
        start_time = time.time()
        buffer = ""
        # Track state for stream event detection
        pending_tool_name = None
        accumulated_json = ""

        try:
            while time.time() - start_time < timeout:
                if process.poll() is not None:
                    remaining = process.stdout.read()
                    if remaining:
                        buffer += remaining.decode("utf-8", errors="replace")
                    break

                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue

                chunk = os.read(process.stdout.fileno(), 8192)
                if not chunk:
                    break
                buffer += chunk.decode("utf-8", errors="replace")

                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue

                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    # Early detection via stream events
                    if event.get("type") == "stream_event":
                        se = event.get("event", {})
                        se_type = se.get("type", "")

                        if se_type == "content_block_start":
                            cb = se.get("content_block", {})
                            if cb.get("type") == "tool_use":
                                tool_name = cb.get("name", "")
                                if tool_name in ("Skill", "Read"):
                                    pending_tool_name = tool_name
                                    accumulated_json = ""
                                else:
                                    pending_tool_name = None  # patched: keep watching later tool calls

                        elif se_type == "content_block_delta" and pending_tool_name:
                            delta = se.get("delta", {})
                            if delta.get("type") == "input_json_delta":
                                accumulated_json += delta.get("partial_json", "")
                                hit = invoked_in(accumulated_json)
                                if hit:
                                    return hit

                        elif se_type in ("content_block_stop", "message_stop"):
                            if pending_tool_name:
                                hit = invoked_in(accumulated_json)
                                if hit:
                                    return hit
                                pending_tool_name = None  # patched: that block was not ours; keep watching

                    # Fallback: full assistant message
                    elif event.get("type") == "assistant":
                        message = event.get("message", {})
                        for content_item in message.get("content", []):
                            if content_item.get("type") != "tool_use":
                                continue
                            tool_name = content_item.get("name", "")
                            tool_input = content_item.get("input", {})
                            if tool_name == "Skill":
                                hit = invoked_in(tool_input.get("skill", ""))
                                if hit:
                                    return hit
                            if tool_name == "Read":
                                hit = invoked_in(tool_input.get("file_path", ""))
                                if hit:
                                    return hit

                    elif event.get("type") == "result":
                        return invoked
        finally:
            # Clean up process on any exit path (return, exception, timeout)
            if process.poll() is None:
                process.kill()
                process.wait()

        return invoked
    finally:
        shutil.rmtree(isolated_root, ignore_errors=True)


def run_eval(
    eval_set: list[dict],
    skills: list[tuple[str, str]],
    num_workers: int,
    timeout: int,
    project_root: Path,
    runs_per_query: int = 1,
    trigger_threshold: float = 0.5,
    model: str | None = None,
) -> dict:
    """Run the full eval set and return results.

    Case semantics:
      should_trigger=false          : pass when NO registered skill is invoked.
      should_trigger=true           : pass when ANY registered skill is invoked.
      should_trigger=true + expected_skill : pass only when THAT skill wins
                                     (routing mode; needs the suite registered).
    """
    results = []

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    skills,
                    timeout,
                    str(project_root),
                    model,
                )
                future_to_info[future] = (item, run_idx)

        query_invocations: dict[str, list[str | None]] = {}
        query_items: dict[str, dict] = {}
        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            query = item["query"]
            query_items[query] = item
            if query not in query_invocations:
                query_invocations[query] = []
            try:
                query_invocations[query].append(future.result())
            except Exception as e:
                print(f"Warning: query failed: {e}", file=sys.stderr)
                query_invocations[query].append(None)

    for query, invocations in query_invocations.items():
        item = query_items[query]
        should_trigger = item["should_trigger"]
        expected = item.get("expected_skill")
        if expected:
            hits = sum(1 for inv in invocations if inv == expected)
        else:
            hits = sum(1 for inv in invocations if inv is not None)
        trigger_rate = hits / len(invocations)
        did_pass = (trigger_rate >= trigger_threshold) == should_trigger
        distribution: dict[str, int] = {}
        for inv in invocations:
            key = inv or "(none)"
            distribution[key] = distribution.get(key, 0) + 1
        result = {
            "query": query,
            "should_trigger": should_trigger,
            "trigger_rate": trigger_rate,
            "triggers": hits,
            "runs": len(invocations),
            "invoked": distribution,
            "pass": did_pass,
        }
        if expected:
            result["expected_skill"] = expected
        results.append(result)

    passed = sum(1 for r in results if r["pass"])
    total = len(results)

    return {
        "skills": [base for base, _ in skills],
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Run trigger evaluation for a skill description")
    parser.add_argument("--eval-set", required=True, help="Path to eval set JSON file")
    parser.add_argument("--skill-path", required=True, help="Path to the primary skill directory")
    parser.add_argument("--suite", default=None, help="Comma-separated extra skill dirs to register alongside --skill-path (routing mode)")
    parser.add_argument("--description", default=None, help="Override the primary skill's description")
    parser.add_argument("--num-workers", type=int, default=10, help="Number of parallel workers")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout per query in seconds")
    parser.add_argument("--runs-per-query", type=int, default=3, help="Number of runs per query")
    parser.add_argument("--trigger-threshold", type=float, default=0.5, help="Trigger rate threshold")
    parser.add_argument("--model", default=None, help="Model to use for claude -p (default: user's configured model)")
    parser.add_argument("--verbose", action="store_true", help="Print progress to stderr")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)

    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    name, original_description, content = parse_skill_md(skill_path)
    description = args.description or original_description
    skills = [(name, description)]
    if args.suite:
        for extra in args.suite.split(","):
            extra_path = Path(extra.strip())
            if not (extra_path / "SKILL.md").exists():
                print(f"Error: No SKILL.md found at {extra_path}", file=sys.stderr)
                sys.exit(1)
            extra_name, extra_desc, _ = parse_skill_md(extra_path)
            skills.append((extra_name, extra_desc))
    project_root = find_project_root()

    if args.verbose:
        print(f"Evaluating {len(skills)} skill(s): {', '.join(base for base, _ in skills)}", file=sys.stderr)

    output = run_eval(
        eval_set=eval_set,
        skills=skills,
        num_workers=args.num_workers,
        timeout=args.timeout,
        project_root=project_root,
        runs_per_query=args.runs_per_query,
        trigger_threshold=args.trigger_threshold,
        model=args.model,
    )

    if args.verbose:
        summary = output["summary"]
        print(f"Results: {summary['passed']}/{summary['total']} passed", file=sys.stderr)
        for r in output["results"]:
            status = "PASS" if r["pass"] else "FAIL"
            rate_str = f"{r['triggers']}/{r['runs']}"
            want = r.get("expected_skill") or r["should_trigger"]
            print(f"  [{status}] rate={rate_str} expected={want} invoked={r['invoked']}: {r['query'][:60]}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
