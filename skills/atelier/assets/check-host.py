#!/usr/bin/env python3
"""Hard rule 38's host half: the settings git alone cannot hold, checked on GitHub.

Rule 38 lands a branch by rebase, deletes it the moment it lands, and lets nobody delete main,
force-push it or put a merge commit on it. Git enforces none of that; the host does once its owner
sets it, and a setting set by hand drifts unseen. This check reads the repository on GitHub and
fails on each finding:

  DEFAULT  the default branch is not main;
  RULE     main lacks an active rule of a type the ruleset file lists (host-ruleset.json as
           shipped: deletion, non_fast_forward, required_linear_history);
  MERGE    merge commits or squash merges are allowed, rebase merges are not, or a merged head
           branch is not deleted automatically.

It needs read access only. GitHub's REST API hides the merge settings from a read-only token, so
they come from GraphQL, which shows them (probed 2026-10-15); a setting GitHub still does not show
is an error, never a pass. HOST_RULESET=unavailable is for a private repository on GitHub Free,
which cannot hold a ruleset: main's missing rules are then reported, not failed, and the opt-out
itself fails on a repository that is not private.

  python3 scripts/check-host.py             check (the shipped branches.yml runs it daily)
  python3 scripts/check-host.py --selftest  prove it fails on each drift

Env: GITHUB_REPOSITORY (owner/name; default: gh repo view), GH_TOKEN (gh's own), RULESET (default:
host-ruleset.json beside this script), HOST_RULESET. Exit 0 passes, 1 is a finding, 2 is a host or
ruleset it could not read, never a pass. Needs python3 and gh.
"""
from __future__ import annotations

import contextlib
import io
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

RULE = "Hard rule 38 (references/workflow.md, Branch lifecycle)."
# Each merge setting: its REST name, its GraphQL name (what the check reads) and the value rule 38
# wants.
MERGE = {
    "allow_merge_commit": ("mergeCommitAllowed", False),
    "allow_squash_merge": ("squashMergeAllowed", False),
    "allow_rebase_merge": ("rebaseMergeAllowed", True),
    "delete_branch_on_merge": ("deleteBranchOnMerge", True),
}


class HostError(Exception):
    """The host or the ruleset file could not be read: exit 2, never a pass."""


class GitHub:
    """The repository as gh sees it. The selftest swaps in a fake with the same methods."""

    def __init__(self, repo: str) -> None:
        self.repo = repo

    def _api(self, *args: str) -> object:
        try:
            done = subprocess.run(["gh", "api", *args], capture_output=True, text=True, encoding="utf-8")
        except FileNotFoundError:
            raise HostError("gh is not on PATH (https://cli.github.com)") from None
        if done.returncode != 0:
            raise HostError(f"gh api {args[0]}: {(done.stderr or done.stdout).strip()}")
        return json.loads(done.stdout) if done.stdout.strip() else None

    def settings(self) -> dict:
        owner, name = self.repo.split("/", 1)
        fields = " ".join(graphql for graphql, _ in MERGE.values())
        query = ("query($owner: String!, $name: String!) { repository(owner: $owner, name: $name) "
                 f"{{ defaultBranchRef {{ name }} isPrivate {fields} }} }}")
        data = self._api("graphql", "-f", f"query={query}", "-f", f"owner={owner}", "-f", f"name={name}")
        repo = ((data or {}).get("data") or {}).get("repository") if isinstance(data, dict) else None
        if not repo:
            raise HostError(f"GitHub returned no repository {self.repo}: {json.dumps(data)[:200]}")
        return {"default": (repo.get("defaultBranchRef") or {}).get("name"), "private": repo.get("isPrivate"),
                **{rest: repo.get(graphql) for rest, (graphql, _) in MERGE.items()}}

    def rules_on_main(self) -> set:
        return {rule.get("type") for rule in self._api(f"repos/{self.repo}/rules/branches/main") or []}



def load_ruleset(path: Path) -> dict:
    """The ruleset main is held to. A file naming no rule would pass every repository: an error."""
    try:
        body = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise HostError(f"cannot read the ruleset {path}: {error}") from None
    rules = body.get("rules") if isinstance(body, dict) else None
    kinds = [rule.get("type") for rule in rules or [] if isinstance(rule, dict)]
    if not kinds or not body.get("name") or not all(isinstance(kind, str) and kind for kind in kinds):
        raise HostError(f"the ruleset {path} names no rule to hold main to")
    return body


def opted_out(value: str) -> bool:
    if value not in ("", "unavailable"):
        raise HostError(f"HOST_RULESET is {value!r}: unset, or unavailable for a private repository on GitHub Free")
    return value == "unavailable"


