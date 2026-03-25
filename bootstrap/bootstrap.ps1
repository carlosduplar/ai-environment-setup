#!/usr/bin/env pwsh
# bootstrap.ps1 — Install the full AI coding environment on Windows 11 + PowerShell 7
# Usage: .\bootstrap\bootstrap.ps1 [-Update] [-DryRun] [-Verbose] [-GWS] [-Firebase]
# Must run from repo root.

param(
    [switch]$Update,    # Re-install / upgrade existing tools
    [switch]$DryRun,    # Print commands without executing
    [switch]$Verbose,   # Extra output
    [switch]$GWS,       # Install Google Workspace CLI + skills
    [switch]$Firebase   # Install Firebase CLI
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
# 1. Core CLIs via winget
# ─────────────────────────────────────────────
Write-Step "1/7 — Core CLIs (winget)"
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
# 2. Node.js global packages
# ─────────────────────────────────────────────
Write-Step "2/7 — npm global packages"
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

# ── Optional: Firebase ──────────────────────────────
if ($Firebase) {
    Write-Step "Optional — Firebase CLI"
    $installed = npm list -g --depth=0 2>$null | Select-String "firebase-tools"
    if ($installed -and -not $Update) {
        Write-OK "firebase-tools already installed"
    } else {
        Write-Info "Installing firebase-tools..."
        Invoke-Command -Cmd { npm install -g firebase-tools } -DryRun:$DryRun
    }
}

# ── Optional: Google Workspace ──────────────────────
if ($GWS) {
    Write-Step "Optional — Google Workspace CLI"
    $installed = npm list -g --depth=0 2>$null | Select-String "@googleworkspace/cli"
    if ($installed -and -not $Update) {
        Write-OK "@googleworkspace/cli already installed"
    } else {
        Write-Info "Installing @googleworkspace/cli..."
        Invoke-Command -Cmd { npm install -g "@googleworkspace/cli" } -DryRun:$DryRun
    }
}

# ─────────────────────────────────────────────
# 3. Install agent skills
# ─────────────────────────────────────────────
Write-Step "3/7 — Install agent skills"
function Install-LocalSkill {
    param([string]$Skill)

    $source = Join-Path $env:USERPROFILE ".agents\skills\$Skill"
    if (-not (Test-Path $source)) {
        Write-Warn "Local source for $Skill not found at $source; skipping."
        return
    }

    Write-Info "Installing $Skill from $source..."
    Invoke-Command -Cmd { npx skills add $source --skill $Skill } -DryRun:$DryRun
}

# Core skills (always installed)
$skills = @(
    "brand-guidelines",
    "canvas-design",
    "context7-cli",
    "doc-coauthoring",
    "docx",
    "find-docs",
    "find-skills",
    "frontend-design",
    "gh-cli",
    "mcp-builder",
    "pdf",
    "playwright-cli",
    "pptx",
    "seo-audit",
    "skill-creator",
    "vercel-react-best-practices",
    "vercel-react-native-skills",
    "web-artifacts-builder",
    "web-design-guidelines",
    "webapp-testing",
    "xlsx"
)

# GWS skills (only with -GWS)
$gwsSkills = @(
    "gws-calendar",
    "gws-docs",
    "gws-drive",
    "gws-gmail",
    "gws-keep",
    "gws-shared",
    "gws-sheets",
    "gws-tasks",
    "gws-workflow-email-to-task",
    "gws-workflow-meeting-prep",
    "gws-workflow-standup-report",
    "gws-workflow-weekly-digest"
)

if ($GWS) {
    $skills += $gwsSkills
}

foreach ($skill in $skills) {
    Install-LocalSkill $skill
}

# ─────────────────────────────────────────────
# 4. Python packages (pip)
# ─────────────────────────────────────────────
Write-Step "4/7 — Python packages"
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Warn "python not found. Skipping pip packages (markitdown will be unavailable)."
} else {
    $pipPackages = Get-Content (Join-Path $manifestsDir "pip-packages.txt")

    foreach ($pkg in $pipPackages) {
        $pkg = $pkg.Trim()
        if ($pkg -match "^#" -or [string]::IsNullOrWhiteSpace($pkg)) { continue }
        Write-Info "Ensuring $pkg..."
        Invoke-Command -Cmd { python -m pip install --user $pkg } -DryRun:$DryRun
    }
}

# ─────────────────────────────────────────────
# 5. Detect agents
# ─────────────────────────────────────────────
Write-Step "5/7 — Detect agents"

