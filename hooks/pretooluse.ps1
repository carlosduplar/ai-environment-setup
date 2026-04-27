param()
$ErrorActionPreference = 'Stop'
$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $payload.tool_name
$filePath = $payload.tool_input.file_path
if (-not $filePath) { $filePath = $payload.tool_input.filePath }

if ($toolName -ne 'Read' -or -not $filePath -or -not (Test-Path -LiteralPath $filePath)) { exit 0 }

Get-ChildItem $env:TEMP -Filter 'claude-read-*' -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-1) } |
  Remove-Item -Force -ErrorAction SilentlyContinue

$ext = [IO.Path]::GetExtension($filePath).TrimStart('.').ToLowerInvariant()
$base = Join-Path $env:TEMP ("claude-read-{0}-{1}" -f [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(), $PID)

function Emit-Redirect([string]$target, [string]$note) {
  $obj = @{
    hookSpecificOutput = @{
      hookEventName = 'PreToolUse'
      permissionDecision = 'allow'
      updatedInput = @{ file_path = $target }
      additionalContext = $note
    }
  }
  $obj | ConvertTo-Json -Depth 10 -Compress | Write-Output
  exit 0
}

switch ($ext) {
  { $_ -in @('png','jpg','jpeg','webp','gif','bmp','tif','tiff') } {
    $magick = Get-Command magick -ErrorAction SilentlyContinue
    if ($magick) {
      $out = "$base.$ext"
      & $magick.Source $filePath -resize '2000x2000>' -quality '85' $out 2>$null
      if (Test-Path -LiteralPath $out) {
        Emit-Redirect -target $out -note 'Read hook used non-mutating optimized image copy.'
      }
    }
  }
  'pdf' {
    $pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
    if ($pdftotext) {
      $out = "$base.txt"
      & $pdftotext.Source -layout $filePath $out 2>$null
      if ((Test-Path -LiteralPath $out) -and (Get-Item -LiteralPath $out).Length -gt 0) {
        Emit-Redirect -target $out -note 'Read hook used non-mutating extracted PDF text copy.'
      }
    }
  }
  { $_ -in @('doc','docx','xls','xlsx','ppt','pptx') } {
    $markitdown = Get-Command markitdown -ErrorAction SilentlyContinue
    if ($markitdown) {
      $out = "$base.md"
      & $markitdown.Source $filePath 2>$null | Out-File -FilePath $out -Encoding utf8
      if ((Test-Path -LiteralPath $out) -and (Get-Item -LiteralPath $out).Length -gt 0) {
        Emit-Redirect -target $out -note 'Read hook used non-mutating markitdown extraction copy.'
      }
    }
  }
}

exit 0