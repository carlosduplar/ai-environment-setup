# Skills Catalog

Claude Code skills can be inspected with `npx skills ls --json`, updated with `npx skills update -g -y`, and added with `npx skills add <skill-name> -g -y`.

## All skills

| Skill | Description | Always Apply | Category |
|-------|-------------|-------------|----------|
| **bright-data-mcp** | Web data operations (scraping, search, browser automation) | No | Data |
| **context7-cli** | Fetch current library docs from Context7 | **Yes** | Dev Tools |
| canvas-design | Create `.png`/`.pdf` visual art | No | Design |
| doc-coauthoring | Guided documentation co-authoring workflow | No | Documentation |
| docs-maintainer | Create/update ADRs, CHANGELOG, README | No | Documentation |
| docx | Read/write `.docx` Word documents | No | Files |
| find-docs | Fetch library docs via Context7 | No | Dev Tools |
| find-skills | Discover and install new skills | No | Skills |
| frontend-design | Production-grade frontend UI generation | No | Design |
| gh-cli | GitHub CLI (`gh`) reference | No | Dev Tools |
| gws-calendar | Google Calendar operations | No | Google Workspace |
| gws-docs | Read/write Google Docs | No | Google Workspace |
| gws-drive | Google Drive file management | No | Google Workspace |
| gws-gmail | Gmail send/read/manage | No | Google Workspace |
| gws-keep | Google Keep notes | No | Google Workspace |
| gws-shared | Shared gws CLI patterns | No | Google Workspace |
| gws-sheets | Google Sheets read/write | No | Google Workspace |
| gws-tasks | Google Tasks management | No | Google Workspace |
| gws-workflow-email-to-task | Gmail → Google Tasks workflow | No | Google Workspace |
| gws-workflow-meeting-prep | Meeting prep from calendar + docs | No | Google Workspace |
| gws-workflow-standup-report | Standup summary from calendar + tasks | No | Google Workspace |
| gws-workflow-weekly-digest | Weekly calendar + email digest | No | Google Workspace |
| pdf | PDF read/create/merge/split | No | Files |
| playwright-cli | Browser automation via Playwright | No | Testing |
| pptx | PowerPoint file operations | No | Files |
| security-threat-modeler | Security review for auth, injection, secrets | No | Security |
| seo-audit | Technical SEO audit | No | Web |
| skill-creator | Create/modify/test skills | No | Skills |
| tech-lead-reviewer | Comprehensive code review | No | Code Review |
| test-writer | Write and run tests | No | Testing |
| vercel-react-best-practices | React/Next.js performance patterns | No | React |
| vercel-react-native-skills | React Native/Expo best practices | No | React Native |
| web-design-guidelines | UI/UX guidelines review | No | Design |
| webapp-testing | Local web app testing with Playwright | No | Testing |
| xlsx | Spreadsheet file operations | No | Files |

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

See bootstrap scripts for the full list of skills installed in this environment.
