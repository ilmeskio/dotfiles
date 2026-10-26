#!/usr/bin/env bash
# shellcheck disable=SC2016 # $names inside single quotes are jq variables
# Show content to the user next to the calling Herdr pane.
#
#   preview.sh diff [git diff args...]   git diff (e.g. --staged, HEAD~1, -- path)
#   preview.sh diff-files <old> <new>    diff of two files outside git
#   preview.sh doc <file>                rendered Markdown / highlighted file
#   preview.sh web <url>                 web page
#   preview.sh run <shell command>       any command; output stays visible
#   preview.sh close                     close the preview
#
# Viewer: when the user is attached to Herdr from Wave Terminal on this
# machine, diffs, docs and local web pages open in one reused Wave block;
# otherwise (Terminal.app, Ghostty, herdr --remote) they open in a Herdr pane.
# Other web pages always open in Chrome. `run` always uses the Herdr pane.
# PREVIEW_VIEWER=pane skips Wave.
#
# The Herdr pane is created on first use (split right on wide panes, down on
# narrow ones, without stealing focus), labeled "preview", and reused.
# Prints where the content went: "wave:<block id>", a pane ID, or "browser".
set -euo pipefail

LABEL=preview
WAVE_MARK=claude:preview
STATE_DIR=${TMPDIR:-/tmp}/herdr-preview

die() { echo "preview.sh: $*" >&2; exit "${2:-1}"; }

[ "${HERDR_ENV:-}" = 1 ] || die "not running inside Herdr (HERDR_ENV != 1)"
command -v jq >/dev/null || die "jq is required"

