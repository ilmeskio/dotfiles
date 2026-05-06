---
name: clipboard
description: Copy text to the system clipboard across all platforms (macOS, Linux, Windows, WSL2, SSH). Use when the user requests to copy text, save to clipboard, or put something in their clipboard. Handles platform detection automatically.
---

# Clipboard Skill

Copy text to the system clipboard seamlessly across all platforms.

## Overview

This skill provides a cross-platform solution for copying text to the system clipboard. It automatically detects the current platform (macOS, Linux, Windows, WSL2, or SSH/remote) and uses the appropriate clipboard command.

## Quick Start

Use the cross-platform script to copy any text to the clipboard:

```bash
# RECOMMENDED: Copy using heredoc (best for complex text, markdown, special characters)
cat << 'EOF' | /Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh
Your text here
Can include backticks, quotes, and special characters
Works perfectly with markdown
EOF

# Alternative: Copy from stdin (simple cases)
echo "your text here" | /Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh

# Alternative: Copy from arguments (only for simple text without special characters)
/Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh "your text here"
```

**Note**: For text containing special characters (backticks, quotes, $, etc.) or markdown formatting, always use the heredoc method to avoid shell interpretation issues.

The script automatically detects your platform and uses the appropriate clipboard command.

## Supported Platforms

- **macOS**: Uses `pbcopy`
- **Linux**: Uses `xclip` (with `xsel` as fallback)
- **Windows**: Uses `clip` (Git Bash, MSYS2, Cygwin)
- **WSL2**: Uses `clip.exe`
- **SSH/Remote**: Uses OSC 52 escape sequence

## Common Use Cases

### Copy Markdown or Code (RECOMMENDED METHOD)
```bash
cat << 'EOF' | /Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh
## Heading
- Bullet with `backticks`
- Special chars: $, ", ', etc.
EOF
```

### Copy SQL Queries or Code Blocks
```bash
cat << 'EOF' | /Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh
SELECT * FROM `users`
WHERE name = 'O''Brien'
  AND email LIKE '%@example.com'
EOF
```

### Copy Command Output
```bash
git log --oneline -5 | /Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh
```

### Copy File Contents
```bash
cat README.md | /Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh
```

### Copy Simple Text (arguments method)
```bash
/Users/ilmeskio/.claude/skills/clipboard/scripts/copy_to_clipboard.sh "Some simple text"
```

## Platform-Specific Commands (Fallback Reference)

If the script doesn't work for your platform, use these commands directly:

### macOS
```bash
echo "text" | pbcopy
```

### Linux
```bash
echo "text" | xclip -selection clipboard
```

### Windows (PowerShell/CMD)
```bash
echo "text" | clip
```

### WSL2
```bash
echo "text" | clip.exe
```

### SSH/Remote Shells
```bash
printf "\033]52;c;%s\007" "$(echo -n "text" | base64)"
```

## Best Practices

### When to use each method:

1. **Heredoc (RECOMMENDED for most cases)**
   - Use for markdown, code, SQL queries
   - Use when text contains backticks, quotes, $, or other special characters
   - Use for multi-line text
   - Most reliable method - avoids shell interpretation issues

2. **Stdin/Pipe**
   - Use for command output or file contents
   - Use when piping from other commands
   - Good for dynamic content

3. **Arguments**
   - Use only for simple, single-line text without special characters
   - Avoid if text contains: `, ", ', $, \, or other shell metacharacters

## Error Handling

On Linux, if `xclip` is not installed, the script will display installation instructions:
- Ubuntu/Debian: `sudo apt-get install xclip`
- Fedora/RHEL: `sudo dnf install xclip`

## Notes

- The script preserves exact text content (no trailing newlines added)
- Status messages are sent to stderr, so they won't interfere with piped output
- SSH clipboard support requires terminal emulator support for OSC 52
- **Always use heredoc for complex text to avoid shell interpretation issues**
