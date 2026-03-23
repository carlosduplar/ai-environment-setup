# Skills Catalog

Claude Code skills — reusable instruction files for sub-agents.

Install globally: `~/.claude/rules/<skill>.md`

## All skills

| Skill | Description | File | Always Apply | Category |
|-------|-------------|------|-------------|----------|
| brand-guidelines | Anthropic brand colors and typography | brand-guidelines.md | No | Design |
| canvas-design | Create `.png`/`.pdf` visual art | canvas-design.md | No | Design |
| **context7-cli** | Fetch current library docs from Context7 | context7.md | **Yes** | Dev Tools |
| doc-coauthoring | Guided documentation co-authoring workflow | doc-coauthoring.md | No | Documentation |
| docs-maintainer | Create/update ADRs, CHANGELOG, README | docs-maintainer.md | No | Documentation |
| docx | Read/write `.docx` Word documents | docx.md | No | Files |
| find-docs | Fetch library docs via Context7 | find-docs.md | No | Dev Tools |
| find-skills | Discover and install new skills | find-skills.md | No | Skills |
| frontend-design | Production-grade frontend UI generation | frontend-design.md | No | Design |
| gh-cli | GitHub CLI (`gh`) reference | gh-cli.md | No | Dev Tools |
| gws-calendar | Google Calendar operations | gws-calendar.md | No | Google Workspace |
| gws-docs | Read/write Google Docs | gws-docs.md | No | Google Workspace |
| gws-drive | Google Drive file management | gws-drive.md | No | Google Workspace |
| gws-gmail | Gmail send/read/manage | gws-gmail.md | No | Google Workspace |
| gws-keep | Google Keep notes | gws-keep.md | No | Google Workspace |
| gws-shared | Shared gws CLI patterns | gws-shared.md | No | Google Workspace |
| gws-sheets | Google Sheets read/write | gws-sheets.md | No | Google Workspace |
| gws-tasks | Google Tasks management | gws-tasks.md | No | Google Workspace |
| gws-workflow-email-to-task | Gmail → Google Tasks workflow | gws-workflow-email-to-task.md | No | Google Workspace |
| gws-workflow-meeting-prep | Meeting prep from calendar + docs | gws-workflow-meeting-prep.md | No | Google Workspace |
| gws-workflow-standup-report | Standup summary from calendar + tasks | gws-workflow-standup-report.md | No | Google Workspace |
| gws-workflow-weekly-digest | Weekly calendar + email digest | gws-workflow-weekly-digest.md | No | Google Workspace |
| mcp-builder | Build MCP servers (FastMCP/MCP SDK) | mcp-builder.md | No | Dev Tools |
| pdf | PDF read/create/merge/split | pdf.md | No | Files |
| playwright-cli | Browser automation via Playwright | playwright-cli.md | No | Testing |
| pptx | PowerPoint file operations | pptx.md | No | Files |
| security-threat-modeler | Security review for auth, injection, secrets | security-threat-modeler.md | No | Security |
| seo-audit | Technical SEO audit | seo-audit.md | No | Web |
| skill-creator | Create/modify/test skills | skill-creator.md | No | Skills |
| tech-lead-reviewer | Comprehensive code review | tech-lead-reviewer.md | No | Code Review |
| test-writer | Write and run tests | test-writer.md | No | Testing |
| vercel-react-best-practices | React/Next.js performance patterns | vercel-react-best-practices.md | No | React |
| vercel-react-native-skills | React Native/Expo best practices | vercel-react-native-skills.md | No | React Native |
| web-artifacts-builder | Multi-component HTML artifacts | web-artifacts-builder.md | No | Design |
| web-design-guidelines | UI/UX guidelines review | web-design-guidelines.md | No | Design |
| webapp-testing | Local web app testing with Playwright | webapp-testing.md | No | Testing |
| xlsx | Spreadsheet file operations | xlsx.md | No | Files |

## Installing all skills

```powershell
# Copy all skills from this repo to Claude Code
$src = "skills\catalog"
$dst = "$env:USERPROFILE\.claude\rules"
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Get-ChildItem "$src\*.md" | Copy-Item -Destination $dst -Force
Write-Host "Installed $(Get-ChildItem $src\*.md | Measure-Object | Select-Object -Expand Count) skills"
```

Note: Skills not in `catalog/` are installed via the `skill-creator` skill directly in Claude Code and are fetched from the official skills registry. They do not need to be stored in this repo.
