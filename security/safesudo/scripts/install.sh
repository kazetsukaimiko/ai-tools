#!/usr/bin/env bash
# Full safesudo user-space install: elev-gate hook + pkexec-only memory/rules.
# Optional: --with-session-keep (needs polkit/pkexec; will prompt once).
#
# Usage:
#   ./install.sh
#   ./install.sh --with-session-keep
#   REPO=/path/to/ai-tools ./install.sh

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SAFESUDO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
# Prefer REPO if set; else parent of security/safesudo
REPO="${REPO:-$(cd "$SAFESUDO_DIR/../.." && pwd)}"

WITH_SESSION_KEEP=0
for arg in "$@"; do
  case "$arg" in
    --with-session-keep) WITH_SESSION_KEEP=1 ;;
    -h|--help)
      echo "Usage: $0 [--with-session-keep]"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

echo "safesudo install: REPO=$REPO"

# 1) PreToolUse elev-gate (Grok)
mkdir -p "${HOME}/.grok/hooks"
cp "$SAFESUDO_DIR/scripts/elev-gate.sh" \
   "$SAFESUDO_DIR/scripts/elev-gate.py" \
   "${HOME}/.grok/hooks/"
cp "$SAFESUDO_DIR/elev-gate.json" "${HOME}/.grok/hooks/elev-gate.json"
chmod +x "${HOME}/.grok/hooks/elev-gate.sh" "${HOME}/.grok/hooks/elev-gate.py"
echo "safesudo install: elev-gate → ${HOME}/.grok/hooks/"

# 2) Memory + global rules (required)
bash "$SCRIPT_DIR/install-memory.sh"

# 3) Optional session keep (root via pkexec)
if [[ "$WITH_SESSION_KEEP" -eq 1 ]]; then
  if ! command -v pkexec >/dev/null 2>&1; then
    echo "safesudo install: pkexec not found; skip session keep" >&2
    exit 1
  fi
  pkexec bash -c "set -euo pipefail
install -d -m 755 /usr/local/lib/safesudo
install -m 755 \"$SAFESUDO_DIR/scripts/session-keep-stamp\" \
               \"$SAFESUDO_DIR/scripts/session-keep-check\" \
               /usr/local/lib/safesudo/
install -d -m 750 /etc/polkit-1/rules.d
install -m 644 \"$SAFESUDO_DIR/polkit/49-pkexec-keep.rules\" \
               /etc/polkit-1/rules.d/49-pkexec-keep.rules"
  echo "safesudo install: session keep helpers + polkit rule installed"
fi

if [[ -x "$SCRIPT_DIR/selftest.sh" ]]; then
  echo "safesudo install: running elev-gate selftest…"
  "$SCRIPT_DIR/selftest.sh" || true
fi

echo "safesudo install: complete"
echo "  Reload Grok hooks if a session is open: /hooks → r"
echo "  Memory file + AGENTS.md/CLAUDE.md sections install pkexec-only policy for agents"
