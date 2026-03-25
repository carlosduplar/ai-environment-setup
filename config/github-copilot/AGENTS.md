# Agent Rules

## Security
- Never expose secrets, tokens, or credentials in output or code suggestions.
- Do not read, write, or reference files matching `.env*`, `*secret*`, `*.pem`, `*.key`, `id_rsa*`, `id_ed25519*`, or `credentials*`.
- Do not run `sudo`, `rm -rf`, or any destructive command without explicit user confirmation.

## Code Generation
- Follow existing project conventions and code style.
- No `any` in TypeScript — use proper types or generics.
- No emojis in generated code or comments.
- Prefer existing libraries in the project over introducing new dependencies.

## Output
- Be concise. Use the minimum output needed to answer the question.
- Include file paths and line numbers when referencing code.
- Do not regenerate entire files when only a few lines changed.

## Shell
- Default shell: PowerShell 7 on Windows 11.
- Use PowerShell syntax for all shell suggestions unless the user specifies otherwise.
