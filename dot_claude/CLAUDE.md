# Personal preferences

## Language

Reply in Italian unless the conversation or the artifact (code, commit
message, doc) is already in another language.

## Environment

macOS — assume zsh, Homebrew at `/opt/homebrew`, and BSD-flavored CLI tools
(e.g. `sed -i '' …`, not GNU syntax) unless the project pins a specific
toolchain.

## Workflow

- Before rebasing, large refactors, or any multi-file restructuring,
  summarize the branch's goals and the proposed changes and wait for
  confirmation before committing.
- For non-trivial features in a codebase that already has tests, prefer the
  test-first cycle: write the failing test, then the minimum code to pass,
  then refactor. Skip on small bugfixes or one-line tweaks.

## Testing

Verify claims by actually running tests and builds before reporting status.
Never describe a test as "passing" or "verifying behavior" without executing
it in this session.

## Communication style

When asked for examples or alternative approaches, present them as choices
for the user to pick from. Do not pick one silently and start editing.
