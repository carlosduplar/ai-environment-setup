# test-hooks.ps1
# Run from anywhere. Requires: jq, git
# Usage: pwsh test-hooks.ps1 [-HooksDir "~/.copilot/scripts"]

param(
    [string]$HooksDir = "$HOME/.copilot/scripts"
)

$HooksDir = (Resolve-Path $HooksDir -ErrorAction SilentlyContinue)?.Path ?? $HooksDir
$pass  = 0
$fail  = 0
$skip  = 0

function Write-Pass($label) { Write-Host "  PASS  $label" -ForegroundColor Green;   $script:pass++ }
function Write-Fail($label) { Write-Host "  FAIL  $label" -ForegroundColor Red;     $script:fail++ }
function Write-Skip($label) { Write-Host "  SKIP  $label" -ForegroundColor Yellow;  $script:skip++ }
function Write-Header($t)   { Write-Host "`n── $t ──────────────────────────────────────" }

# Verify dependencies
foreach ($cmd in @('jq','git')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: '$cmd' is required but not found." -ForegroundColor Red
        exit 1
    }
}

# Run a .ps1 hook with a given JSON payload
# Sets $script:HookOut, $script:HookExit
function Invoke-Hook($script, $payload) {
    $tmpIn  = [System.IO.Path]::GetTempFileName()
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tmpIn -Value $payload -Encoding UTF8
        $proc = Start-Process pwsh -ArgumentList "-NonInteractive","-File","$script" `
            -RedirectStandardInput  $tmpIn `
            -RedirectStandardOutput $tmpOut `
            -RedirectStandardError  $tmpErr `
            -Wait -PassThru -NoNewWindow
        $script:HookOut  = Get-Content $tmpOut -Raw -ErrorAction SilentlyContinue
        $script:HookErr  = Get-Content $tmpErr -Raw -ErrorAction SilentlyContinue
        $script:HookExit = $proc.ExitCode
    } finally {
        Remove-Item $tmpIn,$tmpOut,$tmpErr -Force -ErrorAction SilentlyContinue
    }
}

function Assert-Exit($expected, $label) {
    if ($script:HookExit -eq $expected) { Write-Pass "$label (exit $expected)" }
    else {
        Write-Fail "$label — expected exit $expected, got $($script:HookExit)"
        if ($script:HookErr) { Write-Host "    stderr: $($script:HookErr)" -ForegroundColor DarkGray }
    }
}

function Assert-Contains($needle, $label) {
    if ($script:HookOut -match [regex]::Escape($needle)) { Write-Pass "$label (contains '$needle')" }
    else {
        Write-Fail "$label — output did not contain '$needle'"
        Write-Host "    stdout: $($script:HookOut)" -ForegroundColor DarkGray
    }
}

function Assert-Deny($label) {
    $decision = $script:HookOut | jq -r '.permissionDecision' 2>$null
    if ($decision -eq 'deny') { Write-Pass "$label (permissionDecision=deny)" }
    else {
        Write-Fail "$label — expected deny, got: $($script:HookOut)"
    }
}

function Assert-Allow($label) {
    if ([string]::IsNullOrWhiteSpace($script:HookOut)) {
        Write-Pass "$label (empty output = allow)"
        return
    }
    $decision = $script:HookOut | jq -r '.permissionDecision' 2>$null
    if ($decision -eq 'allow' -or [string]::IsNullOrWhiteSpace($decision)) {
        Write-Pass "$label (allowed)"
    } else {
        Write-Fail "$label — expected allow, got: $($script:HookOut)"
    }
}

function Assert-NotAutoAllow($label) {
    if ([string]::IsNullOrWhiteSpace($script:HookOut)) {
        Write-Pass "$label (no explicit allow)"
        return
    }
    $decision = $script:HookOut | jq -r '.permissionDecision' 2>$null
    if ($decision -ne 'allow') {
        Write-Pass "$label (not explicitly auto-allowed)"
    } else {
        Write-Fail "$label — expected no auto-allow, got: $($script:HookOut)"
    }
}

function Assert-ValidJson($label) {
    if ([string]::IsNullOrWhiteSpace($script:HookOut)) {
        Write-Pass "$label (empty = valid allow)"
        return
    }
    $null = $script:HookOut | jq . 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Pass "$label (valid JSON)" }
    else { Write-Fail "$label — invalid JSON: $($script:HookOut)" }
}

