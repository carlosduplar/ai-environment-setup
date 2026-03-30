# Troubleshooting

## Claude Code

### `claude: command not found`
Claude Code installs to `~/.local/bin/`. Ensure this is on your PATH:

```powershell
# Add to PowerShell profile
$env:PATH += ";$env:USERPROFILE\.local\bin"
```

### `ANTHROPIC_AUTH_TOKEN` errors
Check `.env.local` has the token, and the profile loads it:

```powershell
[System.Environment]::GetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN")
```

### Claude ignores CLAUDE.md
CLAUDE.md must be at `~/.claude/CLAUDE.md` for global scope or in the project root for project scope.

---

## OpenCode

### Bright Data CLI authentication
```powershell
# Authenticate with Bright Data CLI
brightdata login
# Or set API key via environment variable
$env:BRIGHTDATA_API_KEY = "your_key"
```

### `opencode: command not found` after `npm install -g opencode`
npm global bin may not be on PATH:

```powershell
npm config get prefix
# Add <prefix>\bin to PATH
```

---

## Gemini CLI

### OAuth login loop
Delete stored credentials and re-authenticate:

```powershell
Remove-Item "$env:USERPROFILE\.gemini\oauth_creds.json" -ErrorAction SilentlyContinue
gemini  # will prompt for login
```

### GEMINI.md not applied
The file must be at `~/.gemini/GEMINI.md`. Check:

```powershell
Test-Path "$env:USERPROFILE\.gemini\GEMINI.md"
```

---

## gws (Google Workspace CLI)

### Complex JSON args fail in PowerShell
Known issue: shell escaping breaks `--params` flag.
**Workaround**: use Python subprocess:

```python
import subprocess, json
cmd = ["gws", "sheets", "values", "get", "--spreadsheetId", "...", "--range", "A1:B10"]
result = subprocess.run(cmd, capture_output=True, text=True)
print(result.stdout)
```

### Re-authenticate
```powershell
Remove-Item "$env:USERPROFILE\.config\gws\credentials.enc" -ErrorAction SilentlyContinue
gws auth login
```

---

## setup.ps1

### "winget not found"
winget ships with Windows 11. On older systems: install from https://aka.ms/getwinget

### Script execution policy error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Tool installs but CLI not found after setup
Open a new PowerShell window — PATH changes require a new session.

---

## verify.ps1 failures

### All env vars failing
`.env.local` is not being sourced. Ensure it exists and has no syntax errors:

```powershell
Get-Content "$PWD\.env.local" | Select-Object -First 10
```

### Config file missing
Re-run setup with `-Update` flag:

```powershell
.\setup\setup.ps1 -Update
```

---

## General

### PATH not updated after install
Close and reopen PowerShell, or:

```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")
```

### Git Bash and PowerShell have different PATH
Tools installed via npm/uv on PowerShell may not be visible in Git Bash. Add to `~/.bashrc`:

```bash
export PATH="$HOME/AppData/Roaming/npm:$HOME/.local/bin:$PATH"
```
