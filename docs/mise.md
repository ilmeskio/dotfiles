# mise — multi-runtime version manager

[mise](https://mise.jdx.dev) (formerly `rtx`) manages versions of multiple
language runtimes from a single config file. It's the modern successor to
`asdf`, written in Rust, with faster startup and built-in support for
common runtimes (Node, Python, Go, Ruby, Java, …) without needing per-tool
plugins.

## Status in this repo

**Dormant.** The binary is installed via the Brewfile but the activation
line in [dot_zshrc](../dot_zshrc) is commented out. `fnm` remains the
active Node version manager.

## Why not flip the switch yet?

Switching from `fnm` to `mise` means:

- Translating any project-local `.nvmrc` files to `.tool-versions` (or
  leaving both — mise reads `.nvmrc` natively).
- Reinstalling Node versions under mise's data dir (`~/.local/share/mise`).
  The first `cd` into each project will be a bit slow while mise downloads.
- Editors and CI that don't see `mise activate` in their environment may
  fall back to system Node. Cursor/VS Code usually picks it up from the
  shell; CI runners typically don't.

Worth doing on a free afternoon, not mid-project.

## Migration steps

1. Remove `eval "$(fnm env --use-on-cd --shell zsh)"` from `dot_zshrc`.
2. Uncomment `eval "$(mise activate zsh)"` in the same file.
3. (Optional) Remove `brew "fnm"` from the Brewfile.
4. For each project, ensure there's a `.tool-versions` (or `mise.toml`):
   ```
   node 20.11.0
   python 3.12.1
   ```
5. Run `mise install` once in each project to download the versions.
6. `chezmoi apply` to pick up the new `.zshrc`.

## Useful commands

```sh
mise use --global node@lts            # set global default
mise use node@20                      # add to this project's .tool-versions
mise install                          # install everything declared
mise current                          # what's active here, by runtime
mise ls                               # all installed versions
mise outdated                         # versions that could be upgraded
```

## `.tool-versions` vs `mise.toml`

- **`.tool-versions`** — same format as asdf, max compatibility. One line
  per runtime: `<runtime> <version>`.
- **`mise.toml`** — TOML, supports `[env]`, `[tasks]`, hooks, plugin
  pinning. Use when you outgrow the simple format.

mise reads both; if both exist in the same dir, `mise.toml` wins.

## Further reading

- Getting started: <https://mise.jdx.dev/getting-started.html>
- Comparison to asdf: <https://mise.jdx.dev/dev-tools/comparison-to-asdf.html>
- Configuration reference: <https://mise.jdx.dev/configuration.html>
