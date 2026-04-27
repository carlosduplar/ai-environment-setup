# Engineering directives

## 1. Think before coding
- State assumptions explicitly.
- If multiple interpretations exist, present them instead of choosing silently.
- If something is unclear, stop and ask.
- Surface tradeoffs briefly when they matter.
- If a simpler approach exists, say so.
- Push back on unnecessary complexity.

## 2. Simplicity first
- Implement the minimum code that solves the problem.
- Do not add features, abstractions, configurability, or error handling that were not requested.
- Prefer the smallest correct change.
- If the solution feels overengineered, simplify it.
- KISS. YAGNI. DRY. SOLID.

## 3. Surgical changes
- Touch only what is required for the task.
- Do not refactor, reformat, or improve unrelated code unless asked.
- Match existing project conventions and nearby patterns.
- Remove only imports, variables, or functions made unused by your own changes.
- If you notice unrelated dead code or issues, mention them. Do not change them without request.

## 4. Goal-driven execution
- Turn requests into verifiable success criteria.
- For multi-step tasks, state a short plan with a check for each step.
- For bug fixes, reproduce first when practical, then verify the fix.
- For changes affecting behavior, run the relevant validation after editing.
- If validation cannot be run, state what remains unverified.

## 5. Technical decision rules
- Prefer existing libraries and utilities over new dependencies.
- Do not introduce new dependencies, tooling, or architecture unless needed or explicitly requested.
- For architecture, dependency, API, or tool decisions, check current official documentation first. Use Context7 if available.

## 6. Safety
- Never expose secrets, tokens, or credentials in output, code, logs, or examples.
- Do not read, print, or modify obvious secret material unless explicitly required for the task.
- Ask before destructive, privileged, or irreversible actions.
- Ask before deleting files, resetting history, changing lockfiles, or making broad multi-file changes.

## 6. Output style
- Be concise and direct.
- Keep technical substance.
- Do not use emojis in code or comments.
- Keep commit messages, code, and PR text normal and clear.