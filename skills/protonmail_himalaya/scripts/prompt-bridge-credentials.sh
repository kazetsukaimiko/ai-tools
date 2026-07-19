#!/usr/bin/env bash
# Prompt for Proton Bridge mailbox credentials and write a local env file.
# SECURITY: never print the password. Only status lines go to stdout/stderr.
# Prefer: kdialog → zenity → TTY (read -s).
set -euo pipefail

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/protonmail"
ENV_FILE="${CONF_DIR}/bridge.env"
MODE_DIR=700
MODE_FILE=600

mkdir -p "$CONF_DIR"
chmod "$MODE_DIR" "$CONF_DIR"

have() { command -v "$1" >/dev/null 2>&1; }

prompt_text() {
  local title="$1" label="$2" default="${3:-}"
  if have kdialog; then
    kdialog --title "$title" --inputbox "$label" "$default"
  elif have zenity; then
    zenity --title "$title" --entry --text "$label" --entry-text "$default"
  else
    if [[ -n "$default" ]]; then
      read -r -p "$label [$default]: " val
      printf '%s\n' "${val:-$default}"
    else
      read -r -p "$label: " val
      printf '%s\n' "$val"
    fi
  fi
}

prompt_password() {
  local title="$1" label="$2"
  if have kdialog; then
    kdialog --title "$title" --password "$label"
  elif have zenity; then
    zenity --title "$title" --password --text "$label"
  else
    read -r -s -p "$label: " val
    echo >/dev/tty || true
    printf '%s\n' "$val"
  fi
}

# Existing email default (do not read password into shell for defaulting)
default_email=""
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  default_email="$(grep -E '^PROTON_BRIDGE_EMAIL=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true)"
fi

email="$(prompt_text 'Proton Bridge' 'Bridge mailbox email (full address):' "$default_email" || true)"
if [[ -z "${email// }" ]]; then
  echo "error: email cancelled or empty" >&2
  exit 1
fi

# Basic sanity — no spaces; must look like an address (placeholder-safe)
if [[ "$email" != *@* ]]; then
  echo "error: email should look like user@domain" >&2
  exit 1
fi

pass="$(prompt_password 'Proton Bridge' 'Bridge mailbox password (from Bridge UI, not Proton login):' || true)"
if [[ -z "${pass}" ]]; then
  echo "error: password cancelled or empty" >&2
  exit 1
fi

umask 077
tmp="$(mktemp "${CONF_DIR}/bridge.env.XXXXXX")"
# Quote-safe write (values may contain special chars; use single-line ENV format)
{
  printf 'PROTON_BRIDGE_EMAIL=%s\n' "$email"
  # Password: if it contains newline, reject
  if [[ "$pass" == *$'\n'* ]]; then
    echo "error: password must be a single line" >&2
    rm -f "$tmp"
    exit 1
  fi
  printf 'PROTON_BRIDGE_PASSWORD=%s\n' "$pass"
} >"$tmp"
chmod "$MODE_FILE" "$tmp"
mv -f "$tmp" "$ENV_FILE"
chmod "$MODE_FILE" "$ENV_FILE"

# Scrub locals (best-effort)
email=''
pass=''
unset email pass

echo "ok: wrote ${ENV_FILE} (mode ${MODE_FILE})"
echo "ok: password not printed; himalaya should use auth.cmd sourcing this file"
