#!/usr/bin/env python3
"""PreToolUse gate: deny non-pkexec elevation tools.

stdin:  hook JSON with tool name + toolInput.command
stdout: {"decision": "allow"|"deny", "reason"?: str}
exit:   0 allow, 2 deny

Keep BLOCKLIST in sync with ../SKILL.md
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import PurePosixPath

DENY_REASON = (
    "Elevation via this tool is blocked for agents. Use pkexec so polkit can "
    "authenticate (e.g. pkexec <command> …). Do not use sudo, su, doas, kdesu, "
    "run0, or similar. Retry with pkexec only."
)

# Basenames only (see SKILL.md table).
BLOCKLIST = frozenset(
    {
        "sudo",
        "sudoedit",
        "sudoreplay",
        "su",
        "doas",
        "dzdo",
        "run0",
        "kdesu",
        "kdesudo",
        "gksu",
        "gksudo",
        "beesu",
        "lxqt-sudo",
        "xdg-su",
        "pfexec",
        "pbrun",
        "sesu",
        "userv",
    }
)

SHELL_TOOLS = frozenset(
    {
        "",
        "Bash",
        "bash",
        "run_terminal_command",
        "run_terminal_cmd",
        "Shell",
        "shell",
    }
)

# Split on whitespace and common shell metacharacters; keep path-like tokens.
_SPLIT = re.compile(r'[\s|;&()<>`$"\'\\]+')
_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=.")


def allow() -> None:
    print(json.dumps({"decision": "allow"}))
    raise SystemExit(0)


def deny(reason: str) -> None:
    print(json.dumps({"decision": "deny", "reason": reason}))
    raise SystemExit(2)


def extract_command(payload: dict) -> tuple[str, str]:
    tool = payload.get("toolName") or payload.get("tool_name") or ""
    tool_input = payload.get("toolInput") or payload.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        tool_input = {}
    cmd = (
        tool_input.get("command")
        or tool_input.get("cmd")
        or payload.get("command")
        or ""
    )
    if not isinstance(cmd, str):
        cmd = str(cmd) if cmd is not None else ""
    return str(tool), cmd


def blocked_tokens(cmd: str) -> list[str]:
    hits: list[str] = []
    seen: set[str] = set()
    for part in _SPLIT.split(cmd):
        if not part or part.startswith("-"):
            continue
        if _ASSIGN.match(part) and not part.startswith("/"):
            continue
        base = PurePosixPath(part).name
        if base in BLOCKLIST and base not in seen:
            seen.add(base)
            hits.append(base)
    return hits


def main() -> None:
    raw = sys.stdin.read()
    if not raw.strip():
        deny("elev-gate: empty hook input")

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as e:
        deny(f"elev-gate: invalid JSON input: {e}")

    if not isinstance(payload, dict):
        deny("elev-gate: hook input must be a JSON object")

    tool, cmd = extract_command(payload)

    if tool not in SHELL_TOOLS:
        allow()

    if not cmd.strip():
        allow()

    hits = blocked_tokens(cmd)
    if hits:
        deny(f"{DENY_REASON} Blocked token(s): {' '.join(hits)}")

    allow()


if __name__ == "__main__":
    main()
