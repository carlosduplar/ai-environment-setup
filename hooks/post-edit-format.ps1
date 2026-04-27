param()
$ErrorActionPreference = 'SilentlyContinue'
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$filePath = $payload.tool_input.file_path
if (-not $filePath) { $filePath = $payload.tool_input.filePath }
if (-not $filePath -or -not (Test-Path -LiteralPath $filePath)) { exit 0 }
$ext = [IO.Path]::GetExtension($filePath).TrimStart('.').ToLowerInvariant()
switch ($ext) {
  { $_ -in @('js','jsx','ts','tsx','json','css','scss','less','html','htm','md','markdown','yaml','yml') } {
    $prettier = Get-Command prettier -ErrorAction SilentlyContinue
    if ($prettier) { & $prettier.Source --write $filePath 2>$null }
  }
  'py' {
    $black = Get-Command black -ErrorAction SilentlyContinue
    if ($black) { & $black.Source --quiet $filePath 2>$null }
    else {
      $autopep8 = Get-Command autopep8 -ErrorAction SilentlyContinue
      if ($autopep8) { & $autopep8.Source --in-place $filePath 2>$null }
    }
  }
}
exit 0