---
name: herdr-preview
description: Show diffs, documents, files, web pages and command output to the user next to the conversation when Claude runs inside Herdr (HERDR_ENV=1) — in a Wave Terminal block when the user is attached from Wave, otherwise in a Herdr pane. Use when the user asks to see, open, preview or show something ("mostrami il diff", "apri il doc qui accanto", "fammi vedere il file", "apri la pagina"), and after finishing an edit that touches several files, to put the diff in front of the user. Not for content Claude itself needs to read — use Read/Bash for that.
---

# Herdr preview

Herdr is a terminal multiplexer for coding agents; the user often attaches to
it from Wave Terminal, which can show files, diffs and web pages in graphical
blocks. This skill puts content next to the conversation so the user reads it
there while the conversation stays in Claude's pane:

- **Wave block** — when the user is attached to Herdr from Wave on this
  machine. One block for files and diffs and one for local web pages, each
  reused for the next preview.
- **Herdr pane** — otherwise (another terminal, `herdr --remote`), and always
  for command output. One sibling pane labeled `preview`, reused.
- **Chrome** — every non-local web page. Wave's browser is Electron's
  Chromium: no extensions (1Password), no passkeys, no Chrome logins. To act
  on a page in Chrome rather than just show it, use Claude in Chrome.

## Precondition

```bash
test "${HERDR_ENV:-}" = 1
```

If it fails, Claude is not inside Herdr: show the content in the reply as
usual and do not mention this skill.

## Commands

All work goes through one script, which picks the viewer:

```bash
P=~/.claude/skills/herdr-preview/scripts/preview.sh

$P diff                        # unstaged changes
$P diff --staged               # staged changes
$P diff main...HEAD            # branch against main; any `git diff` args work
$P diff -- path/to/file        # one file
$P diff-files old.txt new.txt  # two files outside git
$P doc README.md               # a document or source file
$P web http://localhost:3000   # local page in Wave; any other URL in Chrome
$P run "just test"             # a command; its output stays in the Herdr pane
$P close                       # close the Wave blocks and the Herdr pane
```

The script prints where the content went: `wave:<block id>`, a Herdr pane ID
(for `herdr pane read <id>` when Claude needs to check what it shows), or
`browser`. Exit code 2 means something else is running in the Herdr pane
(the user may be using it): tell the user and offer `$P close` or a new pane.
`PREVIEW_VIEWER=pane` forces the Herdr pane.

## How Wave is reached

Herdr panes inherit the environment of the Herdr server, not of the terminal
the user attached from, so `wsh` (Wave's CLI) inside a pane does not know
about Wave. The script reads the `WAVETERM_*` variables, including Wave's
auth token, from the local Herdr client process running in Wave, and passes
them to `wsh` for that call only. It never prints them; Claude must not
print or store them either.

## How to use it

- **The preview replaces the dump in chat.** After showing something, the
  reply says where it is and what to look at ("diff in the Wave block: the
  change that matters is in `auth.ts`"), and does not paste the same content
  again.
- **After an edit touching several files**, run `$P diff` (or the `git diff`
  args matching what changed) and point the user to it. For a one-line
  change, describing it in the reply is enough.
- **Documents Claude wrote or is discussing** (a plan, a README, a generated
  report): `$P doc <file>`.
- **Long-running or verbose commands the user wants to watch** (tests, logs):
  `$P run "<command>"`. For a server that must keep running, use a separate
  pane, so the next preview does not stop on "busy":
  `herdr pane split --current --direction down --cwd "$PWD" --no-focus`.
- **Do not close the preview on your own** at the end of a task: the user may
  still be reading it. Close it when asked.

## Beyond previews

For anything else in Herdr (other agents, tabs, workspaces, reading other
panes), `herdr --skill` prints Herdr's own guide for agents, and
`herdr <group>` (e.g. `herdr pane`) prints the current syntax. Never run bare
`herdr`: it attaches the TUI. Reading or sending input to panes Claude did
not create — especially other agents' panes — needs the user's request.
