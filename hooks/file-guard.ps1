param()
$ErrorActionPreference = 'Stop'
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $payload.tool_name
$filePath = $payload.tool_input.file_path
if (-not $filePath) { $filePath = $payload.tool_input.filePath }
$command = $payload.tool_input.command
$cwd = $payload.cwd
$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = $cwd }
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$projectDir = [IO.Path]::GetFullPath($projectDir)

$patterns = @(
  '\.env$', '\.env\.', '\.git\\|\.git/', '\.ssh\\|\.ssh/', 'id_rsa', 'id_ed25519', '\.pem$', '\.key$', 'credentials\.json$', 'secrets\.'
)

function Test-ProtectedPath([string]$value) {
  if (-not $value) { return $false }
  foreach ($p in $patterns) {
    if ($value -match $p) { return $true }
  }
  return $false
}

function IsOutsideProject([string]$pathValue) {
  if (-not $pathValue) { return $false }
  $candidate = $pathValue.Replace('~', $env:USERPROFILE)
  try {
    $resolved = [IO.Path]::GetFullPath($candidate)
    return (-not ($resolved -eq $projectDir -or $resolved.StartsWith($projectDir + [IO.Path]::DirectorySeparatorChar)))
  } catch {
    return $false
  }
}

if ($toolName -in @('Write','Edit','MultiEdit')) {
  if (Test-ProtectedPath $filePath) {
    [Console]::Error.WriteLine("BLOCKED: path '$filePath' matches protected pattern")
    exit 2
  }
  if (IsOutsideProject $filePath) {
    [Console]::Error.WriteLine("BLOCKED: write/edit outside workspace is blocked: '$filePath'")
    exit 2
  }
}

if ($toolName -eq 'Bash' -and (Test-ProtectedPath $command)) {
  [Console]::Error.WriteLine('BLOCKED: bash command references protected path/pattern')
  exit 2
}

if ($toolName -eq 'Bash' -and $command -match '^\s*(cat|head|tail|grep|rg|find|Get-Content|type|Select-String|sls)\b') {
  if ($command -match '(^|\s)\.\.[\\/]+') {
    [Console]::Error.WriteLine('BLOCKED: path traversal is blocked for high-risk read commands')
    exit 2
  }
  $pathMatches = [regex]::Matches($command, '(~?[\\/][^ ;|&]+|\.{1,2}[\\/][^ ;|&]+)')
  foreach ($m in $pathMatches) {
    if (IsOutsideProject $m.Value) {
      [Console]::Error.WriteLine("BLOCKED: high-risk read command target outside workspace: '$($m.Value)'")
      exit 2
    }
  }
}

exit 0