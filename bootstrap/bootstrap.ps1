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

if (-not $DryRun) { . (Join-Path $root "templates\.env.example") }

Write-Step "Starting AI environment bootstrap (Windows 11)"

# ─────────────────────────────────────────────
# 1. Package Managers
# ─────────────────────────────────────────────
Write-Step "1/8 — Package managers"

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
Write-Step "2/8 — Core CLIs (winget)"
$wingetPackages = Get-Content (Join-Path $manifestsDir "winget.json") | ConvertFrom-Json

foreach ($pkg in $wingetPackages.packages) {
    $installed = winget list --id $pkg.id --exact --accept-source-agreements 2>&1 | Select-String $pkg.id
    if ($installed -and -not $Update) {
        Write-OK "$($pkg.id) already installed"
    } else {
        Write-Info "Installing $($pkg.id)..."
        Invoke-Command -Cmd { winget install --id $pkg.id --exact --accept-package-agreements --accept-source-agreements --silent } -DryRun:$DryRun
    }
}

# ─────────────────────────────────────────────
# 3. Chocolatey packages
# ─────────────────────────────────────────────
Write-Step "3/8 — Chocolatey packages"
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
# 4. Node.js global packages
# ─────────────────────────────────────────────
Write-Step "4/8 — npm global packages"
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
Write-Step "5/8 — Python tools (uv)"
Assert-Command "uv" "uv is required. Install: winget install astral-sh.uv"

$pipPackages = Get-Content (Join-Path $manifestsDir "pip-packages.txt")

foreach ($pkg in $pipPackages) {
    $pkg = $pkg.Trim()
    if ($pkg -match "^#" -or [string]::IsNullOrWhiteSpace($pkg)) { continue }
    Write-Info "Ensuring $pkg..."
    Invoke-Command -Cmd { uv tool install $pkg } -DryRun:$DryRun
}

# ─────────────────────────────────────────────
# 6. Claude Code (direct binary)
# ─────────────────────────────────────────────
Write-Step "6/8 — Claude Code"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Claude Code..."
    # TODO: Replace with official install command when stable Windows installer is available
    # https://docs.anthropic.com/claude-code
    Write-Warn "Claude Code: install manually from https://docs.anthropic.com/claude-code"
    Write-Warn "Then re-run this script."
} else { Write-OK "claude already installed" }

# ─────────────────────────────────────────────
# 7. Apply config scaffolding
# ─────────────────────────────────────────────
Write-Step "7/8 — Config scaffolding"

$configs = @(
    @{ src = "$configDir\claude-code\settings.json.example"; dst = "$env:USERPROFILE\.claude\settings.json" },
    @{ src = "$configDir\claude-code\CLAUDE.md";             dst = "$env:USERPROFILE\.claude\CLAUDE.md" },
    @{ src = "$configDir\opencode\opencode.json.example";    dst = "$env:USERPROFILE\.config\opencode\opencode.json" },
    @{ src = "$configDir\gemini\GEMINI.md";                  dst = "$env:USERPROFILE\.gemini\GEMINI.md" },
    @{ src = "$configDir\gemini\mcp-server-enablement.json"; dst = "$env:USERPROFILE\.gemini\mcp-server-enablement.json" }
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
# 8. gh extensions
# ─────────────────────────────────────────────
Write-Step "8/8 — gh extensions"
Assert-Command "gh" "GitHub CLI (gh) is required. winget install GitHub.cli"
Invoke-Command -Cmd { gh extension install github/gh-copilot } -DryRun:$DryRun -IgnoreError

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Next: fill in .env.local with your API keys, then run .\bootstrap\verify.ps1"
