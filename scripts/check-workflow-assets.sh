#!/usr/bin/env bash
# Gate: the shipped CI workflows must be self-sufficient in a consumer repo.
#
# Two failure classes this catches (both found live in the 2026-08-30 audit):
#   1. A workflow step runs `scripts/<name>` but assets/ does not ship <name>,
#      so a bootstrapped repo fails CI on a missing file.
#   2. A workflow step invokes a binary GitHub's ubuntu-latest does not
#      preinstall (gitleaks) with no earlier install step in the file.
#
# Usage:
#   bash scripts/check-workflow-assets.sh              # lint the shipped assets
#   bash scripts/check-workflow-assets.sh --selftest   # prove the gate can fail
set -euo pipefail

ASSETS_DIR="${ASSETS_DIR:-skills/atelier/assets}"
# Binaries the workflows may call that are absent from ubuntu-latest runners.
NON_PREINSTALLED=(gitleaks)

# 0. the file must be YAML at all. Whichever parser the machine has: python3 with
#    PyYAML, else ruby with Psych (the ubuntu runner has both). A colon-space
#    inside an unquoted step name is a mapping to YAML, not a name (the ci-next.yml
#    draft of 2026-09-08), and grep cannot see it. Returns 0 parsed, 1 the parser
#    said no (its message on stderr; any parser failure counts, a crashed parser
#    is not a pass), 2 no parser on the machine.
parse_yaml() {
  local wf="$1" st
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$wf" 2>&1 | sed 's/^/    /' >&2; st="${PIPESTATUS[0]}"
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml -e 'YAML.load_file(ARGV[0])' "$wf" 2>&1 | sed 's/^/    /' >&2; st="${PIPESTATUS[0]}"
  else
    return 2
  fi
  [ "$st" -eq 0 ] && return 0
  return 1
}

lint_workflow() {
  local wf="$1" assets_dir="$2" fails=0
  local parsed=0
  parse_yaml "$wf" || parsed=$?
  if [ "$parsed" -eq 1 ]; then
    echo "FAIL $wf: does not parse as YAML (a colon-space in an unquoted scalar, an indentation slip)" >&2
    fails=1
  elif [ "$parsed" -eq 2 ]; then
    echo "NOTE $wf: no YAML parser on this machine (python3 with PyYAML, or ruby); the parse check is skipped here and runs in CI" >&2
  fi

  # 1. every `scripts/<name>` referenced in a run line must ship in assets/
  while IFS= read -r ref; do
    local base="${ref#scripts/}"
    if [ ! -f "$assets_dir/$base" ]; then
      echo "FAIL $wf: references $ref but $assets_dir/$base does not exist" >&2
      fails=1
    fi
  done < <(grep -oE 'scripts/[A-Za-z0-9._-]+\.(sh|ts|py|js)' "$wf" | sort -u)

  # 3. the variant's bootstrap reference must tell consumers to copy each of them
  local ref=""
  case "$(basename "$wf")" in
    ci.yml|audit.yml|mutation.yml) ref="${BOOTSTRAP_REF_BUN:-skills/atelier/references/bun-typescript.md}" ;;
    ci-java.yml|audit-java.yml|mutation-java.yml) ref="${BOOTSTRAP_REF_JAVA:-skills/atelier/references/java-quarkus.md}" ;;
    ci-next.yml) ref="${BOOTSTRAP_REF_NEXT:-skills/atelier/references/nextjs-monorepo.md}" ;;
  esac
  if [ -n "$ref" ] && [ -f "$ref" ]; then
    while IFS= read -r sref; do
      local sbase="${sref#scripts/}"
      if ! grep -q "assets/$sbase" "$ref"; then
        echo "FAIL $wf: needs scripts/$sbase but $ref never copies assets/$sbase" >&2
        fails=1
      fi
    done < <(grep -oE 'scripts/[A-Za-z0-9._-]+\.(sh|ts|py|js)' "$wf" | sort -u)
  fi

  # 2. a non-preinstalled binary needs an install step BEFORE its first bare use
  for bin in "${NON_PREINSTALLED[@]}"; do
    local first_use install_line
    first_use=$(grep -nE "^[[:space:]]*-?[[:space:]]*(run:[[:space:]]*)?${bin}([[:space:]]|$)" "$wf" | head -1 | cut -d: -f1 || true)
    [ -z "$first_use" ] && continue
    install_line=$(grep -nE "(releases/download|apt-get|brew install|setup-|install).*${bin}|${bin}.*(releases/download|apt-get install)" "$wf" | head -1 | cut -d: -f1 || true)
    if [ -z "$install_line" ] || [ "$install_line" -ge "$first_use" ]; then
      echo "FAIL $wf: invokes '$bin' (line $first_use) with no earlier install step" >&2
      fails=1
    fi
  done
  return $fails
}

