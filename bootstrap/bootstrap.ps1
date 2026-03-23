#!/usr/bin/env pwsh
# bootstrap.ps1 — Install the full AI coding environment on Windows 11 + PowerShell 7
# Usage: .\bootstrap\bootstrap.ps1 [-Update] [-DryRun] [-Verbose]
# Must run from repo root.

param(
    [switch]$Update,    # Re-install / upgrade existing tools
    [switch]$DryRun,    # Print commands without executing
    [switch]$Verbose    # Extra output
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\lib\utils.ps1"

# ─────────────────────────────────────────────
# 0. Pre-flight
# ─────────────────────────────────────────────
Assert-PowerShellVersion 7
Assert-EnvFile

$root = Split-Path $PSScriptRoot -Parent
$manifestsDir = Join-Path $root "manifests"
$configDir    = Join-Path $root "config"
$hooksDir     = Join-Path $root "hooks"

if (-not $DryRun) { . (Join-Path $root "templates\.env.example") }

Write-Step "Starting AI environment bootstrap (Windows 11)"

# ─────────────────────────────────────────────
# 1. Package Managers
# ─────────────────────────────────────────────
Write-Step "1/9 — Package managers"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Chocolatey..."
    Invoke-Command -Cmd {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } -DryRun:$DryRun
} else { Write-OK "choco already installed" }

# ─────────────────────────────────────────────
# 2. Core CLIs via winget
# ─────────────────────────────────────────────
Write-Step "2/9 — Core CLIs (winget)"
$wingetData = Get-Content (Join-Path $manifestsDir "winget.json") | ConvertFrom-Json
$wingetPackages = $wingetData.Sources[0].Packages

foreach ($pkg in $wingetPackages) {
    $id = $pkg.PackageIdentifier
    $installed = winget list --id $id --exact --accept-source-agreements 2>&1 | Select-String $id
    if ($installed -and -not $Update) {
        Write-OK "$id already installed"
    } else {
        Write-Info "Installing $id..."
        Invoke-Command -Cmd { winget install --id $id --exact --accept-package-agreements --accept-source-agreements --silent } -DryRun:$DryRun
    }
}

# ─────────────────────────────────────────────
# 3. Chocolatey packages
# ─────────────────────────────────────────────
Write-Step "3/9 — Chocolatey packages"
$chocoPackages = Get-Content (Join-Path $manifestsDir "choco.json") | ConvertFrom-Json

foreach ($pkg in $chocoPackages.packages) {
    $installed = choco list --local-only --exact $pkg.name 2>&1 | Select-String $pkg.name
    if ($installed -and -not $Update) {
        Write-OK "$($pkg.name) already installed"
    } else {
        Write-Info "Installing $($pkg.name)..."
        Invoke-Command -Cmd { choco install $pkg.name -y } -DryRun:$DryRun
    }
}

# ─────────────────────────────────────────────
# 3.5. Verify jq
# ─────────────────────────────────────────────
Write-Step "3.5/9 — Verify jq"
if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    Write-Info "jq not found, installing via Chocolatey..."
    Invoke-Command -Cmd { choco install jq -y } -DryRun:$DryRun
} else {
    Write-OK "jq already installed"
}

# ─────────────────────────────────────────────
# 4. Node.js global packages
# ─────────────────────────────────────────────
Write-Step "5/9 — npm global packages"
Assert-Command "npm" "Node.js / npm is required. Install via winget: winget install OpenJS.NodeJS"

$npmPackages = Get-Content (Join-Path $manifestsDir "npm-global.json") | ConvertFrom-Json

foreach ($pkg in $npmPackages.packages) {
    $installed = npm list -g --depth=0 2>$null | Select-String $pkg.name
    if ($installed -and -not $Update) {
        Write-OK "$($pkg.name) already installed"
    } else {
        Write-Info "Installing $($pkg.name)@$($pkg.version)..."
        Invoke-Command -Cmd { npm install -g "$($pkg.name)@$($pkg.version)" } -DryRun:$DryRun
    }
}

# ─────────────────────────────────────────────
# 5. Python tools via uv
# ─────────────────────────────────────────────
Write-Step "6/9 — Python tools (uv)"
Assert-Command "uv" "uv is required. Install: winget install astral-sh.uv"

$pipPackages = Get-Content (Join-Path $manifestsDir "pip-packages.txt")

foreach ($pkg in $pipPackages) {
    $pkg = $pkg.Trim()
    if ($pkg -match "^#" -or [string]::IsNullOrWhiteSpace($pkg)) { continue }
    Write-Info "Ensuring $pkg..."
    Invoke-Command -Cmd { uv tool install $pkg } -DryRun:$DryRun
}