$agents = @{}
$agentList = @(
    @{ name = "claude";    cmd = "claude" },
    @{ name = "opencode";  cmd = "opencode" },
    @{ name = "gemini";    cmd = "gemini" },
    @{ name = "copilot";   cmd = "gh-copilot" }
)

foreach ($agent in $agentList) {
    if (Get-Command $agent.cmd -ErrorAction SilentlyContinue) {
        Write-OK "$($agent.name) found"
        $agents[$agent.name] = $true
    } else {
        Write-Warn "$($agent.name) not found — skipping its config/hooks"
        $agents[$agent.name] = $false
    }
}

# ─────────────────────────────────────────────
# 6. Config scaffolding (agent-gated)
# ─────────────────────────────────────────────
Write-Step "6/7 — Config scaffolding"

# Always copy shared config
$sharedConfigs = @()

# Agent-specific configs
if ($agents.claude) {
    $sharedConfigs += @(
        @{ src = "$configDir\claude-code\settings.json.example"; dst = "$env:USERPROFILE\.claude\settings.json" },
        @{ src = "$configDir\claude-code\CLAUDE.md";             dst = "$env:USERPROFILE\.claude\CLAUDE.md" },
        @{ src = "$hooksDir\claude-code-pre-tool-use.sh";        dst = "$env:USERPROFILE\.claude\hooks\pre-tool-use.sh" },
        @{ src = "$hooksDir\claude-code-pre-tool-use.ps1";       dst = "$env:USERPROFILE\.claude\hooks\pre-tool-use.ps1" },
        @{ src = "$hooksDir\post-tool-use.sh";                   dst = "$env:USERPROFILE\.claude\hooks\post-tool-use.sh" },
        @{ src = "$hooksDir\post-tool-use.ps1";                  dst = "$env:USERPROFILE\.claude\hooks\post-tool-use.ps1" },
        @{ src = "$hooksDir\notification.sh";                    dst = "$env:USERPROFILE\.claude\hooks\notification.sh" },
        @{ src = "$hooksDir\notification.ps1";                   dst = "$env:USERPROFILE\.claude\hooks\notification.ps1" },
        @{ src = "$hooksDir\post-compact.sh";                    dst = "$env:USERPROFILE\.claude\hooks\post-compact.sh" },
        @{ src = "$hooksDir\post-compact.ps1";                   dst = "$env:USERPROFILE\.claude\hooks\post-compact.ps1" }
    )
}

if ($agents.opencode) {
    $sharedConfigs += @(
        @{ src = "$configDir\opencode\opencode.json.example";    dst = "$env:USERPROFILE\.config\opencode\opencode.json" },
        @{ src = "$configDir\opencode\plugins\security.js";       dst = "$env:USERPROFILE\.config\opencode\plugins\security.js" }
    )
}

if ($agents.gemini) {
    $sharedConfigs += @(
        @{ src = "$configDir\gemini\GEMINI.md";                  dst = "$env:USERPROFILE\.gemini\GEMINI.md" },
        @{ src = "$configDir\gemini\mcp-server-enablement.json"; dst = "$env:USERPROFILE\.gemini\mcp-server-enablement.json" },
        @{ src = "$hooksDir\gemini-pre-tool-use.sh";             dst = "$env:USERPROFILE\.gemini\hooks\pre-tool-use.sh" },
        @{ src = "$hooksDir\gemini-pre-tool-use.ps1";            dst = "$env:USERPROFILE\.gemini\hooks\pre-tool-use.ps1" }
    )
}

if ($agents.copilot) {
    $sharedConfigs += @(
        @{ src = "$configDir\github-copilot\copilot-instructions.md"; dst = "$env:USERPROFILE\.copilot\copilot-instructions.md" },
        @{ src = "$configDir\github-copilot\AGENTS.md";              dst = "$env:USERPROFILE\.copilot\AGENTS.md" }
    )
}

foreach ($cfg in $sharedConfigs) {
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
# Done
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Agents configured: $(($agents.GetEnumerator() | Where-Object { $_.Value }).Name -join ', ')" -ForegroundColor Cyan
if (($agents.GetEnumerator() | Where-Object { -not $_.Value })) {
    Write-Host "Agents skipped:   $(($agents.GetEnumerator() | Where-Object { -not $_.Value }).Name -join ', ')" -ForegroundColor Yellow
}
Write-Host "Next: fill in .env.local with your API keys, then run .\bootstrap\verify.ps1"