quote() { [ $# -eq 0 ] || printf '%q ' "$@"; }

# --- Wave -------------------------------------------------------------------

# Herdr panes inherit the environment of the Herdr server, not of the terminal
# the user attached from, so wsh cannot find Wave on its own. Borrow the Wave
# variables (block, tab, auth token) from a local Herdr client running in Wave.
WAVE_ENV=()
WSH=
wave_init() {
  [ "${PREVIEW_VIEWER:-}" = pane ] && return 1
  local arch pid var
  arch=$(uname -m); [ "$arch" = x86_64 ] && arch=x64
  for WSH in /Applications/Wave.app/Contents/Resources/app.asar.unpacked/dist/bin/wsh-*-darwin."$arch"; do :; done
  [ -x "$WSH" ] || return 1
  for pid in $(pgrep -x herdr | sort -rn); do
    WAVE_ENV=()
    while IFS= read -r var; do WAVE_ENV+=("$var"); done < <(
      ps eww -o command= -p "$pid" 2>/dev/null | tr ' ' '\n' | grep -E '^WAVETERM_[A-Z]+=.' || true)
    [ ${#WAVE_ENV[@]} -gt 0 ] && printf '%s\n' "${WAVE_ENV[@]}" | grep -q '^WAVETERM_JWT=' && return 0
  done
  return 1
}

wsh() { env "${WAVE_ENV[@]}" "$WSH" "$@"; }

wave_tab() { printf '%s\n' "${WAVE_ENV[@]}" | sed -n 's/^WAVETERM_TABID=//p'; }

# jq filter over `wsh blocks list --json`, with $tab bound to the user's Wave tab.
wave_query() {
  wsh blocks list --json | jq -r --arg tab "$(wave_tab)" --arg mark "$WAVE_MARK" "$@"
}

# Show a file or URL in the marked Wave block, creating it if needed. A block
# is reused only for the same kind of content (preview vs web).
wave_show() {
  local target=$1 key=file view=preview block
  case "$target" in http://* | https://*) key=url view=web ;; esac
  block=$(wave_query --arg view "$view" \
    '.[] | select(.tabid == $tab and .meta[$mark] == true and .view == $view) | .blockid' | head -n 1)
  if [ -n "$block" ]; then
    wsh setmeta -b "$block" "$key=$target" >/dev/null
  else
    if [ "$view" = web ]; then wsh web open "$target" >/dev/null; else wsh view "$target" >/dev/null; fi
    block=$(wave_query --arg key "$key" --arg t "$target" \
      '[.[] | select(.tabid == $tab and .meta[$key] == $t)] | last | .blockid')
    wsh setmeta -b "$block" "$WAVE_MARK=true" >/dev/null
  fi
  echo "wave:$block"
}

wave_close() {
  local block
  for block in $(wave_query '.[] | select(.tabid == $tab and .meta[$mark] == true) | .blockid'); do
    wsh deleteblock -b "$block" >/dev/null
  done
}

# Diffs go to a new file each time, so Wave reloads instead of keeping a cached view.
diff_file() {
  local f
  mkdir -p "$STATE_DIR"
  find "$STATE_DIR" -name '*.diff' -mmin +1440 -delete 2>/dev/null || true
  f=$(mktemp "$STATE_DIR/$(basename "$PWD")-XXXXXX")
  mv "$f" "$f.diff"
  echo "$f.diff"
}

# --- Herdr pane ---------------------------------------------------------------

LESS_CMD="less -R --mouse"
# Side by side when the pane is wide enough; delta misreads the width inside Herdr.
# shellcheck disable=SC2016 # expanded inside the pane, against its own width
DELTA_CMD='delta --dark --paging=always --line-numbers --width "$(tput cols)" $( [ "$(tput cols)" -ge 110 ] && echo --side-by-side --wrap-max-lines unlimited )'

find_pane() {
  herdr pane list --workspace "$HERDR_WORKSPACE_ID" |
    jq -r --arg tab "$HERDR_TAB_ID" --arg label "$LABEL" \
      '.result.panes[] | select(.tab_id == $tab and .label == $label) | .pane_id' |
    head -n 1
}

create_pane() {
  local width height direction id
  read -r width height < <(herdr pane layout --pane "$HERDR_PANE_ID" |
    jq -r --arg p "$HERDR_PANE_ID" '.result.layout.panes[] | select(.pane_id == $p) | "\(.rect.width) \(.rect.height)"')
  # Terminal cells are ~2x taller than wide: split right only if the result stays usable.
  if [ "$width" -ge 160 ] || [ "$width" -ge $((height * 3)) ]; then direction=right; else direction=down; fi
  id=$(herdr pane split --current --direction "$direction" --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')
  herdr pane rename "$id" "$LABEL" >/dev/null
  echo "$id"
}

foreground() {
  herdr pane process-info --pane "$1" | jq -r '[.result.process_info.foreground_processes[].name] | join(" ")'
}

at_prompt() {
  case "$1" in "" | zsh | -zsh | bash | -bash | sh | fish) return 0 ;; *) return 1 ;; esac
}

# Prompt hooks (direnv, mise, ...) briefly own the foreground right after a
# command exits: give them up to ~3s to finish before judging the pane.
settle() {
  local fg
  for _ in $(seq 15); do
    fg=$(foreground "$1")
    at_prompt "$fg" && break
    sleep 0.2
  done
  echo "$fg"
}

# Bring an existing preview pane back to its shell prompt: quit a pager we left
# open; refuse to touch anything else running there (the user may be using it).
ready_pane() {
  local id=$1 fg
  fg=$(foreground "$id")
  case " $fg " in
    *" less "* | *" glow "* | *" delta "* | *" bat "*) herdr pane send-keys "$id" q >/dev/null ;;
  esac
  fg=$(settle "$id")
  at_prompt "$fg" || die "preview pane $id is busy running: $fg" 2
}

pane_show() {
  local id
  id=$(find_pane)
  if [ -z "$id" ]; then id=$(create_pane); sleep 0.3; else ready_pane "$id"; fi
  # Run from the caller's cwd: the pane keeps the one it was created in.
  herdr pane run "$id" "clear; cd $(quote "$PWD")&& $1" >/dev/null
  echo "$id"
}

# --- Commands -----------------------------------------------------------------

cmd=${1:-}; shift || true
case "$cmd" in
  diff)
    if wave_init; then
      f=$(diff_file); git diff "$@" >"$f"; wave_show "$f"
    elif command -v delta >/dev/null; then
      pane_show "git diff $(quote "$@") | $DELTA_CMD"
    else
      pane_show "git -c color.ui=always diff $(quote "$@") | $LESS_CMD"
    fi
    ;;
  diff-files)
    [ $# -eq 2 ] || die "usage: preview.sh diff-files <old> <new>"
    if wave_init; then
      f=$(diff_file); diff -u "$1" "$2" >"$f" || true; wave_show "$f"
    elif command -v delta >/dev/null; then
      pane_show "$DELTA_CMD $(quote "$1" "$2")"
    else
      pane_show "diff -u --color=always $(quote "$1" "$2") | $LESS_CMD"
    fi
    ;;
  doc)
    [ $# -eq 1 ] || die "usage: preview.sh doc <file>"
    [ -e "$1" ] || die "no such file: $1"
    if wave_init; then
      wave_show "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
      exit
    fi
    case "$1" in
      *.md | *.markdown)
        if command -v glow >/dev/null; then pane_show "glow -p -s dark -w \$((\$(tput cols) - 4)) $(quote "$1")"; else pane_show "$LESS_CMD $(quote "$1")"; fi
        ;;
      *)
        if command -v bat >/dev/null; then pane_show "bat --paging=always $(quote "$1")"; else pane_show "$LESS_CMD -N $(quote "$1")"; fi
        ;;
    esac
    ;;
  web)
    [ $# -eq 1 ] || die "usage: preview.sh web <url>"
    # Wave's browser is Electron: no extensions (1Password), no passkeys, no
    # Chrome logins. Only local pages go there; the rest opens in Chrome.
    case "$1" in
      http://localhost* | https://localhost* | http://127.0.0.1* | https://127.0.0.1* | \
        http://\[::1\]* | http://*.localhost* | https://*.localhost* | file://*)
        local_url=1 ;;
      *) local_url= ;;
    esac
    if [ -n "$local_url" ] && wave_init; then
      wave_show "$1"
    else
      open -a "Google Chrome" "$1" 2>/dev/null || open "$1"
      echo browser
    fi
    ;;
  run)
    [ $# -ge 1 ] || die "usage: preview.sh run <shell command>"
    pane_show "$*"
    ;;
  close)
    if wave_init; then wave_close; fi
    id=$(find_pane)
    if [ -n "$id" ]; then herdr pane close "$id" >/dev/null; fi
    ;;
  *)
    sed -n '4,10p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 1
    ;;
esac
