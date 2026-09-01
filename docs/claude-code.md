# Claude Code — why `settings.json` is not managed

`~/.claude/settings.json` is **deliberately excluded** from chezmoi (see
[`.chezmoiignore`](../.chezmoiignore)). Everything else under `~/.claude/`
is managed as usual: `CLAUDE.md`, `skills/`, `statusline-command.sh`,
`statusline-helpers.sh`.

## The reason

It isn't a dotfile, it's application state. Claude Code rewrites it on its
own — `/model`, `/config`, every plugin install, the generated `autoMode`
context — and reorders the keys alphabetically while doing so. Managed via
a `.tmpl` it produced permanent, unresolvable drift: `chezmoi status`
showed `MM .claude/settings.json` indefinitely, `chezmoi apply` would have
wiped live settings, and `chezmoi re-add` doesn't work on templates.

Nothing in the file is worth versioning. Two blocks in particular must
*not* reach this repo:

- **`autoMode.environment`** — ~25 generated lines describing a private
  work repo (org name, local paths, SSH remote, which `.env` files are
  sensitive, deploy target). Regenerates itself; no reason to publish it.
- **Localhost hook URLs** — see below.

## Settings worth restoring by hand on a new machine

Everything else is a `/config` toggle away, or churns too fast to track.

| Setting | Value | Why |
|---|---|---|
| `permissions.defaultMode` | `auto` | Deliberate posture, not a default |
| `skipAutoPermissionPrompt` | `true` | Same |
| `statusLine` | `sh ~/.claude/statusline-command.sh` | Points at the managed script |
| `theme` | `auto` | Follows the system |
| `tui` | `fullscreen` | Preference |
| `skipWorkflowUsageWarning` | `true` | One-off dismissal |

Not worth restoring deliberately: `model` and `effortLevel` (moved per
task), `agentPushNotifEnabled` (UI toggle), `enabledPlugins` (changes on
every install — reinstall what you actually reach for).

## The `127.0.0.1:19847` hooks

Not part of Claude Code. They belong to **Claude Usage.app** (bundle id
`HamedElfayome.Claude-Usage`), a third-party menu-bar app that registers
HTTP hooks on eight events — `SessionStart`, `UserPromptSubmit`,
`Pre`/`PostToolUse`, `PostToolUseFailure`, `Stop`, `SessionEnd`,
`Notification` — to build its usage stats. It listens on loopback only.
The `2f3b0399` segment is an install token, not a session id: port and
token survive restarts, but both are specific to this machine's install,
which is one more reason the file doesn't belong in a shared repo.

If the app is ever uninstalled, strip those hooks too: with `timeout: 3`
on every event, POSTing at a closed port slows down each tool call.

## Atuin hooks: removed

`atuin hook claude-code` used to record every `Bash` command Claude ran
into the shell history. Removed — see the *AI-agent hooks* section of
[atuin.md](atuin.md) for the numbers behind that decision.
