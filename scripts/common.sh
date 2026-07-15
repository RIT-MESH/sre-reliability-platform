#!/usr/bin/env bash
# Shared helpers for sre-reliability-platform scripts.
# Sourced by other scripts; not meant to be run directly.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Colors (disabled when output is not a TTY).
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_RESET=""
fi

log()  { printf '%s[INFO]%s %s\n'  "$C_GREEN"  "$C_RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()  { printf '%s[ERROR]%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

# require_cmd <name>...  -> die if any command is missing.
require_cmd() {
  local missing=()
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || missing+=("$c")
  done
  [ ${#missing[@]} -eq 0 ] || die "Missing required commands: ${missing[*]}"
}

# confirm <prompt>  -> exit non-zero unless user types y/yes.
confirm() {
  local prompt="$1"
  printf '%s [y/N]: ' "$prompt"
  read -r ans
  case "${ans,,}" in y|yes) return 0;; *) die "Aborted by user.";; esac
}

usage() {
  [ $# -gt 0 ] && printf 'Usage: %s\n' "$1" >&2
  exit 2
}
