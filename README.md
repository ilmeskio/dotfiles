# dotfiles

Personal macOS dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a new machine

```sh
brew install chezmoi
chezmoi init --apply https://github.com/ilmeskio/dotfiles.git
```

To sync later changes from the repo:

```sh
chezmoi update    # pull + apply
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

## chezmoi conventions used here

Chezmoi encodes behavior in filename prefixes. The ones that show up in this
repo:

- **`private_`** on a directory or file means the target should have
  restrictive permissions (`0700` for dirs, `0600` for files). We use
  `private_Library/` because macOS keeps `~/Library` at `0700` by default —
  without the prefix chezmoi would try to relax it to `0755`.

- **`run_onchange_<name>.sh.tmpl`** is a script chezmoi *executes* during
  `apply`, instead of installing it into `$HOME`. The `onchange_` variant
  reruns the script only when its rendered content changes (alternatives:
  `run_once_` for one-shot, plain `run_` for every apply).

- **`.tmpl`** marks a file as a Go template processed by chezmoi before being
  written or executed. We use it on the reload script to embed the plist's
  hash via `{{ include "..." | sha256sum }}`. That hash is what makes
  `onchange_` notice when the plist changes and re-run the reload — without
  it the script would never re-execute, since its own source never changes.

Other conventions you'll likely meet as the repo grows: `dot_zshrc` →
`~/.zshrc`, `private_dot_ssh/config` → `~/.ssh/config` with `0700` perms,
`encrypted_<name>` for files encrypted with `age`/`gpg`. Full reference:
<https://www.chezmoi.io/reference/source-state-attributes/>.
