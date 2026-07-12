#!/usr/bin/env bash
# Install safesudo "pkexec-only" memory + global agent rules for Grok and Claude Code.
# No root required. Idempotent: re-run to refresh content.
#
# Usage:
#   ./install-memory.sh
#
# Installs:
#   ~/.grok/memory/safesudo-pkexec-only.md
#   ~/.claude/memory/safesudo-pkexec-only.md
#   Managed section in ~/.grok/AGENTS.md and ~/.claude/CLAUDE.md

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SAFESUDO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
SRC="${SAFESUDO_DIR}/memory/pkexec-only.md"

if [[ ! -f "$SRC" ]]; then
  echo "install-memory: missing $SRC" >&2
  exit 1
fi

MARKER_BEGIN="<!-- safesudo:pkexec-only:begin -->"
MARKER_END="<!-- safesudo:pkexec-only:end -->"

rules_section() {
  cat <<EOF
$MARKER_BEGIN
## Privilege escalation: pkexec only (safesudo)

**ALWAYS use \`pkexec\` for privileged commands** — never \`sudo\`, \`su\`, \`doas\`, \`run0\`, \`kdesu\`, or other parallel elevators (full list in memory file). Lead with \`pkexec\` on the first attempt.

Banned basenames (elev-gate denies these): \`sudo\`, \`sudoedit\`, \`sudoreplay\`, \`su\`, \`doas\`, \`dzdo\`, \`run0\`, \`kdesu\`, \`kdesudo\`, \`gksu\`, \`gksudo\`, \`beesu\`, \`lxqt-sudo\`, \`xdg-su\`, \`pfexec\`, \`pbrun\`, \`sesu\`, \`userv\`.

When session keep is installed, stamp inside elevated batches:

\`\`\`bash
pkexec bash -c 'set -euo pipefail
/usr/local/lib/safesudo/session-keep-stamp
# work…
'
\`\`\`

Full standing memory: see \`safesudo-pkexec-only.md\` under the agent memory directory (installed by safesudo).
$MARKER_END
EOF
}

install_memory_file() {
  local dest=$1
  mkdir -p "$(dirname "$dest")"
  cp "$SRC" "$dest"
  chmod 644 "$dest"
  echo "install-memory: wrote $dest"
}

upsert_rules_section() {
  local dest=$1
  mkdir -p "$(dirname "$dest")"
  local section
  section=$(rules_section)

  if [[ ! -f "$dest" ]]; then
    {
      echo "# Global agent rules"
      echo
      printf '%s\n' "$section"
    } >"$dest"
    echo "install-memory: created $dest"
    return
  fi

  SECTION="$section" BEGIN="$MARKER_BEGIN" END="$MARKER_END" DEST="$dest" python3 <<'PY'
import os
from pathlib import Path

path = Path(os.environ["DEST"])
begin, end = os.environ["BEGIN"], os.environ["END"]
section = os.environ["SECTION"]
if not section.endswith("\n"):
    section += "\n"
text = path.read_text(encoding="utf-8")
if begin in text and end in text:
    pre, rest = text.split(begin, 1)
    _, post = rest.split(end, 1)
    if post.startswith("\n"):
        post = post[1:]
    new = pre.rstrip() + "\n\n" + section
    if post.strip():
        new = new.rstrip() + "\n\n" + post.lstrip()
    if not new.endswith("\n"):
        new += "\n"
    path.write_text(new, encoding="utf-8")
    print(f"install-memory: updated managed section in {path}")
else:
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text + "\n" + section, encoding="utf-8")
    print(f"install-memory: appended managed section to {path}")
PY
  chmod 644 "$dest"
}

# --- Grok ---
install_memory_file "${HOME}/.grok/memory/safesudo-pkexec-only.md"
upsert_rules_section "${HOME}/.grok/AGENTS.md"

GROK_MEMORY_INDEX="${HOME}/.grok/memory/MEMORY.md"
mkdir -p "${HOME}/.grok/memory"
if [[ ! -f "$GROK_MEMORY_INDEX" ]]; then
  cat >"$GROK_MEMORY_INDEX" <<'EOF'
# Global memory

## Preferences

EOF
fi
if ! grep -qF 'safesudo-pkexec-only.md' "$GROK_MEMORY_INDEX" 2>/dev/null; then
  printf '\n## safesudo\n\n- [pkexec-only elevation](safesudo-pkexec-only.md) — never use sudo/su/doas/…; always pkexec\n' \
    >>"$GROK_MEMORY_INDEX"
  echo "install-memory: indexed in $GROK_MEMORY_INDEX"
fi

# --- Claude Code ---
install_memory_file "${HOME}/.claude/memory/safesudo-pkexec-only.md"
upsert_rules_section "${HOME}/.claude/CLAUDE.md"

echo "install-memory: done (pkexec-only memory + global rules)"
echo "  Grok memory:   ${HOME}/.grok/memory/safesudo-pkexec-only.md"
echo "  Grok rules:    ${HOME}/.grok/AGENTS.md"
echo "  Claude memory: ${HOME}/.claude/memory/safesudo-pkexec-only.md"
echo "  Claude rules:  ${HOME}/.claude/CLAUDE.md"
echo "Note: Grok memory *search* needs memory enabled ([memory] enabled = true or GROK_MEMORY=1)."
echo "      AGENTS.md / CLAUDE.md apply even when memory is off."
