# Security Policy

## What This Repository Contains

This repository contains **public-safe configuration scaffolding** only:
- Example config files with placeholder values
- Bootstrap and verification scripts
- Documentation and catalogs

## What This Repository Must Never Contain

| Category | Examples | Handling |
|----------|----------|----------|
| API keys & tokens | `ANTHROPIC_AUTH_TOKEN`, `OPENAI_API_KEY`, `NVAPI_*`, `BRIGHT_DATA_API_TOKEN` | Use `$ENV_VAR` placeholders |
| OAuth credentials | `client_secret.json`, `oauth_creds.json`, `credentials.enc` | Listed in `.gitignore`, stored in private overlay |
| SSH keys | `~/.ssh/id_*` | Never referenced in this repo |
| Cookies & sessions | `token_cache.json`, `history.jsonl` | Listed in `.gitignore` |
| Proprietary instructions | Custom system prompts with internal IP | Strip before committing |
| Personal identifiers | Email, employee IDs, internal hostnames | Replace with `<YOUR_*>` |

## Redaction Rules

Before committing any config file:

1. Run `bootstrap/verify.ps1 --security` to scan for common secret patterns.
2. Replace all tokens matching these patterns with environment variable references:

```
sk-[a-zA-Z0-9]{32,}       → $ANTHROPIC_AUTH_TOKEN
nvapi-[a-zA-Z0-9-_]{40,}  → $NVIDIA_API_KEY
AIza[a-zA-Z0-9-_]{35}     → $GOOGLE_API_KEY
[0-9a-f]{8}-[0-9a-f]{4}-... (UUID-style) → $SERVICE_API_TOKEN
```

3. Use `.example` suffix for any file that would otherwise contain secrets.
4. Document required environment variables in `templates/.env.example`.

## Private Overlay Pattern

Your actual credentials live in a **private overlay** — a directory or secret manager not tracked by this repository:

```
~/.env.local              # personal API keys (source in shell profile)
~/.config/*/secrets/      # per-tool credential directories
```

Never symlink or copy private overlay files into this repository.

## Reporting a Security Issue

If you discover a secret accidentally committed to this repository, please:
1. Open a private security advisory on GitHub.
2. Do not open a public issue.
3. Include the commit SHA and affected file path.

## Audit Checklist for Pull Requests

- [ ] No tokens, keys, or passwords in diff
- [ ] No personal email addresses or internal hostnames
- [ ] `.env.example` updated if new env vars introduced
- [ ] `.gitignore` updated if new secret file patterns introduced
- [ ] `verify.ps1` / `verify.sh` passes cleanly
