$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$converter = Join-Path $scriptDir 'convert.py'

$pythonCmd = $null
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $pythonCmd = 'python3'
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = 'python'
} else {
    Write-Error "[binary-to-markdown] Missing dependency: python3/python (required for conversion)."
    exit 0
}

$toolName = [string]$env:GEMINI_TOOL_NAME
$filePath = [string]$env:GEMINI_TOOL_INPUT_PATH
$toolLower = $toolName.ToLowerInvariant()

$validToolNames = @('read', 'read_file', 'open_file', 'view')
if ($validToolNames -notcontains $toolLower) {
    exit 0
}

$supportedExtensions = @('.pdf', '.docx', '.xlsx', '.xls', '.pptx', '.ppt', '.epub', '.ipynb')
$extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
if ($supportedExtensions -notcontains $extension) {
    exit 0
}

& $pythonCmd $converter $filePath | Out-Null
if ($LASTEXITCODE -eq 0) {
    $fileName = [System.IO.Path]::GetFileName($filePath)
    Write-Error '[binary-to-markdown] Note: Gemini hook cannot inject converted content back.'
    Write-Error ("[binary-to-markdown] Converted `{0}` to Markdown but Gemini will still attempt the raw read." -f $fileName)
    Write-Error "[binary-to-markdown] Consider pre-converting manually with: markitdown `"$filePath`""
}

exit 0
