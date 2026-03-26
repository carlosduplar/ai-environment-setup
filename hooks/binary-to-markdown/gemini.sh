#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONVERTER="$SCRIPT_DIR/convert.py"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[binary-to-markdown] Missing dependency: python3 (required for conversion)." >&2
  exit 0
fi

TOOL_NAME="${GEMINI_TOOL_NAME:-}"
FILE_PATH="${GEMINI_TOOL_INPUT_PATH:-}"
TOOL_LOWER="$(printf '%s' "$TOOL_NAME" | tr '[:upper:]' '[:lower:]')"

case "$TOOL_LOWER" in
  read|read_file|open_file|view) ;;
  *) exit 0 ;;
esac

FILE_PATH_LOWER="$(printf '%s' "$FILE_PATH" | tr '[:upper:]' '[:lower:]')"
case "$FILE_PATH_LOWER" in
  *.pdf|*.docx|*.xlsx|*.xls|*.pptx|*.ppt|*.epub|*.ipynb) ;;
  *) exit 0 ;;
esac

if python3 "$CONVERTER" "$FILE_PATH" >/dev/null; then
  FILE_NAME="$(basename "$FILE_PATH")"
  echo "[binary-to-markdown] Note: Gemini hook cannot inject converted content back." >&2
  echo "[binary-to-markdown] Converted \`$FILE_NAME\` to Markdown but Gemini will still attempt the raw read." >&2
  echo "[binary-to-markdown] Consider pre-converting manually with: markitdown \"$FILE_PATH\"" >&2
fi

exit 0
