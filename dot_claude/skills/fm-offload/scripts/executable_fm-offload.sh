#!/bin/bash
# Run a light text task on Apple's on-device Foundation Model (`fm`).
#
# Usage: fm-offload.sh -i "<instructions>" [--schema FILE] [--chunk [--merge]] [--budget N] < input
#
# Reads the input text from stdin. Refuses input that does not fit the model's
# context (about 8k tokens, output included) unless --chunk is given: then the
# input is split on line boundaries and each piece is processed with the same
# instructions. The partial results are joined with duplicate lines removed;
# --merge instead asks the model to merge them (for prose summaries; it can
# drop items).
#
# Exit codes: 0 ok, 1 fm error, 2 usage / input too large, 3 model unavailable.

set -uo pipefail
export NO_COLOR=1

instructions=""
schema=""
chunk=0
merge=0
budget=5500   # max tokens of instructions + input per call; the rest is left for the output

while [ $# -gt 0 ]; do
  case "$1" in
    -i|--instructions) instructions="$2"; shift 2 ;;
    --schema) schema="$2"; shift 2 ;;
    --chunk) chunk=1; shift ;;
    --merge) merge=1; shift ;;
    --budget) budget="$2"; shift 2 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "fm-offload: unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -n "$instructions" ] || { echo "fm-offload: -i <instructions> is required" >&2; exit 2; }
command -v fm >/dev/null || { echo "fm-offload: fm not found (needs macOS 27)" >&2; exit 3; }
fm available >/dev/null 2>&1 || { echo "fm-offload: on-device model not available" >&2; exit 3; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/fm-offload.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/input"
[ -s "$tmp/input" ] || { echo "fm-offload: empty input on stdin" >&2; exit 2; }

strip_ansi() { sed $'s/\x1b\\[[0-9;]*[A-Za-z]//g'; }

count() { # count tokens of file $1 with instructions $2
  fm count-tokens -q -i "$2" < "$1" 2>/dev/null
}

run() { # run the model on file $1 with instructions $2; print the response
  local args=(respond --no-stream --greedy --guardrails permissive-content-transformations -i "$2")
  [ -n "$schema" ] && args+=(--schema "$schema")
  local out
  out=$(fm "${args[@]}" < "$1" 2>&1 | strip_ansi)
  if printf '%s' "$out" | grep -q '^Error:'; then
    echo "fm-offload: $out" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

total=$(count "$tmp/input" "$instructions")
[ -n "$total" ] || { echo "fm-offload: token count failed" >&2; exit 1; }

if [ "$total" -le "$budget" ]; then
  run "$tmp/input" "$instructions" || exit 1
  exit 0
fi

if [ "$chunk" -eq 0 ]; then
  echo "fm-offload: input is $total tokens, budget is $budget. Re-run with --chunk, or do not offload this task." >&2
  exit 2
fi

# Split on line boundaries into pieces of roughly budget*0.8 tokens,
# using this input's own bytes-per-token ratio.
bytes=$(wc -c < "$tmp/input" | tr -d ' ')
piece_bytes=$(( bytes * budget * 8 / 10 / total ))
awk -v max="$piece_bytes" -v dir="$tmp" '
  { len = length($0) + 1
    if (n == 0 || (size + len > max && size > 0)) { n++; size = 0 }
    print > (dir "/piece." sprintf("%03d", n)); size += len }
' "$tmp/input"

: > "$tmp/partials"
i=0
for piece in "$tmp"/piece.*; do
  i=$((i + 1))
  tokens=$(count "$piece" "$instructions")
  if [ "${tokens:-0}" -gt "$budget" ]; then
    echo "fm-offload: piece $i is $tokens tokens (a single very long line?); cannot process" >&2
    exit 2
  fi
  run "$piece" "$instructions" >> "$tmp/partials" || exit 1
done

if [ "$merge" -eq 0 ]; then
  awk 'NF && !seen[$0]++' "$tmp/partials"
  exit 0
fi

reduce="These are partial results of the same task applied to consecutive parts of one input. Merge them into a single result. Keep every distinct item. The original task was: $instructions"
if [ "$(count "$tmp/partials" "$reduce")" -le "$budget" ]; then
  run "$tmp/partials" "$reduce" || exit 1
else
  echo "fm-offload: partial results too large to merge in one call; printing them deduplicated" >&2
  awk 'NF && !seen[$0]++' "$tmp/partials"
fi