selftest() {
  local tmp; tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT
  mkdir -p "$tmp/assets"
  touch "$tmp/assets/present.sh"
  # violation 0: a workflow that is not YAML (the 2026-09-08 ci-next.yml draft)
  printf 'steps:\n  - name: gate (rules 5 and 19: no latest)\n    run: bash scripts/present.sh\n' > "$tmp/v0.yml"
  printf 'copy assets/present.sh into scripts/\n' > "$tmp/ref0.md"
  parse_yaml "$tmp/v0.yml" 2>/dev/null && { echo "selftest FAIL: the parser accepted a colon-space step name" >&2; exit 1; }
  rc=0; parse_yaml "$tmp/v0.yml" 2>/dev/null || rc=$?
  [ "$rc" -eq 2 ] && { echo "selftest FAIL: no YAML parser on this machine (python3 with PyYAML, or ruby); the parse check cannot be proven here" >&2; exit 1; }
  if BOOTSTRAP_REF_BUN="$tmp/ref0.md" lint_workflow "$tmp/v0.yml" "$tmp/assets" 2>/dev/null; then
    echo "selftest FAIL: malformed-YAML violation was accepted" >&2; exit 1
  fi

  # violation 1: missing shipped script
  printf 'steps:\n  - run: bash scripts/missing.sh\n' > "$tmp/v1.yml"
  if lint_workflow "$tmp/v1.yml" "$tmp/assets" 2>/dev/null; then
    echo "selftest FAIL: missing-script violation was accepted" >&2; exit 1
  fi
  # violation 3: workflow needs a script its bootstrap reference never copies
  printf 'steps:\n  - run: bash scripts/present.sh\n' > "$tmp/ci.yml"
  printf 'a bootstrap doc that copies nothing\n' > "$tmp/ref.md"
  if BOOTSTRAP_REF_BUN="$tmp/ref.md" lint_workflow "$tmp/ci.yml" "$tmp/assets" 2>/dev/null; then
    echo "selftest FAIL: uncopied-script violation was accepted" >&2; exit 1
  fi
  printf 'copy assets/present.sh into scripts/\n' > "$tmp/ref.md"
  if ! BOOTSTRAP_REF_BUN="$tmp/ref.md" lint_workflow "$tmp/ci.yml" "$tmp/assets"; then
    echo "selftest FAIL: copied-script fixture was rejected" >&2; exit 1
  fi

  # violation 2: bare binary, no install
  printf 'steps:\n  - run: gitleaks detect --redact\n' > "$tmp/v2.yml"
  if lint_workflow "$tmp/v2.yml" "$tmp/assets" 2>/dev/null; then
    echo "selftest FAIL: bare-binary violation was accepted" >&2; exit 1
  fi
  # compliant fixture must pass
  printf 'steps:\n  - run: |\n      curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/vX/g.tar.gz | tar -xz gitleaks\n  - run: gitleaks detect --redact\n  - run: bash scripts/present.sh\n' > "$tmp/ok.yml"
  if ! lint_workflow "$tmp/ok.yml" "$tmp/assets"; then
    echo "selftest FAIL: compliant fixture was rejected" >&2; exit 1
  fi
  echo "selftest OK: gate rejects a workflow that is not YAML, a missing shipped script, an uninstalled binary, and an uncopied bootstrap script"
}

if [ "${1:-}" = "--selftest" ]; then
  selftest
  exit 0
fi

status=0
for wf in "$ASSETS_DIR"/ci*.yml "$ASSETS_DIR"/audit*.yml "$ASSETS_DIR"/mutation*.yml; do
  lint_workflow "$wf" "$ASSETS_DIR" || status=1
done
if [ "$status" -eq 0 ]; then
  echo "check-workflow-assets: shipped workflows are self-sufficient"
fi
exit $status
