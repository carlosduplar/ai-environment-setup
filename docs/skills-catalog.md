# Skills Catalog

Claude Code skills can be inspected with `npx skills ls --json`, updated with `npx skills update -g -y`, and added with `npx skills add <skill-name> -g -y`.

## Currently Installed Skills

### Core

| Skill | Description | Always Apply | Category |
|-------|-------------|-------------|----------|
| **context7-cli** | Fetch current library docs from Context7 | **Yes** | Dev Tools |
| find-docs | Up-to-date documentation for any developer technology | No | Dev Tools |
| find-skills | Discover and install new skills | No | Skills |
| skill-creator | Create/modify/test skills | No | Skills |

### Search & Research

| Skill | Description | Always Apply | Category |
|-------|-------------|-------------|----------|
| bx | Web search, research, RAG, grounding, deep research | No | Search |

### File Operations

| Skill | Description | Always Apply | Category |
|-------|-------------|-------------|----------|
| docx | Read/write `.docx` Word documents | No | Files |
| pdf | PDF read/create/merge/split | No | Files |
| pptx | PowerPoint file operations | No | Files |
| xlsx | Spreadsheet file operations | No | Files |

### Testing & Automation

| Skill | Description | Always Apply | Category |
|-------|-------------|-------------|----------|
| playwright-cli | Browser automation via Playwright | No | Testing |
| webapp-testing | Local web app testing with Playwright | No | Testing |

## Optional Skills

These skills are available but not installed by default. Use the `-GWS` flag for Google Workspace skills.

### Google Workspace (requires `-GWS` flag)

| Skill | Description | Category |
|-------|-------------|----------|
| gws-calendar | Google Calendar operations | Google Workspace |
| gws-docs | Read/write Google Docs | Google Workspace |
| gws-drive | Google Drive file management | Google Workspace |
| gws-gmail | Gmail send/read/manage | Google Workspace |
| gws-keep | Google Keep notes | Google Workspace |
| gws-shared | Shared gws CLI patterns | Google Workspace |
| gws-sheets | Google Sheets read/write | Google Workspace |

## Installing skills

Skills are installed via the `skill-creator` skill or directly via CLI:

```bash
# List installed skills
npx skills ls --json

# Update installed global skills
npx skills update -g -y

# Add one global skill by name
npx skills add <skill-name> -g -y
```

See setup scripts for the full list of skills installed in this environment.
