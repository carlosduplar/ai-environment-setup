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

function Test-OptionalTool {
    param([string]$Name, [string]$VersionArg = "--version")
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Warn "$Name — not found (optional)"
        return $false
    }
    $ver = & $Name $VersionArg 2>&1 | Select-Object -First 1
    Write-OK "$Name — $ver"
    return $true
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

# ─────────────────────────────────────────────
# 2. AI agents (optional)
# ─────────────────────────────────────────────
Write-Step "2/5 — AI agents"
$hasClaude   = Test-OptionalTool "claude"
$hasOpenCode = Test-OptionalTool "opencode"
$hasGemini   = Test-OptionalTool "gemini"
$hasCopilot  = Test-OptionalTool "gh-copilot"

# ─────────────────────────────────────────────
# 3. Optional tools
# ─────────────────────────────────────────────
Write-Step "3/5 — Optional tools"
Test-OptionalTool "python"      | Out-Null
Test-OptionalTool "ctx7"        | Out-Null
Test-OptionalTool "playwright"  | Out-Null
Test-OptionalTool "npx"         | Out-Null
Test-OptionalTool "gcloud"      | Out-Null
Test-OptionalTool "firebase"    | Out-Null
Test-OptionalTool "gws"         | Out-Null
Test-OptionalTool "markitdown"  | Out-Null

# ─────────────────────────────────────────────
# 4. Config files (agent-gated)
# ─────────────────────────────────────────────
Write-Step "4/5 — Config & hooks"

if ($hasClaude) {
    Test-File "$env:USERPROFILE\.claude\settings.json" "Claude Code settings"
    Test-File "$env:USERPROFILE\.claude\CLAUDE.md"     "Claude Code system prompt"
    Test-File "$env:USERPROFILE\.claude\hooks\pre-tool-use.sh"   "Claude Code hook (sh)"
    Test-File "$env:USERPROFILE\.claude\hooks\pre-tool-use.ps1"  "Claude Code hook (ps1)"
    Test-File "$env:USERPROFILE\.claude\hooks\post-tool-use.sh"  "Claude post-tool-use hook (sh)"
    Test-File "$env:USERPROFILE\.claude\hooks\post-tool-use.ps1" "Claude post-tool-use hook (ps1)"
    Test-File "$env:USERPROFILE\.claude\hooks\notification.sh"   "Claude notification hook (sh)"
    Test-File "$env:USERPROFILE\.claude\hooks\notification.ps1"  "Claude notification hook (ps1)"
    Test-File "$env:USERPROFILE\.claude\hooks\post-compact.sh"   "Claude post-compact hook (sh)"
    Test-File "$env:USERPROFILE\.claude\hooks\post-compact.ps1"  "Claude post-compact hook (ps1)"
} else {
    Write-Info "Claude not installed — skipping its config/hook checks"
}

if ($hasOpenCode) {
    Test-File "$env:USERPROFILE\.config\opencode\opencode.json"     "OpenCode config"
    Test-File "$env:USERPROFILE\.config\opencode\plugins\security.js" "OpenCode security plugin"
    Test-File "$env:USERPROFILE\.config\opencode\plugins\format-on-write.js" "OpenCode format-on-write plugin"
    Test-File "$env:USERPROFILE\.config\opencode\plugins\notifications.js" "OpenCode notifications plugin"
    Test-File "$env:USERPROFILE\.config\opencode\plugins\context-refresh.js" "OpenCode context-refresh plugin"
    Test-File "$env:USERPROFILE\.config\opencode\plugins\session-lifecycle.js" "OpenCode session-lifecycle plugin"
} else {
    Write-Info "OpenCode not installed — skipping its config checks"
}

if ($hasGemini) {
    Test-File "$env:USERPROFILE\.gemini\GEMINI.md"                    "Gemini system prompt"
    Test-File "$env:USERPROFILE\.gemini\mcp-server-enablement.json"  "Gemini MCP enablement"
    Test-File "$env:USERPROFILE\.gemini\hooks\pre-tool-use.sh"       "Gemini hook (sh)"
    Test-File "$env:USERPROFILE\.gemini\hooks\pre-tool-use.ps1"      "Gemini hook (ps1)"
} else {
    Write-Info "Gemini not installed — skipping its config/hook checks"
}

if ($hasCopilot) {
    Test-File "$env:USERPROFILE\.copilot\copilot-instructions.md" "Copilot instructions"
    Test-File "$env:USERPROFILE\.copilot\AGENTS.md"               "Copilot AGENTS config"
} else {
    Write-Info "Copilot not installed — skipping its config checks"
}

# Always check repo-level Copilot hook config
Test-File "$root\.github\hooks\hooks.json" "Copilot repo hook config"

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
    "MISTRAL_API_KEY"
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
Write-Host "Results: $script:_pass passed, $script:_warn warnings, $script:_fail failed" -ForegroundColor $(if ($script:_fail -gt 0) { "Red" } elseif ($script:_warn -gt 0) { "Yellow" } else { "Green" })
exit $(if ($script:_fail -gt 0) { 1 } else { 0 })
