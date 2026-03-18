# utils.ps1 — Shared helpers for bootstrap scripts

$script:_pass = 0
$script:_fail = 0
$script:_warn = 0

function Write-Step([string]$msg) {
    Write-Host "`n── $msg" -ForegroundColor Cyan
}

function Write-OK([string]$msg) {
    $script:_pass++
    Write-Host "  [+] $msg" -ForegroundColor Green
}

function Write-Fail([string]$msg) {
    $script:_fail++
    Write-Host "  [!] $msg" -ForegroundColor Red
}

function Write-Warn([string]$msg) {
    $script:_warn++
    Write-Host "  [~] $msg" -ForegroundColor Yellow
}

function Write-Info([string]$msg) {
    Write-Host "  [ ] $msg" -ForegroundColor Gray
}

function Assert-PowerShellVersion([int]$minMajor) {
    if ($PSVersionTable.PSVersion.Major -lt $minMajor) {
        throw "PowerShell $minMajor+ required. Current: $($PSVersionTable.PSVersion)"
    }
    Write-OK "PowerShell $($PSVersionTable.PSVersion)"
}

function Assert-Command([string]$name, [string]$hint = "") {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        $msg = "$name not found."
        if ($hint) { $msg += " $hint" }
        throw $msg
    }
}

function Assert-EnvFile {
    $envFile = Join-Path (Split-Path $PSScriptRoot -Parent) ".env.local"
    if (-not (Test-Path $envFile)) {
        Write-Warn ".env.local not found. Copy templates\.env.example to .env.local and fill in your secrets."
        Write-Warn "Some tools may not work without their API keys."
    } else {
        # Source env vars from .env.local (key=value format, skip comments)
        Get-Content $envFile | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "=" } | ForEach-Object {
            $k, $v = $_ -split "=", 2
            [System.Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim(), "Process")
        }
        Write-OK ".env.local loaded"
    }
}

function Invoke-Command {
    param(
        [scriptblock]$Cmd,
        [switch]$DryRun,
        [switch]$IgnoreError
    )
    if ($DryRun) {
        Write-Info "[DRY-RUN] $Cmd"
        return
    }
    try {
        & $Cmd
    } catch {
        if (-not $IgnoreError) { throw }
        Write-Warn "Non-fatal error: $_"
    }
}
