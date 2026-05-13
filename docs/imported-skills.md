# Imported skills

Claude Code skills we've pulled in verbatim from upstream repos. Each file
under `dot_claude/skills/<name>/SKILL.md` is a frozen copy from a specific
commit, kept intentionally byte-identical to the source so future re-syncs
are a clean `cp`.

## Provenance

| Skill | Upstream | Commit | Imported |
|---|---|---|---|
| `humanizer` | [harperreed/dotfiles](https://github.com/harperreed/dotfiles/blob/master/.claude/skills/humanizer/SKILL.md) | `bf0eece` | 2026-05-13 |
| `session-reflection-analysis` | [harperreed/dotfiles](https://github.com/harperreed/dotfiles/blob/master/.claude/skills/session-reflection-analysis/SKILL.md) | `bf0eece` | 2026-05-13 |

The full SHA at import time was
`bf0eece05cb9bfe18e75d1789e1a15d10eb67be8` for both. If Harper renames
or restructures, re-pin against a newer SHA — see *Re-syncing* below.

## What each one does

### `humanizer`

Editing skill that removes AI-writing tells from text: em-dash overuse,
"rule of three" patterns, vague attributions, "it's not just X, it's Y",
vocabulary words like *delve / leverage / seamless / robust*. Based on
the Wikipedia "Signs of AI writing" guide. Language-agnostic, works on
emails, blog posts, README sections, anywhere the output reads too AI.

**Triggers**: Claude picks it up when you ask to "humanize", "rewrite to
sound more natural", "edit out AI patterns", "make this less AI-coded",
etc. — anything matching its YAML `description` field.

### `session-reflection-analysis`

Meta-skill that reads your past Claude Code session files from
`~/.claude/projects/<encoded-cwd>/*.jsonl`, summarizes them via `jq`
(never reads them raw — they're huge), and produces a report on
*how* you've been working: repeated requests, friction points,
permission prompts you keep approving, suggestions to refine your
`CLAUDE.md` or hooks.

**Triggers**: "reflect on the session", "how did this session go",
"what could we improve", etc. Best run periodically (weekly?) on a
project's session history, not after every chat.

**Pre-req**: `jq` must be on `PATH`. It is — the Brewfile pulls it in
transitively via several other formulas. (If a future change removes
the transitive dep, add `brew "jq"` explicitly.)

## Why not add `ABOUTME:` headers?

The repo convention says every config/script file starts with two
`# ABOUTME:` lines. **SKILL.md files are exempt** for two reasons:

1. The YAML frontmatter (`name`, `description`) already serves the same
   purpose, and Claude Code parses it as the skill's self-description.
2. Adding our own header would diverge the file from the upstream byte
   stream — and the whole point of these imports is that a re-sync is
   a clean `cp`.

The exception is documented in the top-level
[README](../README.md#repo-conventions-not-chezmoi).

## Re-syncing from upstream

When Harper updates one of these, do:

```sh
UPSTREAM_SHA=$(gh api repos/harperreed/dotfiles/commits/master --jq .sha)

for skill in humanizer session-reflection-analysis; do
  gh api "repos/harperreed/dotfiles/contents/.claude/skills/$skill/SKILL.md?ref=$UPSTREAM_SHA" \
    | python3 -c "import sys, json, base64; sys.stdout.buffer.write(base64.b64decode(json.load(sys.stdin)['content']))" \
    > "dot_claude/skills/$skill/SKILL.md"
done

# Update the "Imported" column above to today's date and the new SHA,
# then commit with a message like "Re-sync imported skills against <sha>".
```

The cron-based upstream review described in
[upstream-review.md](upstream-review.md) is the trigger for this — when it
flags changes under `.claude/skills/humanizer/` or
`.claude/skills/session-reflection-analysis/`, you re-sync.

## Anything else worth importing?

For now, no. Harper's other active skills are iOS/Swift-specific
(`swiftui-*`, `ios-debugger-agent`, `swift-concurrency-expert`,
`app-store-changelog`, `native-app-performance`) and not relevant.

His `skills-archive/` contains things like `granola-to-obsidian` (depends
on a private MCP server) and four `dot-file-*` skills which — despite
the name — operate on **Graphviz `.dot` pipeline files**, not on shell
dotfiles. False friend; ignore.

If Harper adds something new and trasversale, see
[upstream-review.md](upstream-review.md) for how the periodic check
should flag it.
