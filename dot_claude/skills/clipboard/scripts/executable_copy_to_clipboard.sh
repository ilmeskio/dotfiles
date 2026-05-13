#!/usr/bin/env bash
# ABOUTME: Cross-platform clipboard copy used by the `clipboard` Claude Code skill
# ABOUTME: Dispatches to pbcopy / xclip|xsel / clip.exe / clip / OSC 52 based on platform and SSH state

set -euo pipefail

# Function to detect platform and copy to clipboard
copy_to_clipboard() {
    local text="$1"

    # Check if we're in an SSH session or remote shell
    if [ -n "${SSH_CLIENT:-}" ] || [ -n "${SSH_TTY:-}" ]; then
        # Use OSC 52 escape sequence for SSH
        printf "\033]52;c;%s\007" "$(echo -n "$text" | base64)" >&2
        echo "Text copied to clipboard via OSC 52 (SSH/remote)" >&2
        return 0
    fi

    # Detect platform
    case "$(uname -s)" in
        Darwin)
            # macOS
            echo -n "$text" | pbcopy
            echo "Text copied to clipboard (macOS)" >&2
            ;;
        Linux)
            # Check if we're in WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                # WSL2
                echo -n "$text" | clip.exe
                echo "Text copied to clipboard (WSL2)" >&2
            elif command -v xclip &> /dev/null; then
                # Linux with xclip
                echo -n "$text" | xclip -selection clipboard
                echo "Text copied to clipboard (Linux)" >&2
            elif command -v xsel &> /dev/null; then
                # Linux with xsel as fallback
                echo -n "$text" | xsel --clipboard --input
                echo "Text copied to clipboard (Linux)" >&2
            else
                echo "Error: No clipboard utility found. Please install xclip or xsel." >&2
                echo "  Ubuntu/Debian: sudo apt-get install xclip" >&2
                echo "  Fedora/RHEL: sudo dnf install xclip" >&2
                return 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash, MSYS2, Cygwin)
            echo -n "$text" | clip
            echo "Text copied to clipboard (Windows)" >&2
            ;;
        *)
            echo "Error: Unsupported platform: $(uname -s)" >&2
            return 1
            ;;
    esac

    return 0
}

# Main script logic
main() {
    local text=""

    # Check if input is from stdin or arguments
    if [ -t 0 ]; then
        # No stdin, use arguments
        if [ $# -eq 0 ]; then
            echo "Usage: $0 <text>" >&2
            echo "   or: echo <text> | $0" >&2
            exit 1
        fi
        text="$*"
    else
        # Read from stdin
        text=$(cat)
    fi

    # Copy to clipboard
    copy_to_clipboard "$text"
}

main "$@"
