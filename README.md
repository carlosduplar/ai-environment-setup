# AI Environment Setup

A **public template repository** capturing a reproducible AI coding environment for Windows 11 + PowerShell 7 + Git Bash, designed to be cloned onto a new machine in minutes.

## What This Repo Does

- Documents every CLI tool and its install source
- Provides safe, secret-free config scaffolding for OpenCode, Claude Code, Gemini CLI, GitHub Copilot CLI
- Ships bootstrap scripts to install everything from scratch
- Ships verify scripts to assert a machine is in the expected state
- Catalogs shared skills and hooks

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows 11 + PowerShell 7 | Primary target |
| Windows 11 + Git Bash | Supported |
| macOS | Planned |
| Linux | Planned |

## Why No MCP Servers? (MCP vs CLI)

This repository deliberately excludes MCP (Model Context Protocol) servers in favor of standalone CLI tools. The core reasons:

### 1. Context Window Bloat

MCP servers send schemas, tool descriptions, and discovery payloads to the model on every request. As more MCP servers are added, the context window fills with metadata that has nothing to do with the task. Benchmarks show this can inflate token usage significantly.

### 2. Token Efficiency

CLI calls are leaner — just the command and its output. MCP adds JSON schemas, tool discovery, and structured responses that multiply token usage. Studies show CLI-agent approaches can achieve up to 33% better token efficiency in developer tasks.

### 3. Inspectability and Debugging

CLIs are directly observable: run `gh issue list` in your terminal, see the output, pipe it through `jq`, or re-run the command manually. MCP interactions are opaque — they happen inside the protocol, requiring MCP-specific debugging tools. When something breaks, you can always fall back to running the CLI yourself.

### 4. Cost

Fewer tokens mean lower inference costs. MCP's schema overhead adds up, especially for lightweight automation tasks that CLI handles with a single command.

### 5. Explicit Opt-in for Browsers

Only Playwright MCP remains — because browser automation is inherently stateful (requires CDP, session state). For everything else (search, docs, drive, calendar, email), use the corresponding CLI.

### Rule: When to Add an MCP Server

Only add an MCP server if ALL of these are true:
1. No equivalent CLI exists (e.g., `@playwright/mcp`)
2. The tool is browser-based (requires CDP/state)
3. The MCP is maintained by the official vendor
4. It provides meaningful value that CLI cannot replicate

Otherwise, prefer the CLI. See [docs/tools-catalog.md](docs/tools-catalog.md) for the current CLI inventory.

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
│   └── github-copilot/
├── mcp/                # MCP server catalog (minimal)
├── skills/             # Agent skills catalog
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
| Claude Code | `winget install Anthropic.ClaudeCode` / native installer | `~/.claude/settings.json` |
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
| Bright Data | `npm -g @brightdata/cli` | `~/.config/brightdata/` |

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

Shared hook scripts that run before tool calls to enforce security policies and safety checks.

### Rule: Hook Design Principles

1. **Fail closed** — deny by default, allow explicitly
2. **Never execute AI output** — validate all inputs before running commands
3. **Log decisions** — track why access was granted or denied
4. **Platform-aware** — provide both `.sh` (Git Bash) and `.ps1` (PowerShell) versions
5. **Tool-specific** — each AI tool has different hook interfaces (env vars, JSON stdin, etc.)

### Pre-Built Hooks

| Tool | Hook Script | Mechanism |
|------|-------------|-----------|
| Claude Code | `claude-code-pre-tool-use.sh` / `.ps1` | Environment variables (`CLAUDE_TOOL_NAME`, etc.) — exit non-zero to deny |
| OpenCode | `opencode-pre-tool-use.sh` / `.ps1` | JSON stdin (`toolName`, `toolArgs`) — output JSON with `permissionDecision` |
| Gemini CLI | `gemini-pre-tool-use.sh` / `.ps1` | Environment variables (`GEMINI_TOOL_NAME`, etc.) — exit non-zero to deny |

### What the Hooks Do

- **Secret file protection** — Deny read/edit/create on `.env`, `secrets/`, `*.key`, `credentials.json`, etc.
- **Compact safety check** — Block `/compact` when git working tree has uncommitted changes

### Hook Scope by Tool

- **Claude Code**: Uses `CLAUDE_TOOL_NAME`, `CLAUDE_TOOL_INPUT_PATH`, `CLAUDE_TOOL_INPUT_COMMAND`. Exit code 1 = deny.
- **OpenCode**: Receives JSON via stdin: `{"toolName": "Read", "toolArgs": {"filePath": "..."}}`. Output: `{"permissionDecision": "allow"}` or `{"permissionDecision": "deny", "reason": "..."}`.
- **Gemini CLI**: Uses `GEMINI_TOOL_NAME`, `GEMINI_TOOL_INPUT_PATH`, `GEMINI_TOOL_INPUT_COMMAND`. Exit code 1 = deny.
- **GitHub Copilot CLI**: No hook support. Secret protection enforced via generic pre-tool-use hook (manual config).

See [hooks/README.md](hooks/README.md) and [docs/hooks-catalog.md](docs/hooks-catalog.md) for details.

## Skills

Agent skills extend AI tool capabilities. Installed via `npx skills add <repo>`.

### Rule: When to Add a Skill

Add a skill if:
1. The skill automates a recurring workflow (docs, sheets, calendar, email)
2. It replaces manual CLI invocations
3. It is maintained by a reputable vendor

See [docs/skills-catalog.md](docs/skills-catalog.md) for installed skills.

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
| MCP servers (except Playwright) | CLI-first preference — see "Why No MCP Servers?" above |

## Contributing

This is a personal environment template. PRs that add cross-platform support (macOS/Linux) or improve the bootstrap scripts are welcome. See [SECURITY.md](SECURITY.md) before submitting.

## License

MIT — see [LICENSE](LICENSE).