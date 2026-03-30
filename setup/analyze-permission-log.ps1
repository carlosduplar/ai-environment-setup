#!/usr/bin/env pwsh
# analyze-permission-log.ps1 — Analyze permission logs and suggest auto-allow patterns
# Usage: .\setup\analyze-permission-log.ps1

$logFile = Join-Path $env:USERPROFILE ".config\opencode\permission-log.jsonl"

if (-not (Test-Path $logFile)) {
    Write-Host "No permission log found at $logFile" -ForegroundColor Yellow
    Write-Host "Run some commands first, then check back!"
    exit 1
}

Write-Host "Analyzing permission log..." -ForegroundColor Cyan

$entries = Get-Content $logFile | ForEach-Object { 
    try { $_ | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { $null }
} | Where-Object { $_ -ne $null }

$commandPatterns = @{}
$toolCounts = @{}

foreach ($entry in $entries) {
    $tool = $entry.tool
    $cmd = $entry.command
    
    if (-not $toolCounts[$tool]) { $toolCounts[$tool] = 0 }
    $toolCounts[$tool]++
    
    if ($tool -eq "bash" -and $cmd) {
        # Extract base command pattern
        $baseCmd = ($cmd -split '\s+')[0]
        if (-not $commandPatterns[$baseCmd]) { $commandPatterns[$baseCmd] = 0 }
        $commandPatterns[$baseCmd]++
    }
}

Write-Host "`n=== Tool Usage Summary ===" -ForegroundColor Green
$toolCounts.GetEnumerator() | Sort-Object Value -Descending | Format-Table -AutoSize

Write-Host "`n=== Frequent Bash Commands (candidates for auto-allow) ===" -ForegroundColor Green
$commandPatterns.GetEnumerator() | 
    Where-Object { $_.Value -ge 3 } |
    Sort-Object Value -Descending |
    ForEach-Object {
        $suggestion = if ($_.Key -match '^(git|npm|pnpm|yarn|python|node|ls|cat|rg|grep|find|head|tail|wc|tree)$') {
            "$($_.Key) *`: allow  # Used $($_.Value) times"
        } else {
            "$($_.Key) *`: ask   # Used $($_.Value) times (review before allowing)"
        }
        [PSCustomObject]@{
            Command = $_.Key
            Count = $_.Value
            Suggestion = $suggestion
        }
    } | Format-Table -AutoSize

Write-Host "`n=== Recent Unique Commands (last 20) ===" -ForegroundColor Green
$entries | 
    Select-Object -Last 20 |
    ForEach-Object {
        [PSCustomObject]@{
            Time = $_.timestamp.Substring(0, 19)
            Tool = $_.tool
            Command = if ($_.command.Length -gt 60) { $_.command.Substring(0, 60) + "..." } else { $_.command }
        }
    } | Format-Table -AutoSize

Write-Host "`nTo add these to your auto-allow list, edit:" -ForegroundColor Cyan
Write-Host "  ~\.config\opencode\opencode.json" -ForegroundColor White
Write-Host "`nTip: Commands used 5+ times are usually safe to auto-allow" -ForegroundColor Yellow
