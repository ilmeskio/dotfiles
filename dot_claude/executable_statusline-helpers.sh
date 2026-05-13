#!/bin/bash
# ABOUTME: Helpers sourced by statusline-command.sh — usage-cache fetch + time/color/token formatters
# ABOUTME: Caches Claude usage API responses to ~/.claude/.usage-cache.json with a 60s TTL

CACHE_FILE="$HOME/.claude/.usage-cache.json"
CACHE_TTL=60  # seconds
KEYCHAIN_SERVICE="Claude Code-credentials"

# Fetch usage data with 60-second caching
fetch_usage_cached() {
    local now=$(date +%s)
    local cache_valid=false

    # Check if cache exists and is fresh
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)
        local age=$((now - cache_time))
        if [[ $age -lt $CACHE_TTL ]]; then
            cache_valid=true
        fi
    fi

    # Return cached data if valid
    if $cache_valid; then
        cat "$CACHE_FILE"
        return 0
    fi

    # Fetch fresh data from API
    # Get credentials from macOS Keychain
    local credentials=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null)
    if [[ -z "$credentials" ]]; then
        echo '{"error": "no_credentials"}'
        return 1
    fi

    local token=$(echo "$credentials" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [[ -z "$token" ]]; then
        echo '{"error": "no_token"}'
        return 1
    fi

    local response=$(curl -s -m 5 \
        -H "Authorization: Bearer $token" \
        -H "anthropic-version: 2023-06-01" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [[ $? -eq 0 && -n "$response" ]]; then
        # Save to cache
        echo "$response" > "$CACHE_FILE"
        echo "$response"
        return 0
    else
        # API failed, try to use stale cache
        if [[ -f "$CACHE_FILE" ]]; then
            cat "$CACHE_FILE"
        else
            echo '{"error": "api_failed"}'
        fi
        return 1
    fi
}

# Format ISO 8601 timestamp to "in Xh, 10:30am" or "in Xd, Feb 9 10am"
format_reset_time() {
    local iso_time="$1"

    if [[ -z "$iso_time" || "$iso_time" == "null" ]]; then
        echo "?"
        return
    fi

    # Parse ISO time to epoch (cross-platform)
    local reset_epoch
    if date --version >/dev/null 2>&1; then
        # GNU date
        reset_epoch=$(date -d "$iso_time" +%s 2>/dev/null)
    else
        # BSD date (macOS)
        reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${iso_time%%.*}" +%s 2>/dev/null)
    fi

    if [[ -z "$reset_epoch" ]]; then
        echo "?"
        return
    fi

    local now=$(date +%s)
    local diff=$((reset_epoch - now))

    if [[ $diff -lt 0 ]]; then
        echo "now"
        return
    fi

    local hours=$((diff / 3600))
    local days=$((diff / 86400))

    local relative=""
    local absolute=""

    if [[ $days -ge 1 ]]; then
        relative="in ${days}d"
        if date --version >/dev/null 2>&1; then
            # GNU date
            absolute=$(date -d "@$reset_epoch" "+%b %-d %H:%M" 2>/dev/null)
        else
            # BSD date (macOS)
            absolute=$(date -r "$reset_epoch" "+%b %-d %H:%M" 2>/dev/null)
        fi
    else
        relative="in ${hours}h"
        if date --version >/dev/null 2>&1; then
            # GNU date
            absolute=$(date -d "@$reset_epoch" "+%H:%M" 2>/dev/null)
        else
            # BSD date (macOS)
            absolute=$(date -r "$reset_epoch" "+%H:%M" 2>/dev/null)
        fi
    fi

    echo "$relative, $absolute"
}

# Get ANSI color code based on percentage
get_color_for_pct() {
    local pct="$1"

    # Handle non-numeric input
    if [[ ! "$pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "\033[0m"  # Reset/normal
        return
    fi

    # Convert to integer for comparison
    local pct_int=${pct%.*}

    if [[ $pct_int -ge 90 ]]; then
        echo "\033[0;31m"  # Red
    elif [[ $pct_int -ge 70 ]]; then
        echo "\033[0;33m"  # Yellow
    else
        echo "\033[0m"  # Normal/reset
    fi
}

# Format large numbers to k/m notation
format_tokens() {
    local num="$1"

    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
        echo "$num"
        return
    fi

    if [[ $num -ge 1000000 ]]; then
        echo "$((num / 1000000))m"
    elif [[ $num -ge 1000 ]]; then
        echo "$((num / 1000))k"
    else
        echo "$num"
    fi
}
