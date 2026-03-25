#!/usr/bin/env pwsh
# verify.ps1 — Assert the AI environment is correctly installed
# Usage: .\bootstrap\verify.ps1 [-Security] [-Fix]
# Exit code: 0 = all pass, 1 = failures found

param(
    [switch]$Security,  # Run secret-scanning checks in addition to tool checks
    [switch]$Fix        # Attempt to fix simple issues (re-copy missing configs)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

. "$PSScriptRoot\lib\utils.ps1"

$pass = 0
$fail = 0
$warn = 0
$root = Split-Path $PSScriptRoot -Parent

function Test-Tool {
    param([string]$Name, [string]$VersionArg = "--version", [string]$MinVersion = "")
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Fail "$Name — NOT FOUND"
        return
    }
    $ver = & $Name $VersionArg 2>&1 | Select-Object -First 1
    Write-OK "$Name — $ver"
}

function Test-File {
    param([string]$Path, [string]$Label = "")
    $label = if ($Label) { $Label } else { $Path }
    if (Test-Path $Path) {
        Write-OK "$label exists"
    } else {
        Write-Fail "$label — MISSING at $Path"
    }
}

function Test-EnvVar {
    param([string]$Name)
    $val = [System.Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($val)) {
        Write-Warn "$Name — not set"
    } else {
        Write-OK "$Name — set (${val.Length} chars)"
    }
}

# ─────────────────────────────────────────────
# 1. Core tools
# ─────────────────────────────────────────────
Write-Step "1/5 — Core tools"
Test-Tool "git"
Test-Tool "node"
Test-Tool "npm"
Test-Tool "pwsh"
Test-Tool "bash"
Test-Tool "jq"
Test-Tool "curl"
Test-Tool "gh"
Test-Tool "choco"

# ─────────────────────────────────────────────
# 2. AI tools
# ─────────────────────────────────────────────
Write-Step "2/5 — AI tools"
Test-Tool "claude"
Test-Tool "opencode"
Test-Tool "gemini"
Test-Tool "uv"
Test-Tool "python"

# ─────────────────────────────────────────────
# 3. Additional CLIs
# ─────────────────────────────────────────────
Write-Step "3/5 — Additional CLIs"
Test-Tool "playwright"
Test-Tool "ctx7"
Test-Tool "firebase"
Test-Tool "gcloud"
Test-Tool "gws"
Test-Tool "markitdown"

Test-Tool "npx"
Test-Tool "uvx"

# ─────────────────────────────────────────────
# 4. Config files
# ─────────────────────────────────────────────
Write-Step "4/5 — Config files"
Test-File "$env:USERPROFILE\.claude\settings.json"          "Claude Code settings"
Test-File "$env:USERPROFILE\.claude\CLAUDE.md"              "Claude Code system prompt"
Test-File "$env:USERPROFILE\.config\opencode\opencode.json" "OpenCode config"
Test-File "$env:USERPROFILE\.gemini\GEMINI.md"              "Gemini system prompt"
Test-File "$env:USERPROFILE\.gemini\mcp-server-enablement.json" "Gemini MCP enablement"
Test-File "$env:USERPROFILE\.gitconfig"                     "Git global config"

# ─────────────────────────────────────────────
# 4b. Hooks
# ─────────────────────────────────────────────
Write-Step "4b/5 — Hooks & Plugins"
Test-File "$env:USERPROFILE\.claude\hooks\pre-tool-use.sh"                  "Claude Code hook (sh)"
Test-File "$env:USERPROFILE\.claude\hooks\pre-tool-use.ps1"                 "Claude Code hook (ps1)"
Test-File "$env:USERPROFILE\.claude\hooks\post-tool-use.sh"                 "Claude Code post-tool-use hook (sh)"
Test-File "$env:USERPROFILE\.claude\hooks\post-tool-use.ps1"                "Claude Code post-tool-use hook (ps1)"
Test-File "$env:USERPROFILE\.claude\hooks\notification.sh"                  "Claude Code notification hook (sh)"
Test-File "$env:USERPROFILE\.claude\hooks\notification.ps1"                 "Claude Code notification hook (ps1)"
Test-File "$env:USERPROFILE\.claude\hooks\post-compact.sh"                  "Claude Code post-compact hook (sh)"
Test-File "$env:USERPROFILE\.claude\hooks\post-compact.ps1"                 "Claude Code post-compact hook (ps1)"
Test-File "$env:USERPROFILE\.config\opencode\plugins\security.js"           "OpenCode security plugin"
Test-File "$env:USERPROFILE\.gemini\hooks\pre-tool-use.sh"                  "Gemini hook (sh)"
Test-File "$env:USERPROFILE\.gemini\hooks\pre-tool-use.ps1"                 "Gemini hook (ps1)"
Test-File "$root\.github\hooks\hooks.json"                                  "Copilot repo hook config"

# ─────────────────────────────────────────────
# 5. Environment variables
# ─────────────────────────────────────────────
Write-Step "5/5 — Environment variables"
$requiredEnvVars = @(
    "ANTHROPIC_AUTH_TOKEN",
    "BRIGHTDATA_API_KEY",
    "GITHUB_TOKEN"
)
$optionalEnvVars = @(
    "NVIDIA_API_KEY",
    "OPENROUTER_API_KEY",
    "MISTRAL_API_KEY",
    "GOOGLE_CLOUD_PROJECT",
    "FIREBASE_TOKEN"
)
foreach ($v in $requiredEnvVars) { Test-EnvVar $v }
foreach ($v in $optionalEnvVars) {
    $val = [System.Environment]::GetEnvironmentVariable($v)
    if ([string]::IsNullOrWhiteSpace($val)) {
        Write-Info "$v — not set (optional)"
    } else {
        Write-OK "$v — set"
    }
}

# ─────────────────────────────────────────────
# Security scan (optional)
# ─────────────────────────────────────────────
if ($Security) {
    Write-Step "Security — scanning for accidental secrets"
    $patterns = @(
        'sk-[a-zA-Z0-9]{32,}',          # Anthropic keys
        'nvapi-[a-zA-Z0-9_-]{40,}',     # NVIDIA keys
        'AIza[a-zA-Z0-9_-]{35}',        # Google API keys
        '"password"\s*:\s*"[^"]+"',     # Passwords in JSON
        'token\s*=\s*[a-zA-Z0-9_-]{20,}' # Generic tokens
    )
    foreach ($pattern in $patterns) {
        $hits = Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -notmatch '\.(png|jpg|gif|ico|zip|lock)$' } |
            Select-String -Pattern $pattern -ErrorAction SilentlyContinue
        if ($hits) {
            foreach ($hit in $hits) {
                Write-Fail "SECRET DETECTED: $($hit.Filename):$($hit.LineNumber) matches '$pattern'"
            }
        }
    }
    Write-OK "Security scan complete"
}

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Results: $pass passed, $warn warnings, $fail failed" -ForegroundColor $(if ($fail -gt 0) { "Red" } elseif ($warn -gt 0) { "Yellow" } else { "Green" })
exit $(if ($fail -gt 0) { 1 } else { 0 })
