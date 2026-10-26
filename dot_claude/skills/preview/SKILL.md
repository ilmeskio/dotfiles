---
name: preview
description: Standard ways to put something in front of the user instead of a wall of chat text — questions to answer one at a time (each answer reaches Claude as it is sent), a diff of only the files that matter, readable on a narrow panel, and a visual recap of a plan. Builds the page locally and shows it with whatever viewer the user has (another preview skill if one is available, otherwise a URL or a path). Use when the user must answer several open questions, review a large change, or approve a plan; and when they ask to "show", "open", "fammi vedere", "mostrami" something that reads better as a page.
---

# Preview

Three recipes for showing things to the user, and one rule for **where** to show them.
The recipes build a local file or a local page; they never assume a terminal, a
viewer or an editor.

## Where to show it

1. **Another preview skill is listed in this session** (one that opens files, diffs or
   web pages next to the conversation — a terminal multiplexer, a terminal with
   graphical blocks, an IDE): use it to open the path or the URL.
2. **None is**: give the user the URL (`http://127.0.0.1:<port>/…`) or the path, once,
   as a clickable line.

Never ask the user which viewer they use; never mention a viewer by name in a project
document — projects are shared with people whose setup differs.

**Every page is responsive**: it must read on a side panel 400 px wide as well as on a
full window — one column, lines that wrap, no horizontal scroll of the page. Light and
dark both: colors as CSS variables, redefined under `prefers-color-scheme: dark`.

A browser may cache a page served from the same URL: add `?v=<timestamp>` when you
reopen one you changed.

## Recipe 1 — questions, one at a time

When the user has several open questions to answer (decisions for a document, the
open points of an issue, the forks of a plan), do not list them in chat: put them on a
page where each answer reaches you **as it is sent**.

```bash
Q=<scratchpad>/questions-<topic>          # one folder per round of questions
mkdir -p "$Q" && cp ~/.claude/skills/preview/scripts/questions/{server.mjs,index.html} "$Q"/
# write "$Q/questions.json" (format below), then start the server detached:
(cd "$Q" && nohup node server.mjs >> server.log 2>&1 &)   # PORT=4777 by default
```

`questions.json`:

```json
{ "title": "Domande aperte · #258",
  "questions": [
    { "id": "D1", "who": "product owner", "q": "Entro quanto si risponde a una richiesta?",
      "context": "Oggi il PDR dice: nessun termine promesso.",
      "options": ["Nessun termine, come oggi", "Un termine indicativo (scrivi quale)"] } ] }
```

- `context` may hold simple HTML (`<b>`, `<i>`, `<code>`); everything else is text.
- Keep options to what really branches; the free note covers the rest.
- Questions the user does not understand get rewritten with a concrete example, not
  re-asked louder.

**Get woken by each answer.** The server prints one line per answer to its log:
`ANSWER <id> | choice: … | note: …`. Watch it with the session's event mechanism —
in Claude Code the Monitor tool:

```
tail -n 0 -F "$Q/server.log" | grep --line-buffered -E "ANSWER|Error|EADDRINUSE"
```

The server runs **detached from the watch**: when the watch expires, re-arm it; the
server keeps storing answers in `answers.json` meanwhile, so nothing sent while
nobody watched is lost — read the file when you come back.

**Reply under a card** by writing `replies.json` (`{"<id>": {"text": "…"}}`); the page
polls every 4 seconds. Reply when an answer has a consequence the user should see (a
document it changes, a follow-up question); acknowledge the rest in chat in one line.

When every question has an answer, write the answers where they belong (documents,
issues) and stop the server (`kill $(lsof -t -iTCP:4777 -sTCP:LISTEN)`).

## Recipe 2 — the salient diff

A large change is reviewed by its **decisions**, not by its renames. Before asking for
a review, show the diff of only the files that carry decisions (documents of decisions,
the code that implements a new rule), and say in one line what is left out (renames,
link updates, tests, generated files).

```bash
~/.claude/skills/preview/scripts/diff-page.sh <out.html> "<title>" -- <git diff args>
# e.g. diff-page.sh "$S/salienti.html" "Modifiche salienti" ce2bc14..HEAD -- docs/adr/X.md docs/…/Y.md
```

It renders with `diff2html`, word-level highlighting, and is **responsive**: side by side
on a window at least 900 px wide, one column with one line number on a narrow panel;
lines wrap instead of scrolling, the file name stays on top while scrolling. The theme
follows the viewer's preference, with an *Auto · Chiaro · Scuro* switch at the top right
(remembered per browser): a viewer may report dark even when the system is light. Serve it
(`python3 -m http.server <port> --bind 127.0.0.1 --directory <dir>`) or open the file.
Renamed files: pass both the old and the new path, so `-M` shows a rename with changes.

## Recipe 3 — the plan recap

When a plan needs approval (an iteration, a release), show it as a page instead of a
table in chat: **a grid with the iterations as columns and the assignees as rows**;
each card carries the issue number (new ones marked), a short title, its area as a
color, and `↳ dopo #N` when it waits on another issue; the backlog left out goes below,
each item with one sentence on what it is. When there are two variants, a switch
between them, not two pages. Build it as a single self-contained HTML file from the
data you already have; no library.

## Guardrails

- Local only: bind to `127.0.0.1`, never expose a page to the network.
- No personal data in a page that is not already in front of the user in the session.
- One server per round of questions; stop it when the round is over.
- The recipes say *what* to show; the project's own rules (who answers, where an answer
  is written) still apply.
