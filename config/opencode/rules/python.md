# Python rules

## Environment facts
- Python executable: `/usr/bin/python3`. The `python` command is not available.
- System Python is externally managed per PEP 668: never install into it.

## Command policy
- Never run bare `python`; use `/usr/bin/python3` for one-off scripts and ad hoc commands.
- `/usr/bin/python3 -m pip` only for inspection (`show`, `list`, `--version`) — never to install.
- Never run `pip install` globally or into the system Python.
- Do not install anything, or create a venv, unless explicitly asked.

## Running project tooling (tests, lint, format, type-check)
Never run project tooling — pytest, ruff, mypy, etc. — via the system Python (`python`, `python3`, or `/usr/bin/python3` directly). Always go through the project's own environment.

1. Inspect project config: `pyproject.toml`, `requirements*.txt`, `uv.lock`, `poetry.lock`, `tox.ini`, `noxfile.py`, `Makefile`, `README*`, `.github/workflows/*`.
2. Detect the project environment: `.venv/bin/python`, `uv`, `poetry`, `pdm`, `tox`, `nox`.
3. Use the matching command:
   - `uv run pytest ...` if `uv.lock` or uv config exists
   - `.venv/bin/python -m pytest ...` if `.venv` exists
   - `poetry run pytest ...` if `poetry.lock` exists
   - `tox ...` if `tox.ini` exists
   - `nox ...` if `noxfile.py` exists
4. If a tool isn't available in that environment, report it and suggest the minimal setup — don't install globally.
5. If no project environment exists at all, stop and report:
   "Project dependencies are not installed in an isolated environment. I will not use the system Python."
