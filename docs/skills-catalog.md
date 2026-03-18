# Skills Catalog

Claude Code skills — reusable instruction files for sub-agents.

Install globally: `~/.claude/rules/<skill>.md`

## All skills

| Skill | File | Always Apply | Category |
|-------|------|-------------|----------|
| brand-guidelines | brand-guidelines.md | No | Design |
| canvas-design | canvas-design.md | No | Design |
| **context7-cli** | context7.md | **Yes** | Dev Tools |
| doc-coauthoring | doc-coauthoring.md | No | Documentation |
| docs-maintainer | docs-maintainer.md | No | Documentation |
| docx | docx.md | No | Files |
| find-docs | find-docs.md | No | Dev Tools |
| find-skills | find-skills.md | No | Skills |
| frontend-design | frontend-design.md | No | Design |
| gh-cli | gh-cli.md | No | Dev Tools |
| gws-calendar | gws-calendar.md | No | Google Workspace |
| gws-docs | gws-docs.md | No | Google Workspace |
| gws-drive | gws-drive.md | No | Google Workspace |
| gws-gmail | gws-gmail.md | No | Google Workspace |
| gws-keep | gws-keep.md | No | Google Workspace |
| gws-shared | gws-shared.md | No | Google Workspace |
| gws-sheets | gws-sheets.md | No | Google Workspace |
| gws-tasks | gws-tasks.md | No | Google Workspace |
| gws-workflow-email-to-task | gws-workflow-email-to-task.md | No | Google Workspace |
| gws-workflow-meeting-prep | gws-workflow-meeting-prep.md | No | Google Workspace |
| gws-workflow-standup-report | gws-workflow-standup-report.md | No | Google Workspace |
| gws-workflow-weekly-digest | gws-workflow-weekly-digest.md | No | Google Workspace |
| mcp-builder | mcp-builder.md | No | Dev Tools |
| pdf | pdf.md | No | Files |
| playwright-cli | playwright-cli.md | No | Testing |
| pptx | pptx.md | No | Files |
| security-threat-modeler | security-threat-modeler.md | No | Security |
| seo-audit | seo-audit.md | No | Web |
| skill-creator | skill-creator.md | No | Skills |
| tech-lead-reviewer | tech-lead-reviewer.md | No | Code Review |
| test-writer | test-writer.md | No | Testing |
| vercel-react-best-practices | vercel-react-best-practices.md | No | React |
| vercel-react-native-skills | vercel-react-native-skills.md | No | React Native |
| web-artifacts-builder | web-artifacts-builder.md | No | Design |
| web-design-guidelines | web-design-guidelines.md | No | Design |
| webapp-testing | webapp-testing.md | No | Testing |
| xlsx | xlsx.md | No | Files |

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
