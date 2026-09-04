#!/usr/bin/env bash
#
# The six-pack's own gate: the pack composes and the prompts close the loop.
#
# swarm-forge parses swarmforge.conf at `./swarm` time, on the operator's
# machine, so a broken pack would surface after install rather than in CI.
# This check applies the launcher's parse rules here (a known directive and
# agent, unique roles with no underscore, a valid unique worktree, exactly one
# master, the receive and propagation tokens, a prompt per role) and then what
# the launcher cannot know: every role prompt names the receive/send/done
# helpers, each role hands off to the next role in conf order and the last
# role addresses every other one (the terminal broadcast that marks the card
# Done), no pack article reuses a shared-article name (get-swarm-forge drops
# it silently), no em dash anywhere in the pack, and the README role table
# agrees with the conf.
#
# Usage:
#   bash scripts/check-six-pack.sh                   packs/six-pack in this checkout
#   PACK_ROOT=<dir> bash scripts/check-six-pack.sh   another pack tree
#   bash scripts/check-six-pack.sh --selftest        proves every rule can fail
set -euo pipefail

if [ "${1:-}" = "--selftest" ]; then
  gate="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  src="$(cd "$(dirname "$0")/../packs/six-pack" && pwd)"
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  pack="$tmp/pack"
  conf="$pack/swarmforge/swarmforge.conf"
  roles="$pack/swarmforge/roles"
  fresh() {
    rm -rf "$pack"; mkdir -p "$pack"
    cp -R "$src/." "$pack/"
    rm -rf "$pack/swarmforge/scripts"
    rm -f "$pack/swarmforge/constitution/articles/engineering.prompt" \
          "$pack/swarmforge/constitution/articles/workflow.prompt" \
          "$pack/swarmforge/constitution/articles/handoffs.prompt"
  }
  edit() { local file="$1"; shift; sed "$@" "$file" > "$file.new" && mv "$file.new" "$file"; }
  green() { PACK_ROOT="$pack" bash "$gate" >/dev/null 2>&1; }
  expect_red() { if green; then echo "selftest FAIL: accepted $1" >&2; exit 1; fi; }

  fresh; green || { echo "selftest FAIL: rejected the shipped pack:" >&2; PACK_ROOT="$pack" bash "$gate" || true; exit 1; }
  fresh; echo 'window-invisible coder claude coder-two' >> "$conf"; expect_red "a duplicate role"
  fresh; edit "$conf" 's/^window-invisible coder claude coder$/window-invisible coder claude master/'; expect_red "two master worktrees"
  fresh; edit "$conf" 's/^window-invisible cleaner claude /window-invisible cleaner gpt /'; expect_red "an unknown agent"
  fresh; edit "$conf" 's/^window-invisible reviewer claude reviewer/window-invisible review_er claude reviewer/'; expect_red "a role with an underscore"
  fresh; rm "$roles/cleaner.prompt"; expect_red "a missing role prompt"
  fresh; edit "$roles/coder.prompt" 's/done_with_current\.sh/done_later.sh/g'; expect_red "a prompt that never names the done helper"
  fresh; edit "$roles/coder.prompt" 's/`git_handoff` to `cleaner`/`git_handoff` to `architect`/'; expect_red "a handoff that skips the next role"
  fresh; edit "$roles/reviewer.prompt" 's/`git_handoff` to `specifier,coder,cleaner,architect,hardener`/`git_handoff` to `specifier,coder`/'; expect_red "a terminal handoff that is not the full broadcast"
  fresh; touch "$pack/swarmforge/constitution/articles/engineering.prompt"; expect_red "a pack article named like a shared one"
  fresh; edit "$pack/README.md" 's/^| `coder` \(.*\) | task | forward only |$/| `coder` \1 | batch | forward only |/'; expect_red "a README row that disagrees with the conf"
  fresh; printf 'a dash %s here\n' "$(printf '\xe2\x80\x94')" >> "$pack/swarmforge/constitution.prompt"; expect_red "an em dash in the pack"
  echo "selftest OK: the gate accepts the shipped pack and rejects a duplicate role, two masters, an unknown agent, an underscore, a missing prompt, a broken loop, a skipped role, a partial broadcast, a shared-article name, a README mismatch, and an em dash"
  exit 0
fi

root="${PACK_ROOT:-$(cd "$(dirname "$0")/../packs/six-pack" && pwd)}"
conf="$root/swarmforge/swarmforge.conf"
roles_dir="$root/swarmforge/roles"
articles="$root/swarmforge/constitution/articles"
readme="$root/README.md"
status=0
bad() { echo "  ╳ $*" >&2; status=1; }

[ -f "$conf" ] || { echo "check-six-pack: no conf at $conf" >&2; exit 1; }
[ -f "$root/swarmforge/constitution.prompt" ] || bad "missing swarmforge/constitution.prompt"
[ -x "$root/swarm" ] || bad "swarm launcher missing or not executable"
for name in project local-engineering local-workflow; do
  [ -f "$articles/$name.prompt" ] || bad "missing article swarmforge/constitution/articles/$name.prompt"
done

