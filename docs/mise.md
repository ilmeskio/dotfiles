# mise — runtimes and project tools

[mise](https://mise.jdx.dev) manages the versions of Node, Ruby and the
tools a project needs. It is installed by the Brewfile and activated in
[dot_zshrc](../dot_zshrc) (`mise activate zsh`) and, for login shells, in
`~/.zprofile` (`mise activate zsh --shims`).

## Where versions are declared

- **Global**: [`~/.config/mise/config.toml`](../dot_config/mise/config.toml)
  — Node, Ruby and the tools used everywhere: `ai-profile` and `ai-secrets`
  from the releases of `ilmeskio/ai-profiles`, the native Bitwarden CLIs
  (`bw`, `bws`). A private repo downloads with `gh auth token`
  (`settings.github.credential_command`).
- **A project of mine**: its `mise.toml`, committed with the project.
- **A repo of others**: `mise.local.toml`, ignored by the global gitignore
  ([`dot_config/private_git/private_ignore`](../dot_config/private_git/private_ignore)).
- **Once, outside any project**: `mise exec <tool>@<version> -- <command>`.

Homebrew holds only the tools used everywhere: a brew copy of a tool that a
project pins (OpenTofu, Go, …) would shadow the pinned version.

## Daily commands

```sh
mise use node@24                  # pin in this project's mise.toml
mise use -g node@26               # change the global version
mise install                      # install everything declared here
mise current                      # what is active here
mise outdated                     # versions that could be upgraded
```

## References

- Getting started: <https://mise.jdx.dev/getting-started.html>
- Configuration: <https://mise.jdx.dev/configuration.html>
- GitHub backend: <https://mise.jdx.dev/dev-tools/backends/github.html>
