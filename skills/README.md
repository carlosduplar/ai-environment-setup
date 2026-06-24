# Skills

Skills are reusable instruction files that configure sub-agents for specific tasks. They live in `~/.agents/skills/` (global) or `.claude/rules/` (per-repo for Claude Code).

## Install location

```
~/.agents/skills/<skill-name>/SKILL.md    # global, applies everywhere
.claude/rules/<skill-name>.md             # project-scoped (Claude Code)
```

## Using a skill

Skills are activated by name in the AI tool session. For always-on rules, set `alwaysApply: true` in the front matter.

## Currently installed skills

### Core

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| context7-cli | **Yes** | Fetch current library docs from Context7 |
| find-docs | No | Up-to-date documentation for any developer technology |
| find-skills | No | Discover and install new skills |
| skill-creator | No | Create/modify/test skills |

### Search & Research

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| bx | No | Web search, research, RAG, grounding, deep research |

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

```bash
# Install a skill globally (affects all AI tool sessions)
npx skills add <skill-name> -g -y

# List installed skills
npx skills ls -g

# Update installed global skills
npx skills update -g -y
```

## Updating skills

Skills installed via `skill-creator` can be updated in-session. For skills in this repo, update the `.md` file and re-copy to `~/.agents/skills/`.
