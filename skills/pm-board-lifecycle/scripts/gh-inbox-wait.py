#!/usr/bin/env python3
"""Print one unread GitHub notification as a JSON line, then exit.

Sleeps until a notification is waiting. Prints nothing on an empty poll.
Does not mark anything read and does not print a token.

Usage: gh-inbox-wait.py LOGIN [IGNORE_FILE]
IGNORE_FILE is newline-separated notification thread ids to skip.
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

if len(sys.argv) < 2:
    print("usage: gh-inbox-wait.py LOGIN [IGNORE_FILE]", file=sys.stderr)
    sys.exit(2)

login = sys.argv[1]
ignore_path = sys.argv[2] if len(sys.argv) > 2 else ""
interval = int(os.environ.get("GH_INBOX_INTERVAL", "30"))

memory = os.path.expanduser("~/.claude/memory/gh-multi-account.md")
text = open(memory).read()
match = re.search(rf"(?m)^{re.escape(login)}: (ghp_\S+)", text)
if not match:
    print(json.dumps({"login": login, "error": "no token entry"}))
    sys.exit(1)
token = match.group(1)


def ignored():
    if not ignore_path or not os.path.exists(ignore_path):
        return set()
    with open(ignore_path) as handle:
        return {line.strip() for line in handle if line.strip()}


failures = 0
while True:
    request = urllib.request.Request(
        "https://api.github.com/notifications?per_page=20",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "pm-inbox-wait",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            notes = json.load(response)
        failures = 0
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        failures += 1
        if failures >= 5:
            print(json.dumps({"login": login, "error": "notifications request failed"}))
            sys.exit(1)
        time.sleep(interval)
        continue
    skip = ignored()
    for note in notes:
        thread_id = str(note.get("id"))
        if thread_id in skip:
            continue
        subject = note.get("subject") or {}
        print(
            json.dumps(
                {
                    "login": login,
                    "id": thread_id,
                    "reason": note.get("reason"),
                    "url": subject.get("url"),
                    "title": subject.get("title"),
                },
                ensure_ascii=True,
            )
        )
        sys.exit(0)
    time.sleep(interval)
