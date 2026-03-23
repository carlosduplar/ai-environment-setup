# Tools Catalog

Complete reference for every CLI in this environment.

## Install sources key

| Symbol | Meaning |
|--------|---------|
| W | winget |
| C | Chocolatey |
| N | npm global |
| U | uv tool |
| GH | gh extension |
| D | Direct binary |

---

## AI Coding Agents

### Claude Code
- **CLI**: `claude`
- **Install**: W — `winget install Anthropic.ClaudeCode` or native installer script (see https://code.claude.com/docs/en/setup)
- **Config**: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`
- **Auth**: `ANTHROPIC_AUTH_TOKEN` env var
- **Docs**: https://docs.anthropic.com/claude-code
- **Notes**: Installed to `~/.local/bin/claude.exe` on Windows

### OpenCode
- **CLI**: `opencode`
- **Install**: N — `npm install -g opencode`
- **Config**: `~/.config/opencode/opencode.json`
- **Auth**: Delegated to provider API keys (see `.env.local`)
- **Docs**: https://opencode.ai
- **Notes**: Multi-agent, multi-provider. Config supports named agents with separate model + permission sets.

### Gemini CLI
- **CLI**: `gemini`
- **Install**: N — `npm install -g @google/gemini-cli`
- **Config**: `~/.gemini/GEMINI.md` (system prompt), `~/.gemini/mcp-server-enablement.json`
- **Auth**: Google OAuth (browser-based) or `GOOGLE_API_KEY`
- **Docs**: https://github.com/google-gemini/gemini-cli

### GitHub Copilot CLI
- **CLI**: `gh copilot`
- **Install**: W — `winget install GitHub.Copilot` or N — `npm install -g @github/copilot`
- **Config**: `~/.config/copilot/`
- **Auth**: `gh auth login` → `GITHUB_TOKEN`
- **Docs**: https://docs.github.com/copilot/using-github-copilot/using-github-copilot-in-the-command-line

---

## Source Control

### Git
- **CLI**: `git`
- **Install**: W — `winget install Git.Git`
- **Config**: `~/.gitconfig`, `~/.gitignore_global`
- **Docs**: https://git-scm.com

### GitHub CLI
- **CLI**: `gh`
- **Install**: W — `winget install GitHub.cli`
- **Config**: `~/.config/gh/`
- **Auth**: `gh auth login`
- **Docs**: https://cli.github.com

---

## Cloud & Infrastructure

### Google Cloud SDK
- **CLI**: `gcloud`
- **Install**: W — `winget install Google.CloudSDK`
- **Config**: `~/.config/gcloud/`
- **Auth**: `gcloud auth login`
- **Docs**: https://cloud.google.com/sdk

### Firebase CLI
- **CLI**: `firebase`
- **Install**: N — `npm install -g firebase-tools`
- **Config**: `~/.config/configstore/firebase-tools.json`
- **Auth**: `firebase login`
- **Docs**: https://firebase.google.com/docs/cli

### Google Workspace CLI (gws)
- **CLI**: `gws`
- **Install**: N — `npm install -g @googleworkspace/cli`
- **Config**: `~/.config/gws/`
- **Auth**: OAuth2 via `gws auth login`
- **Notes**: Credentials stored in `~/.config/gws/` — never commit
- **Docs**: Internal / see skills catalog



---

## Runtime & Package Managers

### Node.js / npm
- **CLI**: `node`, `npm`, `npx`
- **Install**: W — `winget install OpenJS.NodeJS.LTS`
- **Version**: LTS

### uv (Python package manager)
- **CLI**: `uv`, `uvx`
- **Install**: W — `winget install astral-sh.uv`
- **Docs**: https://docs.astral.sh/uv

### Python
- **CLI**: `python`, `pip`
- **Install**: W — `winget install Python.Python.3.11`

### .NET SDK
- **CLI**: `dotnet`
- **Install**: W — `winget install Microsoft.DotNet.SDK.8`

---

## Browser Automation

### Playwright
- **CLI**: `playwright`
- **Install**: U — `uv tool install playwright`
- **Post-install**: `playwright install` (downloads browsers)
- **Docs**: https://playwright.dev

---

## AI Documentation

### Context7 (ctx7)
- **CLI**: `ctx7`
- **Install**: N — `npm install -g ctx7`
- **Auth**: None
- **Docs**: https://context7.com

### MarkItDown
- **CLI**: `markitdown`
- **Install**: U — `uv tool install markitdown`
- **Docs**: https://github.com/microsoft/markitdown
- **Notes**: Converts PDF, DOCX, XLSX, images → Markdown

---

## Utilities

### jq
- **CLI**: `jq`
- **Install**: C — `choco install jq` or W — `winget install jqlang.jq`
- **Docs**: https://jqlang.github.io/jq

### micro
- **CLI**: `micro`
- **Install**: W — `winget install sharkdp.micro`
- **Docs**: https://micro-editor.github.io

### Chocolatey
- **CLI**: `choco`
- **Install**: https://chocolatey.org/install
- **Notes**: Required for some packages not on winget

### winget
- **CLI**: `winget`
- **Install**: Built into Windows 11
- **Docs**: https://learn.microsoft.com/windows/package-manager

---

## Environment Variables Reference

| Variable | Tool | Required |
|----------|------|----------|
| `ANTHROPIC_AUTH_TOKEN` | Claude Code | Yes |
| `ANTHROPIC_BASE_URL` | Claude Code | No (proxy only) |
| `BRIGHTDATA_API_KEY` | Bright Data CLI | Yes |
| `NVIDIA_API_KEY` | OpenCode (nvidia provider) | No |
| `OPENROUTER_API_KEY` | OpenCode (openrouter provider) | No |
| `MISTRAL_API_KEY` | OpenCode (mistral provider) | No |
| `GITHUB_TOKEN` | gh, Copilot CLI | Yes |
| `GOOGLE_CLOUD_PROJECT` | gcloud, Firebase | No |
| `FIREBASE_TOKEN` | Firebase CI | No |

