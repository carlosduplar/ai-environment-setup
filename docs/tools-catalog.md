# Tools Catalog

Complete reference for every CLI in this environment.

## Install sources key

| Symbol | Meaning |
|--------|---------|
| W | winget |
| N | npm global |
| P | pip |
| GH | gh extension |
| D | Direct binary |

---

## AI Coding Agents (detected, not installed)

These agents are **detected** by setup — if present, their config and hooks are scaffolded. If absent, setup warns and skips.

### Claude Code
- **CLI**: `claude`
- **Install**: W — `winget install Anthropic.ClaudeCode` or native installer script (see https://code.claude.com/docs/en/setup)
- **Config**: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`
- **Auth**: `ANTHROPIC_AUTH_TOKEN` env var
- **Docs**: https://docs.anthropic.com/claude-code

### OpenCode
- **CLI**: `opencode`
- **Install**: N — `npm install -g opencode`
- **Config**: `~/.config/opencode/opencode.json`
- **Auth**: Delegated to provider API keys (see `.env.local`)
- **Docs**: https://opencode.ai

### Gemini CLI
- **CLI**: `gemini`
- **Install**: N — `npm install -g @google/gemini-cli`
- **Config**: `~/.gemini/GEMINI.md` (system prompt), `~/.gemini/mcp-server-enablement.json`
- **Auth**: Google OAuth (browser-based) or `GOOGLE_API_KEY`
- **Docs**: https://github.com/google-gemini/gemini-cli

### GitHub Copilot CLI
- **CLI**: `copilot`
- **Install**: N — `npm install -g @github/copilot`
- **Config**: `~/.copilot/`
- **Auth**: `gh auth login` → `GITHUB_TOKEN`
- **Docs**: https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli

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

## Runtime & Package Managers

### Node.js / npm
- **CLI**: `node`, `npm`, `npx`
- **Install**: W — `winget install OpenJS.NodeJS.LTS`
- **Version**: LTS

### Python
- **CLI**: `python`, `pip`
- **Install**: W — `winget install Python.Python.3` (only if no python exists)
- **Notes**: Installed by setup only when python is not already present

---

## Browser Automation

### Playwright
- **CLI**: `playwright`
- **Install**: N — `npm install -g @playwright/cli`
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
- **Install**: P — `pip install markitdown`
- **Docs**: https://github.com/microsoft/markitdown
- **Notes**: Converts PDF, DOCX, XLSX, images → Markdown. Requires python + pip. **Auto-skipped on Termux** (not supported on Android).

---

## Utilities

### jq
- **CLI**: `jq`
- **Install**: W — `winget install jqlang.jq`
- **Docs**: https://jqlang.github.io/jq

### winget
- **CLI**: `winget`
- **Install**: Built into Windows 11
- **Docs**: https://learn.microsoft.com/windows/package-manager

---

## Optional Tools (flag-gated)

These are NOT installed by default. Use setup flags to opt in.

### Firebase CLI (`-Firebase`)
- **CLI**: `firebase`
- **Install**: N — `npm install -g firebase-tools`
- **Config**: `~/.config/configstore/firebase-tools.json`
- **Auth**: `firebase login`
- **Docs**: https://firebase.google.com/docs/cli

### Google Workspace CLI (`-GWS`)
- **CLI**: `gws`
- **Install**: N — `npm install -g @googleworkspace/cli`
- **Config**: `~/.config/gws/`
- **Auth**: OAuth2 via `gws auth login`
- **Docs**: Internal / see skills catalog
- **Skills**: All `gws-*` skills are gated behind `-GWS`

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
