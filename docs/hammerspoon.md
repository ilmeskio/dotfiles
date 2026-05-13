# Hammerspoon — macOS automation in Lua

[Hammerspoon](https://www.hammerspoon.org) is a macOS-only automation tool
that exposes most of the system (windows, displays, USB, audio, network,
filesystem, …) to Lua scripts. Think AutoHotkey for Mac, but properly
typed and with a much richer API.

## Wired in this repo

- Installed via `cask "hammerspoon"` in [Brewfile](../Brewfile)
- **Config not yet managed.** When you start writing Lua, do:
  ```sh
  chezmoi add ~/.hammerspoon/init.lua
  ```
  and the file moves into the source tree as `dot_hammerspoon/init.lua`.
  Subsequent edits go in the source and propagate via `chezmoi apply`.

## First-run setup (manual, can't be automated)

1. Open Hammerspoon.app (Launchpad or Spotlight) once.
2. Grant **Accessibility** permission:
   *System Settings → Privacy & Security → Accessibility → toggle on
   Hammerspoon.* Without this, the app can't capture global hotkeys or
   manipulate windows.
3. (Optional) Hide the menubar icon if you find it distracting — add this
   to your `init.lua`:
   ```lua
   hs.menuIcon = false
   ```

## What you can build

A non-exhaustive list of common Hammerspoon use cases:

- **Window management** — tile windows to halves/quarters with
  `Cmd+Alt+H/J/K/L`, move between displays, save/restore layouts
- **App launching shortcuts** — `Cmd+Alt+S` opens Slack, `Cmd+Alt+T` Ghostty
- **Context-aware automation** — mute Slack on AirPods disconnect, switch
  audio output when a specific monitor is plugged in, dim screen when
  battery drops below 20%
- **Custom menubar items** — show CPU/network stats, calendar next event
- **Caps Lock remap** — turn Caps Lock into a hyper key for global hotkeys

## Spoons

[Spoons](https://www.hammerspoon.org/Spoons/) are community-maintained Lua
modules — pre-built solutions for common tasks. Install one by dropping
the `.spoon` directory into `~/.hammerspoon/Spoons/` and loading it:

```lua
hs.loadSpoon("MiroWindowsManager")
spoon.MiroWindowsManager:bindHotkeys({
  up    = {{"ctrl", "alt", "cmd"}, "up"},
  right = {{"ctrl", "alt", "cmd"}, "right"},
  down  = {{"ctrl", "alt", "cmd"}, "down"},
  left  = {{"ctrl", "alt", "cmd"}, "left"},
})
```

Useful Spoons to look at: `MiroWindowsManager`, `ReloadConfiguration`,
`SpoonInstall`, `EmmyLua` (for VS Code autocomplete on the Hammerspoon API).

## Minimal starter `init.lua`

```lua
-- Snap focused window to left/right half with Cmd+Alt+Left/Right
hs.hotkey.bind({"cmd", "alt"}, "left", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local f = win:screen():frame()
  win:setFrame({x = f.x, y = f.y, w = f.w / 2, h = f.h})
end)

hs.hotkey.bind({"cmd", "alt"}, "right", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local f = win:screen():frame()
  win:setFrame({x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h})
end)

-- Auto-reload config on file change (so you don't have to click "Reload Config")
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function() hs.reload() end):start()
hs.alert.show("Hammerspoon loaded")
```

Drop this in `~/.hammerspoon/init.lua`, click the Hammerspoon menubar icon
→ *Reload Config*, and the hotkeys are live.

## Further reading

- Getting started: <https://www.hammerspoon.org/go/>
- Full API: <https://www.hammerspoon.org/docs/>
- Community Spoons: <https://www.hammerspoon.org/Spoons/>
- Example configs from the wild:
  - <https://github.com/scottwhudson/Lunette>
  - <https://github.com/dbalatero/dotfiles/tree/master/hammerspoon>
