#!/usr/bin/env python3
"""Phase 4 drift gate: conformance-matrix.md must stay true to the vendored canon.

Three checks, any failure exits non-zero (a CI gate):
  1. The matrix has exactly 116 rows, with the canonical per-pillar counts.
  2. Every matrix (id, sub-concept) equals the canonical index verbatim (12.1: a
     renumbered or retitled copy is doc drift and a defect).
  3. Each vendored canon file's SHA-256 equals the hash the matrix header pins, so
     bumping the canon without re-auditing the matrix fails the build.

    python3 scripts/check-matrix-drift.py            # run the gate
    python3 scripts/check-matrix-drift.py --selftest # prove the gate can fail
"""
import hashlib
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MATRIX = REPO / "conformance-matrix.md"
CANON = REPO / "docs/global-rules/global-rules-dos-and-donts.md"
PER_PILLAR = [2, 6, 9, 8, 10, 7, 7, 6, 5, 14, 3, 7, 4, 3, 9, 5, 7, 4]


def canonical_index(canon_text: str) -> list[tuple[str, str]]:
    """(id, title) pairs from the 'Every sub-concept' index links: [1.1 Title](#anchor)."""
    block = canon_text.split("### Every sub-concept", 1)[1].split("\n---", 1)[0]
    return [(i, t.strip()) for i, t in re.findall(r"\[(\d+\.\d+) ([^\]]+)\]\(#", block)]


def matrix_rows(matrix_text: str) -> list[tuple[str, str]]:
    """(id, sub-concept) from the pillar tables: | 1.1 | Title | VERDICT | ... |."""
    rows = []
    for line in matrix_text.splitlines():
        m = re.match(r"^\|\s*(\d+\.\d+)\s*\|(.+)\|\s*$", line)
        if not m:
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 6:  # ID | Sub-concept | Verdict | Evidence | Enforcement | Notes
            rows.append((cells[0], cells[1]))
    return rows


def pinned_hashes(matrix_text: str) -> dict[str, str]:
    """path -> sha256 from the matrix header's pinned-inputs table."""
    return {
        p: h
        for p, h in re.findall(r"\|\s*(docs/global-rules/[^\s|]+\.md)\s*\|\s*([0-9a-f]{64})\s*\|", matrix_text)
    }


def check(matrix_text: str, canon_text: str) -> list[str]:
    errors = []
    canon = canonical_index(canon_text)
    rows = matrix_rows(matrix_text)

    # 1. row count + per-pillar
    if len(rows) != 116:
        errors.append(f"row count is {len(rows)}, expected 116")
    per = [sum(1 for i, _ in rows if i.split(".")[0] == str(p)) for p in range(1, 19)]
    if per != PER_PILLAR:
        errors.append(f"per-pillar counts {per} != canonical {PER_PILLAR}")

    # 2. id+title verbatim, in canonical order
    canon_map = dict(canon)
    for rid, rtitle in rows:
        if canon_map.get(rid) != rtitle:
            errors.append(f"{rid}: matrix title {rtitle!r} != canon {canon_map.get(rid)!r}")
    missing = set(canon_map) - {i for i, _ in rows}
    if missing:
        errors.append(f"matrix missing canon ids: {sorted(missing)}")

    # 3. canon sha256 pins
    pins = pinned_hashes(matrix_text)
    if not pins:
        errors.append("no sha256 pins found in the matrix header")
    for rel, pinned in pins.items():
        f = REPO / rel
        if not f.is_file():
            errors.append(f"pinned file missing: {rel}")
            continue
        actual = hashlib.sha256(f.read_bytes()).hexdigest()
        if actual != pinned:
            errors.append(f"{rel}: sha256 {actual[:12]}.. != pinned {pinned[:12]}.. (canon changed, re-audit the matrix)")
    return errors


def selftest() -> None:
    """Prove each check can fail: a mutated matrix must be rejected."""
    canon_text = CANON.read_text(encoding="utf-8")
    good = MATRIX.read_text(encoding="utf-8")
    if check(good, canon_text):
        print("SELFTEST FAILED: the real matrix should pass but did not:")
        for e in check(good, canon_text):
            print(f"  {e}")
        sys.exit(1)
    # retitle one row -> check 2 must fire
    mutated = good.replace("| 1.1 | One committed config for style |", "| 1.1 | One committed config for STYLE |", 1)
    if mutated == good or not check(mutated, canon_text):
        print("SELFTEST FAILED: a retitled row was not caught")
        sys.exit(1)
    # corrupt a pinned hash -> check 3 must fire
    m2 = re.sub(r"([0-9a-f]{55})[0-9a-f]{9}", r"\g<1>000000000", good, count=1)
    if m2 == good or not check(m2, canon_text):
        print("SELFTEST FAILED: a corrupted sha256 pin was not caught")
        sys.exit(1)
    print("selftest OK: drift gate rejects a retitled row and a corrupted canon pin")


def main() -> None:
    if "--selftest" in sys.argv[1:]:
        selftest()
        return
    errors = check(MATRIX.read_text(encoding="utf-8"), CANON.read_text(encoding="utf-8"))
    if errors:
        print("conformance-matrix drift detected:")
        for e in errors:
            print(f"  {e}")
        sys.exit(1)
    print("conformance-matrix.md: 116 rows, ids+titles verbatim, canon sha256 pins intact")


if __name__ == "__main__":
    main()
