# hooks/pre-tool-use.ps1
# Windows equivalent of pre-tool-use.sh

$inputData = $input | Out-String | ConvertFrom-Json -ErrorAction SilentlyContinue
$tool = $inputData.toolName
$args_raw = $inputData.toolArgs

$blockedPatterns = @(
    '\.env', '\.env\.', '/secrets/', '/secret/', '\.pem$', '\.key$',
    '\.p12$', '\.pfx$', '\.jks$', 'id_rsa', 'id_ed25519', 'id_ecdsa',
    '\.netrc$', '\.npmrc', '\.pypirc', 'credentials$', 'credentials\.json',
    'service.account', 'serviceaccount', '\.aws/credentials', '\.aws/config',
    'kubeconfig', '\.kube/config', 'terraform\.tfvars', '\.tfvars$',
    'vault\.hcl', 'auth\.json$', 'token\.json$', 'client_secret'
)

$fileTools = @('read','view','edit','create','write','str_replace','insert','bash')

if ($tool -in $fileTools) {
    try {
        $parsed = $args_raw | ConvertFrom-Json -ErrorAction Stop
        $targetPath = if ($parsed.path) { $parsed.path }
                      elseif ($parsed.file) { $parsed.file }
                      elseif ($parsed.command) { $parsed.command }
                      else { $args_raw }
    } catch {
        $targetPath = $args_raw
    }

    foreach ($pattern in $blockedPatterns) {
        if ($targetPath -match $pattern) {
            @{
                permissionDecision = "deny"
                permissionDecisionReason = "Secret file access blocked by pre-tool-use hook. Path matched pattern: $pattern. Do not attempt to read, write, or reference this file."
            } | ConvertTo-Json -Compress
            exit 0
        }
    }
}

# Compact safety check
if ($tool -eq "bash") {
	try {
		$cmd = ($args_raw | ConvertFrom-Json -ErrorAction Stop).command
	} catch { $cmd = $args_raw }

	if ($cmd -match "compact") {
		$gitStatus = git status --porcelain 2>$null
		if ($gitStatus) {
			@{
				permissionDecision = "deny"
				permissionDecisionReason = "Cannot compact with uncommitted changes. Commit or restore all changes first, then update PLAN.md status."
			} | ConvertTo-Json -Compress
			exit 0
		}
	}
}

# Hook 5: Auto-Approval God Mode
# Whitelisted commands that bypass permission prompts
$safeCommands = @(
	'^npm test',
	'^npm run test',
	'^npm run lint',
	'^npm run typecheck',
	'^npm run build',
	'^pnpm test',
	'^pnpm run test',
	'^pnpm run lint',
	'^pnpm run typecheck',
	'^pnpm run build',
	'^yarn test',
	'^yarn lint',
	'^yarn typecheck',
	'^yarn build',
	'^npx prettier',
	'^git diff',
	'^git status',
	'^git log',
	'^git show',
	'^git rev-parse',
	'^git ls-files',
	'^git branch --show-current',
	'^rg ',
	'^grep ',
	'^ls',
	'^cat',
	'^head ',
	'^tail ',
	'^wc ',
	'^find ',
	'^tree',
	'^pytest',
	'^python -m pytest',
	'^ruff check',
	'^mypy '
)
if ($tool -eq "bash") {
	try {
		$cmd = ($args_raw | ConvertFrom-Json -ErrorAction Stop).command
	} catch { $cmd = $args_raw }

	foreach ($pattern in $safeCommands) {
		if ($cmd -match $pattern) {
			@{
				permissionDecision = "allow"
				permissionDecisionReason = "Command matches safe whitelist pattern: $pattern"
			} | ConvertTo-Json -Compress
			exit 0
		}
	}
}

exit 0
