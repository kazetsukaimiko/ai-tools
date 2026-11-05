# Agent roster

The roster moved to [lonewatt-ops](https://github.com/kazetsukaimiko/lonewatt-ops/tree/main/agent_roles). That repo is the process source of truth. This directory is only the pointer.

Install from a clone of lonewatt-ops:

```bash
mkdir -p ~/.grok/agents ~/.grok/roles ~/.config/agent-roster
cp agent_roles/agents/*.md ~/.grok/agents/
cp agent_roles/roles/*.toml ~/.grok/roles/
cp agent_roles/identity.example.md ~/.config/agent-roster/identity.md
```

Fill `~/.config/agent-roster/identity.md`. Logins stay in that file.
