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

Skills marked with **-GWS** require the `-GWS` setup flag (includes `@googleworkspace/cli`).

| Skill | Always Apply | Description |
|-------|-------------|-------------|
| brand-guidelines | No | Anthropic brand colors and typography |
| context7-cli | **Yes** | Fetch current library docs from Context7 |
| doc-coauthoring | No | Guided documentation co-authoring workflow |
| docs-maintainer | No | Create/update ADRs, CHANGELOG, README |
| docx | No | Read/write `.docx` Word documents |
| find-skills | No | Discover and install new skills |
| frontend-design | No | Production-grade frontend UI generation |
| gh-cli | No | GitHub CLI (`gh`) reference |
| gws-calendar **-GWS** | No | Google Calendar operations |
| gws-docs **-GWS** | No | Read/write Google Docs |
| gws-drive **-GWS** | No | Google Drive file management |
| gws-gmail **-GWS** | No | Gmail send/read/manage |
| gws-keep **-GWS** | No | Google Keep notes |
| gws-shared **-GWS** | No | Shared gws CLI patterns |
| gws-sheets **-GWS** | No | Google Sheets read/write |
| gws-tasks **-GWS** | No | Google Tasks management |
| gws-workflow-email-to-task **-GWS** | No | Gmail → Google Tasks workflow |
| gws-workflow-meeting-prep **-GWS** | No | Meeting prep from calendar + docs |
| gws-workflow-standup-report **-GWS** | No | Standup summary from calendar + tasks |
| gws-workflow-weekly-digest **-GWS** | No | Weekly calendar + email digest |
| mcp-builder | No | Build MCP servers (FastMCP/MCP SDK) |
| pdf | No | PDF read/create/merge/split |
| playwright-cli | No | Browser automation via Playwright |
| pptx | No | PowerPoint file operations |
| security-threat-modeler | No | Security review for auth, injection, secrets |
| seo-audit | No | Technical SEO audit |
| skill-creator | No | Create/modify/test skills |
| tech-lead-reviewer | No | Comprehensive code review |
| test-writer | No | Write and run tests |
| vercel-react-best-practices | No | React/Next.js performance patterns |
| vercel-react-native-skills | No | React Native/Expo best practices |
| web-artifacts-builder | No | Multi-component HTML artifacts |
| web-design-guidelines | No | UI/UX guidelines review |
| webapp-testing | No | Local web app testing with Playwright |
| xlsx | No | Spreadsheet file operations |

## Adding a skill

```powershell
# Install a skill globally (affects all Claude Code sessions)
# 1. Place the skill .md file in ~/.claude/rules/
# 2. Or use the skill-creator skill to generate from a description

Copy-Item skills/catalog/my-skill.md "$env:USERPROFILE\.claude\rules\"
```

## Updating skills

Skills installed via `skill-creator` can be updated in-session. For skills in this repo, update the `.md` file and re-copy to `~/.claude/rules/`.
