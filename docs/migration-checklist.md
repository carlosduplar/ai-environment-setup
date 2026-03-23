# Migration Checklist

Step-by-step guide to migrate your current Windows 11 machine state into this repository.

## Phase 1 — Audit current state

- [ ] Run `.\bootstrap\verify.ps1` on your current machine to get a baseline
- [ ] Export current winget packages: `winget export --output manifests/winget.json`
- [ ] List current npm globals: `npm list -g --depth=0`
- [ ] List current uv tools: `uv tool list`
- [ ] Compare outputs against `manifests/` files and add anything missing

## Phase 2 — Sanitize config files

**CRITICAL: Do not commit real secrets.**

For each config file you want to add:

| Source file | Action |
|-------------|--------|
| `~/.claude/settings.json` | Replace `ANTHROPIC_AUTH_TOKEN` value with `$ANTHROPIC_AUTH_TOKEN` |
| `~/.config/opencode/opencode.json` | Replace `API_TOKEN` values with `$SERVICE_API_TOKEN` |
| `~/.gemini/GEMINI.md` | Safe to commit as-is (no secrets) |
| `~/.config/gws/` | Do NOT commit — OAuth credentials |
| `~/.gitconfig` | Replace email/name with `<YOUR_*>` placeholders |

Run the security check before each commit:

```powershell
.\bootstrap\verify.ps1 -Security
```

## Phase 3 — Move system prompt / rules

- [ ] Copy `~/.claude/CLAUDE.md` → `config/claude-code/CLAUDE.md`
- [ ] Copy `~/.gemini/GEMINI.md` → `config/gemini/GEMINI.md`
- [ ] Copy any `~/.claude/rules/*.md` → `skills/catalog/`
- [ ] Review each file for private info before committing

## Phase 4 — Document non-scripted tools

For any tool installed manually (not via winget/choco/npm/uv), add it to `docs/tools-catalog.md` with install instructions.

Tools currently requiring manual install:
- **Claude Code**: Direct binary from https://docs.anthropic.com/claude-code


## Phase 5 — Populate .env.local

Copy `templates/.env.example` → `.env.local` and fill in all values:

```powershell
Copy-Item templates\.env.example .env.local
code .env.local  # edit
```

Verify all required keys are set:

```powershell
.\bootstrap\verify.ps1
```

## Phase 6 — Initialize the repo

```powershell
cd C:\projects\ai-environment-setup
git init
git remote add origin https://github.com/<YOUR_USERNAME>/ai-environment-setup
git add .
git commit -m "Initial AI environment setup"
git push -u origin main
```

## Phase 7 — Test on a clean machine

The real test is applying this to a fresh Windows 11 install:

1. Clone repo
2. Copy and fill `.env.local`
3. Run `.\bootstrap\bootstrap.ps1`
4. Run `.\bootstrap\verify.ps1`
5. Fill in `setup-report.md`

## Known gaps / TODOs

- [ ] Claude Code has no stable Windows installer script yet — manual step required

- [ ] Add per-skill `.md` files for all 37 skills (currently only `context7.md` is included)
- [ ] Add `dotnet-tools.json` manifest if .NET global tools are added
- [ ] Add macOS/Linux bootstrap scripts
