#!/usr/bin/env python3
"""Grade a review-eval run: which planted violations did the review catch?

Each run directory holds `.review.txt`, the reviewing agent's full output.
`violations.json` lists the planted violations (id, file, rule, evidence regex);
`clean-files.json` lists changed files that carry NO violation, for the
false-positive lens.

Scoring, per violation, at paragraph granularity (blank-line separated):
  caught      the review has a paragraph naming the file's basename AND matching
              the violation's evidence regex (arm-neutral: no rule number needed,
              so a skill-less reviewer can score).
  rule_cited  caught, and that paragraph also cites the violation's rule number
              (the skill's added precision of language).
False positive: a SENTENCE that names a clean file's basename and asserts a
rule number against it (paragraph granularity miscounts exonerations).

    python3 scripts/review-eval/grade.py <runs-dir>     # grades every */-arm dir
    python3 scripts/review-eval/grade.py --selftest     # prove the grader can fail

The selftest is wired into CI (`review-eval grader selftest`), the same pattern
as the conformance grader: a grader that cannot fail proves nothing.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from posixpath import basename

HERE = Path(__file__).parent


def paragraphs(review: str) -> list[str]:
    return [p.strip() for p in re.split(r"\n\s*\n", review) if p.strip()]


def rule_pattern(rule: int) -> re.Pattern[str]:
    # "rule 27", "Rule 27:", "(27)", "27." as a list lead, but never a bare
    # number inside a path or a line reference like crm-sync.ts:27.
    return re.compile(rf"(?i)rule\s*{rule}\b|\({rule}\)|^\s*{rule}[.)]\s", re.MULTILINE)


def grade_review(review: str, violations: list[dict], clean_files: list[str]) -> dict:
    paras = paragraphs(review)
    caught: list[str] = []
    rule_cited: list[str] = []
    for v in violations:
        base = basename(v["file"])
        evidence = re.compile(v["evidence"])
        rule = rule_pattern(v["rule"])
        hit = next((p for p in paras if base in p and evidence.search(p)), None)
        if hit is None:
            continue
        caught.append(v["id"])
        if any(base in p and evidence.search(p) and rule.search(p) for p in paras):
            rule_cited.append(v["id"])
    # FP granularity is the SENTENCE, not the paragraph: a finding's paragraph
    # may name a clean file only to exonerate it ("nothing in shipping.ts
    # changed", "shipping.ts is exempt") while citing a rule against another
    # file. Accusation means the clean basename and a rule claim share a
    # sentence.
    sentences = [s for p in paras for s in re.split(r"(?<=[.!?])\s+", p)]
    false_positives = [
        f
        for f in clean_files
        if any(basename(f) in s and re.search(r"(?i)rule\s*\d+\b|\(\d{1,2}\)", s) for s in sentences)
    ]
    return {"caught": caught, "rule_cited": rule_cited, "false_positives": false_positives}


def selftest() -> None:
    violations = [
        {"id": "v-console", "file": "src/use-cases/award-points.ts", "rule": 4, "evidence": r"(?i)console\.(log|error|warn)"},
        {"id": "v-deadline", "file": "src/infra/crm-sync.ts", "rule": 29, "evidence": r"(?i)deadline|timeout|AbortSignal"},
        {"id": "v-harddelete", "file": "src/infra/orders-db.ts", "rule": 30, "evidence": r"(?i)hard.?delete|soft.?delete"},
        {"id": "v-latest", "file": "package.json", "rule": 19, "evidence": r"(?i)\"?latest\"?"},
    ]
    clean = ["src/domain/shipping.ts"]

    review = """Findings, most important first.

award-points.ts uses console.log for the audit line; rule 4 requires the injected Logger port.

crm-sync.ts calls fetch with no timeout at all. Every outbound call needs a deadline (rule 29).

shipping.ts extracts the threshold to a constant; rule 12 requires branding the weight. This is wrong but asserted anyway.

orders-db.ts line 30 looks fine to me.
"""
    got = grade_review(review, violations, clean)
    # caught: console (file+evidence), deadline (file+evidence). NOT harddelete:
    # its paragraph names the file but carries no evidence match ("looks fine",
    # and the bare 30 is a line reference the rule pattern must NOT count).
    # NOT latest: never mentioned.
    assert got["caught"] == ["v-console", "v-deadline"], got
    assert got["rule_cited"] == ["v-console", "v-deadline"], got
    # shipping.ts is clean but the review asserts "rule 12" against it -> FP.
    assert got["false_positives"] == ["src/domain/shipping.ts"], got

    # An empty review scores zero everywhere and flags nothing.
    empty = grade_review("", violations, clean)
    assert empty == {"caught": [], "rule_cited": [], "false_positives": []}, empty

    # Arm-neutral: catching without citing the rule number still counts as caught.
    wordy = "The fetch in crm-sync.ts has no timeout, add one before landing."
    got = grade_review(wordy, violations, clean)
    assert got["caught"] == ["v-deadline"] and got["rule_cited"] == [], got

    # A line reference like orders-db.ts:30 must not count as citing rule 30.
    lineref = "orders-db.ts:30 does a hard delete where a soft delete is required."
    got = grade_review(lineref, violations, clean)
    assert got["caught"] == ["v-harddelete"] and got["rule_cited"] == [], got

    # Exoneration is not accusation: a paragraph may cite a rule against one
    # file while mentioning a clean file only to clear it. Neither of these,
    # both taken verbatim from real with_skill reviews, is a false positive.
    exoneration1 = (
        "shipping.test.ts breaks rule 24 (never touch a test without confirmation). "
        "An existing expected value was changed from 899 to 499. Nothing in shipping.ts "
        "changed behaviour: the constant extraction preserves the boundary."
    )
    got = grade_review(exoneration1, violations, clean)
    assert got["false_positives"] == [], got
    exoneration2 = (
        "Four new production files ship with no test at all, breaking rule 11. "
        "loyalty.ts and crm-sync.ts have no accompanying test. "
        "shipping.ts is exempt: a constant extraction covered by existing tests."
    )
    got = grade_review(exoneration2, violations, clean)
    assert got["false_positives"] == [], got

    print("selftest OK: catches evidence, requires the rule token for citation, flags clean-file claims, ignores exonerations, scores an empty review 0")


def main() -> None:
    args = sys.argv[1:]
    if "--selftest" in args:
        selftest()
        return
    if not args:
        sys.exit("usage: grade.py <runs-dir> | --selftest")
    runs_dir = Path(args[0])
    violations = json.loads((HERE / "violations.json").read_text())
    clean_files = json.loads((HERE / "clean-files.json").read_text())
    total = len(violations)
    for run in sorted(p for p in runs_dir.iterdir() if p.is_dir()):
        review_file = run / ".review.txt"
        if not review_file.exists():
            print(f"{run.name}: no .review.txt, skipped")
            continue
        got = grade_review(review_file.read_text(errors="replace"), violations, clean_files)
        missed = [v["id"] for v in violations if v["id"] not in got["caught"]]
        print(
            f"{run.name}: caught {len(got['caught'])}/{total}, rule-cited {len(got['rule_cited'])}/{total}, "
            f"false-positives {len(got['false_positives'])}"
        )
        if missed:
            print(f"  missed: {', '.join(missed)}")
        if got["false_positives"]:
            print(f"  fp on clean files: {', '.join(got['false_positives'])}")


if __name__ == "__main__":
    main()
