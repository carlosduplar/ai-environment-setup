# AI Environment Setup

A **public template repository** capturing a reproducible AI coding environment for Windows 11 + PowerShell 7 + Git Bash, designed to be cloned onto a new machine in minutes.

## What This Repo Does

- Documents every CLI tool and its install source
- Provides safe, secret-free config scaffolding for OpenCode, Claude Code, Gemini CLI, GitHub Copilot CLI, and shared MCPs
- Ships bootstrap scripts to install everything from scratch
- Ships verify scripts to assert a machine is in the expected state
- Catalogs shared skills, MCP servers, and hooks

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows 11 + PowerShell 7 | ✅ Primary target |
| Windows 11 + Git Bash | ✅ Supported |
| macOS | 🔲 Planned |
| Linux | 🔲 Planned |

## Repository Layout

```
ai-environment-setup/
├── bootstrap/          # Install + verify scripts
├── manifests/          # Package inventories (npm, pip, winget, choco)
├── dotfiles/           # Shell and git config examples
├── config/             # AI tool config scaffolding (no secrets)
│   ├── claude-code/
│   ├── opencode/
│   ├── gemini/
│   ├── github-copilot/
│   └── vscode/
├── mcp/                # MCP server catalog and example configs
├── skills/             # Claude Code skills catalog
├── hooks/              # Shared hooks for AI tools
├── templates/          # .env.example and setup-report template
└── docs/               # Reference documentation
```

## Quick Start

### Windows 11

```powershell
# 1. Clone the repo
git clone https://github.com/<YOUR_USERNAME>/ai-environment-setup
cd ai-environment-setup

# 2. Copy and fill in your secrets
Copy-Item templates\.env.example .env.local
# Edit .env.local with your actual API keys — never commit this file

# 3. Run bootstrap (installs all CLIs)
.\bootstrap\bootstrap.ps1

# 4. Verify everything is in place
.\bootstrap\verify.ps1
```

### Git Bash

```bash
git clone https://github.com/<YOUR_USERNAME>/ai-environment-setup
cd ai-environment-setup
cp templates/.env.example .env.local
# Edit .env.local
bash bootstrap/bootstrap.sh
bash bootstrap/verify.sh
```

## Tool Inventory

See [docs/tools-catalog.md](docs/tools-catalog.md) for the full list of tools, their install sources, and required environment variables.

| Tool | Install Method | Config Location |
|------|---------------|-----------------|
| Claude Code | `winget install Anthropic.ClaudeCode` / native installer script | `~/.claude/settings.json` |
| OpenCode | `npm -g opencode` | `~/.config/opencode/opencode.json` |
| Gemini CLI | `npm -g @google/gemini-cli` | `~/.gemini/GEMINI.md` |
| GitHub Copilot CLI | `winget install GitHub.Copilot` / `npm -g @github/copilot` | `~/.config/copilot/` |
| Playwright | `uv tool install playwright` | Per-project |
| Context7 (ctx7) | `npm -g ctx7` | Per-project |
| Firebase CLI | `npm -g firebase-tools` | `~/.config/configstore/` |
| gcloud | Google Cloud SDK installer | `~/.config/gcloud/` |
| gws | `npm -g @googleworkspace/cli` | `~/.config/gws/` |
| markitdown | `uv tool install markitdown` | None |
| gh | `winget install GitHub.cli` | `~/.config/gh/` |

## Configuration Flow

```
templates/.env.example
        │
        ▼ (copy + fill)
    .env.local  ──────────────────────────────────────────────────────┐
        │                                                              │
        ▼                                                              │
config/claude-code/settings.json.example  ──(apply)──>  ~/.claude/settings.json
config/opencode/opencode.json.example     ──(apply)──>  ~/.config/opencode/opencode.json
config/gemini/GEMINI.md                   ──(apply)──>  ~/.gemini/GEMINI.md
```

## Update Flow

1. Pull latest: `git pull`
2. Re-run bootstrap: `.\bootstrap\bootstrap.ps1 --update`
3. Verify: `.\bootstrap\verify.ps1`
4. Sync any new config examples to your live config manually (never automated to avoid overwriting local state)

## Security Model

- **This repo contains zero secrets.** All sensitive values are environment variables.
- Secrets live in `~/.env.local` (gitignored) or your secret manager.
- `.example` files show structure only — placeholder values are clearly marked.
- See [SECURITY.md](SECURITY.md) for the full redaction rules.

## Hooks

Shared hook scripts that run before tool calls to enforce security policies (block secret file access) and safety checks (prevent compaction with uncommitted changes).

| Tool | Hook Support | Hook Script | Configuration |
|------|-------------|-------------|---------------|
| Claude Code | Yes (PreToolUse) | `claude-code-pre-tool-use.sh` / `.ps1` | `~/.claude/hooks/` (referenced in `~/.claude/settings.json`) |
| OpenCode | Yes (bash hooks) | `opencode-pre-tool-use.sh` / `.ps1` | `~/.config/opencode/hooks/` (referenced in `~/.config/opencode/opencode.json`) |
| Gemini CLI | Yes (environment variables) | `gemini-pre-tool-use.sh` / `.ps1` | `~/.gemini/hooks/` (referenced in `~/.gemini/settings.json`) |
| GitHub Copilot CLI | No | N/A | N/A |

**What the hooks do:**
- **Secret file protection** – Deny read/edit/create operations on files matching patterns like `.env`, `secrets/`, `*.key`, `credentials.json`, etc.
- **Compact safety check** – Block `/compact` commands when the git working tree has uncommitted changes.

**Scope:**
- Claude Code hooks use environment variables (`CLAUDE_TOOL_NAME`, `CLAUDE_TOOL_INPUT_PATH`, `CLAUDE_TOOL_INPUT_COMMAND`) and exit with non‑zero to deny.
- OpenCode hooks expect JSON input via stdin (keys: `toolName`, `toolArgs`) and output JSON with `permissionDecision`.
- Gemini CLI hooks use environment variables (`GEMINI_TOOL_NAME`, `GEMINI_TOOL_INPUT_PATH`, `GEMINI_TOOL_INPUT_COMMAND`) and exit with non‑zero to deny.
- GitHub Copilot CLI does not support hooks; secret protection is enforced via the generic pre‑tool‑use hook (which can be manually configured).

See `hooks/README.md` for details on adding custom hooks.

## What Is Intentionally Excluded

| Excluded | Reason |
|----------|--------|
| API keys, tokens, cookies | Security — use `.env.local` |
| OAuth credentials (`client_secret.json`, etc.) | Security — private overlay only |
| Conversation history | Privacy |
| Machine-specific paths | Portability |
| Proprietary internal system prompts | IP protection |
| Tool caches and session state | Not reproducible |
| SSH keys | Security |

## Contributing

This is a personal environment template. PRs that add cross-platform support (macOS/Linux) or improve the bootstrap scripts are welcome. See [SECURITY.md](SECURITY.md) before submitting.

## License

MIT — see [LICENSE](LICENSE).
