# atuin — modern shell history

[atuin](https://atuin.sh) replaces zsh's `Ctrl-R` substring search with a
TUI that does fuzzy matching across a SQLite-backed history. It records
the full context of every command (cwd, exit code, duration, hostname,
session), and **optionally** syncs end-to-end-encrypted across machines.

## Wired in this repo

- Installed via `brew "atuin"` in [Brewfile](../Brewfile)
- Activated in [dot_zshrc](../dot_zshrc) with `eval "$(atuin init zsh)"`,
  placed after `oh-my-zsh.sh` because it rebinds the history widgets

On first launch atuin imports your existing `~/.zsh_history` automatically,
so no history is lost when you start using it.

## Key bindings (defaults)

- `Ctrl-R` — open the search TUI (fuzzy across the whole history)
- Inside the TUI:
  - `Tab` — toggle filter mode (Global / Host / Session / Directory)
  - `Ctrl-D` — toggle directory filter (just commands run *here*)
  - `Esc` — cancel
  - `Enter` — accept and edit
  - `Tab` (in some configs) — accept and run

## Useful commands

```sh
atuin search 'gh pr'           # CLI search without the TUI
atuin stats                    # most-used commands, totals, time spent
atuin history list --cwd .     # all commands run in this directory
```

## AI-agent hooks

Atuin 18+ ships a feature to capture commands run by AI coding agents
(Claude Code, aider, …) into your atuin history alongside the ones you
type. Enabled in this repo for Claude Code.

### What's installed

`~/.claude/settings.json` registers three Claude Code hooks — all on
the `Bash` tool matcher — that pipe the tool input through
`atuin hook claude-code`:

- `PreToolUse` — records the command before execution
- `PostToolUse` — records exit code, duration, output snippet
- `PostToolUseFailure` — captures failures explicitly

The config is templated in
[`dot_claude/private_settings.json.tmpl`](../dot_claude/private_settings.json.tmpl)
so it travels with chezmoi.

### Why it's useful

After a session you can `atuin search` and find both the commands you
typed yourself *and* the ones Claude ran (e.g., `git diff`, `gh api`,
`chezmoi apply`). Handy when you remember "we ran something yesterday
that did X" but can't remember whether it was you or the agent.

### Filtering them out

If the agent commands clutter your `Ctrl-R` results, atuin lets you
filter by session/host/cwd inside the TUI. There's no official "hide
AI commands" flag yet — keep an eye on the
[atuin changelog](https://github.com/atuinsh/atuin/releases) for one.

### Removing the hooks

`atuin hook` doesn't ship an `uninstall` subcommand. To disable:

1. Edit the template
   [`dot_claude/private_settings.json.tmpl`](../dot_claude/private_settings.json.tmpl)
   and remove the `"hooks"` block.
2. `chezmoi apply ~/.claude/settings.json` to push the change to `$HOME`.

### Drift warning when re-running `atuin hook install`

`atuin hook install claude-code` writes directly to
`~/.claude/settings.json` and reorders the keys alphabetically. Since
this file is chezmoi-managed via a `.tmpl`, every install creates a
drift between source and target. The repo template is already in the
post-install state (sorted keys, hooks block present), so this isn't
an issue today — but if you re-run `atuin hook install` after editing
the template, you'll have to merge the changes back into the `.tmpl`
manually (`chezmoi re-add` doesn't work on templates).

## Other features (and what we deliberately skipped)

Atuin keeps growing beyond shell history. Quick verdict on each, for
this specific setup:

- **`atuin dotfiles alias` / `atuin dotfiles var`** — *skipped*.
  Stores aliases and env vars in atuin's synced DB. For a setup that
  already has chezmoi as the source-of-truth for `~/.zshrc`, this
  creates two places to look for "why does this alias exist" and makes
  the dotfiles incomplete when atuin sync is down. Right answer for
  people without a dotfiles manager — wrong for us.
- **`atuin scripts`** — *skipped*. Stores reusable snippets synced via
  the atuin server. Our equivalent is `~/.local/bin/` versioned in
  chezmoi: more transparent, no external dependency. Reconsider only
  for sensitive snippets that shouldn't go in a public repo.
- **`atuin ai inline`** — *not enabled*. TUI overlay that suggests
  shell commands via cloud LLMs as you type, using your atuin history
  as context. Costs tokens; overlaps heavily with Claude Code in
  another pane. Worth a play only if you genuinely want shell-level AI
  completion.
- **`atuin daemon`** — *not enabled*. Experimental background process
  for faster history writes. Wait until it's marked stable.

## Optional: cloud sync

Atuin's default server is `api.atuin.sh` (managed by the project author)
and sync is end-to-end-encrypted with a key derived from a passphrase you
set.

```sh
atuin register -u <username> -e <email>   # creates the account
atuin login -u <username>                  # on a second machine
atuin sync                                 # bidirectional sync
```

To self-host, point `~/.config/atuin/config.toml` at your own server URL.

## Pitfalls

- The `Up` arrow's behavior changes if atuin's `up_arrow` keybind is left
  on its default. If you preferred plain "last command" recall, edit
  `~/.config/atuin/config.toml`:
  ```toml
  enter_accept = false
  inline_height = 0
  ```
  Or unbind `up_arrow` entirely with `atuin init zsh --disable-up-arrow`.
- `.zsh_history` is still written to in parallel (atuin doesn't take it
  over), so any tool that reads it keeps working. Atuin reads from its
  own SQLite DB at `~/.local/share/atuin/history.db`.

## Further reading

- Official docs: <https://docs.atuin.sh>
- Self-hosting guide: <https://docs.atuin.sh/self-hosting/>
- Config reference: <https://docs.atuin.sh/configuration/config/>
