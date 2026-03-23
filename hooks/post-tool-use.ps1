# hooks/post-tool-use.ps1
$inputData = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue
$tool = $inputData.toolName
$resultType = $inputData.toolResult.resultType

if ($tool -ne "bash" -or $resultType -ne "success") { exit 0 }

$lastMsg = git log -1 --pretty=%s 2>$null
if ($lastMsg -match "^feat: ") {
    $files = git log -1 --name-only --pretty="" 2>$null
    if ($files -notmatch "PLAN\.md") {
        Write-Host "WARNING: feat commit detected but PLAN.md was not updated in the same commit."
    }
}

if (Test-Path "PLAN.md") {
    $blocked = (Select-String -Path "PLAN.md" -Pattern "^### \[BLOCKED\]").Count
    if ($blocked -ge 3) {
        Write-Host "──────────────────────────────────────────"
        Write-Host "WARNING: $blocked milestones are BLOCKED. Review before continuing:"
        Select-String -Path "PLAN.md" -Pattern "^### \[BLOCKED\]" |
            ForEach-Object { Write-Host "  $($_.Line -replace '^### ', '')" }
        Write-Host "──────────────────────────────────────────"
    }
}
