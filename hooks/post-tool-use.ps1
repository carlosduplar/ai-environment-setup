# hooks/post-tool-use.ps1
$inputData = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue
$tool = $inputData.toolName
$resultType = $inputData.toolResult.resultType

# Hook 1: Auto-Format Every File Edit
# Runs Prettier on every file edit/write
if ($tool -match "^(Edit|Write)$" -and $resultType -eq "success") {
    $filePath = $inputData.toolResult.path
    if ($filePath -and (Test-Path $filePath)) {
        $ext = [System.IO.Path]::GetExtension($filePath)
        $formattableExts = @('.js', '.ts', '.jsx', '.tsx', '.json', '.css', '.scss', '.html', '.vue', '.yaml', '.yml', '.md')
        if ($ext -in $formattableExts) {
            prettier --write $filePath 2>$null
        }
    }
}

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
