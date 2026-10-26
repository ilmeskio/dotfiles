# ABOUTME: Homebrew bundle — formulae, casks, and Mac App Store apps installed on apply
# ABOUTME: Consumed by run_onchange_before_install-packages.sh.tmpl; .chezmoiignore keeps it out of $HOME

# === Taps ===
tap "atlassian/acli"

# === Core CLI ===
# chezmoi itself is deliberately NOT here: the bootstrap one-liner in the
# README drops it at ~/.local/bin/chezmoi, which precedes /opt/homebrew/bin
# in PATH and would shadow a brew copy anyway. Update it with `chezmoi upgrade`.
brew "git"
brew "gh"
brew "zsh"
brew "mas"                    # Mac App Store CLI (used by the mas entries below)

# === Languages / runtimes ===
brew "mise"                   # multi-runtime version manager (asdf successor); activated in dot_zshrc, owns Node (global and per project, .nvmrc) and OpenTofu via a project's mise.toml
brew "oven-sh/bun/bun"

# === Shell productivity ===
brew "direnv"                 # auto-load .envrc per directory (env vars per project)

# === Databases ===
brew "mysql-client"

# === Infra / cloud ===
brew "cloudflare/cloudflare/cf-terraforming"
brew "hashicorp/tap/terraform"
# OpenTofu comes from mise (a project's mise.toml), not brew: a brew copy shadows the pinned version.
brew "atlassian/acli/acli"

# === Document tooling ===
brew "pandoc"
brew "graphviz"
brew "poppler"
brew "weasyprint"
brew "git-delta"              # side-by-side diffs in the terminal (herdr-preview fallback outside Wave)

# === Misc ===
brew "speedtest-cli"
brew "duti"                   # default apps per file type; list in dot_config/duti/defaults.duti

# === GUI apps ===
cask "1password"
cask "1password-cli"
cask "visual-studio-code"
cask "zed"                     # visualizzatore predefinito per testo e codice (duti)
cask "dbeaver-community"
cask "docker-desktop"
cask "maccy"                  # clipboard manager
cask "claude"                 # Claude Desktop chat app
cask "obsidian"
cask "spotify"
cask "google-chrome"
cask "thebrowsercompany-dia"
cask "notion"
cask "notion-calendar"
cask "todoist-app"
cask "raindropio"
cask "whatsapp"
cask "handy"
cask "logi-options+"
cask "nordvpn"
cask "openvpn-connect"

# === Mac App Store ===
# Requires being signed into the App Store at least once (mas can't sign you
# in from the CLI on modern macOS). Sign in via the App Store.app, then
# re-run `brew bundle`.
mas "QuickGif", id: 6744745027