# ─────────────────────────────────────────────
# 6. Claude Code
# ─────────────────────────────────────────────
Write-Step "7/9 — Claude Code"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Claude Code..."
    # Try WinGet first (recommended for Windows)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing via winget..."
        Invoke-Command -Cmd { winget install Anthropic.ClaudeCode --exact --accept-package-agreements --accept-source-agreements --silent } -DryRun:$DryRun
    } else {
        # Fallback to native PowerShell installer
        Write-Info "Winget not found, using native PowerShell installer..."
        Invoke-Command -Cmd {
            irm https://claude.ai/install.ps1 | iex
        } -DryRun:$DryRun
    }
    # Verify installation
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-OK "Claude Code installed successfully"
    } else {
        Write-Warn "Claude Code installation may have failed. Install manually from https://code.claude.com/docs/en/setup"
    }
} else { Write-OK "claude already installed" }

# ─────────────────────────────────────────────
# 7. Apply config scaffolding
# ─────────────────────────────────────────────
Write-Step "8/9 — Config scaffolding"

$configs = @(
    @{ src = "$configDir\claude-code\settings.json.example"; dst = "$env:USERPROFILE\.claude\settings.json" },
    @{ src = "$configDir\claude-code\CLAUDE.md";             dst = "$env:USERPROFILE\.claude\CLAUDE.md" },
    @{ src = "$configDir\opencode\opencode.json.example";    dst = "$env:USERPROFILE\.config\opencode\opencode.json" },
    @{ src = "$configDir\gemini\GEMINI.md";                  dst = "$env:USERPROFILE\.gemini\GEMINI.md" },
    @{ src = "$configDir\gemini\mcp-server-enablement.json"; dst = "$env:USERPROFILE\.gemini\mcp-server-enablement.json" },
    @{ src = "$hooksDir\claude-code-pre-tool-use.sh";        dst = "$env:USERPROFILE\.claude\hooks\pre-tool-use.sh" },
    @{ src = "$hooksDir\claude-code-pre-tool-use.ps1";       dst = "$env:USERPROFILE\.claude\hooks\pre-tool-use.ps1" },
    @{ src = "$hooksDir\opencode-pre-tool-use.sh";           dst = "$env:USERPROFILE\.config\opencode\hooks\pre-tool-use.sh" },
    @{ src = "$hooksDir\opencode-pre-tool-use.ps1";          dst = "$env:USERPROFILE\.config\opencode\hooks\pre-tool-use.ps1" },
    @{ src = "$hooksDir\gemini-pre-tool-use.sh";             dst = "$env:USERPROFILE\.gemini\hooks\pre-tool-use.sh" },
    @{ src = "$hooksDir\gemini-pre-tool-use.ps1";            dst = "$env:USERPROFILE\.gemini\hooks\pre-tool-use.ps1" }
)

foreach ($cfg in $configs) {
    if (Test-Path $cfg.dst) {
        Write-OK "$($cfg.dst) already exists — skipping (use -Update to overwrite)"
        if ($Update) {
            Write-Info "Backing up and overwriting $($cfg.dst)..."
            if (-not $DryRun) {
                $backup = "$($cfg.dst).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $cfg.dst $backup
                Copy-Item $cfg.src $cfg.dst
            }
        }
    } else {
        Write-Info "Copying $($cfg.src) -> $($cfg.dst)"
        if (-not $DryRun) {
            $dstDir = Split-Path $cfg.dst
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            Copy-Item $cfg.src $cfg.dst
        }
    }
}

# ─────────────────────────────────────────────
# 8. GitHub Copilot CLI
# ─────────────────────────────────────────────
Write-Step "9/9 — GitHub Copilot CLI"
# Install via winget (recommended) or npm
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Info "GitHub CLI (gh) not found, installing via winget..."
    Invoke-Command -Cmd { winget install GitHub.cli --exact --accept-package-agreements --accept-source-agreements --silent } -DryRun:$DryRun
}
# Install Copilot CLI via winget
if (-not (Get-Command "gh-copilot" -ErrorAction SilentlyContinue)) {
    Write-Info "Installing GitHub Copilot CLI via winget..."
    Invoke-Command -Cmd { winget install GitHub.Copilot --exact --accept-package-agreements --accept-source-agreements --silent } -DryRun:$DryRun
} else {
    Write-OK "GitHub Copilot CLI already installed"
}

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Next: fill in .env.local with your API keys, then run .\bootstrap\verify.ps1"
