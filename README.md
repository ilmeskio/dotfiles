# dotfiles

Personal macOS dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a new machine

Two commands:

```sh
# 1. Homebrew (interactive — one time per machine)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. chezmoi + this repo
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply ilmeskio
```

The chezmoi one-liner downloads chezmoi to `~/.local/bin/chezmoi` and runs
`init --apply` against this repo. The install-packages script finds brew at
its canonical install path (`/opt/homebrew/bin/brew` on Apple Silicon,
`/usr/local/bin/brew` on Intel) even if you haven't yet run
`eval $(brew shellenv)` in this shell — so the two commands above can be run
back-to-back in a fresh terminal.

`chezmoi apply` then, in order:

1. Runs `brew bundle` against the [Brewfile](#homebrew-packages) (installs
   CLI tools and casks — including `chezmoi` itself, so future updates go
   through brew rather than the bootstrap binary).
2. Bootstraps oh-my-zsh and clones the [external plugins](#shell---zshrc-oh-my-zsh--external-plugins).
3. Installs the managed dotfiles (`.zshrc`, `.gitconfig`, `.ssh/config`,
   VS Code config, the 1Password LaunchAgent, …).

To sync later changes from the repo:

```sh
chezmoi update    # pull + apply
```

To upgrade chezmoi itself: `brew upgrade chezmoi`.

## Prerequisites

Homebrew is installed by step 1 of the bootstrap above. The two manual
sign-ins below can't be automated:

- **1Password 8** with the SSH agent enabled (Settings → Developer → "Use the
  SSH agent"). Required for the SSH integration; the cask is installed by
  the Brewfile but you still need to sign in once.
- **Mac App Store** — needed for the `mas` entries in the Brewfile (e.g.
  QuickGif). Open App Store.app and sign in once before running
  `chezmoi apply`; `mas` can't sign you in from the CLI on modern macOS.

## What's inside

### Homebrew packages

[`Brewfile`](Brewfile) declares all formulae and casks. The
[`run_onchange_before_install-packages.sh.tmpl`](run_onchange_before_install-packages.sh.tmpl)
script runs `brew bundle` whenever the Brewfile content changes (chezmoi pins
the script's identity to the Brewfile SHA-256). The `before_` prefix ensures
packages are installed *before* the rest of the dotfiles are applied — so
e.g. `fnm` exists by the time `.zshrc` evals it.

The Brewfile itself is listed in `.chezmoiignore` so chezmoi treats it as a
source resource, not a target file (it would otherwise try to install it as
`~/Brewfile`).

### Shell — `.zshrc`, oh-my-zsh & external plugins

[`dot_zshrc`](dot_zshrc) is the managed `~/.zshrc`. It loads oh-my-zsh with a
plugin list that includes the three external autocompletion plugins
installed by
[`run_onchange_install-omz-plugins.sh.tmpl`](run_onchange_install-omz-plugins.sh.tmpl):

- `zsh-autosuggestions` — fish-like inline suggestions from history
- `zsh-syntax-highlighting` — colors commands as you type (must be loaded last)
- `zsh-completions` — extra completions for many tools

The script also bootstraps oh-my-zsh itself on a fresh machine (with
`KEEP_ZSHRC=yes` so it doesn't clobber the chezmoi-managed `.zshrc`).

> **Caveat:** because `.zshrc` is now managed, installers that auto-edit it
> (bun, opencode, pnpm, …) will create drift. After running such an
> installer, run `chezmoi re-add ~/.zshrc` to absorb the changes into the
> source, or port the new lines manually.

### Git — `.gitconfig` & global gitignore

[`dot_gitconfig`](dot_gitconfig) holds identity and `git-lfs` filters.
[`dot_config/private_git/private_ignore`](dot_config/private_git/private_ignore)
is the XDG-located global gitignore (`~/.config/git/ignore`).

### SSH — `~/.ssh/config` and the 1Password agent

Two halves of the same setup:

- **CLI side:** [`private_dot_ssh/private_config`](private_dot_ssh/private_config)
  sets `IdentityAgent` to 1Password's agent socket. Terminal `ssh` reads keys
  from 1Password directly.
- **GUI side:** [`private_Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist`](private_Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist)
  installs a LaunchAgent that, at login, symlinks the default macOS
  `$SSH_AUTH_SOCK` (`/private/tmp/com.apple.launchd.*/Listeners`) to
  1Password's agent socket. Every GUI app that talks to the system SSH agent
  (DBeaver, JetBrains IDEs, etc.) transparently uses 1Password's keys — no
  per-app configuration needed.

The plist uses `$HOME` (expanded at runtime by `sh -c`) instead of a hardcoded
user path, so the same file works on every machine.
[`run_onchange_load-1password-ssh-agent.sh.tmpl`](run_onchange_load-1password-ssh-agent.sh.tmpl)
reloads the LaunchAgent whenever the plist content changes.

**Reference:** 1Password's official guide —
<https://developer.1password.com/docs/ssh/agent/compatibility/#configure-ssh_auth_sock-globally-for-every-client>

### VS Code

User-level `settings.json` and `keybindings.json` (under
`Library/Application Support/Code/User/`). Extensions and the activity sync
are intentionally **not** managed here — those are handled by VS Code's
built-in Settings Sync.

### Claude Code

The Claude Code CLI is installed by
[`run_once_install-claude-code.sh.tmpl`](run_once_install-claude-code.sh.tmpl)
via Anthropic's native installer (`claude.ai/install.sh`) — the binary
lands at `~/.local/share/claude/versions/<version>` with a symlink at
`~/.local/bin/claude`. Subsequent updates are handled by `claude` itself,
not chezmoi (`run_once_` means it runs only on first apply per machine).

The Claude Desktop chat app comes from `cask "claude"` in the Brewfile.

On top of that, a small, deliberate slice of `~/.claude/`:

- [`dot_claude/CLAUDE.md`](dot_claude/CLAUDE.md) — global preferences loaded
  in every Claude Code conversation (language, environment assumptions,
  workflow rules).
- [`dot_claude/private_settings.json.tmpl`](dot_claude/private_settings.json.tmpl)
  — UI preferences (theme, enabled plugins) plus the wiring that points
  the statusline at the script below. Templated so the path embeds
  `{{ .chezmoi.homeDir }}` instead of a hardcoded user.
- [`dot_claude/statusline-command.sh`](dot_claude/statusline-command.sh) +
  [`statusline-helpers.sh`](dot_claude/executable_statusline-helpers.sh) —
  custom statusline scripts (referenced by `settings.json` above).
- [`dot_claude/skills/clipboard/`](dot_claude/skills/clipboard) — custom
  Skill that exposes a cross-platform clipboard helper.

Everything else under `~/.claude/` (`.claude.json`, `history.jsonl`,
`projects/`, `sessions/`, caches, telemetry, …) is **not** managed: it
contains either auth tokens, runtime state, or machine-specific data that
shouldn't follow you across machines.

## chezmoi conventions used here

Chezmoi encodes behavior in filename prefixes. The ones that show up in this
repo:

- **`dot_<name>`** → installs to `~/.<name>` (e.g. `dot_zshrc` → `~/.zshrc`).

- **`private_`** on a directory or file means the target should have
  restrictive permissions (`0700` for dirs, `0600` for files). We use it on
  `private_Library/` because macOS keeps `~/Library` at `0700` by default —
  without the prefix chezmoi would try to relax it to `0755`. SSH and git
  config files also pick up `private_` automatically since their source
  permissions are already restricted.

- **`run_onchange_<name>.sh.tmpl`** is a script chezmoi *executes* during
  `apply`, instead of installing it into `$HOME`. The `onchange_` variant
  reruns the script only when its rendered content changes (alternatives:
  `run_once_` for one-shot, plain `run_` for every apply). The optional
  `before_` modifier (e.g. `run_onchange_before_install-packages.sh.tmpl`)
  forces the script to run *before* file targets are applied.

- **`.tmpl`** marks a file as a Go template processed by chezmoi before being
  written or executed. We use it on the install scripts to embed external
  content's hash via `{{ include "..." | sha256sum }}`. That hash is what
  makes `onchange_` notice when the source changes and re-run the script —
  without it the script would never re-execute, since its own source never
  changes.

- **`.chezmoiignore`** lists source files that should *not* be installed into
  `$HOME`. We use it for `README.md` and `Brewfile` (the Brewfile is a
  resource consumed by `run_onchange_before_install-packages.sh.tmpl`, not a
  file destined for `$HOME`).

Full reference:
<https://www.chezmoi.io/reference/source-state-attributes/>.
