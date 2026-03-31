#!/usr/bin/env pwsh
# setup.ps1 — Install the full AI coding environment on Windows 11 + PowerShell 7
# Usage: .\setup\setup.ps1 [-Update] [-DryRun] [-Verbose] [-GWS] [-Firebase] [-SkipVerify]
# Must run from repo root.
# Precondition: Agentic coder CLIs (claude, opencode, gemini, copilot) must be pre-installed

param(
    [switch]$Update,      # Re-install / upgrade existing tools
    [switch]$DryRun,      # Print commands without executing
    [switch]$Verbose,     # Extra output
    [switch]$GWS,         # Install Google Workspace CLI + skills
    [switch]$Firebase,    # Install Firebase CLI
    [switch]$SkipVerify   # Skip automatic verification at the end
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\lib\utils.ps1"

# ─────────────────────────────────────────────
# 0. Pre-flight checks
# ─────────────────────────────────────────────
Write-Step "0/8 — Pre-flight checks"

Assert-PowerShellVersion 7
Assert-WinGetAvailable

$root = Split-Path $PSScriptRoot -Parent
$manifestsDir = Join-Path $root "manifests"
$configDir    = Join-Path $root "config"
$hooksDir     = Join-Path $root "hooks"

Write-Step "Starting AI environment setup (Windows 11)"

# ─────────────────────────────────────────────
# 1. Core CLIs via winget
# ─────────────────────────────────────────────
Write-Step "1/8 — Core CLIs (winget)"

# Check Node.js availability before trying winget install
$nodeCheck = Test-NodeJsAvailable
if ($nodeCheck.Success) {
    Write-OK "Node.js $($nodeCheck.NodeVersion) / npm $($nodeCheck.NpmVersion) already available"
    $skipNodeInstall = $true
} else {
    Write-Info "Node.js/npm not detected, will install via winget"
    $skipNodeInstall = $false
}

$wingetData = Get-Content (Join-Path $manifestsDir "winget.json") | ConvertFrom-Json
$wingetPackages = $wingetData.Sources[0].Packages
$totalWinget = $wingetPackages.Count
$currentWinget = 0

# Check which CLI tools are already available outside of winget
$gitAvailable = Get-Command git -ErrorAction SilentlyContinue
$jqAvailable = Get-Command jq -ErrorAction SilentlyContinue

foreach ($pkg in $wingetPackages) {
    $currentWinget++
    $id = $pkg.PackageIdentifier
    
    # Skip Node.js if already available from another source
    if ($id -eq "OpenJS.NodeJS.LTS" -and $skipNodeInstall -and -not $Update) {
        Write-OK "$id already available (via alternative install)"
        continue
    }
    
    # Skip git if already available (installed via Git for Windows, scoop, etc.)
    if ($id -eq "Git.Git" -and $gitAvailable -and -not $Update) {
        Write-OK "$id already available (via alternative install)"
        continue
    }
    
    # Skip jq if already available
    if ($id -eq "jqlang.jq" -and $jqAvailable -and -not $Update) {
        Write-OK "$id already available (via alternative install)"
        continue
    }
    
    $installed = winget list --id $id --exact --accept-source-agreements 2>&1 | Select-String $id
    if ($installed -and -not $Update) {
        Write-OK "$id already installed"
    } else {
        Write-Info "Installing $id..."
        Invoke-CommandWithProgress -Activity "Installing $id" -TotalItems $totalWinget -CurrentItem $currentWinget -DryRun:$DryRun -Cmd {
            winget install --id $id --exact --accept-package-agreements --accept-source-agreements --silent
        }
    }
}

# ─────────────────────────────────────────────
# 2. Node.js global packages
# ─────────────────────────────────────────────
Write-Step "2/8 — npm global packages"

# Verify npm is actually available
if (-not (Test-NodeJsAvailable).Success) {
    throw "Node.js / npm is required but not available even after winget install. Please install manually."
}

$npmPackages = Get-Content (Join-Path $manifestsDir "npm-global.json") | ConvertFrom-Json
$totalNpm = $npmPackages.packages.Count
$currentNpm = 0

foreach ($pkg in $npmPackages.packages) {
    $currentNpm++
    $installed = npm list -g --depth=0 2>$null | Select-String $pkg.name
    if ($installed -and -not $Update) {
        Write-OK "$($pkg.name) already installed"
    } else {
        Write-Info "Installing $($pkg.name)@$($pkg.version)..."
        Invoke-CommandWithProgress -Activity "Installing $($pkg.name)" -TotalItems $totalNpm -CurrentItem $currentNpm -DryRun:$DryRun -Cmd {
            npm install -g "$($pkg.name)@$($pkg.version)"
        }
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
# 3. Install agent skills (parallel by repo)
# ─────────────────────────────────────────────
Write-Step "3/8 — Install agent skills"

function Get-InstalledSkillMap {
    $map = @{}
    if ($DryRun) {
        Write-Info "[DRY-RUN] npx skills ls --json"
        return @{ Success = $false; Map = $map }
    }

    try {
        $raw = npx skills ls --json 2>$null
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            $parsed = $raw | ConvertFrom-Json
            $entries = @()
            if ($parsed -is [System.Array]) {
                $entries = $parsed
            } elseif ($null -ne $parsed) {
                $entries = @($parsed)
            }

            foreach ($entry in $entries) {
                $name = $null
                if ($entry -is [string]) {
                    $name = $entry
                } elseif ($entry.PSObject.Properties["name"]) {
                    $name = [string]$entry.name
                } elseif ($entry.PSObject.Properties["id"]) {
                    $name = [string]$entry.id
                } elseif ($entry.PSObject.Properties["skill"]) {
                    $name = [string]$entry.skill
                }

                if (-not [string]::IsNullOrWhiteSpace($name)) {
                    $map[$name] = $true
                }
            }
        }
        return @{ Success = $true; Map = $map }
    } catch {
        Write-Warn "Unable to list installed skills via 'npx skills ls --json'; continuing without validation."
        return @{ Success = $false; Map = $map }
    }
}

# Core skills grouped by repository (always installed)
$skillGroups = [ordered]@{
    "anthropics/skills" = @(
        "docx",
        "pdf",
        "pptx", 
        "xlsx",
        "webapp-testing",
        "frontend-design",
        "skill-creator"
    )
    "vercel-labs/agent-skills" = @(
        "vercel-react-best-practices",
        "vercel-react-native-skills",
        "web-design-guidelines"
    )
    "vercel-labs/skills" = @(
        "find-skills"
    )
    "coreyhaines31/marketingskills" = @(
        "seo-audit"
    )
    "microsoft/playwright-cli" = @(
        "playwright-cli"
    )
    "upstash/context7" = @(
        "context7-cli",
        "find-docs"
    )
}

# Bright Data skills (only if CLI and API key present)
$brightDataSkillGroup = [ordered]@{
    "brightdata/skills" = @(
        "brightdata-cli",
        "search",
        "scrape"
    )
}

# GWS skills (only with -GWS)
$gwsSkillGroup = [ordered]@{
    "googleworkspace/cli" = @(
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
}

$installedSkillState = Get-InstalledSkillMap
$canValidateInstalledSkills = [bool]$installedSkillState.Success
$installedSkillMap = $installedSkillState.Map

if ($canValidateInstalledSkills -and $installedSkillMap.Count -gt 0) {
    Write-Info "Installed skills detected; running 'npx skills update -g -y' before adding new skills."
    Invoke-Command -Cmd { npx skills update -g -y } -DryRun:$DryRun -IgnoreError
}

# Install skills in parallel by repository
Write-Info "Installing skills from $($skillGroups.Count) repositories in parallel..."
$skillGroups.GetEnumerator() | ForEach-Object -Parallel {
    $repo = $_.Key
    $skills = $_.Value
    $DryRun = $using:DryRun
    $installedSkillMap = $using:installedSkillMap
    $canValidateInstalledSkills = $using:canValidateInstalledSkills
    
    # Inline installation logic
    $skillsToInstall = @()
    foreach ($skill in $skills) {
        if ($canValidateInstalledSkills -and $installedSkillMap.ContainsKey($skill)) {
            [Console]::WriteLine("  [+] $skill already installed")
        } else {
            $skillsToInstall += $skill
        }
    }

    if ($skillsToInstall.Count -gt 0) {
        [Console]::WriteLine("  [ ] Installing skills from ${repo}: $($skillsToInstall -join ', ')")
        
        if (-not $DryRun) {
            try {
                $output = npx skills add $repo --skill @skillsToInstall -g -y 2>&1
                if ($LASTEXITCODE -eq 0) {
                    foreach ($skill in $skillsToInstall) {
                        [Console]::WriteLine("  [+] $skill installed")
                    }
                } else {
                    [Console]::WriteLine("  [!] Failed to install skills from ${repo}: $output")
                }
            } catch {
                [Console]::WriteLine("  [!] Error installing skills from ${repo}: $_")
            }
        } else {
            [Console]::WriteLine("  [ ] [DRY-RUN] npx skills add $repo --skill @skillsToInstall -g -y")
        }
    }
} -ThrottleLimit 3

# Install GWS skills if -GWS flag is set (also parallel)
if ($GWS) {
    Write-Info "Installing GWS skills from $($gwsSkillGroup.Count) repositories in parallel..."
    $gwsSkillGroup.GetEnumerator() | ForEach-Object -Parallel {
        $repo = $_.Key
        $skills = $_.Value
        $DryRun = $using:DryRun
        
        # Inline installation logic
        $skillsToInstall = @()
        foreach ($skill in $skills) {
            $skillsToInstall += $skill
        }

        if ($skillsToInstall.Count -gt 0) {
            [Console]::WriteLine("  [ ] Installing skills from ${repo}: $($skillsToInstall -join ', ')")
            
            if (-not $DryRun) {
                try {
                    $output = npx skills add $repo --skill @skillsToInstall -g -y 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        foreach ($skill in $skillsToInstall) {
                            [Console]::WriteLine("  [+] $skill installed")
                        }
                    } else {
                        [Console]::WriteLine("  [!] Failed to install skills from ${repo}: $output")
                    }
                } catch {
                    [Console]::WriteLine("  [!] Error installing skills from ${repo}: $_")
                }
            } else {
                [Console]::WriteLine("  [ ] [DRY-RUN] npx skills add $repo --skill @skillsToInstall -g -y")
            }
        }
    } -ThrottleLimit 3
}

# ─────────────────────────────────────────────
# 4. Python packages (pip)
# ─────────────────────────────────────────────
Write-Step "4/8 — Python packages"
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Warn "python not found. Skipping pip packages (markitdown will be unavailable)."
} else {
    $pipPackages = Get-Content (Join-Path $manifestsDir "pip-packages.txt")
    $filteredPipPackages = @($pipPackages | Where-Object { $_ -notmatch "^#" -and -not [string]::IsNullOrWhiteSpace($_) })
    $totalPip = $filteredPipPackages.Count
    $currentPip = 0

    foreach ($pkg in $filteredPipPackages) {
        $pkg = $pkg.Trim()
        $currentPip++
        Write-Info "Ensuring $pkg..."
        Invoke-CommandWithProgress -Activity "Installing $pkg" -TotalItems $totalPip -CurrentItem $currentPip -DryRun:$DryRun -Cmd {
            python -m pip install --user $pkg
        }
    }
}

# ─────────────────────────────────────────────
# 5. Detect agents
# ─────────────────────────────────────────────
Write-Step "5/8 — Detect agents"

$agents = @{}
$agentList = @(
    @{ name = "claude";    cmd = "claude" },
    @{ name = "opencode";  cmd = "opencode" },
    @{ name = "gemini";    cmd = "gemini" },
    @{ name = "copilot";   cmd = "copilot" }
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
# 5b. Detect optional CLIs (API-key gated)
# ─────────────────────────────────────────────
Write-Step "6/8 — Optional CLIs"

# Check for Bright Data API key and CLI
$brightDataApiKey = [System.Environment]::GetEnvironmentVariable("BRIGHTDATA_API_KEY")
$hasBrightDataCli = $false

if (-not [string]::IsNullOrWhiteSpace($brightDataApiKey)) {
    if (Get-Command "brightdata" -ErrorAction SilentlyContinue) {
        Write-OK "brightdata CLI found"
        $hasBrightDataCli = $true
    } else {
        Write-Warn "brightdata CLI not found — Bright Data skills will be skipped"
    }
} else {
    Write-Info "BRIGHTDATA_API_KEY not set — skipping Bright Data CLI and skills"
}

# ── Optional: Bright Data skills ──────────────────────
if ($hasBrightDataCli) {
    Write-Step "Optional — Bright Data skills"
    Write-Info "Installing Bright Data skills..."
    $brightDataSkillGroup.GetEnumerator() | ForEach-Object -Parallel {
        $repo = $_.Key
        $skills = $_.Value
        $DryRun = $using:DryRun
        
        $skillsToInstall = @()
        foreach ($skill in $skills) {
            $skillsToInstall += $skill
        }

        if ($skillsToInstall.Count -gt 0) {
            [Console]::WriteLine("  [ ] Installing skills from ${repo}: $($skillsToInstall -join ', ')")
            
            if (-not $DryRun) {
                try {
                    $output = npx skills add $repo --skill @skillsToInstall -g -y 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        foreach ($skill in $skillsToInstall) {
                            [Console]::WriteLine("  [+] $skill installed")
                        }
                    } else {
                        [Console]::WriteLine("  [!] Failed to install skills from ${repo}: $output")
                    }
                } catch {
                    [Console]::WriteLine("  [!] Error installing skills from ${repo}: $_")
                }
            } else {
                [Console]::WriteLine("  [ ] [DRY-RUN] npx skills add $repo --skill @skillsToInstall -g -y")
            }
        }
    } -ThrottleLimit 1
} else {
    Write-Info "Bright Data CLI not available — skipping Bright Data skills"
}

# ─────────────────────────────────────────────
# 6. Config scaffolding (agent-gated)
# ─────────────────────────────────────────────
Write-Step "7/8 — Config scaffolding"

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
        @{ src = "$configDir\opencode\plugins\security.js";       dst = "$env:USERPROFILE\.config\opencode\plugins\security.js" },
        @{ src = "$configDir\opencode\plugins\format-on-write.js"; dst = "$env:USERPROFILE\.config\opencode\plugins\format-on-write.js" },
        @{ src = "$configDir\opencode\plugins\notifications.js";   dst = "$env:USERPROFILE\.config\opencode\plugins\notifications.js" },
        @{ src = "$configDir\opencode\plugins\context-refresh.js"; dst = "$env:USERPROFILE\.config\opencode\plugins\context-refresh.js" },
        @{ src = "$configDir\opencode\plugins\session-lifecycle.js"; dst = "$env:USERPROFILE\.config\opencode\plugins\session-lifecycle.js" },
        @{ src = "$configDir\opencode\plugins\binary-to-markdown.js"; dst = "$env:USERPROFILE\.config\opencode\plugins\binary-to-markdown.js" },
        @{ src = "$configDir\opencode\plugins\permission-logger.js"; dst = "$env:USERPROFILE\.config\opencode\plugins\permission-logger.js" },
        @{ src = "$configDir\opencode\plugins\shell-detector.js"; dst = "$env:USERPROFILE\.config\opencode\plugins\shell-detector.js" }
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

$totalConfigs = $sharedConfigs.Count
$currentConfig = 0

foreach ($cfg in $sharedConfigs) {
    $currentConfig++
    if (Test-Path $cfg.dst) {
        Write-OK "$($cfg.dst) already exists — skipping (use -Update to overwrite)"
        if ($Update) {
            Write-Info "Backing up and overwriting $($cfg.dst)..."
            if (-not $DryRun) {
                Backup-And-CopyFile -Source $cfg.src -Destination $cfg.dst -DryRun:$DryRun
                Write-OK "$($cfg.dst) updated (backup created)"
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
    Write-Progress -Activity "Config scaffolding" -Status "$currentConfig of $totalConfigs" -PercentComplete ([math]::Round(($currentConfig / $totalConfigs) * 100))
}
Write-Progress -Activity "Config scaffolding" -Completed

# ─────────────────────────────────────────────
# 7. Done — Auto-run verification
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Agents configured: $(($agents.GetEnumerator() | Where-Object { $_.Value }).Name -join ', ')" -ForegroundColor Cyan
if (($agents.GetEnumerator() | Where-Object { -not $_.Value })) {
    Write-Host "Agents skipped:   $(($agents.GetEnumerator() | Where-Object { -not $_.Value }).Name -join ', ')" -ForegroundColor Yellow
}

# Auto-run verification unless -SkipVerify was passed
if (-not $SkipVerify) {
    Write-Host ""
    Write-Host "Running automatic verification..." -ForegroundColor Cyan
    & "$PSScriptRoot\verify.ps1"
    exit $LASTEXITCODE
} else {
    Write-Host "Verification skipped (use -SkipVerify to bypass automatic verification)" -ForegroundColor Yellow
    Write-Host "Run .\setup\verify.ps1 to verify your installation."
    Write-Host "Run .\setup\analyze-permission-log.ps1 to see which commands you can auto-allow."
}
