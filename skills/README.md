# Skills

Claude Code skills are reusable instruction files that configure sub-agents for specific tasks. They live in `~/.claude/rules/` (global) or `.claude/rules/` (per-repo).

## Install location

```
~/.claude/rules/<skill-name>.md    # global, applies everywhere
.claude/rules/<skill-name>.md      # project-scoped
```

## Using a skill

Skills are activated by name in the Copilot CLI or Claude Code session. For always-on rules, set `alwaysApply: true` in the front matter.

## Skill catalog

See [catalog/](catalog/) for all skill definitions.

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| context7-cli | **Yes** | Fetch current library docs from Context7 |
| find-skills | No | Discover and install new skills |
| skill-creator | No | Create/modify/test skills |

### File Operations

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| docx | No | Read/write `.docx` Word documents |
| pdf | No | PDF read/create/merge/split |
| pptx | No | PowerPoint file operations |
| xlsx | No | Spreadsheet file operations |

### Testing & Automation

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| playwright-cli | No | Browser automation via Playwright |
| webapp-testing | No | Local web app testing with Playwright |

### Dev Tools

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| gh-cli | No | GitHub CLI (`gh`) reference |

### Google Workspace (requires `-GWS` flag)

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| gws-calendar | No | Google Calendar operations |
| gws-docs | No | Read/write Google Docs |
| gws-drive | No | Google Drive file management |
| gws-gmail | No | Gmail send/read/manage |
| gws-keep | No | Google Keep notes |
| gws-shared | No | Shared gws CLI patterns |
| gws-sheets | No | Google Sheets read/write |

## Adding a skill

```powershell
# Install a skill globally (affects all Claude Code sessions)
# 1. Place the skill .md file in ~/.claude/rules/
# 2. Or use the skill-creator skill to generate from a description

Copy-Item skills/catalog/my-skill.md "$env:USERPROFILE\.claude\rules\"
```

## Updating skills

Skills installed via `skill-creator` can be updated in-session. For skills in this repo, update the `.md` file and re-copy to `~/.claude/rules/`.
