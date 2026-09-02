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

## AI-agent hooks — tried, then removed

Atuin 18+ can capture commands run by AI coding agents (Claude Code,
aider, …) into your history alongside the ones you type. It was enabled
here for Claude Code from May 2026, via three `atuin hook claude-code`
hooks on the `Bash` tool matcher in `~/.claude/settings.json`.

**Removed in September 2026.** The reason is arithmetic: of 72,348
entries in the history database, 71,646 were Claude's — 99.0%. Only 702
commands were actually typed by a human. `Ctrl-R` had stopped being a
memory aid and become a log of somebody else's work.

### Filtering, if you ever re-enable them

The hooks are worth knowing about, because atuin *does* distinguish the
two. The `history` table has `author` (`claude-code` vs your username)
and `intent` (the agent's one-line rationale for the command), and
`atuin search` grew an `--author` flag that takes `$all-user`
(non-agents), `$all-agent`, or a literal name:

```sh
atuin search --author '$all-user'    # only what you typed
atuin search --author '$all-agent'   # only what the agent ran
```

Two caveats found the hard way:

- The equivalent key in `config.toml` (`[search] author`) is **ignored**
  — verified against 18.16.1, output identical with and without it. Only
  the CLI flag works.
- To default `Ctrl-R` to human-only you therefore have to wrap the zsh
  widget, which forwards its arguments down to `atuin search`:

  ```zsh
  _atuin_search_human() { _atuin_search --author '$all-user' "$@" }
  zle -N atuin-search-human _atuin_search_human
  bindkey -M emacs '^r' atuin-search-human
  ```

Not installed here — with the hooks gone there is nothing to filter.

### Re-enabling

`atuin hook install claude-code` writes directly to
`~/.claude/settings.json`, reordering its keys alphabetically. That file
is no longer chezmoi-managed (see [claude-code.md](claude-code.md)), so
this no longer causes drift — but it also means the change won't travel
to another machine.

### The archive, and the full reset

The ~71.6k agent commands already recorded were deleted with
`atuin search --author '$all-agent' --delete`, which does honour the
author filter — the 711 human entries survived it. Shortly after, the
whole history was reset from scratch: daemon stopped, then `history.db`,
`records.db`, `meta.db` and `key` removed. Atuin recreates all of them
(and a fresh encryption key) on the next run; config and the zsh binding
are untouched. That reclaimed ~350 MB — `records.db`, the append-only
sync log, had grown to 172 MB on its own and no `atuin` subcommand
compacts it.

Two gotchas met along the way, both worth remembering:

- `--delete` refuses to run on filters alone: `--author '$all-agent'`
  without a query errors with *"Please specify a query"*. Pass an empty
  query (`''`) to mean "everything matching the filters".
- Deleting rows does not shrink `history.db` — the freed pages stay in
  the file. `sqlite3 history.db 'VACUUM;'` took it from 178 MB to 336 KB.

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
- **`atuin daemon`** — *enabled* (`[daemon] enabled = true`,
  `autostart = true`). Background process for faster history writes;
  starts with the first interactive shell. Note it holds the database
  open, so stop it before removing or replacing any file under
  `~/.local/share/atuin/`.

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
