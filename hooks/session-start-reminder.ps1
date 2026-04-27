param()
$ErrorActionPreference = 'SilentlyContinue'
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$source = $payload.source
$cwd = $payload.cwd
if ($cwd) { Set-Location -LiteralPath $cwd -ErrorAction SilentlyContinue }

$parts = @("Session: $source")

if (Test-Path 'package.json') {
  $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
  $name = if ($pkg -and $pkg.name) { $pkg.name } else { 'project' }
  $parts += "$name (Node.js)"
} elseif (Test-Path 'pyproject.toml') {
  $parts += 'Python project'
} elseif (Test-Path 'Cargo.toml') {
  $parts += 'Rust project'
} elseif (Test-Path 'go.mod') {
  $parts += 'Go project'
}

$branch = git branch --show-current 2>$null
if ($branch) {
  $changes = (git status --short 2>$null | Measure-Object -Line).Lines
  if ($changes -gt 0) {
    $parts += "branch: $branch ($changes uncommitted)"
  } else {
    $parts += "branch: $branch"
  }
}

$parts += 'Keepalive: if >5m idle, run /loop'

@{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = ($parts -join ' | ') } } | ConvertTo-Json -Compress
exit 0