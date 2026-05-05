# dotfiles

Personal macOS dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a new machine

```sh
brew install chezmoi
chezmoi init <this-repo-url>
chezmoi diff      # review what will change
chezmoi apply
```

## What's inside

### 1Password SSH agent — global `SSH_AUTH_SOCK`

`private_Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist` installs a
LaunchAgent that, at login, symlinks the default macOS `$SSH_AUTH_SOCK`
(`/private/tmp/com.apple.launchd.*/Listeners`) to 1Password's agent socket at
`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`.

This makes every GUI app that talks to the system SSH agent (DBeaver,
JetBrains IDEs, etc.) transparently use 1Password's keys — no per-app
configuration needed. Terminal SSH is also covered via `~/.ssh/config`'s
`IdentityAgent` directive.

The plist uses `$HOME` (expanded at runtime by `sh -c`) instead of a hardcoded
user path, so the same file works on every machine.

`run_onchange_load-1password-ssh-agent.sh.tmpl` reloads the LaunchAgent
whenever the plist content changes (chezmoi pins the script to the plist's
SHA-256 via `{{ include ... | sha256sum }}`).

**Reference:** 1Password's official guide to this setup —
<https://developer.1password.com/docs/ssh/agent/compatibility/#configure-ssh_auth_sock-globally-for-every-client>

### Prerequisites

- 1Password 8 with the SSH agent enabled (Settings → Developer → "Use the SSH agent").
