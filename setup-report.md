# Setup Report

Fill this out after applying the environment on a new machine.

## Machine Info

- **Date**: <!-- YYYY-MM-DD -->
- **OS**: Windows 11 (<!-- version -->)
- **PowerShell version**: <!-- pwsh --version -->
- **Git Bash version**: <!-- bash --version -->

## Bootstrap Result

- [ ] `bootstrap.ps1` completed without errors
- [ ] `verify.ps1` passed all checks
- [ ] `.env.local` populated with all required keys

## Tools Installed

Run `bootstrap\verify.ps1` and paste output here:

```
<!-- paste verify output -->
```

## MCP Servers Configured

- [ ] playwright (optional)
- [ ] <!-- add others -->

## Known Issues / Deviations

<!-- Document anything that didn't go as expected -->

## Post-Setup Checklist

- [ ] Claude Code: tested `claude` command
- [ ] OpenCode: tested `opencode` command
- [ ] Gemini CLI: tested `gemini` command
- [ ] GitHub Copilot CLI: tested `gh copilot suggest`
- [ ] gws: authenticated (`gws auth login`)
- [ ] gcloud: authenticated (`gcloud auth login`)
- [ ] firebase: authenticated (`firebase login`)
- [ ] ctx7: resolved first library docs
- [ ] Playwright: installed browsers (`playwright install`)