# The launcher's parse rules (swarmforge.bb, parse-window-line and validate-window!).
roles=(); recvs=(); props=(); worktrees=(); masters=0; lineno=0
while IFS= read -r raw || [ -n "$raw" ]; do
  lineno=$((lineno + 1))
  line="$(printf '%s' "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ -z "$line" ]; then continue; fi
  case "$line" in '#'*) continue ;; esac
  # shellcheck disable=SC2086
  set -- $line
  if [ $# -lt 4 ]; then bad "line $lineno: fewer than four fields"; continue; fi
  directive="$1"; role="$2"; agent="$(printf '%s' "$3" | tr '[:upper:]' '[:lower:]')"; wt="$4"; shift 4
  case "$directive" in window|window-invisible) ;; *) bad "line $lineno: unknown directive '$directive'" ;; esac
  case "$role" in *_*) bad "line $lineno: role '$role' contains an underscore" ;; esac
  for r in ${roles[@]+"${roles[@]}"}; do
    if [ "$r" = "$role" ]; then bad "line $lineno: duplicate role '$role'"; fi
  done
  case "$agent" in claude|codex|copilot|grok) ;; *) bad "line $lineno: unsupported agent '$agent'" ;; esac
  case "$wt" in */*|.|..) bad "line $lineno: invalid worktree '$wt'" ;; esac
  if [ "$wt" = master ]; then
    masters=$((masters + 1))
  elif [ "$wt" != none ]; then
    for w in ${worktrees[@]+"${worktrees[@]}"}; do
      if [ "$w" = "$wt" ]; then bad "line $lineno: duplicate worktree '$wt'"; fi
    done
    worktrees+=("$wt")
  fi
  receive=task; propagation=forward-only
  case "${1:-}" in task|batch) receive="$1"; shift ;; esac
  case "${1:-}" in forward-only|back-one|back-all) propagation="$1"; shift ;; esac
  [ -f "$roles_dir/$role.prompt" ] || bad "line $lineno: missing swarmforge/roles/$role.prompt"
  roles+=("$role"); recvs+=("$receive"); props+=("$propagation")
done < "$conf"

n=${#roles[@]}
[ "$n" -gt 0 ] || bad "no window lines in swarmforge.conf"
[ "$masters" -eq 1 ] || bad "exactly one master worktree required, found $masters"

# What the launcher cannot know: the prompts close the handoff loop in conf order.
i=0
while [ "$i" -lt "$n" ]; do
  role="${roles[$i]}"; prompt="$roles_dir/$role.prompt"
  if [ -f "$prompt" ]; then
    for helper in ready_for_next.sh swarm_handoff.sh done_with_current.sh; do
      grep -q "$helper" "$prompt" || bad "$role.prompt never names $helper"
    done
    next=$((i + 1))
    if [ "$next" -lt "$n" ]; then
      grep -qF "\`git_handoff\` to \`${roles[$next]}\`" "$prompt" || bad "$role.prompt does not hand off to the next role in conf order, ${roles[$next]}"
    else
      others=""; j=0
      while [ "$j" -lt "$n" ]; do
        if [ "$j" -ne "$i" ]; then others="${others:+$others,}${roles[$j]}"; fi
        j=$((j + 1))
      done
      grep -qF "\`git_handoff\` to \`$others\`" "$prompt" || bad "$role.prompt is the last role and must broadcast to \`$others\` (that set marks the card Done)"
    fi
  fi
  i=$((i + 1))
done

# A pack article carrying a shared-article name is dropped by get-swarm-forge.
for name in engineering workflow handoffs; do
  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ -n "$(git -C "$root" ls-files "swarmforge/constitution/articles/$name.prompt")" ]; then
      bad "swarmforge/constitution/articles/$name.prompt is tracked; that name belongs to swarm-forge main and the installer drops it"
    fi
  elif [ -e "$articles/$name.prompt" ]; then
    bad "swarmforge/constitution/articles/$name.prompt reuses a shared-article name; the installer drops it"
  fi
done

# The standard bans the character in everything an agent reads (SKILL.md, Interaction).
dash="$(printf '\xe2\x80\x94')"
hits="$(grep -l "$dash" "$root/swarm" "$conf" "$root/swarmforge/constitution.prompt" "$roles_dir"/*.prompt \
        "$articles"/project.prompt "$articles"/local-*.prompt "$readme" 2>/dev/null || true)"
[ -z "$hits" ] || bad "em dash (U+2014) in: $(printf '%s' "$hits" | tr '\n' ' ')"

# The README role table is the operator's view of the conf; the two must agree.
if [ -f "$readme" ]; then
  table="$(awk -F'|' '/^\| `[a-zA-Z-]+` \|/ {
    gsub(/[` ]/, "", $2); gsub(/^ +| +$/, "", $5); gsub(/^ +| +$/, "", $6); gsub(/ /, "-", $6);
    print $2, $5, $6 }' "$readme")"
  expected=""; i=0
  while [ "$i" -lt "$n" ]; do
    expected="${expected}${roles[$i]} ${recvs[$i]} ${props[$i]}"$'\n'
    i=$((i + 1))
  done
  expected="${expected%$'\n'}"
  if [ "$table" != "$expected" ]; then
    bad "README role table disagrees with swarmforge.conf"
    { echo "      expected (role receive propagation):"; printf '%s\n' "$expected" | sed 's/^/        /'
      echo "      README:"; printf '%s\n' "$table" | sed 's/^/        /'; } >&2
  fi
else
  bad "missing README.md in the pack root"
fi

if [ "$status" -eq 0 ]; then
  echo "  ✓ six-pack: $n roles, one master, prompts close the loop, README table matches the conf"
fi
exit "$status"