def check(host: GitHub, ruleset: dict, opt_out: bool) -> tuple[list, list]:
    """Findings, each failing the run, and notes, named but never failing (the opt-out's rules)."""
    seen = host.settings()
    findings, notes = [], []
    if seen["default"] != "main":
        findings.append(f"DEFAULT  the default branch is {seen['default']}, not main")
    active = host.rules_on_main()
    for kind in (rule["type"] for rule in ruleset["rules"]):
        if kind not in active:
            (notes if opt_out else findings).append(f"RULE  main has no active {kind} rule")
    if opt_out and seen["private"] is not True:
        findings.append("RULE  HOST_RULESET=unavailable on a repository that is not private, which can hold a ruleset")
    for rest, (graphql, wanted) in MERGE.items():
        if not isinstance(seen[rest], bool):
            raise HostError(f"GitHub did not show {graphql} to this token, so {rest} cannot be checked")
        if seen[rest] is not wanted:
            findings.append(f"MERGE  {rest} is {json.dumps(seen[rest])}, rule 38 wants {json.dumps(wanted)}")
    return findings, notes


def run(host: GitHub, ruleset: dict, opt_out: bool) -> int:
    findings, notes = check(host, ruleset, opt_out)
    for note in notes:
        print(f"  · {note}, reported only (HOST_RULESET=unavailable)")
    if findings:
        for finding in findings:
            print(f"  ╳ {finding}", file=sys.stderr)
        print(f"\n  {len(findings)} finding(s) on {host.repo}.\n  {RULE}", file=sys.stderr)
        return 1
    held = "unprotected, by its owner's opt-out" if notes else "protected by the ruleset"
    print(f"check-host: {host.repo}: main is the default branch, {held}; rebase merges only, "
          "head branches deleted on merge")
    return 0


def current_repo() -> str:
    try:
        done = subprocess.run(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"],
                              capture_output=True, text=True, encoding="utf-8")
    except FileNotFoundError:
        done = None
    if done is None or done.returncode != 0 or "/" not in done.stdout:
        raise HostError("cannot tell which repository to check: set GITHUB_REPOSITORY=owner/name")
    return done.stdout.strip()


def main(argv: list[str]) -> int:
    # The findings carry a box-drawing cross, which a cp1252 console cannot print (2026-10-09).
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")
    if argv == ["--selftest"]:
        return selftest()
    if argv and argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    if argv:
        print("usage: check-host.py [--selftest]", file=sys.stderr)
        return 2
    try:
        opt_out = opted_out(os.environ.get("HOST_RULESET", ""))
        ruleset = load_ruleset(Path(os.environ.get("RULESET") or Path(__file__).resolve().parent / "host-ruleset.json"))
        host = GitHub(os.environ.get("GITHUB_REPOSITORY") or current_repo())
        return run(host, ruleset, opt_out)
    except HostError as error:
        print(f"check-host: {error}", file=sys.stderr)
        return 2


class FakeGitHub:
    """A repository in memory. Its rules sit on the default branch, as the ruleset targets it."""

    def __init__(self, default: str = "main", private: bool = False, rules: tuple = (),
                 merge: dict | None = None) -> None:
        self.repo, self.default, self.private, self.rules = "acme/widget", default, private, set(rules)
        self.merge = dict(merge if merge is not None else {rest: want for rest, (_, want) in MERGE.items()})

    def settings(self) -> dict:
        return {"default": self.default, "private": self.private, **self.merge}

    def rules_on_main(self) -> set:
        return set(self.rules) if self.default == "main" else set()



