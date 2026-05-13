# Documentation index

Deep-dive notes on the tools and conventions used in this dotfiles repo.
Anything that would bloat the top-level [README](../README.md) lives here.

These files are excluded from `chezmoi apply` via `.chezmoiignore`, so they
stay in the source repo and never get installed into `$HOME`.

## Tools

- [atuin.md](atuin.md) — modern shell history (replaces zsh's `Ctrl-R`)
- [direnv.md](direnv.md) — per-directory env vars from `.envrc`
- [mise.md](mise.md) — multi-runtime version manager (dormant; replaces `fnm` when ready)
- [ghostty.md](ghostty.md) — terminal config, theme picking, font customization
- [hammerspoon.md](hammerspoon.md) — macOS automation in Lua

## Workflow

- [upstream-review.md](upstream-review.md) — periodically pulling spunti from
  [harperreed/dotfiles](https://github.com/harperreed/dotfiles)

## Conventions

The `ABOUTME:` header convention is documented directly in the top-level
[README](../README.md) under *Repo conventions (not chezmoi)*.
