# direnv — per-directory environment variables

[direnv](https://direnv.net) intercepts the shell prompt and loads/unloads
environment variables based on `.envrc` files in the current directory tree.
It's the standard way to scope project-specific config (API keys, `PATH`
mods, venv activation) without polluting the global shell.

## Wired in this repo

- Installed via `brew "direnv"` in [Brewfile](../Brewfile)
- Activated in [dot_zshrc](../dot_zshrc) with `eval "$(direnv hook zsh)"`

## How to use

In a project directory, create `.envrc`:

```sh
export OPENAI_API_KEY="sk-..."
export PYTHONPATH="$PWD/src:$PYTHONPATH"
```

Then authorize it once per file:

```sh
direnv allow
```

direnv will export those variables every time you `cd` into the directory
and unset them when you leave. Edit the file → `direnv allow` again.

## Common patterns

**Python venv auto-activation:**
```sh
layout python3                # creates .direnv/python-3.x and activates it
```

**Node version via fnm (or mise):**
```sh
use fnm                       # reads .nvmrc / .node-version
```

**Secrets from 1Password CLI (no plaintext in the file):**
```sh
export GITHUB_TOKEN="$(op read 'op://Personal/gh-token/credential')"
```

**Layered configs:**
```sh
source_up_if_exists           # inherits the parent dir's .envrc, if any
```

## Security model

`.envrc` files can run **arbitrary shell**. The `direnv allow` mechanism is
the trust boundary: direnv refuses to load until you've explicitly
authorized the current content (it hashes the file). Re-edit → re-allow.

**Never commit secrets** to a `.envrc` that gets pushed:
- Put `.envrc` in your project's `.gitignore`, **or**
- Use a sourcing pattern that pulls from a secret manager (1Password,
  AWS Secrets Manager, doppler, …), so the file itself only contains
  references, not values.

## Useful commands

```sh
direnv allow                  # authorize the current .envrc
direnv deny                   # revoke authorization
direnv reload                 # force a reload without leaving the dir
direnv status                 # show the loaded variables for this dir
```

## Further reading

- Stdlib reference: <https://direnv.net/man/direnv-stdlib.1.html>
- Wiki of recipes: <https://github.com/direnv/direnv/wiki>
