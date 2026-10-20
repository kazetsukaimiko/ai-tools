# Local agent identity

Copy this file to `~/.config/agent-roster/identity.md` and fill the blanks.
That path is not in this repository. Do not commit the filled file.

`github_tokens` is the file that maps a GitHub login to a token. Agents read
one entry at runtime. They do not print the token.

```text
github_tokens: ~/.config/agent-roster/github-tokens.md

## yuni
github_login:
commit_name:
commit_email:
ssh_key: ~/.ssh/yuni_ed25519

## security
github_login:

## techops
github_login:
commit_name:
commit_email:

## project-manager
github_login:
board_owner:
board_title:
project_number:
board_url:

## sysadmin
browser_profile: ~/.config/sysadmin-browser/profile
proton_pass_token: ~/.config/sysadmin/proton-pass-token
proton_pass_session: ~/.config/sysadmin/proton-pass-session
```

Sysadmin has no GitHub login. Its browser profile and Proton Pass token stay
on the machine. The token file is mode `0600`.
