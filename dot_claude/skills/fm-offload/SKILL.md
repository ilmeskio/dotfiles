---
name: fm-offload
description: Offload light, lossy text work to Apple's on-device Foundation Model (the `fm` CLI, macOS 27) to keep bulky text out of Claude's context. Use to get the gist of a long prose document (man page, README, article, long doc) or to pull a few fields into JSON from semi-structured text, when an approximate result is acceptable. Do not use for finding lines in logs (use grep), code reasoning, edits, exact counts, or anything whose answer must be correct.
---

# fm-offload

Apple's on-device model is a ~3B parameter model: free, local, a few seconds
per call. Its context is about 8,192 tokens, output included. It paraphrases,
drops details, miscounts, and invents plausible content. Treat its output as a
lossy preview, never as a source of truth.

## When to use it

Use it when the alternative is pulling a large blob into your own context only
to keep a small part of it, and the part you keep is *meaning*, not exact
lines:

- the gist of a long prose document (man page, README, article, changelog);
- a handful of fields extracted into JSON with `--schema` from text that fits
  in one call (git log, an email, a config dump);
- tagging or classifying a list of short items.

Do not use it for:

- **finding specific lines in logs or command output.** On a 1,500-line log it
  missed a FATAL line inside a 4,400-token piece; with smaller pieces it found
  it but invented error messages that were not in the log. Use `grep`, `rg`,
  `awk`, `jq`.
- reading or writing code, decisions, exact numbers or counts,
  security-relevant judgments;
- anything short enough to read directly (under ~200 lines).

## How to call it

The wrapper reads the input on stdin and takes the task as instructions:

```bash
man rsync | col -b | ~/.claude/skills/fm-offload/scripts/fm-offload.sh --chunk --merge \
  -i "Summarize in 5 short bullet points what this tool does and its most important options."
```

Options:

- `-i "<instructions>"` (required): the task. Write it in English, be specific
  about the output format, and ask for short output.
- `--schema FILE`: structured JSON output. Build the schema with `fm schema`;
  `--array` marks the preceding property as a list:
  `fm schema object --name Commit --string author --string subject --string files --array > FILE`.
- `--chunk`: input larger than the budget is split on line boundaries, each
  piece is processed with the same instructions, and the results are joined
  with duplicate lines removed. Each piece adds ~3 s. Expect more invented
  content than with a single call.
- `--merge` (with `--chunk`): the model merges the partial results into one.
  Reads better for prose summaries; it can drop items.
- `--budget N`: tokens allowed for instructions + input per call (default
  5500, leaving room for the answer).

Exit codes: `0` ok · `1` fm error · `2` input too large without `--chunk`, or
bad usage · `3` model unavailable. On exit 2 or 3, fall back to your normal
approach (filter the input and read the relevant part yourself).

## Using the result

- Cut the input down with ordinary tools first; `fm` is the last step.
- Before acting on anything the model reports, check it against the source:
  `grep` the exact string, open the file at the reported spot.
- When you report to the user, say the summary came from the on-device model.
