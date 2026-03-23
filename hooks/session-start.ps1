# hooks/session-start.ps1
# Windows equivalent of session-start.sh

$input_data = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue
$source = if ($input_data.source) { $input_data.source.ToUpper() } else { "UNKNOWN" }

Write-Host "──────────────────────────────────────────"
Write-Host "SESSION $source — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $commit = git rev-parse --short HEAD 2>$null
    Write-Host "Branch : $branch"
    Write-Host "Commit : $commit"
} catch {
    Write-Host "Branch : (not a git repo)"
}

if (-not (Test-Path "PLAN.md")) {
    Write-Host ""
    Write-Host "ERROR: PLAN.md not found. Run the planning agent first."
    Write-Host "──────────────────────────────────────────"
    exit 1
}

if (-not (Test-Path "AGENTS.md")) {
    Write-Host ""
    Write-Host "ERROR: AGENTS.md not found in repo root."
    Write-Host "──────────────────────────────────────────"
    exit 1
}

$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
    Write-Host ""
    Write-Host "ERROR: Uncommitted changes detected. Commit or stash before starting."
    git status --short
    Write-Host "──────────────────────────────────────────"
    exit 1
}

Write-Host ""
Write-Host "PLAN.md status:"
Select-String -Path "PLAN.md" -Pattern "^### \[(DONE|PENDING|BLOCKED)\]" |
    ForEach-Object { Write-Host "  $($_.Line -replace '^### ', '')" }

Write-Host ""
Write-Host "Next pending:"
$nextPending = Select-String -Path "PLAN.md" -Pattern "^### \[PENDING\]" | Select-Object -First 1
if ($nextPending) {
    Write-Host "  $($nextPending.Line -replace '^### ', '')"
} else {
    Write-Host "  None — plan may be complete or all blocked"
}
Write-Host "──────────────────────────────────────────"
