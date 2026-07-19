#!/usr/bin/env bash
# Install a himalaya config for Proton Bridge using bridge.env (email only).
# Does not write the password into the TOML — uses auth.cmd.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EXAMPLE="${SKILL_DIR}/references/himalaya-config.example.toml"

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/himalaya"
CONF_FILE="${CONF_DIR}/config.toml"
ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/protonmail/bridge.env"

if [[ ! -f "$EXAMPLE" ]]; then
  echo "error: missing example config at $EXAMPLE" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: missing $ENV_FILE — run prompt-bridge-credentials.sh first" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
# shellcheck disable=SC1091
source "$ENV_FILE"
set +a

if [[ -z "${PROTON_BRIDGE_EMAIL:-}" ]]; then
  echo "error: PROTON_BRIDGE_EMAIL empty in bridge.env" >&2
  exit 1
fi

mkdir -p "$CONF_DIR"
if [[ -f "$CONF_FILE" ]]; then
  bak="${CONF_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  cp -a "$CONF_FILE" "$bak"
  echo "ok: backed up existing config to $bak"
fi

# Substitute placeholders; email may contain sed-special chars — use python for safety
python3 - "$EXAMPLE" "$CONF_FILE" "$PROTON_BRIDGE_EMAIL" <<'PY'
import sys
from pathlib import Path
src, dst, email = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
text = src.read_text(encoding="utf-8")
text = text.replace("YOU@EXAMPLE.COM", email)
dst.write_text(text, encoding="utf-8")
print(f"ok: wrote {dst}")
PY

chmod 600 "$CONF_FILE" 2>/dev/null || true
echo "ok: himalaya account points at 127.0.0.1 Bridge; password via bridge.env auth.cmd"
