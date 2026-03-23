# hooks/claude-code-pre-tool-use.ps1
# Fires before EVERY tool call in Claude Code.
# Uses environment variables: CLAUDE_TOOL_NAME, CLAUDE_TOOL_INPUT_PATH, CLAUDE_TOOL_INPUT_COMMAND.
# Exit 0 to allow, non-zero to deny.

$blockedPatterns = @(
    '\.env', '\.env\.', '/secrets/', '/secret/', '\.pem$', '\.key$',
    '\.p12$', '\.pfx$', '\.jks$', 'id_rsa', 'id_ed25519', 'id_ecdsa',
    '\.netrc$', '\.npmrc', '\.pypirc', 'credentials$', 'credentials\.json',
    'service.account', 'serviceaccount', '\.aws/credentials', '\.aws/config',
    'kubeconfig', '\.kube/config', 'terraform\.tfvars', '\.tfvars$',
    'vault\.hcl', 'auth\.json$', 'token\.json$', 'client_secret'
)

$tool = $env:CLAUDE_TOOL_NAME
$targetPath = $env:CLAUDE_TOOL_INPUT_PATH
$command = $env:CLAUDE_TOOL_INPUT_COMMAND

# Determine which string to check
$checkString = ""
if ($targetPath) { $checkString = $targetPath }
elseif ($command) { $checkString = $command }

if ($checkString) {
    foreach ($pattern in $blockedPatterns) {
        if ($checkString -match $pattern) {
            Write-Error "Secret file access blocked by pre-tool-use hook. Path matched pattern: $pattern. Do not attempt to read, write, or reference this file."
            exit 1
        }
    }
}

# Compact safety check
if ($tool -eq "Bash" -and $command -match "compact") {
    $gitStatus = git status --porcelain 2>$null
    if ($gitStatus) {
        Write-Error "Cannot compact with uncommitted changes. Commit or restore all changes first, then update PLAN.md status."
        exit 1
    }
}

exit 0