$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$converter = Join-Path $scriptDir 'convert.py'

$pythonCmd = $null
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = 'python3'
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = 'python'
} else {
    Write-Error "[binary-to-markdown] Missing dependency: python3/python (required for hook parsing and conversion)."
    exit 0
}

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "[binary-to-markdown] Failed to parse Claude hook JSON input."
    exit 0
}

$toolName = [string]$payload.tool_name
$filePath = [string]$payload.tool_input.file_path

if ($toolName -ne 'Read') {
    exit 0
}

$supportedExtensions = @('.pdf', '.docx', '.xlsx', '.xls', '.pptx', '.ppt', '.epub', '.ipynb')
$extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
if ($supportedExtensions -notcontains $extension) {
    exit 0
}

$fileName = [System.IO.Path]::GetFileName($filePath)
$markdown = & $pythonCmd $converter $filePath
if ($LASTEXITCODE -eq 0) {
    $reason = "[binary-to-markdown] Converted `{0}` -> Markdown`n`n{1}" -f $fileName, $markdown
    @{
        decision = 'block'
        reason = $reason
    } | ConvertTo-Json -Compress
    exit 0
}

@{
    decision = 'block'
    reason = "[binary-to-markdown] Conversion failed for `{0}`. See stderr for details." -f $fileName
} | ConvertTo-Json -Compress
exit 0
