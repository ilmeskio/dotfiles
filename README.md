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

That bootstrap binary stays the one you use: `~/.local/bin` precedes
`/opt/homebrew/bin` in `PATH`, so a Homebrew copy would sit there shadowed
and never run — which is exactly what happened between May and September
2026, leaving the real chezmoi four months stale while `brew upgrade`
dutifully updated a binary nobody invoked. chezmoi is therefore kept out of
the Brewfile on purpose; update it in place with `chezmoi upgrade`.

`chezmoi apply` then, in order:

1. Asks once for the personal data kept out of this public repo (see
   [Personal data](#personal-data-and-work-files)).
2. Runs `brew bundle` against the [Brewfile](#homebrew-packages) (installs
   CLI tools and casks).
3. Bootstraps oh-my-zsh and clones the [external plugins](#shell---zshrc-oh-my-zsh--external-plugins).
4. Installs the managed dotfiles (`.zshrc`, `.gitconfig`, `.ssh/config`,
   VS Code config, the 1Password LaunchAgent, …) and writes the work tools
   kept as 1Password documents.

Then `mise install` installs the global tools of
[`~/.config/mise/config.toml`](dot_config/mise/config.toml), `ai-profile`
included; its first run restores the private part of its configuration
from 1Password (see [AI agents](#ai-agents--ai-profile)).

To sync later changes from the repo:

```sh
chezmoi update    # pull + apply
```

To upgrade chezmoi itself: `chezmoi upgrade`.

## Prerequisites

Homebrew is installed by step 1 of the bootstrap above. The two manual
sign-ins below can't be automated:

- **1Password 8** with the SSH agent enabled (Settings → Developer → "Use the
  SSH agent") and the CLI integration ("Integrate with 1Password CLI").
  Required for SSH and for the files restored from 1Password documents; the
  cask is installed by the Brewfile but you still need to sign in once.
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
e.g. `mise` exists by the time `.zshrc` evals it.

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

- [`dot_agents/AGENTS.md.tmpl`](dot_agents/AGENTS.md.tmpl) →
  `~/.agents/AGENTS.md` — instructions shared by every coding agent
  (language, environment, workflow rules); each profile's `CLAUDE.md` links
  to it.
- `~/.claude/settings.json` — **not managed**, on purpose: Claude Code
  rewrites it on its own and it drifted permanently against the source.
  See [docs/claude-code.md](docs/claude-code.md) for the reasoning and
  the handful of settings worth restoring by hand.
- [`dot_claude/statusline-command.sh`](dot_claude/statusline-command.sh) +
  [`statusline-helpers.sh`](dot_claude/executable_statusline-helpers.sh) —
  custom statusline scripts (referenced by `settings.json` in `$HOME`).
- [`dot_claude/skills/clipboard/`](dot_claude/skills/clipboard) — custom
  Skill that exposes a cross-platform clipboard helper.
- [`dot_claude/skills/fm-offload/`](dot_claude/skills/fm-offload),
  [`preview/`](dot_claude/skills/preview) and
  [`herdr-preview/`](dot_claude/skills/herdr-preview) — own Skills: light
  text work on Apple's on-device model, and pages or panes that put
  questions, diffs and documents in front of the user.
- [`dot_claude/skills/humanizer/`](dot_claude/skills/humanizer) and
  [`dot_claude/skills/session-reflection-analysis/`](dot_claude/skills/session-reflection-analysis)
  — Skills imported verbatim from
  [harperreed/dotfiles](https://github.com/harperreed/dotfiles). The
  first edits text to remove AI-writing patterns; the second analyzes
  past Claude Code session logs for inefficiencies. See
  [`docs/imported-skills.md`](docs/imported-skills.md) for provenance and
  re-sync instructions.

Everything else under `~/.claude/` (`.claude.json`, `history.jsonl`,
`projects/`, `sessions/`, caches, telemetry, …) is **not** managed: it
contains either auth tokens, runtime state, or machine-specific data that
shouldn't follow you across machines.

### AI agents — ai-profile

Agents run through [ai-profile](https://github.com/ilmeskio/ai-profiles),
which picks the profile (Claude account, MCP servers, secrets) from the
current folder:

- [`dot_local/share/ai-profiles/shims/`](dot_local/share/ai-profiles/shims)
  links `claude` and `codex` to `ai-profile`; the folder comes first in
  `PATH` (`~/.zprofile` for login shells and GUI apps, last `PATH` change
  in `dot_zshrc` for interactive ones).
- [`private_dot_claude-personale/`](private_dot_claude-personale) holds the
  default profile's links to the shared parts of `~/.claude`; client
  profiles are created by `ai-profile new` and `ai-profile sync`.
- [`dot_config/ai-profiles/config.toml`](dot_config/ai-profiles/config.toml)
  and [`dot_config/private_ai-secrets/config.toml`](dot_config/private_ai-secrets/config.toml)
  are the public part of the configuration. Client profiles, emails and
  vault references sit in each tool's `private.toml`, which `ai-profile
  backup` / `ai-secrets backup` save as 1Password documents and the tools
  restore when it is missing.

### Personal data and work files

The repo is public. What names clients, people or infrastructure stays out
of it:

- [`.chezmoi.toml.tmpl`](.chezmoi.toml.tmpl) asks on `chezmoi init` for the
  personal Google account and work mail used in `~/.agents/AGENTS.md`, and
  stores them in the local `~/.config/chezmoi/chezmoi.toml`.
- Work tools with client hosts (`~/.local/bin/vpn`, `~/.local/bin/sshto`)
  are `create_` templates that read a 1Password document, so they are
  written only when missing. After changing one:
  `op document edit <name> --vault Work ~/.local/bin/<name>`.

### Shell productivity — direnv, mise

Two CLI tools installed by the Brewfile and wired into `dot_zshrc`:

- **[direnv](https://direnv.net)** loads project-local environment variables
  from `.envrc`. Run `direnv allow` once per file to authorize. See
  [`docs/direnv.md`](docs/direnv.md).
- **[mise](https://mise.jdx.dev)** manages Node, Ruby and the tools a
  project pins (Go, OpenTofu, Supabase, …): global versions in
  [`~/.config/mise/config.toml`](dot_config/mise/config.toml), a project's
  in its `mise.toml` (own repos) or the globally ignored `mise.local.toml`
  (repos of others). See [`docs/mise.md`](docs/mise.md).

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

- **`create_`** writes the file only when it is missing; later changes in
  home are left alone. Used for the files read from 1Password documents.

- **`symlink_<name>.tmpl`** creates a symlink whose target is the rendered
  content (the ai-profile shims and profile links).

- **`.chezmoi.toml.tmpl`** generates chezmoi's own config on `chezmoi init`:
  personal data prompts and `git.autoCommit`, so `chezmoi add`, `edit`,
  `re-add` and `forget` commit the source. Pushing stays manual
  (`chezmoi git -- push`).

- **`.chezmoiignore`** lists source files that should *not* be installed into
  `$HOME`. We use it for `README.md` and `Brewfile` (the Brewfile is a
  resource consumed by `run_onchange_before_install-packages.sh.tmpl`, not a
  file destined for `$HOME`).

Full reference:
<https://www.chezmoi.io/reference/source-state-attributes/>.

## Repo conventions (not chezmoi)

### `ABOUTME:` header on every script and config file

Every script and config file in this repo starts with two `# ABOUTME:`
comment lines (right after the shebang, if any):

1. **What** the file is — one line.
2. **How it's wired in** — who sources/executes it, key dependency, or the
   non-obvious gotcha worth knowing at first glance.

Example:

```sh
#!/bin/sh
# ABOUTME: Runs `brew bundle` against the Brewfile; reruns whenever the Brewfile content changes
# ABOUTME: Hash below ties this script's identity to the Brewfile so chezmoi sees the onchange:
```

The prefix is intentionally improbable so the whole repo can be indexed
with a single grep:

```sh
grep -rH '^# ABOUTME:' .
```

The convention applies to every file we add. Exceptions:

- `*.json.tmpl` files whose rendered output is JSON (no comment syntax) —
  there the description lives in this README instead.
- `SKILL.md` files under `dot_claude/skills/*/` — the YAML frontmatter
  already serves as self-description, and skills imported from upstream
  are kept byte-identical to enable clean re-syncs. See
  [`docs/imported-skills.md`](docs/imported-skills.md).

## Further reading

Deep-dive notes on individual tools and workflows live under
[`docs/`](docs/) — one markdown file per topic. They're kept out of
`$HOME` via `.chezmoiignore`, so they stay as repo documentation only:

- [`docs/direnv.md`](docs/direnv.md) — per-directory env vars
- [`docs/mise.md`](docs/mise.md) — runtimes and project tools
- [`docs/upstream-review.md`](docs/upstream-review.md) — periodically
  pulling spunti from
  [harperreed/dotfiles](https://github.com/harperreed/dotfiles)
- [`docs/imported-skills.md`](docs/imported-skills.md) — Claude Code
  skills pulled in verbatim from upstream (provenance + re-sync)
