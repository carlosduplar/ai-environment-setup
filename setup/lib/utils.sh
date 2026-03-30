#!/usr/bin/env bash
# utils.sh — Shared helpers for setup shell scripts

_pass=0
_fail=0
_warn=0

step()  { echo -e "\n\033[36m── $1\033[0m"; }
ok()    { _pass=$((_pass+1));  echo -e "  \033[32m[+] $1\033[0m"; }
fail()  { _fail=$((_fail+1));  echo -e "  \033[31m[!] $1\033[0m"; }
warn()  { _warn=$((_warn+1));  echo -e "  \033[33m[~] $1\033[0m"; }
info()  { echo -e "  \033[90m[ ] $1\033[0m"; }

assert_command() {
    local name="$1"
    local hint="${2:-}"
    if ! command -v "$name" &>/dev/null; then
        echo "ERROR: $name not found. $hint" >&2
        exit 1
    fi
}

check_tool() {
    local name="$1"
    if command -v "$name" &>/dev/null; then
        local ver
        ver=$("$name" --version 2>&1 | head -1)
        ok "$name — $ver"
    else
        fail "$name — NOT FOUND"
    fi
}

check_file() {
    local path="$1"
    local label="${2:-$1}"
    if [[ -f "$path" ]]; then
        ok "$label exists"
    else
        fail "$label — MISSING at $path"
    fi
}

check_env() {
    local name="$1"
    if [[ -n "${!name:-}" ]]; then
        ok "$name set"
    else
        warn "$name — NOT SET"
    fi
}

load_env_file() {
    local env_file
    env_file="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.env.local"
    if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
        ok ".env.local loaded"
    else
        warn ".env.local not found. Copy templates/.env.example to .env.local"
    fi
}

run() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY-RUN] $*"
    else
        "$@"
    fi
}
