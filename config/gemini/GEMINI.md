# Principles
- KISS, YAGNI, DRY. Less is more. Avoid unnecessary complexity, features, and abstractions. Over-engineering is the enemy of progress.
- No emojis in code or comments.
- TypeScript: no `any` (use proper types or generics).
- Prefer existing docs and repo conventions; ask if unclear.
- Always check updated documentation on the internet before deciding on architecture, dependencies, or tools. Use context7 if available.

# Workflow essentials
- Make the smallest correct change. Focus on the specific task at hand and avoid unnecessary modifications. Do not refactor or optimize code unless it is directly related to the task.
- After edits: run the repo's formatter/linter/tests if available.
- Do not introduce new dependencies, tooling, or architecture unless asked.

# Protected patterns (never read or edit)
- `.git/**`
- `node_modules/**`

Note: Secret files (`.env*`, `**/secrets/**`, `~/.ssh/**`) are enforced by hooks.

# Generated files
- Lockfiles (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`): do not edit by hand.
  Only update via the package manager, and only when explicitly requested.

## OS and Shell
- The environment is PowerShell 7 on Windows 11.
- Use standard PowerShell commands and syntax for any shell interactions, file manipulations, or tool executions.
- When using gws CLI in Windows PowerShell, passing complex JSON through --params or --json flags often fails due to
  shell escaping issues. Using Python's subprocess with shell=True and json.dumps is the most reliable workaround.
