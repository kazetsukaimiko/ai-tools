# Security item schema (`ITEM.md`)

Each checklist entry is a directory under `security/items/` containing at least `ITEM.md`. Optional `check.sh` (or path named in frontmatter) performs a **read-only** machine check.

## Directory layout

```text
security/items/<area>/.../<item_slug>/
  ITEM.md       # required
  check.sh      # optional; must be executable when used
```

Example: `security/items/browsers/firefox/plugins/ublock_origin/`.

## Frontmatter fields

YAML between `---` fences at the top of `ITEM.md`:

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Stable dotted id, e.g. `browsers.firefox.plugins.ublock_origin` |
| `title` | yes | Short human title |
| `severity` | yes | `info` \| `low` \| `medium` \| `high` |
| `tags` | no | List of strings (`browser`, `privacy`, `network`, …) |
| `greenlist` | no | `true` if this is a group-recommended control when applicable (default `false`) |
| `platforms` | no | e.g. `[linux]` |
| `install_vectors` | no | Where the control may live, e.g. `system-firefox`, `flatpak-firefox` |
| `requires_elevation_to_fix` | no | `true` if a typical fix needs root/polkit (default `false`) |
| `check` | no | Relative path to a check script (default `check.sh` if that file exists) |

## Body sections (recommended)

Use these H2 headings so agents parse consistently:

1. **Why** — threat / rationale (no secrets).
2. **How to check (agent)** — steps if there is no script, or how to interpret the script.
3. **How to fix (agent)** — user-consent-first remediation; prefer user-level changes; use `pkexec` for elevation (see safesudo).
4. **Notes** — limits, false positives, Flatpak vs system.

## Optional `check.sh` contract

- **Read-only.** Do not change system state.
- Print **one JSON object** to stdout (pretty or compact):

```json
{
  "status": "pass",
  "summary": "short human string",
  "evidence": {},
  "fix_hint": "optional"
}
```

| `status` | Meaning |
|----------|---------|
| `pass` | Control satisfied |
| `fail` | Not satisfied |
| `warn` | Partial / uncertain / degraded |
| `skip` | Not applicable on this host |
| `error` | Checker could not run |

- Exit code **`0`**: checker ran (status may still be `fail` / `warn` / `skip`).
- Exit code **`2`**: checker error (treat result as `error` if JSON missing).
- Use `$HOME` / XDG; do not hardcode personal usernames or hostnames.
- Prefer best-effort multi-vector checks (system package + Flatpak paths).

## Greenlist semantics

When `greenlist: true` and status is `fail` (or missing install when expected), the audit report should call this out as a **group-recommended gap**, not only a generic fail.
