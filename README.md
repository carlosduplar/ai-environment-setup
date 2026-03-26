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

MCP servers send schemas, tool descriptions, and discovery payloads to the model on every request. As more MCP servers are added, the context window fills with metadata that has nothing to do with the task. This inflates token usage significantly.

### 2. Token Efficiency

CLI calls are leaner — just the command and its output. MCP adds JSON schemas, tool discovery, and structured responses that multiply token usage. Studies show CLI-agent approaches can achieve up to 33% better token efficiency in developer tasks. The Playwright CLI explicitly recommends CLI over MCP for coding agents because "CLI invocations are more token-efficient: they avoid loading large tool schemas and verbose accessibility trees into the model context."

### 3. Inspectability and Debugging

CLIs are directly observable: run `gh issue list` in your terminal, see the output, pipe it through `jq`, or re-run the command manually. MCP interactions are opaque — they happen inside the protocol, requiring MCP-specific debugging tools. When something breaks, you can always fall back to running the CLI yourself.

### 4. Cost

Fewer tokens mean lower inference costs. MCP's schema overhead adds up, especially for lightweight automation tasks that CLI handles with a single command. For users on token-based subscriptions or PAYG accounts, this can burn through credits exponentially faster.

### Rule: When to Add an MCP Server

**Almost never.** Check for a CLI alternative first:
1. Search for CLI versions of popular MCP products
2. Use [CLI-Anything](https://github.com/HKUDS/CLI-Anything) to convert open-source repos into CLIs
3. Only add MCP if no CLI exists and the value justifies the token cost

See [docs/tools-catalog.md](docs/tools-catalog.md) for the current CLI inventory.

## Repository Layout

```
ai-environment-setup/
├── bootstrap/          # Install + verify scripts
├── manifests/          # Package inventories (npm, pip, winget)
├── dotfiles/           # Shell and git config examples
├── config/ # AI tool config scaffolding (no secrets)
│   ├── claude-code/
│   ├── opencode/
│   ├── gemini/
│   └── github-copilot/
├── skills/ # Agent skills catalog
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

# 3. Run bootstrap (detects installed agents, configures them)
.\bootstrap\bootstrap.ps1

# Optional: include Google Workspace CLI + skills
.\bootstrap\bootstrap.ps1 -GWS

# Optional: include Firebase CLI
.\bootstrap\bootstrap.ps1 -Firebase

# 4. Verify everything is in place
.\bootstrap\verify.ps1
```

### Git Bash

```bash
git clone https://github.com/<YOUR_USERNAME>/ai-environment-setup
cd ai-environment-setup
cp templates/.env.example .env.local
# Edit .env.local

# Run bootstrap (detects installed agents, configures them)
bash bootstrap/bootstrap.sh

# Optional flags
bash bootstrap/bootstrap.sh --gws --firebase

bash bootstrap/verify.sh
```

## Tool Inventory

See [docs/tools-catalog.md](docs/tools-catalog.md) for the full list of tools, their install sources, and required environment variables.

| Tool | Description | Install Method | Config Location |
|------|-------------|---------------|-----------------|
| Claude Code | Anthropic's AI coding assistant | Detected; configure if present | `~/.claude/settings.json` |
| OpenCode | OpenCode's AI coding assistant | Detected; configure if present | `~/.config/opencode/opencode.json` |
| Gemini CLI | Google's AI CLI | Detected; configure if present | `~/.gemini/GEMINI.md` |
| GitHub Copilot CLI | GitHub's AI coding assistant | Detected; configure if present | `~/.copilot/` |
| Playwright CLI | Browser automation | `npm install -g @playwright/cli` | Per-project |
| Context7 (ctx7) | Fetch current library docs | `npm -g ctx7` | Per-project |
| markitdown | Convert documents to Markdown | `pip install markitdown` | None |
| gh | GitHub CLI | `winget install GitHub.cli` | `~/.config/gh/` |
| Firebase CLI | Firebase project management | `-Firebase` flag (opt-in) | `~/.config/configstore/` |
| gws | Google Workspace CLI | `-GWS` flag (opt-in) | `~/.config/gws/` |

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
config/github-copilot/copilot-instructions.md  ──(apply)──>  ~/.copilot/copilot-instructions.md
```

Config scaffolding is **agent-gated** — only configures tools that are already installed. Run `.\bootstrap\verify.ps1` to see which agents were detected.

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

### Why Hooks Instead of Instructions in Markdown?

You might wonder: why not just add security rules to `CLAUDE.md` or `AGENTS.md`? The answer is simple: **LLMs treat markdown files as suggestions, not requirements.**

We learned this the hard way. Here's what happens:

- You write "never touch .env files" in `CLAUDE.md`
- The LLM reads it, nods politely, and 3 sessions later deletes your `.env` while "cleaning up the project"
- You add it again in bigger letters: "DO NOT EDIT .env"
- Next week: same problem, different session

LLMs are helpful by default — they want to complete your task. When they see a file that looks "messy" or "out of place," they'll clean it. Your secrets are collateral damage.

**Hooks solve this.** They execute *before* the tool runs, at the protocol level. The LLM cannot bypass them because:

1. Hooks intercept the tool call before it executes
2. Blocking returns a denial that the LLM must respect
3. No amount of clever prompting can bypass a pre-tool-use guard

Markdown instructions are **advisory** — hooks are **enforcement**. Use hooks for anything that must never, ever happen (secret file access, destructive commands, etc.).

### Rule: Hook Design Principles

1. **Fail closed** — deny by default, allow explicitly
2. **Never execute AI output** — validate all inputs before running commands
3. **Log decisions** — track why access was granted or denied
4. **Platform-aware** — provide both `.sh` (Git Bash) and `.ps1` (PowerShell) versions
5. **Tool-specific** — each AI tool has different hook interfaces (env vars, JSON stdin, etc.)

### Pre-Built Hooks

| Tool | Hook Script | Mechanism | Global (User) Config | Repo Config |
|------|-------------|-----------|---------------------|-------------|
| Claude Code | `claude-code-pre-tool-use.sh` / `.ps1` | Environment variables (`CLAUDE_TOOL_NAME`, etc.) — exit non-zero to deny | `~/.claude/settings.json` | `.claude/settings.json` |
| OpenCode | `config/opencode/plugins/security.js` | Plugin hook (`tool.execute.before`) — throw Error to deny | `~/.config/opencode/opencode.json` + `~/.config/opencode/plugins/` | `config/opencode/plugins/` |
| Gemini CLI | `gemini-pre-tool-use.sh` / `.ps1` | Environment variables (`GEMINI_TOOL_NAME`, etc.) — exit non-zero to deny | `~/.gemini/` | `.gemini/` |
| GitHub Copilot CLI | `hooks/pre-tool-use.sh` / `.ps1` | JSON stdin (`toolName`, `toolArgs`) — output JSON with `permissionDecision` | Not supported | `.github/hooks/*.json` |

### Shared Hook Scripts (all platforms)

| Script | Purpose |
|--------|---------|
| `pre-tool-use.ps1/.sh` | Hook 2 (Secret blocking) + Hook 5 (Auto-approval) |
| `post-tool-use.ps1/.sh` | Hook 1 (Auto-format) |
| `notification.ps1/.sh` | Hook 3 (Desktop notifications) |
| `post-compact.ps1/.sh` | Hook 4 (Context memory refresh) |

### What the Hooks Do

- **Hook 1: Auto-Format Every File Edit** — Runs Prettier on every file edit/write automatically
- **Hook 2: Secret file protection** — Deny read/edit/create on `.env`, `secrets/`, `*.key`, `credentials.json`, etc.
- **Hook 3: Desktop Notifications** — Native OS alerts when Claude needs your input
- **Hook 4: Context Memory Refresh** — Re-reads critical files (CLAUDE.md, ARCHITECTURE.md) after context compaction
- **Hook 5: Auto-Approval God Mode** — Whitelists safe commands (npm test, git diff, etc.) to skip permission prompts
- **Compact safety check** — Block `/compact` when git working tree has uncommitted changes

### Hook Scope by Tool

- **Claude Code**: Uses `CLAUDE_TOOL_NAME`, `CLAUDE_TOOL_INPUT_PATH`, `CLAUDE_TOOL_INPUT_COMMAND`. Exit code 1 = deny.
- **OpenCode**: Uses `config/opencode/plugins/security.js` (`tool.execute.before`). The plugin inspects `input.tool` + args and throws to deny unsafe actions.
- **Gemini CLI**: Uses `GEMINI_TOOL_NAME`, `GEMINI_TOOL_INPUT_PATH`, `GEMINI_TOOL_INPUT_COMMAND`. Exit code 1 = deny.
- **GitHub Copilot CLI**: Hooks are **repo-scoped only** (`.github/hooks/`). There is **no global/user-level hook config** — hooks must be added to each repository individually. This is a known limitation tracked in [GitHub issue #1157](https://github.com/github/copilot-cli/issues/1157).

### Copilot CLI Hook Limitation

Unlike Claude Code, OpenCode, and Gemini CLI — which all support global/user-level hook configuration — GitHub Copilot CLI currently **does not support user-based hook files**. This means:

- Hooks only work when running Copilot CLI **from within a repository** that has `.github/hooks/*.json`
- Each repo must independently include its own hook configuration
- There is no `~/.copilot/hooks.json` or equivalent that applies across all repos

**Workaround**: We place hooks in `.github/hooks/hooks.json` in this repo. For other repos, you must manually copy the hook config. A third-party tool, [gh-hookflow](https://github.com/htekdev/gh-hookflow), can install personal hooks at `~/.copilot/hooks/hooks.json`, but this is not native Copilot CLI behavior.

See [hooks/README.md](hooks/README.md) and [docs/hooks-catalog.md](docs/hooks-catalog.md) for details.

## Skills

Agent skills extend AI tool capabilities. Installed via `npx skills add` from local sources.

Skills are installed per the [skills catalog](skills/README.md). Google Workspace skills (`gws-*`) are gated behind the `-GWS` flag and are not installed by default.

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
| MCP servers | CLI-first preference — see "Why No MCP Servers?" above |

## Contributing

This is a personal environment template. PRs that add cross-platform support (macOS/Linux) or improve the bootstrap scripts are welcome. See [SECURITY.md](SECURITY.md) before submitting.

## License

MIT — see [LICENSE](LICENSE).
