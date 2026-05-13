# Reviewing harperreed/dotfiles periodically

[harperreed/dotfiles](https://github.com/harperreed/dotfiles) is a public,
actively maintained dotfiles repo from which we've already borrowed the
`ABOUTME:` convention and chunks of the Ghostty config. The author commits
multiple times per week, so it's worth checking in occasionally for new
ideas — without grafting his whole repo in.

This doc describes a lightweight workflow for that, plus a sketch for a
GitHub Action that automates the check.

## Manual workflow (today)

Clone the repo once into a scratch dir (**not** into the chezmoi source):

```sh
git clone --depth 1 https://github.com/harperreed/dotfiles \
  ~/Developer/refs/harperreed-dotfiles
```

When you want to check what's new:

```sh
cd ~/Developer/refs/harperreed-dotfiles
git pull
git log --since=<last-review-date> --stat -- \
  .claude/ .config/macos/ .zshrc Brewfile
```

The path filter is intentional — Harper has a lot of files we don't care
about (terminal emulators we don't use, iOS-specific Claude skills, Linux
configs, mutt/khard/vdirsyncer, …). Focus on `.claude/`, `.config/macos/`,
`.zshrc`, `Brewfile`, and the top-level scripts.

## Proposed CI (not yet implemented)

Add `.github/workflows/upstream-review.yml` to this repo:

- Triggers weekly on cron (e.g. Monday 09:00 UTC).
- Reads the last-reviewed SHA from `.upstream/harperreed.sha` (a 1-line
  file committed in this repo).
- Calls `gh api repos/harperreed/dotfiles/compare/<sha>...master`,
  filters the changed files to the paths we care about (regex on
  `.claude/|.config/macos/|.zshrc|Brewfile`).
- If anything changed: opens a GitHub issue titled
  "Upstream review YYYY-MM-DD" with the file list, labeled
  `upstream-review`.
- You triage the issue manually. When done, bump
  `.upstream/harperreed.sha` to the current `master` SHA and close the
  issue.

Sketch:

```yaml
name: Upstream review (harperreed)
on:
  schedule: [{cron: "0 9 * * MON"}]
  workflow_dispatch:
jobs:
  diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - id: last
        run: echo "sha=$(cat .upstream/harperreed.sha 2>/dev/null || echo HEAD~30)" >> $GITHUB_OUTPUT
      - env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
        run: |
          gh api "repos/harperreed/dotfiles/compare/${{ steps.last.outputs.sha }}...master" \
            --jq '.files[] | select(.filename | test("^\\.claude/|^\\.config/macos/|^\\.zshrc$|^Brewfile")) | "\(.status)\t\(.filename)"' \
            > /tmp/changed.txt
      - if: hashFiles('/tmp/changed.txt') != ''
        env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
        run: |
          gh issue create --title "Upstream review $(date +%F)" \
            --body "$(cat /tmp/changed.txt)" \
            --label upstream-review
```

The point of the SHA file is to avoid re-reviewing the same commits if a
run skips a week. It's authoritative: the next CI run starts from there.

## Why not auto-merge?

Tempting but bad:

- His repo isn't structured as a chezmoi source — file naming differs
  (`dot_zshrc` vs `.zshrc`, no `private_` prefixes, etc.).
- Many commits include personal preferences (themes, hotkeys,
  "Doctor Biz" persona in `CLAUDE.md`) that would clash with our setup.
- Reviewing manually means we only adopt things we actually understand
  and want.

## What we've already adopted

- **`ABOUTME:` header convention** — documented in
  [../README.md](../README.md) under *Repo conventions (not chezmoi)*.
- **Ghostty config** — behavior settings (`confirm-close-surface`,
  clipboard policy), macOS-style tab keybinds, `Shift+Enter` for literal
  newline. See [ghostty.md](ghostty.md) and
  [`../dot_config/ghostty/config`](../dot_config/ghostty/config).

## Inspiration we considered but skipped

- His `.claude/settings.json` — too aggressive
  (`permissions.defaultMode: "bypassPermissions"`,
  `MAX_THINKING_TOKENS: 128000`, experimental flags). Cherry-pick only.
- Per-OS `.gitconfig` split (`.gitconfig.linux` / `.gitconfig.mac`) —
  better done with a chezmoi template (`{{ if eq .chezmoi.os "darwin" }}`).
- Most of his iOS/Swift skills under `.claude/skills/` — not relevant
  to our workflow.
- `mutt`, `khard`, `vdirsyncer`, `beets`, `conky`, `pop-shell`,
  `remmina`, `variety` — niche or Linux-only tooling.
- Multiple terminal emulator configs (alacritty, kitty, terminator) —
  we only use Ghostty.

## Further reading

- The upstream repo: <https://github.com/harperreed/dotfiles>
- Harper's blog (occasionally describes what he's doing and why):
  <https://harperreed.com>
