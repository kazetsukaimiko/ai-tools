#!/usr/bin/env bash
# Offline checks for elev-gate (no Grok required).
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
GATE="$DIR/elev-gate.sh"
chmod +x "$GATE" "$DIR/elev-gate.py"

run() {
  local cmd=$1
  python3 -c 'import json,sys; print(json.dumps({"toolName":"run_terminal_command","toolInput":{"command":sys.argv[1]}}))' "$cmd" \
    | "$GATE" || true
}

expect_deny() {
  local cmd=$1
  local out
  out=$(run "$cmd")
  python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get("decision")=="deny" else 1)' "$out" \
    || { echo "FAIL expected deny: $cmd -> $out" >&2; exit 1; }
  echo "ok deny: $cmd"
}

expect_allow() {
  local cmd=$1
  local out
  out=$(run "$cmd")
  python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get("decision")=="allow" else 1)' "$out" \
    || { echo "FAIL expected allow: $cmd -> $out" >&2; exit 1; }
  echo "ok allow: $cmd"
}

expect_deny "sudo true"
expect_deny "sudo -i"
expect_deny "/usr/bin/sudo pacman -Syu"
expect_deny "su -"
expect_deny "su -c id"
expect_deny "doas pacman -S foo"
expect_deny "pkexec bash -c 'sudo true'"
expect_deny "env sudo true"
expect_deny "run0 true"
expect_deny "kdesu true"

expect_allow "pkexec true"
expect_allow "pkexec pacman -S foo"
expect_allow "ls -la /etc/sudoers"
expect_allow "cat /etc/sudoers.d/readme"
expect_allow "git status"
expect_allow "echo no-elevation-here"
# substring must not match: path ends with sudoers, not basename sudo
expect_allow "grep -n Defaults /etc/sudoers"

echo "All selftests passed."
