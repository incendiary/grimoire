# format-before-commit

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Run black and ruff format locally before every commit to prevent formatting CI failures.
Never commit code that has not passed a local format check.

Invoke when: a Python project uses black or ruff format in CI. Trigger phrases:
"set up formatting", "pre-commit for this project", or when a CI run fails on black
or ruff format errors.

## Context needed
- Whether the project uses black, ruff format, or both
- Line length from `pyproject.toml` (default 88 for black, 88 for ruff)
- Whether isort is configured separately or via ruff's `isort` rules

## What to do

1. **Before any `git commit`, run the formatter in check mode first:**
   ```bash
   black --check . && ruff format --check .
   ```
   If either fails, run the auto-fix version, review the diff, then re-stage:
   ```bash
   black . && ruff format .
   git diff          # review what changed
   git add -u        # re-stage formatted files
   git commit ...
   ```

2. **Add a pre-commit hook** so the check runs automatically:
   ```yaml
   # .pre-commit-config.yaml
   - repo: https://github.com/psf/black
     rev: 24.3.0
     hooks:
       - id: black
   - repo: https://github.com/astral-sh/ruff-pre-commit
     rev: v0.3.4
     hooks:
       - id: ruff-format
   ```
   Pin versions. Do not use `latest`.

3. **When a format check fails in CI, fix locally before pushing another commit.**
   Do not add a "fix formatting" commit on top of the broken one — squash or amend
   before the PR is reviewed.

## Gotchas
- Black and ruff format can conflict if both are managing import sort order. Use
  ruff's `isort` rules (`select = ["I"]` in `ruff.toml`) and disable isort from
  black's configuration entirely.
- Some projects have a custom `line-length` in `pyproject.toml`. Always read the
  project config before running with defaults.
- `black --check` exits with a non-zero code if any file would be reformatted.
  This is expected behaviour — it means files need formatting, not that black failed.
- Blank line changes are a common black modification. They are correct — black enforces
  PEP 8 blank line rules that the developer may not notice.

## Suggested scripts
- `.pre-commit-config.yaml` snippet with pinned black and ruff-format hooks
