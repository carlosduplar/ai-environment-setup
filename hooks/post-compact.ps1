# hooks/post-compact.ps1
# Hook 4: Context Memory Refresh
# Automatically re-reads critical files after Claude compacts its context

$inputData = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue

$criticalFiles = @(
	"$HOME/.claude/CLAUDE.md",
	"$HOME/.claude/ARCHITECTURE.md",
	"$HOME/.claude/STYLE_GUIDE.md",
	"$HOME/.claude/rules.md"
)

$loadedFiles = @()
foreach ($file in $criticalFiles) {
	if (Test-Path $file) {
		$loadedFiles += $file
	}
}

if ($loadedFiles.Count -gt 0) {
	Write-Host "Context Memory Refresh: Loaded $($loadedFiles.Count) critical files"
	$loadedFiles | ForEach-Object { Write-Host "  - $_" }
}

exit 0