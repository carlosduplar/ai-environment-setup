# hooks/session-end.ps1
$inputData = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue
$reason = if ($inputData.reason) { $inputData.reason } else { "unknown" }

Write-Host "──────────────────────────────────────────"
Write-Host "SESSION END — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') (reason: $reason)"

if (-not (Test-Path "PLAN.md")) {
    Write-Host "PLAN.md not found — no summary available."
    Write-Host "──────────────────────────────────────────"
    exit 0
}

$done    = (Select-String -Path "PLAN.md" -Pattern "^### \[DONE\]").Count
$pending = (Select-String -Path "PLAN.md" -Pattern "^### \[PENDING\]").Count
$blocked = (Select-String -Path "PLAN.md" -Pattern "^### \[BLOCKED\]").Count
$total   = $done + $pending + $blocked

Write-Host "Plan: $done/$total done | $pending pending | $blocked blocked"

if ($blocked -gt 0) {
    Write-Host ""
    Write-Host "Blocked milestones:"
    Select-String -Path "PLAN.md" -Pattern "^### \[BLOCKED\]" |
        ForEach-Object { Write-Host "  $($_.Line -replace '^### ', '')" }
}

if ($pending -eq 0 -and $blocked -eq 0 -and $total -gt 0) {
    Write-Host ""
    Write-Host "All milestones complete."
}
Write-Host "──────────────────────────────────────────"
