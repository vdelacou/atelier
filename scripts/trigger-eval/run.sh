#!/usr/bin/env bash
#
# Run a trigger-eval set against a skill, from the right probe fixture.
#
#   bash scripts/trigger-eval/run.sh <set> <skill-dir> [fixture] [runs]
#
#   set      : a JSON file in scripts/trigger-eval/sets/ (or a path)
#   skill-dir: e.g. skills/atelier
#   fixture  : probe-root | probe-root-java | probe-root-empty (default probe-root)
#   runs     : runs per query (default 3; use 5 for a tighter read)
#
# Results land in skills/atelier-workspace/trigger-eval-<date>/ (gitignored).
# The probe uses `claude -p` with the session's configured model unless
# TRIGGER_EVAL_MODEL is set. Each probe runs in an isolated temp copy of the
# fixture; see run_eval.py's header for why that matters.
#
# Examples:
#   bash scripts/trigger-eval/run.sh atelier-bun.json skills/atelier
#   bash scripts/trigger-eval/run.sh atelier-java.json skills/atelier probe-root-java 5
#   bash scripts/trigger-eval/run.sh atelier-greenfield.json skills/atelier-greenfield probe-root-empty

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

SET="${1:?usage: run.sh <set> <skill-dir> [fixture] [runs]}"
SKILL="${2:?usage: run.sh <set> <skill-dir> [fixture] [runs]}"
FIXTURE="${3:-probe-root}"
RUNS="${4:-3}"

[ -f "$SET" ] || SET="$HERE/sets/$SET"
[ -f "$SET" ] || { echo "run.sh: eval set not found: $SET" >&2; exit 1; }
[ -d "$REPO_ROOT/$SKILL" ] || { echo "run.sh: skill dir not found: $SKILL" >&2; exit 1; }
[ -d "$HERE/$FIXTURE" ] || { echo "run.sh: fixture not found: $HERE/$FIXTURE" >&2; exit 1; }

OUT_DIR="$REPO_ROOT/skills/atelier-workspace/trigger-eval-$(date +%F)"
mkdir -p "$OUT_DIR"
BASE="$(basename "$SET" .json)-$(basename "$SKILL")"

cd "$HERE/$FIXTURE"
python3 "$HERE/run_eval.py" \
  --eval-set "$SET" \
  --skill-path "$REPO_ROOT/$SKILL" \
  --runs-per-query "$RUNS" \
  --num-workers 10 \
  --timeout 90 \
  ${TRIGGER_EVAL_MODEL:+--model "$TRIGGER_EVAL_MODEL"} \
  --verbose \
  > "$OUT_DIR/$BASE.json" \
  2> "$OUT_DIR/$BASE.log"

python3 - "$OUT_DIR/$BASE.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
res = d["results"]
ok = sum(1 for r in res if (r["trigger_rate"] >= 0.5) == r["should_trigger"])
print(f"{sys.argv[1]}: {ok}/{len(res)} pass")
for r in res:
    if (r["trigger_rate"] >= 0.5) != r["should_trigger"]:
        print(f"  FAIL want={'T' if r['should_trigger'] else 'F'} rate={r['trigger_rate']:.1f} | {r['query'][:90]}")
PY
