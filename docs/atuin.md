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
