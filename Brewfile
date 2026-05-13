# ABOUTME: Homebrew bundle — formulae, casks, and Mac App Store apps installed on apply
# ABOUTME: Consumed by run_onchange_before_install-packages.sh.tmpl; .chezmoiignore keeps it out of $HOME

# === Taps ===
tap "atlassian/acli"
tap "cloudflare/cloudflare"
tap "hashicorp/tap"
tap "oven-sh/bun"

# === Core CLI ===
brew "chezmoi"                # this very repo's apply tool — managed by brew so it stays updated
brew "git"
brew "gh"
brew "zsh"
brew "mas"                    # Mac App Store CLI (used by the mas entries below)

# === Languages / runtimes ===
brew "fnm"                    # Node.js version manager
brew "mise"                   # multi-runtime version manager (asdf successor); activation in dot_zshrc is currently commented out — flip the switch when migrating off fnm
brew "python@3.12"
brew "go"
brew "oven-sh/bun/bun"

# === Shell productivity ===
brew "atuin"                  # modern shell history with fuzzy Ctrl-R search (works fully offline; sync is opt-in)
brew "direnv"                 # auto-load .envrc per directory (env vars per project)

# === Databases ===
brew "mysql-client"

# === Infra / cloud ===
brew "cloudflared"
brew "cloudflare/cloudflare/cf-terraforming"
brew "hashicorp/tap/terraform"
brew "opentofu"
brew "atlassian/acli/acli"

# === Document tooling ===
brew "pandoc"
brew "graphviz"
brew "poppler"
brew "weasyprint"

# === Misc ===
brew "speedtest-cli"

# === GUI apps ===
cask "1password"
cask "1password-cli"
cask "visual-studio-code"
cask "dbeaver-community"
cask "gcloud-cli"
cask "docker-desktop"
cask "maccy"                  # clipboard manager
cask "claude"                 # Claude Desktop chat app
cask "obsidian"
cask "spotify"
cask "ghostty"                # GPU-accelerated terminal (config managed at dot_config/ghostty/config)
cask "hammerspoon"            # macOS automation in Lua; needs Accessibility permission on first launch (config at ~/.hammerspoon/init.lua, not yet managed here)

# === Mac App Store ===
# Requires being signed into the App Store at least once (mas can't sign you
# in from the CLI on modern macOS). Sign in via the App Store.app, then
# re-run `brew bundle`.
mas "QuickGif", id: 6744745027
