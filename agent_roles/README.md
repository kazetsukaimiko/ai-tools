# Agent roster

Grok Build seats for this team. Each seat is a pair: an agent file (what it
does and how) and a role file (capability and reasoning effort).

| Agent | Owns |
| --- | --- |
| [onboarding](agents/onboarding.md) | Agent definitions and team shape |
| [project-manager](agents/project-manager.md) | The human's GitHub project boards |
| [security](agents/security.md) | Security review of pull requests and designs |
| [yuni](agents/yuni.md) | Product frontend and backend code |
| [techops](agents/techops.md) | Work inside a VPS that already exists, and runtime pull requests |
| [sysadmin](agents/sysadmin.md) | Provider accounts above the VPS, initial provisioning, and granting access |

Sysadmin has no GitHub account. Techops does not create or destroy machines.

## Install

```bash
mkdir -p ~/.grok/agents ~/.grok/roles ~/.config/agent-roster
cp agent_roles/agents/*.md ~/.grok/agents/
cp agent_roles/roles/*.toml ~/.grok/roles/
cp agent_roles/identity.example.md ~/.config/agent-roster/identity.md
```

Fill `~/.config/agent-roster/identity.md`. Logins, email addresses, the board,
and token paths stay in that file. They do not belong in git.

In the installed `sysadmin.md`, replace the Playwright `--user-data-dir`
argument with the absolute profile path. The browser process does not expand
`~`. Leave the server headed, and let it inherit the desktop `DISPLAY`.

Start a new Grok session after copying. The Playwright server is declared on
sysadmin only.
