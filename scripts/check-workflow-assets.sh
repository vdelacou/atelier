#!/usr/bin/env bash
# Gate: the shipped CI workflows must be self-sufficient in a consumer repo.
#
# Two failure classes this catches (both found live in the 2026-08-30 audit):
#   1. A workflow step runs `scripts/<name>` but assets/ does not ship <name>,
#      so a bootstrapped repo fails CI on a missing file.
#   2. A workflow step invokes a binary GitHub's ubuntu-latest does not
#      preinstall (gitleaks) with no earlier install step in the file, or
#      downloads it from a release without a sha256sum -c before its first use.
#
# The shipped Claude Code settings (claude-settings.json, the reply gate's Stop
# hook, 2026-10-04) run `scripts/<name>` the same way, in every variant, so they
# get the same checks: JSON parses as YAML, and each variant must copy the script.
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

  # 3. every variant that ships the workflow must tell consumers to copy each of them.
  #    An unmapped workflow and a missing reference are failures: until 2026-09-27 both
  #    skipped this check silently, and audit.yml (shipped by Bun and Next alike) was
  #    checked against the Bun reference only.
  local bun_ref="${BOOTSTRAP_REF_BUN:-skills/atelier/references/bun-typescript.md}"
  local java_ref="${BOOTSTRAP_REF_JAVA:-skills/atelier/references/java-quarkus.md}"
  local next_ref="${BOOTSTRAP_REF_NEXT:-skills/atelier/references/nextjs-monorepo.md}"
  local refs=()
  case "$(basename "$wf")" in
    ci.yml|mutation.yml) refs=("$bun_ref") ;;
    audit.yml) refs=("$bun_ref" "$next_ref") ;;
    ci-java.yml|audit-java.yml|mutation-java.yml) refs=("$java_ref") ;;
    ci-next.yml) refs=("$next_ref") ;;
    claude-settings.json|branches.yml) refs=("$bun_ref" "$next_ref" "$java_ref") ;;
    *)
      echo "FAIL $wf: no bootstrap reference is mapped for this workflow (add it to check 3's case list)" >&2
      fails=1
      ;;
  esac
  local ref
  for ref in ${refs[@]+"${refs[@]}"}; do
    if [ ! -f "$ref" ]; then
      echo "FAIL $wf: its bootstrap reference $ref does not exist" >&2
      fails=1
      continue
    fi
    while IFS= read -r sref; do
      local sbase="${sref#scripts/}"
      if ! grep -q "assets/$sbase" "$ref"; then
        echo "FAIL $wf: needs scripts/$sbase but $ref never copies assets/$sbase" >&2
        fails=1
      fi
    done < <(grep -oE 'scripts/[A-Za-z0-9._-]+\.(sh|ts|py|js)' "$wf" | sort -u)
  done

  # 2. a non-preinstalled binary needs an install step BEFORE its first bare use
  for bin in "${NON_PREINSTALLED[@]}"; do
    local first_use install_line
    first_use=$(grep -nE "^[[:space:]]*-?[[:space:]]*(run:[[:space:]]*)?${bin}([[:space:]]|$)" "$wf" | head -1 | cut -d: -f1 || true)
    [ -z "$first_use" ] && continue
    install_line=$(grep -nE "(releases/download|apt-get|brew install|setup-|install).*${bin}|${bin}.*(releases/download|apt-get install)" "$wf" | head -1 | cut -d: -f1 || true)
    if [ -z "$install_line" ] || [ "$install_line" -ge "$first_use" ]; then
      echo "FAIL $wf: invokes '$bin' (line $first_use) with no earlier install step" >&2
      fails=1
    elif grep -nE "releases/download.*${bin}" "$wf" >/dev/null; then
      # 2b. a binary fetched from a release is checksum-verified before its first use:
      # a pinned version is not a pinned artifact (2026-09-26, the skills.sh Gen audit
      # flagged the download; the tarball went through sudo install unverified).
      local verify_line
      verify_line=$(grep -nE "sha256sum[[:space:]]+(-c|--check)" "$wf" | head -1 | cut -d: -f1 || true)
      if [ -z "$verify_line" ] || [ "$verify_line" -ge "$first_use" ]; then
        echo "FAIL $wf: downloads '$bin' from a release with no sha256sum -c before its first use (line $first_use)" >&2
        fails=1
      fi
    fi
  done
  return $fails
}

