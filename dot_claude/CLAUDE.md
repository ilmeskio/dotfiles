# Personal preferences

## Language

Reply in Italian unless the conversation or the artifact (code, commit
message, doc) is already in another language.

## Environment

macOS — assume zsh, Homebrew at `/opt/homebrew`, and BSD-flavored CLI tools
(e.g. `sed -i '' …`, not GNU syntax) unless the project pins a specific
toolchain.

## GitHub / SSH

L'autenticazione GitHub avviene via SSH con la chiave gestita da 1Password
(SSH agent). Ogni operazione che usa la chiave (`git push`, `git fetch`,
`git clone` da un remote `git@github.com:…`) richiede un'approvazione
interattiva nel prompt di 1Password: se non la confermo, l'operazione SSH
fallisce (es. permission denied / timeout). Non è un problema di
configurazione — basta approvare e riprovare.

Non aggirare mai il flusso SSH per evitare quell'approvazione: non passare a
remote HTTPS, non riscrivere gli URL dei remote, non usare token o
`GIT_ASKPASS`. Se un'operazione SSH fallisce per mancata approvazione,
segnalamelo e attendi che approvi, poi riprova via SSH.

## Workflow

- Do not append `Co-Authored-By:` trailers (or "Generated with Claude Code"
  lines) to commit messages — keep them clean.
- Before rebasing, large refactors, or any multi-file restructuring,
  summarize the branch's goals and the proposed changes and wait for
  confirmation before committing.
- For non-trivial features in a codebase that already has tests, prefer the
  test-first cycle: write the failing test, then the minimum code to pass,
  then refactor. Skip on small bugfixes or one-line tweaks.
- When creating a git branch, never set its upstream to the branch it was
  started from. Create it with plain `git switch -c <name>` (no start-point
  ref like `origin/main`), and before the first push check the upstream with
  `git rev-parse --abbrev-ref @{upstream}`. If it points at another branch,
  run `git branch --unset-upstream` first. Publish with
  `git push -u origin HEAD` so the remote branch takes the same name.

## Dotfiles (chezmoi)

My dotfiles are managed by chezmoi: the source of truth is
`~/.local/share/chezmoi` (remote `git@github.com:ilmeskio/dotfiles.git`),
not the files in my home directory. `~/.gitconfig`, `~/.zshrc` and
everything under `~/.claude/` are managed this way.

- Never edit a managed file directly in home, and never use `git config
  --global` for a permanent setting — `chezmoi apply` will silently discard
  it. Edit the source instead: `chezmoi edit --apply <target>`, or modify the
  file under `~/.local/share/chezmoi` and then `chezmoi apply <target>`.
- `chezmoi re-add` does not work on templates (files ending in `.tmpl`, e.g.
  `dot_gitconfig.tmpl`) — it skips them without a word. Check with
  `chezmoi source-path <target>` before assuming a file can be re-added.
- Preview a template's rendered output with `chezmoi cat <target>` before
  applying it.
- Check for drift with `chezmoi status` when you touch anything managed, and
  tell me what it reports. Never run a bare `chezmoi apply` to resolve drift
  you did not create — it overwrites the home version. Show me the
  `chezmoi diff` and let me decide which side wins.

## Testing

Verify claims by actually running tests and builds before reporting status.
Never describe a test as "passing" or "verifying behavior" without executing
it in this session.

## Communication style

When asked for examples or alternative approaches, present them as choices
for the user to pick from. Do not pick one silently and start editing.

Be literal in technical contexts. When a word could mean either a concrete
artifact (a git branch, a file, a temp folder, a process) or a figure of
speech (a "branch" to explore, a "thread" of reasoning), state which you
mean — never leave it ambiguous. Prefer plain, concrete wording over
metaphor when describing what exists and where it lives.
