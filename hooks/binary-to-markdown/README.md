# binary-to-markdown Hook

Converts supported binary files to Markdown before AI tools read them, so the model receives text instead of raw binary bytes. This reduces token usage and usually improves extraction quality for document-heavy workflows.

## Tool Compatibility

| Tool | Mechanism | Conversion + Injection | Notes |
|------|-----------|------------------------|-------|
| Claude Code | `PreToolUse` shell hook (`claude-code.sh` / `claude-code.ps1`) | Yes (full) | Blocks `Read` and injects converted Markdown in hook response. |
| OpenCode | Plugin (`config/opencode/plugins/binary-to-markdown.js`) | Yes (full) | Plugin intercepts `read`, runs converter, then denies with Markdown payload. |
| Gemini CLI | BeforeTool shell hook (`gemini.sh` / `gemini.ps1`) | Partial | Converts and logs guidance, but Gemini cannot accept injected replacement content. |
| GitHub Copilot CLI | Repo-scoped hooks (`.github/hooks/hooks.json`) | Not wired by default | Copilot supports repo hooks, but this package does not add a dedicated wrapper yet. |
| Codex | Stub (`codex.sh` / `codex.ps1`) | No | Placeholder until Codex hook specification is published. |

## Supported Extensions

- `.pdf`
- `.docx`
- `.xlsx`
- `.xls`
- `.pptx`
- `.ppt`
- `.epub`
- `.ipynb`

`.doc` is intentionally excluded because `markitdown` does not provide a reliable parser for legacy binary Word (`.doc`) files.

## Dependencies

- Required: `markitdown` CLI (`pip install markitdown`)
- Optional: `httpx` (`pip install httpx`) for Mistral OCR fallback
- Optional: `MISTRAL_API_KEY` environment variable for Mistral OCR fallback on PDFs

## Conversion Pipeline

1. Read from cache (`~/.cache/ai-hooks/binary-to-markdown/`) by file mtime+size key.
2. Run `markitdown <file_path>`.
3. If extraction is poor and file is PDF, attempt Mistral OCR (`mistral-ocr-latest`) when `MISTRAL_API_KEY` is set.
4. Cache final Markdown and return it.

Poor extraction criteria:
- Trimmed text length `< 100`
- Non-ASCII/control ratio (`ord(c) > 127` or `\x00\x01\x02`) `> 5%`

## Installation

### 1) Place files

- Copy this folder to your hook location for Claude/Gemini (for example `~/.claude/hooks/binary-to-markdown/`, `~/.gemini/hooks/binary-to-markdown/`).
- Copy OpenCode plugin file to `~/.config/opencode/plugins/binary-to-markdown.js`.

### 2) Make shell scripts executable

```bash
chmod +x claude-code.sh gemini.sh codex.sh
```

PowerShell scripts do not need `chmod`, but must run under PowerShell 7+.

### 3) Claude Code (`~/.claude/settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/binary-to-markdown/claude-code.sh"
          }
        ]
      }
    ]
  }
}
```

### 4) OpenCode (plugin)

Copy `binary-to-markdown.js` into `~/.config/opencode/plugins/`.

If converter is not at `./hooks/binary-to-markdown/convert.py` relative to your working repo, set:

```bash
export BINARY_TO_MARKDOWN_CONVERTER="/absolute/path/to/convert.py"
```

```powershell
$env:BINARY_TO_MARKDOWN_CONVERTER = 'C:\path\to\convert.py'
```

### 5) Gemini CLI

Set `GEMINI_HOOK_COMMAND` (or your equivalent Gemini hook command setting) to:

```bash
bash ~/.gemini/hooks/binary-to-markdown/gemini.sh
```

```powershell
pwsh -File "$HOME/.gemini/hooks/binary-to-markdown/gemini.ps1"
```

## Cache

- Location: `~/.cache/ai-hooks/binary-to-markdown/`
- Clear cache:

```bash
rm -rf ~/.cache/ai-hooks/binary-to-markdown
```

```powershell
Remove-Item -Recurse -Force "$HOME/.cache/ai-hooks/binary-to-markdown"
```

## Mistral OCR Fallback

Fallback OCR runs only when:
- `markitdown` output is poor
- file extension is `.pdf`
- `MISTRAL_API_KEY` is set

If OCR fails (network/API/non-2xx), the hook logs to stderr and returns the `markitdown` output.

## Known Limitations

- Gemini cannot inject converted content back into the tool call; it can only log guidance.
- `.doc` is excluded (no reliable `markitdown` support).
- PPT/PPTX visual fidelity is not preserved; extracted Markdown focuses on textual content.