selftest() {
  local tmp; tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT
  mkdir -p "$tmp/assets"
  touch "$tmp/assets/present.sh"
  # One reference that copies every script the fixtures call, so a case is red for
  # its own reason and never for a missing copy line; each case asserts the reason.
  printf 'copy assets/present.sh and assets/missing.sh into scripts/\n' > "$tmp/ref.md"
  red() { # $1 what, $2 the FAIL text the gate must print, $3 the workflow; env from the caller
    local out rc=0
    out=$(lint_workflow "$3" "$tmp/assets" 2>&1) || rc=$?
    if [ "$rc" -eq 0 ]; then echo "selftest FAIL: $1 was accepted" >&2; exit 1; fi
    case "$out" in
      *"$2"*) ;;
      *) echo "selftest FAIL: $1 was rejected, but not for its own reason:" >&2; echo "$out" >&2; exit 1 ;;
    esac
  }
  fixture() { mkdir -p "$tmp/$1"; printf '%b' "$2" > "$tmp/$1/ci.yml"; echo "$tmp/$1/ci.yml"; }
  export BOOTSTRAP_REF_BUN="$tmp/ref.md"

  # violation 0: a workflow that is not YAML (the 2026-09-08 ci-next.yml draft)
  wf=$(fixture v0 'steps:\n  - name: gate (rules 5 and 19: no latest)\n    run: bash scripts/present.sh\n')
  rc=0; parse_yaml "$wf" 2>/dev/null || rc=$?
  [ "$rc" -eq 2 ] && { echo "selftest FAIL: no YAML parser on this machine (python3 with PyYAML, or ruby); the parse check cannot be proven here" >&2; exit 1; }
  red "a malformed workflow" "does not parse as YAML" "$wf"
  # violation 1: a missing shipped script
  red "a missing shipped script" "does not exist" "$(fixture v1 'steps:\n  - run: bash scripts/missing.sh\n')"
  # violation 2: a bare binary with no install step
  red "a bare binary" "with no earlier install step" "$(fixture v2 'steps:\n  - run: gitleaks git --redact\n')"
  # violation 4: a release download installed with no checksum (the pre-2026-09-26 shape)
  red "an unverified download" "no sha256sum -c before its first use" \
    "$(fixture v4 'steps:\n  - run: |\n      curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/vX/g.tar.gz | tar -xz gitleaks\n  - run: gitleaks git --redact\n  - run: bash scripts/present.sh\n')"
  # violation 3: a script the bootstrap reference never copies
  printf 'a bootstrap doc that copies nothing\n' > "$tmp/bare-ref.md"
  BOOTSTRAP_REF_BUN="$tmp/bare-ref.md" red "an uncopied script" "never copies assets/present.sh" "$(fixture v3 'steps:\n  - run: bash scripts/present.sh\n')"
  # violation 3b: the bootstrap reference is missing (skipped silently until 2026-09-27)
  BOOTSTRAP_REF_BUN="$tmp/no-such-ref.md" red "a missing bootstrap reference" "does not exist" "$tmp/v3/ci.yml"
  # violation 3c: a workflow no variant is mapped to (skipped silently until 2026-09-27)
  cp "$tmp/v3/ci.yml" "$tmp/deploy.yml"
  red "an unmapped workflow" "no bootstrap reference is mapped" "$tmp/deploy.yml"
  # violation 3d: audit.yml ships with Bun and Next, so the Next reference must copy it too
  mkdir -p "$tmp/v3d" && cp "$tmp/v3/ci.yml" "$tmp/v3d/audit.yml"
  out=$(BOOTSTRAP_REF_NEXT="$tmp/bare-ref.md" lint_workflow "$tmp/v3d/audit.yml" "$tmp/assets" 2>&1) && { echo "selftest FAIL: audit.yml passed with a Next reference that never copies its script" >&2; exit 1; }
  case "$out" in *"bare-ref.md never copies assets/present.sh"*) ;; *) echo "selftest FAIL: audit.yml was rejected, but not on the Next reference:" >&2; echo "$out" >&2; exit 1 ;; esac
  # violation 3e: the Claude settings ship with every variant, so the Java reference must copy
  # the hook's script too (the Bun and Next references here do, so Java is the only reason)
  mkdir -p "$tmp/v3e"
  printf '{"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "python3 scripts/present.sh --hook"}]}]}}\n' > "$tmp/v3e/claude-settings.json"
  out=$(BOOTSTRAP_REF_NEXT="$tmp/ref.md" BOOTSTRAP_REF_JAVA="$tmp/bare-ref.md" lint_workflow "$tmp/v3e/claude-settings.json" "$tmp/assets" 2>&1) && { echo "selftest FAIL: claude-settings.json passed with a Java reference that never copies its hook script" >&2; exit 1; }
  case "$out" in *"bare-ref.md never copies assets/present.sh"*) ;; *) echo "selftest FAIL: claude-settings.json was rejected, but not on the Java reference:" >&2; echo "$out" >&2; exit 1 ;; esac
  BOOTSTRAP_REF_NEXT="$tmp/ref.md" BOOTSTRAP_REF_JAVA="$tmp/ref.md" lint_workflow "$tmp/v3e/claude-settings.json" "$tmp/assets" \
    || { echo "selftest FAIL: claude-settings.json was rejected with every reference copying its script" >&2; exit 1; }

  # the compliant fixture passes: a verified download, an installed binary, a copied script
  wf=$(fixture ok 'steps:\n  - run: |\n      curl -sSfL -o g.tar.gz https://github.com/gitleaks/gitleaks/releases/download/vX/g.tar.gz\n      echo "0000  g.tar.gz" | sha256sum -c -\n      tar -xzf g.tar.gz gitleaks\n  - run: gitleaks git --redact\n  - run: bash scripts/present.sh\n')
  if ! lint_workflow "$wf" "$tmp/assets"; then
    echo "selftest FAIL: compliant fixture was rejected" >&2; exit 1
  fi
  echo "selftest OK: gate rejects a workflow that is not YAML, a missing shipped script, an uninstalled binary, an unverified release download, an uncopied bootstrap script, a missing bootstrap reference, an unmapped workflow, a variant that ships audit.yml without its script and a variant that ships the Claude settings without the hook's script, each for its own reason; a compliant workflow and compliant settings pass"
}

if [ "${1:-}" = "--selftest" ]; then
  selftest
  exit 0
fi

status=0
# every shipped workflow, not a name pattern: a new one is mapped or it fails check 3
for wf in "$ASSETS_DIR"/*.yml "$ASSETS_DIR"/claude-settings.json; do
  lint_workflow "$wf" "$ASSETS_DIR" || status=1
done
if [ "$status" -eq 0 ]; then
  echo "check-workflow-assets: shipped workflows and Claude settings are self-sufficient"
fi
exit $status
