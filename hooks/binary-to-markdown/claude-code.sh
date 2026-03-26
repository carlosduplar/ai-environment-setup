#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONVERTER="$SCRIPT_DIR/convert.py"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[binary-to-markdown] Missing dependency: python3 (required for hook parsing and conversion)." >&2
  exit 0
fi

INPUT_JSON="$(cat)"
PARSED="$(printf '%s' "$INPUT_JSON" | python3 -c 'import json,sys
try:
    payload=json.load(sys.stdin)
except Exception:
    print("\n", end="")
    sys.exit(0)
tool=payload.get("tool_name") or ""
file_path=(payload.get("tool_input") or {}).get("file_path") or ""
sys.stdout.write(tool+"\n"+file_path)
')"

TOOL_NAME="$(printf '%s' "$PARSED" | sed -n '1p')"
FILE_PATH="$(printf '%s' "$PARSED" | sed -n '2p')"

if [[ "$TOOL_NAME" != "Read" ]]; then
  exit 0
fi

FILE_PATH_LOWER="$(printf '%s' "$FILE_PATH" | tr '[:upper:]' '[:lower:]')"
case "$FILE_PATH_LOWER" in
  *.pdf|*.docx|*.xlsx|*.xls|*.pptx|*.ppt|*.epub|*.ipynb) ;;
  *) exit 0 ;;
esac

FILE_NAME="$(basename "$FILE_PATH")"
if MARKDOWN_OUTPUT="$(python3 "$CONVERTER" "$FILE_PATH")"; then
  printf '%s' "$MARKDOWN_OUTPUT" | python3 -c 'import json,sys
filename=sys.argv[1]
markdown=sys.stdin.read()
reason="[binary-to-markdown] Converted `{0}` -> Markdown\n\n{1}".format(filename, markdown)
print(json.dumps({"decision":"block","reason":reason}))
' "$FILE_NAME"
else
  python3 -c 'import json,sys
filename=sys.argv[1]
reason="[binary-to-markdown] Conversion failed for `{0}`. See stderr for details.".format(filename)
print(json.dumps({"decision":"block","reason":reason}))
' "$FILE_NAME"
fi