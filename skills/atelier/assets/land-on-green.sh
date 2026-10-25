#!/usr/bin/env bash
#
# Land a pull request once CI is green: rebase merge, the branch deleted, pinned to the head CI
# tested (rule 38). The shipped land.yml runs it on `workflow_run` after the ci workflow completes
# with success, so nobody presses merge and nothing lands red (references/workflow.md, Landing on
# green).
#
# Trust: land.yml runs from the default branch, and so does this script. A job that checked out
# the pull request and ran its copy of this script with a write token would hand that token to
# whoever wrote the pull request (Socket flagged exactly that on 2.8.0's in-ci land job,
# 2026-10-25), so nothing here reads code from the pull request; it reads its metadata through the
# API only.
#
# It skips, green, when no open pull request has the tested head or that pull request is a draft.
# It refuses, red, when:
#   - another check on the head is still running after LAND_WAIT_MIN minutes (default 20), or
#     finished other than success, skipped or neutral (a dependency audit in its own workflow, a
#     review bot);
#   - the head is behind the base branch. CI tested the head merged onto the base as it was then;
#     when the head already contains the base, that merge is the head itself, so what lands is what
#     ran. Rebase onto the base and push: CI runs again and this lands it.
#
# Inputs, all set by land.yml: GH_TOKEN, GITHUB_REPOSITORY, RUN_HEAD_SHA (the tested head,
# github.event.workflow_run.head_sha), LAND_JOB (this job's check name, ignored among the checks).
#
# Usage:
#   bash scripts/land-on-green.sh              # in land.yml
#   bash scripts/land-on-green.sh --selftest   # prove it skips and refuses, with a stub gh
set -euo pipefail

land() {
  local repo="$GITHUB_REPOSITORY" head="$RUN_HEAD_SHA"
  local self="${LAND_JOB:-land}" wait_min="${LAND_WAIT_MIN:-20}" poll="${LAND_POLL_SEC:-20}"

  # The open pull request whose head CI tested; its number, draft flag and base come from the API.
  local pr draft base_ref
  IFS=$'\t' read -r pr draft base_ref < <(gh api "repos/$repo/commits/$head/pulls" \
    --jq "[.[] | select(.state == \"open\" and .head.sha == \"$head\")] | first // empty | [.number, .draft, .base.ref] | @tsv") || true
  if [ -z "${pr:-}" ]; then
    echo "land: no open pull request has head ${head:0:7}; nothing to land"
    return 0
  fi
  if [ "$draft" = "true" ]; then
    echo "land: pull request #$pr is a draft; it lands once marked ready and green"
    return 0
  fi

  # Every other check on the head: wait while one runs, then all must have passed.
  local deadline=$(( $(date +%s) + wait_min * 60 )) runs pending failed
  while :; do
    runs=$(gh api "repos/$repo/commits/$head/check-runs?per_page=100" --paginate \
      --jq '.check_runs[] | [.name, .status, (.conclusion // "")] | @tsv')
    runs=$(printf '%s\n' "$runs" | awk -F'\t' -v self="$self" 'NF && $1 != self')
    pending=$(printf '%s\n' "$runs" | awk -F'\t' 'NF && $2 != "completed" {print $1}')
    [ -z "$pending" ] && break
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "land: #$pr still has checks running after ${wait_min} min, not landing:" >&2
      printf '%s\n' "$pending" | sed 's/^/    /' >&2
      return 1
    fi
    sleep "$poll"
  done
  failed=$(printf '%s\n' "$runs" | awk -F'\t' 'NF && $3 != "success" && $3 != "skipped" && $3 != "neutral" {print $1 " (" $3 ")"}')
  if [ -n "$failed" ]; then
    echo "land: a check on #$pr did not pass, not landing:" >&2
    printf '%s\n' "$failed" | sed 's/^/    /' >&2
    return 1
  fi

  # The head must contain the base, so the tree CI tested is the tree that lands.
  local behind
  behind=$(gh api "repos/$repo/compare/$base_ref...$head" --jq '.behind_by')
  if [ "$behind" != "0" ]; then
    echo "land: #$pr is $behind commit(s) behind $base_ref; rebase onto $base_ref and push, and CI lands it" >&2
    return 1
  fi

  echo "land: CI green on #$pr at ${head:0:7}, on top of $base_ref; rebase merge, branch deleted"
  gh pr merge "$pr" --repo "$repo" --rebase --delete-branch --match-head-commit "$head"
}

