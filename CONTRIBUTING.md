# Contributing to sre-reliability-platform

Thanks for your interest in contributing! This is a portfolio project, but
contributions, improvements and corrections are welcome.

## Getting started

1. Fork and clone the repository.
2. Copy `.env.example` to `.env` and adjust values (never commit `.env`).
3. Install pre-commit hooks: `pip install pre-commit && pre-commit install`.
4. Start the local stack: `make up`.

## Development workflow

- Keep the FastAPI app hermetic: unit tests must pass with **no external
  services** (they use an in-memory SQLite + fake Redis).
- Run checks before pushing:
  ```bash
  pre-commit run --all-files
  cd app && pytest -q
  ```
- Terraform changes: run `terraform fmt` and `terraform validate` in the
  affected environment.
- Do not commit `*.tfstate`, `.terraform/`, secrets, or `.env`.

## Pull requests

- Use the PR template.
- Group changes logically and write meaningful commit messages
  (e.g. `feat: add Redis fallback metrics`).
- Add or update tests for application changes.
- Update docs when behaviour changes.

## Code style

- Python: `ruff` (lint + format), 4-space indent.
- Terraform: `terraform fmt`, 2-space indent.
- Shell: `set -euo pipefail`, shellcheck-clean.

## Reporting issues

Use the bug report or feature request issue templates.
