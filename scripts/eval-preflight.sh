#!/usr/bin/env bash
#
# The evals' preflight: one `claude -p` turn before a pass, so a pass never starts where the CLI
# cannot answer.
#
# Four times an environmental failure spent a whole pass before anyone read it: an expired OAuth
# session made every trigger probe read 0.0 (2026-08-29), an overnight ENOTFOUND outage
# (2026-09-04), a revoked CLI token (2026-09-06), and 24 of 42 sessions were refused with "API
# Error: 403 Request not allowed" after midnight (2026-09-20). Each read as both arms dropping at
# once (.claude/LESSONS.md). Every eval runner calls this right before its first session: it asks
# for one word from a scratch folder outside the repo, with the runners' isolation flags and the
# pass's model, and stops the pass on anything but that word. A failure that starts mid-pass is
# still the graders' to name (grade.py leaves a dead session out of the score).
#
# Usage:
#   bash scripts/eval-preflight.sh [model]   # exit 0: the CLI answered; 1: it did not
#   bash scripts/eval-preflight.sh --selftest
# Env: PREFLIGHT_TIMEOUT_S, the wall-clock cap on the turn (default 120).
set -euo pipefail

probe() { # $1 model, empty for the user's configured one
  local model="${1:-}" cap="${PREFLIGHT_TIMEOUT_S:-120}" dir status=0 said
  dir="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/atelier-preflight.XXXXXX")" && pwd -P)"
  local isolate=(--setting-sources project,local)
  [ ! -f "$HOME/.claude/settings.json" ] || isolate+=(--settings "$HOME/.claude/settings.json")
  # The runners' own shape (conformance-eval/run.sh): a session outside the repo, its wall-clock
  # cap a watchdog rather than `timeout`, which macOS does not ship.
  ( cd "$dir" && exec env -u CLAUDECODE claude -p "Reply with the single word: ready" \
      "${isolate[@]}" --max-turns 1 ${model:+--model "$model"} \
      < /dev/null > "$dir/.said" 2>&1 ) &
  local session=$!
  # Its own stdio goes nowhere: a sleep orphaned by the kill below would otherwise hold a
  # caller's output pipe open for the whole cap.
  ( sleep "$cap" && kill "$session" 2>/dev/null && : > "$dir/.capped" ) > /dev/null 2>&1 &
  local watchdog=$!
  wait "$session" 2>/dev/null || status=$?
  kill "$watchdog" 2>/dev/null || true; wait "$watchdog" 2>/dev/null || true
  said="$(head -c 600 "$dir/.said" 2>/dev/null || true)"
  local why=""
  if [ -e "$dir/.capped" ]; then
    why="no answer within ${cap} s"
  elif [ "$status" -ne 0 ]; then
    why="claude exited $status"
  elif ! grep -qi 'ready' <<<"$said"; then
    why="it answered something else"
  fi
  rm -rf "${dir:?}"
  if [ -n "$why" ]; then
    {
      echo "eval-preflight: $why${model:+ (model $model)}, so no session of this pass runs:"
      sed 's/^/  | /' <<<"${said:-(no output)}"
      echo "  Fix the environment (sign-in, network, model name) and rerun: an eval pass in it would"
      echo "  read as both arms dropping at once (.claude/LESSONS.md)."
    } >&2
    return 1
  fi
  echo "eval-preflight: the CLI answered${model:+ (model $model)}"
}

selftest() {
  local tmp gate here
  tmp="$(mktemp -d)"
  trap "rm -rf '$tmp'" EXIT  # expanded now: the local is gone by the time EXIT fires
  gate="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  here="$(cd "$(dirname "$0")/.." && pwd -P)"
  mkdir -p "$tmp/bin"
  # The fake CLI: FAKE_MODE picks the answer, and every call records its arguments and where it ran.
  cat > "$tmp/bin/claude" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$PWD" "$@" > "$FAKE_LOG"
case "$FAKE_MODE" in
  ready) echo "Ready." ;;
  refused) echo "Failed to authenticate. API Error: 403 Request not allowed"; exit 1 ;;
  transport) echo "API Error: Can't reach the API server (ENOTFOUND)"; exit 1 ;;
  exit) echo "ready"; exit 1 ;;
  other) echo "I can help with that. What would you like to build?" ;;
  hang) exec sleep 30 ;;
esac
FAKE
  chmod +x "$tmp/bin/claude"
  expect() { # $1 what, $2 mode, $3 exit wanted, $4 text the output must hold, $5 model
    local out rc=0
    out=$(PATH="$tmp/bin:$PATH" FAKE_MODE="$2" FAKE_LOG="$tmp/log" PREFLIGHT_TIMEOUT_S=2 \
      bash "$gate" ${5:+"$5"} 2>&1) || rc=$?
    if [ "$rc" -ne "$3" ] || [[ "$out" != *"$4"* ]]; then
      echo "selftest FAIL: $1 (exit $rc, wanted $3):" >&2; echo "$out" >&2; exit 1
    fi
  }
  expect "an answer" ready 0 "the CLI answered (model m)" m
  local ran
  ran="$(head -1 "$tmp/log")"
  case "$ran" in "$here"|"$here"/*) echo "selftest FAIL: the probe ran inside the repo ($ran)" >&2; exit 1 ;; esac
  for flag in -p "--setting-sources" "project,local" "--max-turns" "--model"; do
    grep -qx -- "$flag" "$tmp/log" || { echo "selftest FAIL: the probe did not pass $flag" >&2; exit 1; }
  done
  expect "a refused session" refused 1 "API Error: 403 Request not allowed"
  expect "a transport error" transport 1 "ENOTFOUND"
  expect "a non-zero exit that still says ready" exit 1 "claude exited 1"
  expect "another answer" other 1 "it answered something else"
  expect "a hang past the cap" hang 1 "no answer within 2 s"
  echo "selftest OK: an answer passes; a 403, a transport error, a non-zero exit, another answer and a hang past the cap each stop the pass; the probe runs outside the repo with the runners' isolation flags and the pass's model"
}

case "${1:-}" in
  --selftest) selftest ;;
  -h|--help) sed -n '2,19p' "$0" ;;
  *) [ $# -le 1 ] || { echo "usage: eval-preflight.sh [model] | --selftest" >&2; exit 2; }; probe "${1:-}" ;;
esac