selftest() {
  local tmp fails=0
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/bin"
  # The stub answers from STUB_* variables and records a merge in $tmp/merged.
  cat > "$tmp/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  "api repos/o/r/commits/h1/pulls "*) printf '%b' "$STUB_PULLS" ;;
  "api repos/o/r/commits/h1/check-runs"*) printf '%b' "$STUB_RUNS" ;;
  "api repos/o/r/compare/main...h1 "*) echo "$STUB_BEHIND" ;;
  "pr merge 7 --repo o/r --rebase --delete-branch --match-head-commit h1") echo merged > "$STUB_DIR/merged" ;;
  *) echo "stub gh: unexpected call: $*" >&2; exit 9 ;;
esac
STUB
  chmod +x "$tmp/bin/gh"

  # name | open pull request (number, draft, base) | check runs | behind | expect: merged, skip, or the refusal
  local open='7\tfalse\tmain\n'
  local cases=(
    "green|$open|land\tin_progress\t\nci\tcompleted\tsuccess\naudit\tcompleted\tskipped\n|0|merged"
    "no open pull request||ci\tcompleted\tsuccess\n|0|skip:nothing to land"
    "a draft|7\ttrue\tmain\n|ci\tcompleted\tsuccess\n|0|skip:is a draft"
    "a check failed|$open|ci\tcompleted\tsuccess\naudit\tcompleted\tfailure\n|0|did not pass"
    "a check cancelled|$open|ci\tcompleted\tcancelled\n|0|did not pass"
    "a check still running|$open|audit\tqueued\t\n|0|still has checks running"
    "behind main|$open|ci\tcompleted\tsuccess\n|2|behind main"
  )
  local c name pulls runs behind want out st
  for c in "${cases[@]}"; do
    IFS='|' read -r name pulls runs behind want <<<"$c"
    rm -f "$tmp/merged"
    out=$(PATH="$tmp/bin:$PATH" STUB_DIR="$tmp" STUB_PULLS="$pulls" STUB_RUNS="$runs" STUB_BEHIND="$behind" \
      GITHUB_REPOSITORY=o/r RUN_HEAD_SHA=h1 LAND_JOB=land LAND_WAIT_MIN=0 LAND_POLL_SEC=0 land 2>&1) && st=0 || st=$?
    if [ "$want" = merged ]; then
      if [ "$st" -eq 0 ] && [ -f "$tmp/merged" ]; then echo "  ok:   $name lands"
      else echo "  FAIL: $name did not land: $out"; fails=$((fails + 1)); fi
    elif [ "${want#skip:}" != "$want" ]; then
      if [ "$st" -eq 0 ] && [ ! -f "$tmp/merged" ] && grep -q "${want#skip:}" <<<"$out"; then echo "  ok:   $name skips (${want#skip:})"
      else echo "  FAIL: $name: exit $st, merged=$([ -f "$tmp/merged" ] && echo yes || echo no): $out"; fails=$((fails + 1)); fi
    elif [ "$st" -ne 0 ] && [ ! -f "$tmp/merged" ] && grep -q "$want" <<<"$out"; then
      echo "  ok:   $name refuses ($want)"
    else
      echo "  FAIL: $name: exit $st, merged=$([ -f "$tmp/merged" ] && echo yes || echo no): $out"; fails=$((fails + 1))
    fi
  done
  [ "$fails" -eq 0 ] && echo "land-on-green: selftest passed" && return 0
  echo "land-on-green: selftest FAILED ($fails)"; return 1
}

if [ "${1:-}" = "--selftest" ]; then selftest; else land; fi
