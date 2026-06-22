# Tools Catalog

Complete reference for every CLI in this environment.

## Install sources key

| Symbol | Meaning |
|--------|---------|
| W | winget |
| A | apt (Debian/Ubuntu) |
| N | npm global |
| P | pip |
| PX | pipx |
| GH | gh extension |
| D | Direct binary |

---

## AI Coding Agents (detected, not installed)

These agents are **detected** by setup — if present, their config and hooks are scaffolded. If absent, setup warns and skips.

### Claude Code
- **CLI**: `claude`
- **Install**: W — `winget install Anthropic.ClaudeCode` or native installer script (see https://code.claude.com/docs/en/setup)
- **Config**: `~/.claude/settings.json`, `~/.claude/CLAUDE.md` → symlink to repo `config/.agents/core.md`
- **Output Styles**: Optional `~/.claude/output-styles/` (see `config/output-styles/caveman.md`). Set `"outputStyle": "caveman"` in settings.json for ultra-compact responses.
- **Auth**: `ANTHROPIC_AUTH_TOKEN` env var
- **Docs**: https://docs.anthropic.com/claude-code

### OpenCode
- **CLI**: `opencode`
- **Install**: D — `~/.opencode/bin/opencode`
- **Config**: `~/.config/opencode/opencode.json` — see `config/opencode/opencode.json.example`
- **Auth**: Delegated to provider API keys (see `.env.local`)
- **Docs**: https://opencode.ai

### Antigravity CLI (agy)
- **CLI**: `agy`
- **Install**: D — `~/.local/bin/agy`
- **Config**: `~/.gemini/AGY.md` → symlink to repo `config/antigravity/AGY.md`
- **Auth**: OAuth (browser-based) or `GEMINI_API_KEY`
- **Notes**: Successor to Gemini CLI. Uses `~/.gemini/` as its config directory.

### Codex
- **CLI**: `codex`
- **Install**: N — `npm install -g @openai/codex`
- **Config**: `~/.codex/config.toml`, `~/.codex/AGENTS.md` → symlink to repo `config/.agents/core.md`
- **Example**: `config/codex/config.toml.example` (merge with existing config)

### GitHub Copilot CLI
- **CLI**: `copilot`
- **Install**: N — `npm install -g @github/copilot`
- **Config**: `~/.copilot/copilot-instructions.md` → symlink to repo `config/.agents/core.md`
- **Auth**: `gh auth login` → `GITHUB_TOKEN`
- **Docs**: https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli

---

## Source Control

### Git
- **CLI**: `git`
- **Install**: W — `winget install Git.Git` / A — `sudo apt install git`
- **Config**: `~/.gitconfig`, `~/.gitignore_global`
- **Docs**: https://git-scm.com

### GitHub CLI
- **CLI**: `gh`
- **Install**: W — `winget install GitHub.cli` / A — `sudo apt install gh`
- **Config**: `~/.config/gh/`
- **Auth**: `gh auth login`
- **Docs**: https://cli.github.com

---

## Runtime & Package Managers

### Node.js / npm
- **CLI**: `node`, `npm`, `npx`
- **Install**: W — `winget install OpenJS.NodeJS.LTS` / NVM on Linux
- **Version**: LTS

### Python
- **CLI**: `python3`, `pip`
- **Install**: W — `winget install Python.Python.3` / A — `sudo apt install python3 python3-pip`
- **Notes**: Installed by setup only when python is not already present

### uv (Fast Python)
- **CLI**: `uv`, `uvx`
- **Install**: D — `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Notes**: Fast Python package installer and resolver

### Bun
- **CLI**: `bun`
- **Install**: D — `curl -fsSL https://bun.sh/install | bash`
- **Notes**: Fast JavaScript runtime and package manager

### Cargo (Rust)
- **CLI**: `cargo`, `rustc`
- **Install**: D — `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- **Notes**: Rust package manager

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
- **Auth**: None (optional `CONTEXT7_API_KEY` for higher rate limits)
- **Docs**: https://context7.com

### MarkItDown
- **CLI**: `markitdown`
- **Install**: P — `pip install markitdown`
- **Docs**: https://github.com/microsoft/markitdown
- **Notes**: Converts PDF, DOCX, XLSX, images → Markdown. Requires python + pip. **Auto-skipped on Termux** (not supported on Android).

---

## AI Proxy & Optimization

### Headroom
- **CLI**: `headroom`
- **Install**: PX — `pipx install headroom-ai`
- **Config**: `~/.headroom/`
- **Auth**: API key
- **Notes**: Routes all AI API calls through a local proxy for cost optimization and token tracking. Central component for multi-agent setups.
- **Env vars**: `HEADROOM_PORT`, `HEADROOM_HOST`, `HEADROOM_MODE`, `HEADROOM_BACKEND`

### RTK (Rust Token Killer)
- **CLI**: `rtk`
- **Install**: D — `~/.local/bin/rtk`
- **Notes**: Wraps commands for 60-90% output reduction. Token savings wrapper.

### LiteLLM
- **CLI**: `litellm`, `litellm-proxy`
- **Install**: PX — via uv tool
- **Notes**: Universal LLM API proxy. Supports 100+ LLM providers.

---

## AI Assistants & Tools

### Aider
- **CLI**: `aider`
- **Install**: PX — `pipx install aider-chat`
- **Notes**: AI pair programming in your terminal. Git-aware editing.

### Kimi Code
- **CLI**: `kimi-code`
- **Install**: D — `~/.kimi-code/bin/kimi-code`
- **Config**: `~/.kimi-code/config.toml`
- **Notes**: Moonshot AI coding assistant.

### MiMo Code
- **CLI**: `mimo`
- **Install**: D — `~/.mimocode/bin/mimo`
- **Notes**: Xiaomi MiMo coding agent.

### Cursor Agent
- **CLI**: `cursor-agent`
- **Install**: D — `~/.local/bin/cursor-agent`
- **Notes**: Cursor IDE's command-line agent.

### CodeRabbit
- **CLI**: `coderabbit`, `cr`
- **Install**: D — `~/.local/bin/coderabbit`
- **Notes**: AI code review tool.

### Modal
- **CLI**: `modal`
- **Install**: PX — `pipx install modal`
- **Notes**: Cloud compute platform for AI/ML workloads.

### HuggingFace CLI
- **CLI**: `hf`, `huggingface-cli`, `tiny-agents`
- **Install**: PX — `pipx install huggingface-hub`
- **Auth**: `HF_TOKEN`
- **Notes**: HuggingFace Hub access, model downloads, tiny agents.

---

## Utilities

### jq
- **CLI**: `jq`
- **Install**: W — `winget install jqlang.jq` / A — `sudo apt install jq`
- **Docs**: https://jqlang.github.io/jq

### dotenv
- **CLI**: `dotenv`
- **Install**: D — `~/.local/bin/dotenv`
- **Notes**: Load environment variables from `.env` files.

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
| `ANTHROPIC_BASE_URL` | Claude Code (proxy) | No |
| `GITHUB_TOKEN` | gh, Copilot CLI | Yes |
| `BRIGHTDATA_API_KEY` | Bright Data CLI | Optional |
| `NVIDIA_API_KEY` | OpenCode (nvidia provider) | Optional |
| `OPENROUTER_API_KEY` | OpenCode (openrouter provider) | Optional |
| `MISTRAL_API_KEY` | OpenCode (mistral) + Mistral OCR | Optional |
| `GROQ_API_KEY` | Groq API | Optional |
| `HF_TOKEN` | HuggingFace CLI | Optional |
| `BRAVE_SEARCH_API_KEY` | Brave Search | Optional |
| `CONTEXT7_API_KEY` | Context7 (higher rate limits) | Optional |
| `GEMINI_API_KEY` | Antigravity CLI (agy) | Optional |
| `GOOGLE_CLOUD_PROJECT` | gcloud/Firebase | Optional |
| `HEADROOM_PORT` | Headroom proxy | Optional |
| `HEADROOM_HOST` | Headroom proxy | Optional |
| `HEADROOM_MODE` | Headroom proxy | Optional |
| `HEADROOM_BACKEND` | Headroom proxy | Optional |
