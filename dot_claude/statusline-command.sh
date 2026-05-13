#!/bin/sh
# ABOUTME: Claude Code statusline renderer — dir, git branch, ctx %, 5h/7d rate limits, model + CC version
# ABOUTME: Reads JSON from stdin (Claude Code statusline contract); wired via dot_claude/private_settings.json.tmpl

input=$(cat)

# Directory + git info
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
dir=$(basename "$cwd")
cd "$cwd" 2>/dev/null
git_info=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      git_info=$(printf " \033[1;34mgit:(\033[0;31m%s\033[1;34m) \033[0;33m✗\033[0m" "$branch")
    else
      git_info=$(printf " \033[1;34mgit:(\033[0;31m%s\033[1;34m)\033[0m" "$branch")
    fi
  fi
fi

# Model + Claude Code version
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
cc_version=$(echo "$input" | jq -r '.version // empty')
model_info=""
if [ -n "$model_name" ]; then
  label="$model_name"
  [ -n "$cc_version" ] && label="$label @cc$cc_version"
  model_info=$(printf " \033[0;36m[%s]\033[0m" "$label")
fi

# Context window
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

ctx_info=""
if [ -n "$used_pct" ] && [ -n "$ctx_size" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  remaining_int=$(printf "%.0f" "$remaining_pct")
  # Color: green <50%, yellow 50-80%, red >80%
  if [ "$used_int" -ge 80 ]; then
    ctx_color="\033[0;31m"
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="\033[0;33m"
  else
    ctx_color="\033[0;32m"
  fi
  ctx_info=$(printf " ${ctx_color}ctx:%d%%\033[0m" "$used_int")
fi

# Rate limits
rate_info=""
now=$(date +%s)

# Helper: format absolute reset time for 5h block.
# Shows HH:MM if reset is today, otherwise "gio 14:35".
fmt_reset_5h() {
  epoch=$1
  if [ "$epoch" -le "$now" ]; then
    printf "ora"
    return
  fi
  reset_day=$(date -r "$epoch" +%Y%m%d)
  today=$(date +%Y%m%d)
  if [ "$reset_day" = "$today" ]; then
    date -r "$epoch" +%H:%M
  else
    date -r "$epoch" +"%a %H:%M"
  fi
}

# Helper: format absolute reset time for 7d block.
# Always shows abbreviated weekday + time, e.g. "lun 10:00".
fmt_reset_7d() {
  epoch=$1
  if [ "$epoch" -le "$now" ]; then
    printf "ora"
    return
  fi
  date -r "$epoch" +"%a %H:%M"
}

# 5-hour session limit
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five_pct" ] && [ -n "$five_reset" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  five_time=$(fmt_reset_5h "$five_reset")
  if [ "$five_int" -ge 80 ]; then
    five_color="\033[0;31m"
  elif [ "$five_int" -ge 50 ]; then
    five_color="\033[0;33m"
  else
    five_color="\033[0;32m"
  fi
  rate_info=$(printf " ${five_color}5h:%d%%(%s)\033[0m" "$five_int" "$five_time")
fi

# 7-day weekly limit
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ] && [ -n "$week_reset" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  week_time=$(fmt_reset_7d "$week_reset")
  if [ "$week_int" -ge 80 ]; then
    week_color="\033[0;31m"
  elif [ "$week_int" -ge 50 ]; then
    week_color="\033[0;33m"
  else
    week_color="\033[0;32m"
  fi
  rate_info=$(printf "%s ${week_color}7d:%d%%(%s)\033[0m" "$rate_info" "$week_int" "$week_time")
fi

# Assemble output
printf "\033[1;32m➜\033[0m  \033[0;36m%s\033[0m%s%s%s" "$dir" "$git_info" "$ctx_info" "$rate_info"
[ -n "$model_info" ] && printf "\n  %s" "$model_info"
