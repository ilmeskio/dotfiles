# Ghostty — terminal emulator

[Ghostty](https://ghostty.org) is a GPU-accelerated terminal by Mitchell
Hashimoto (HashiCorp founder). It's a modern alternative to iTerm2 — fast,
sensible defaults, file-based configuration, and Kitty graphics protocol
support.

## Wired in this repo

- Installed via `cask "ghostty"` in [Brewfile](../Brewfile)
- Config at [`dot_config/ghostty/config`](../dot_config/ghostty/config),
  which chezmoi installs to `~/.config/ghostty/config`

## Reloading config

Inside Ghostty: `Cmd+Shift+,` reloads the config file in the current
window. No restart needed.

## Themes

Ghostty ships with ~300 built-in themes. List them:

```sh
ghostty +list-themes
```

To use one, edit the config and uncomment / replace the line:

```
theme = Catppuccin Macchiato
```

The repo's config has the line commented out as a starting point — pick
what you like. Popular options: `Catppuccin Macchiato`, `Tokyo Night`,
`Dracula`, `Nord`, `Gruvbox Dark`.

## Fonts

The config leaves `font-family` commented (uses the system monospace).
To use a programming font:

1. Add the font cask to `Brewfile`:
   ```ruby
   cask "font-jetbrains-mono"
   ```
2. Uncomment `font-family = JetBrains Mono` in the Ghostty config.
3. `chezmoi apply` and reload Ghostty (`Cmd+Shift+,`).

Other popular options:
- `font-fira-code` (with ligatures)
- `font-cascadia-code`
- `font-iosevka`
- `font-jetbrains-mono-nerd-font` (with icons, useful with Powerlevel10k etc.)

## Keybindings in this config

- `Cmd+Left` / `Cmd+Right` — previous / next tab (macOS-native style)
- `Shift+Enter` — insert a literal newline (handy in REPLs and multi-line
  inputs that submit on plain `Enter`)

Default keybinds (not overridden) still work:
- `Cmd+T` — new tab
- `Cmd+D` — split right
- `Cmd+Shift+D` — split down
- `Cmd+W` — close current surface
- `Cmd+,` — open the config file in `$EDITOR`

## Behavior settings explained

- `confirm-close-surface = false` — don't prompt before closing a tab/split
- `quit-after-last-window-closed = true` — macOS-like behavior (quit when
  last window closes, vs. staying alive in the menubar)
- `clipboard-read/write = allow` — programs running in the terminal can
  read/write the clipboard via OSC 52 (the escape sequence the
  `dot_claude/skills/clipboard/scripts/executable_copy_to_clipboard.sh`
  script uses when SSH'd in)
- `clipboard-trim-trailing-spaces = true` — strip trailing whitespace on
  paste, so pasted snippets don't auto-execute when there's a trailing
  newline

## Further reading

- Documentation: <https://ghostty.org/docs>
- Config reference (all keys): <https://ghostty.org/docs/config/reference>
- Keybind syntax: <https://ghostty.org/docs/config/keybind>