# Create a temp git repo with PLAN.md and AGENTS.md committed
function New-TestRepo {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("copilot-test-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Push-Location $tmp
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    "# test" | Set-Content README.md
    git add . 2>$null
    git commit -q -m "initial" 2>$null

    @"
# AGENTS.md
## Test placeholder
"@ | Set-Content AGENTS.md

    @"
# PLAN.md

## Test runner
echo tests pass

## Compaction Checkpoints
After Milestone 1

## Milestones

### [PENDING] Milestone 1 — Add feature
**Touched files:**
- ``src/feature.ts``

**Depends on:** none
"@ | Set-Content PLAN.md

    git add . 2>$null
    git commit -q -m "add plan" 2>$null
    return $tmp
}

# ═══════════════════════════════════════════════════════════════════════════════
Write-Header "UNIT TESTS — session-start.ps1"
$script = Join-Path $HooksDir "session-start.ps1"

if (-not (Test-Path $script)) {
    Write-Skip "session-start.ps1 not found at $script"
} else {
    $repo = New-TestRepo

    # Test 1: clean repo
    $payload = "{`"timestamp`":1704614400000,`"cwd`":`"$($repo -replace '\\','\\\\')`",`"source`":`"new`",`"initialPrompt`":`"test`"}"
    Invoke-Hook $script $payload
    Assert-Exit 0 "Clean repo starts successfully"
    Assert-Contains "SESSION" "Prints session header"

    # Test 2: missing PLAN.md
    Remove-Item (Join-Path $repo "PLAN.md")
    Invoke-Hook $script $payload
    Assert-Exit 1 "Blocks when PLAN.md is missing"
    Assert-Contains "PLAN.md" "Reports PLAN.md as missing"
    Push-Location $repo; git checkout PLAN.md 2>$null; Pop-Location

    # Test 3: missing AGENTS.md
    Remove-Item (Join-Path $repo "AGENTS.md")
    Invoke-Hook $script $payload
    Assert-Exit 1 "Blocks when AGENTS.md is missing"
    Push-Location $repo; git checkout AGENTS.md 2>$null; Pop-Location

    # Test 4: dirty tree
    "dirty" | Set-Content (Join-Path $repo "dirty.txt")
    Invoke-Hook $script $payload
    Assert-Exit 1 "Blocks on dirty working tree"
    Remove-Item (Join-Path $repo "dirty.txt") -ErrorAction SilentlyContinue

    # Test 5: resume label
    $payloadResume = "{`"timestamp`":1704614400000,`"cwd`":`"$($repo -replace '\\','\\\\')`",`"source`":`"resume`",`"initialPrompt`":`"`"}"
    Invoke-Hook $script $payloadResume
    Assert-Contains "RESUME" "Labels session as RESUME when source=resume"

    Pop-Location
    Remove-Item $repo -Recurse -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════════════════
Write-Header "UNIT TESTS — pre-tool-use.ps1 (secrets blocking)"
$script = Join-Path $HooksDir "pre-tool-use.ps1"

if (-not (Test-Path $script)) {
    Write-Skip "pre-tool-use.ps1 not found at $script"
} else {
    $repo = New-TestRepo

    # Helper to build a preToolUse payload
    function New-Payload($tool, $argJson) {
        "{`"timestamp`":1704614400000,`"cwd`":`"$($repo -replace '\\','\\\\')`",`"toolName`":`"$tool`",`"toolArgs`":`"$($argJson -replace '"','\"')`"}"
    }

    # Should DENY
    Invoke-Hook $script (New-Payload "read"  '{"path":"/project/.env"}')
    Assert-Deny ".env file read is denied"
    Assert-ValidJson ".env deny output is valid JSON"

    Invoke-Hook $script (New-Payload "view"  '{"path":".env.production"}')
    Assert-Deny ".env.production view is denied"

    Invoke-Hook $script (New-Payload "read"  '{"path":"/app/secrets/db.json"}')
    Assert-Deny "/secrets/ path read is denied"

    Invoke-Hook $script (New-Payload "view"  '{"path":"certs/server.pem"}')
    Assert-Deny ".pem file view is denied"

    Invoke-Hook $script (New-Payload "read"  '{"path":"C:/Users/user/.ssh/id_rsa"}')
    Assert-Deny "id_rsa read is denied"

    Invoke-Hook $script (New-Payload "read"  '{"path":"C:/Users/user/.aws/credentials"}')
    Assert-Deny ".aws/credentials read is denied"

    Invoke-Hook $script (New-Payload "read"  '{"path":"infra/prod.tfvars"}')
    Assert-Deny ".tfvars file read is denied"

    Invoke-Hook $script (New-Payload "bash"  '{"command":"cat .env"}')
    Assert-Deny "bash cat .env is denied"

    Invoke-Hook $script (New-Payload "bash"  '{"command":"Get-Content .env.local"}')
    Assert-Deny "PowerShell Get-Content .env.local is denied"

    # Should ALLOW
    Invoke-Hook $script (New-Payload "read"  '{"path":"src/main.ts"}')
    Assert-Allow "src/main.ts read is allowed"

    Invoke-Hook $script (New-Payload "edit"  '{"path":"tests/main.test.ts"}')
    Assert-Allow "tests/ edit is allowed"

    Invoke-Hook $script (New-Payload "read"  '{"path":"PLAN.md"}')
    Assert-Allow "PLAN.md read is allowed"

    Invoke-Hook $script (New-Payload "view"  '{"path":"package.json"}')
    Assert-Allow "package.json view is allowed"

    Invoke-Hook $script (New-Payload "read"  '{"path":"docs/environment-guide.md"}')
    Assert-Allow "docs/environment-guide.md is allowed"

    Invoke-Hook $script (New-Payload "bash" '{"command":"git show HEAD --stat"}')
    Assert-Allow "git show is auto-allowed"

    Invoke-Hook $script (New-Payload "bash" '{"command":"npm run lint"}')
    Assert-Allow "npm run lint is auto-allowed"

    Invoke-Hook $script (New-Payload "bash" '{"command":"python -m pytest -q"}')
    Assert-Allow "python -m pytest is auto-allowed"

    # Should NOT auto-allow (must remain approval-gated by permission system)
    Invoke-Hook $script (New-Payload "bash" '{"command":"pip install requests"}')
    Assert-NotAutoAllow "pip install is not auto-allowed"

    # Compact safety
    "dirty" | Set-Content (Join-Path $repo "dirty.txt")
    Invoke-Hook $script (New-Payload "bash" '{"command":"/compact"}')
    Assert-Deny "compact denied on dirty tree"
    Remove-Item (Join-Path $repo "dirty.txt")

    Invoke-Hook $script (New-Payload "bash" '{"command":"/compact"}')
    Assert-Allow "compact allowed on clean tree"

    Pop-Location
    Remove-Item $repo -Recurse -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════════════════
Write-Header "UNIT TESTS — post-tool-use.ps1"
$script = Join-Path $HooksDir "post-tool-use.ps1"

if (-not (Test-Path $script)) {
    Write-Skip "post-tool-use.ps1 not found at $script"
} else {
    $repo = New-TestRepo

    $payload = "{`"timestamp`":1704614400000,`"cwd`":`"$($repo -replace '\\','\\\\')`",`"toolName`":`"read`",`"toolResult`":{`"resultType`":`"success`"}}"
    Invoke-Hook $script $payload
    Assert-Exit 0 "Non-bash tool exits cleanly"

    $payload = "{`"timestamp`":1704614400000,`"cwd`":`"$($repo -replace '\\','\\\\')`",`"toolName`":`"bash`",`"toolResult`":{`"resultType`":`"success`"}}"
    Invoke-Hook $script $payload
    Assert-Exit 0 "Clean bash call exits cleanly"

    # 3 blocked milestones
    @"
# PLAN.md
### [BLOCKED] Milestone 1 — First
### [BLOCKED] Milestone 2 — Second
### [BLOCKED] Milestone 3 — Third
"@ | Set-Content (Join-Path $repo "PLAN.md")
    Push-Location $repo
    git add PLAN.md 2>$null
    git commit -q -m "plan: blocked milestones" 2>$null
    New-Item -ItemType Directory -Path "src" -Force | Out-Null
    "code" | Set-Content "src/feature.ts"
    git add . 2>$null
    git commit -q -m "feat: some feature" 2>$null
    Pop-Location

    Invoke-Hook $script $payload
    Assert-Contains "BLOCKED" "Warns when 3+ milestones blocked"

    Remove-Item $repo -Recurse -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════════════════
Write-Header "UNIT TESTS — session-end.ps1"
$script = Join-Path $HooksDir "session-end.ps1"

if (-not (Test-Path $script)) {
    Write-Skip "session-end.ps1 not found at $script"
} else {
    $repo = New-TestRepo

    $payload = "{`"timestamp`":1704614400000,`"cwd`":`"$($repo -replace '\\','\\\\')`",`"reason`":`"complete`"}"
    Invoke-Hook $script $payload
    Assert-Exit 0 "session-end exits cleanly"
    Assert-Contains "SESSION END" "Prints session end header"
    Assert-Contains "pending" "Reports pending count"

    # All done
    @"
# PLAN.md
### [DONE] Milestone 1 — Feature A
### [DONE] Milestone 2 — Feature B
"@ | Set-Content (Join-Path $repo "PLAN.md")
    Push-Location $repo
    git add PLAN.md 2>$null
    git commit -q -m "plan: all done" 2>$null
    Pop-Location

    Invoke-Hook $script $payload
    Assert-Contains "complete" "Reports completion when all done"

    Remove-Item $repo -Recurse -Force -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════════════════
Write-Header "RESULTS"
$total = $pass + $fail + $skip
Write-Host "  $pass passed  /  $fail failed  /  $skip skipped  (total: $total)"
Write-Host ""

if ($fail -gt 0) {
    Write-Host "Some tests failed. Review output above before deploying hooks." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests passed." -ForegroundColor Green
    exit 0
}
