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
brew "pnpm"                   # global pnpm — coexists with per-project pnpm via corepack
brew "python@3.12"
brew "go"
brew "oven-sh/bun/bun"

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

# === Mac App Store ===
# Requires being signed into the App Store at least once (mas can't sign you
# in from the CLI on modern macOS). Sign in via the App Store.app, then
# re-run `brew bundle`.
mas "QuickGif", id: 6744745027
