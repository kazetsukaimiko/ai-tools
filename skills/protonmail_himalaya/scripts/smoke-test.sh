#!/usr/bin/env bash
# Read-only connectivity check for Bridge + himalaya.
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "error: missing $1" >&2; exit 1; }; }
need himalaya

ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/protonmail/bridge.env"
CONF_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/himalaya/config.toml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: missing $ENV_FILE" >&2
  exit 1
fi
if [[ ! -f "$CONF_FILE" ]]; then
  echo "error: missing $CONF_FILE — run install-himalaya-config.sh" >&2
  exit 1
fi

if ! ss -ltn 2>/dev/null | grep -qE '127\.0\.0\.1:1143'; then
  echo "warn: nothing listening on 127.0.0.1:1143 — is Proton Bridge running?" >&2
fi
if ! ss -ltn 2>/dev/null | grep -qE '127\.0\.0\.1:1025'; then
  echo "warn: nothing listening on 127.0.0.1:1025 — is Proton Bridge SMTP up?" >&2
fi

echo "=== account list ==="
himalaya account list 2>/dev/null || himalaya account list

echo "=== folder list (first 30 lines) ==="
himalaya folder list 2>/dev/null | head -30 || himalaya folder list | head -30

echo "=== INBOX sample (5) ==="
himalaya envelope list --folder INBOX --page-size 5 order by date desc 2>/dev/null \
  || himalaya envelope list --folder INBOX --page-size 5 order by date desc

echo "ok: smoke test finished (read-only)"
