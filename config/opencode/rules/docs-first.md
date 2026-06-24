# Documentation-first rules

Before writing code, modifying code, debugging, or proposing implementation details:

- Check latest relevant official documentation first.
- Prefer official docs, project docs, README, changelog, release notes, migration guides, and source examples.
- Use ctx7 CLI (find-docs skill) before coding.
- Do not rely on memory for APIs, framework behavior, CLI flags, config formats, dependency behavior, or error messages.
- Do not invent APIs, parameters, config keys, decorators, hooks, command options, or file formats.
- If documentation cannot be accessed, say so explicitly and mark the solution as based on local code inspection only.
- If docs and local code disagree, prefer local project conventions unless the task is specifically to upgrade or align with current docs.
