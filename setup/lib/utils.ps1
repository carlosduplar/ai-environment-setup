# utils.ps1 — Shared helpers for setup scripts

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

function Test-NodeJsAvailable {
    # Check if Node.js and npm are actually functional
    try {
        $nodeVer = & node --version 2>$null
        $npmVer = & npm --version 2>$null
        if ($nodeVer -and $npmVer) {
            return @{ Success = $true; NodeVersion = $nodeVer; NpmVersion = $npmVer }
        }
    } catch {
        # Fall through to failure
    }
    return @{ Success = $false }
}

function Assert-EnvFile {
    $root = Split-Path $PSScriptRoot -Parent
    $envFile = Join-Path $root ".env.local"
    
    if (-not (Test-Path $envFile)) {
        # Only show message if BRIGHTDATA_API_KEY or other required keys are not set
        $needsKeys = $false
        if (-not [System.Environment]::GetEnvironmentVariable("BRIGHTDATA_API_KEY")) { $needsKeys = $true }
        if (-not [System.Environment]::GetEnvironmentVariable("NVIDIA_API_KEY")) { $needsKeys = $true }
        if (-not [System.Environment]::GetEnvironmentVariable("OPENROUTER_API_KEY")) { $needsKeys = $true }
        
        if ($needsKeys) {
            Write-Warn ".env.local not found. Create it from templates\.env.example if you need API keys for optional tools."
        }
    } else {
        # Source env vars from .env.local (key=value format, skip comments)
        Get-Content $envFile | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "=" } | ForEach-Object {
            $k, $v = $_ -split "=", 2
            [System.Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim(), "Process")
        }
        Write-OK ".env.local loaded"
    }
}

function Assert-WinGetAvailable {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        throw "winget not found. Please install winget or App Installer from Microsoft Store."
    }
    
    # Test if winget can run without admin (it will fail on some restricted systems)
    try {
        $testOutput = winget --version 2>&1
        if ($LASTEXITCODE -ne 0 -and $testOutput -match "admin") {
            Write-Warn "winget may require administrator privileges for some operations."
        }
    } catch {
        throw "winget is not functional. Error: $_"
    }
    
    Write-OK "winget available"
}

function Invoke-Command {
    param(
        [scriptblock]$Cmd,
        [switch]$DryRun,
        [switch]$IgnoreError,
        [string]$Activity = "Running command"
    )
    if ($DryRun) {
        Write-Info "[DRY-RUN] $Cmd"
        return
    }
    
    try {
        & $Cmd
        # Check $LASTEXITCODE for native commands (npm, git, etc.)
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
    } catch {
        if (-not $IgnoreError) { throw }
        Write-Warn "Non-fatal error: $_"
    }
}

function Invoke-CommandWithProgress {
    param(
        [scriptblock]$Cmd,
        [string]$Activity,
        [int]$TotalItems = 1,
        [int]$CurrentItem = 1,
        [switch]$DryRun,
        [switch]$IgnoreError
    )
    
    if ($DryRun) {
        Write-Info "[DRY-RUN] $Activity"
        return
    }
    
    $percent = [math]::Round(($CurrentItem / $TotalItems) * 100)
    Write-Progress -Activity $Activity -Status "$CurrentItem of $TotalItems" -PercentComplete $percent
    
    try {
        & $Cmd
        # Check $LASTEXITCODE for native commands (npm, git, etc.)
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
    } catch {
        if (-not $IgnoreError) { 
            Write-Progress -Activity $Activity -Completed
            throw 
        }
        Write-Warn "Non-fatal error: $_"
    } finally {
        Write-Progress -Activity $Activity -Completed
    }
}

function Backup-And-CopyFile {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$DryRun
    )
    
    if (-not $DryRun) {
        $dstDir = Split-Path $Destination
        if (-not (Test-Path $dstDir)) { 
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null 
        }
        
        if (Test-Path $Destination) {
            $backup = "$Destination.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $Destination $backup -Force
        }
        
        Copy-Item $Source $Destination -Force
    }
}