def selftest() -> int:
    failures: list[str] = []
    ruleset = load_ruleset(Path(__file__).resolve().parent / "host-ruleset.json")
    kinds = [rule["type"] for rule in ruleset["rules"]]
    good = {rest: want for rest, (_, want) in MERGE.items()}

    def outcome(host: FakeGitHub, opt_out: bool = False) -> tuple[int, str]:
        said = io.StringIO()
        with contextlib.redirect_stdout(said), contextlib.redirect_stderr(said):
            try:
                code = run(host, ruleset, opt_out)
            except HostError as error:
                print(f"check-host: {error}")
                code = 2
        return code, said.getvalue()

    def expect(what: str, got: tuple[int, str], code: int, *held: str, absent: tuple = ()) -> None:
        if got[0] != code or any(text not in got[1] for text in held) or any(text in got[1] for text in absent):
            failures.append(f"{what}: exit {got[0]}, wanted {code}:\n{got[1]}")

    # Each drift fails for its own reason, and a setting GitHub does not show is an error, not a pass.
    expect("a held repository", outcome(FakeGitHub(rules=kinds)), 0, "protected by the ruleset")
    expect("master as the default", outcome(FakeGitHub("master", rules=kinds)), 1,
           "DEFAULT  the default branch is master")
    expect("no ruleset", outcome(FakeGitHub()), 1, *(f"no active {kind} rule" for kind in kinds))
    for kind in kinds:
        expect(f"main without {kind}", outcome(FakeGitHub(rules=[k for k in kinds if k != kind])), 1,
               f"no active {kind} rule", absent=tuple(f"no active {k} rule" for k in kinds if k != kind))
    for rest, (graphql, want) in MERGE.items():
        expect(f"{rest} flipped", outcome(FakeGitHub(rules=kinds, merge={**good, rest: not want})), 1,
               f"MERGE  {rest} is {json.dumps(not want)}")
        expect(f"{rest} not shown", outcome(FakeGitHub(rules=kinds, merge={**good, rest: None})), 2,
               f"did not show {graphql}")
    expect("the opt-out on a private repository", outcome(FakeGitHub(private=True), opt_out=True), 0,
           "reported only", "unprotected")
    expect("the opt-out on a public repository", outcome(FakeGitHub(), opt_out=True), 1, "not private")

    # The inputs: an opt-out value that means nothing, and ruleset files that hold main to nothing.
    try:
        opted_out("none")
        failures.append("HOST_RULESET=none was accepted")
    except HostError:
        pass
    with tempfile.TemporaryDirectory() as tmp:
        for text in ('{"name": "main", "rules": []}', '{"rules": [{"type": "deletion"}]}', "[]", "not json"):
            (Path(tmp) / "ruleset.json").write_text(text, encoding="utf-8")
            try:
                load_ruleset(Path(tmp) / "ruleset.json")
                failures.append(f"the ruleset {text!r} was accepted")
            except HostError:
                pass

    # The real class: the commands gh receives, with subprocess.run stubbed. The GraphQL answer is
    # the probe's for this skill's repository (2026-10-15): GitHub's defaults, three findings.
    calls: list = []
    answers = {
        "graphql": '{"data": {"repository": {"defaultBranchRef": {"name": "main"}, "isPrivate": false, '
                   '"rebaseMergeAllowed": true, "squashMergeAllowed": true, "mergeCommitAllowed": true, '
                   '"deleteBranchOnMerge": false}}}',
        "repos/acme/widget/rules/branches/main": '[{"type": "deletion"}]',
    }

    def stub(cmd: list, input: str | None = None, **_: object) -> subprocess.CompletedProcess:
        calls.append((cmd[2:], input))
        return subprocess.CompletedProcess(cmd, 0, answers.get(cmd[2], ""), "")

    real, subprocess.run = subprocess.run, stub
    try:
        host = GitHub("acme/widget")
        seen = host.settings()
        if seen != {"default": "main", "private": False, **{rest: rest != "delete_branch_on_merge" for rest in MERGE}}:
            failures.append(f"the probe's GraphQL answer read as {seen}")
        findings, _ = check(host, ruleset, False)
        if len(findings) != 5:
            failures.append(f"the probe's answer gave {len(findings)} findings, wanted 5: {findings}")
    finally:
        subprocess.run = real
    sent = [(args[:4] if args[0] == "-X" else args[:1], json.loads(body) if body else None) for args, body in calls]
    wanted = [
        (["graphql"], None), (["graphql"], None), (["repos/acme/widget/rules/branches/main"], None),
    ]
    if sent != wanted:
        failures.append("gh received:\n" + "\n".join(map(str, sent)))
    # GitHub's names, spelled once more: the probe's answer is true for three of them, so a swap
    # between those would read the same.
    spelled = {"allow_merge_commit": "mergeCommitAllowed", "allow_squash_merge": "squashMergeAllowed",
               "allow_rebase_merge": "rebaseMergeAllowed", "delete_branch_on_merge": "deleteBranchOnMerge"}
    if {rest: graphql for rest, (graphql, _) in MERGE.items()} != spelled:
        failures.append(f"the merge settings map to {MERGE}, not GitHub's names")
    query = next(args for args, _ in calls if args[0] == "graphql")
    if not all(f"{graphql} " in query[2] for graphql, _ in MERGE.values()) or query[3:] != ["-f", "owner=acme", "-f", "name=widget"]:
        failures.append(f"the GraphQL call was {query}")

    for failure in failures:
        print(f"check-host.py --selftest: {failure}")
    if failures:
        return 1
    print("check-host.py --selftest: each drift fails for its own reason (the default branch, each rule, each "
          "merge setting), a setting GitHub does not show and a ruleset naming no rule are errors, the opt-out "
          "holds only on a private repository, and gh receives the documented calls")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
