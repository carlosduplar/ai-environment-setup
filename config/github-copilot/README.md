# GitHub Copilot CLI

GitHub Copilot CLI is installed as a `gh` extension.

## Install

```powershell
gh extension install github/gh-copilot
```

## Usage

```powershell
# Suggest a shell command
gh copilot suggest "list all running processes sorted by memory"

# Explain a command
gh copilot explain "git rebase -i HEAD~3"
```

## Authentication

Copilot CLI uses your existing `gh auth` credentials. Ensure you're authenticated:

```powershell
gh auth login
gh auth status
```

## Config location

The `gh` CLI stores its config at: `~/.config/gh/`

Copilot extension config: `~/.config/copilot/`

No additional config file is needed for Copilot CLI beyond `gh auth`.

## Required environment variable

```
GITHUB_TOKEN=<YOUR_GITHUB_PAT>
```

Set this in `.env.local`.
