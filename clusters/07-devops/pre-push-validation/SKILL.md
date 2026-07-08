# pre-push-validation

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description

Shift-left validation: runs all feasible local checks **before** push to GitHub, preventing avoidable CI failures.

**Repo-aware architecture**: The script automatically detects `.github/workflows/validate.yml` and runs the exact same checks that GitHub Actions would run — locally, in seconds, before you push.

- **For repos with CI workflows**: Parses `.github/workflows/validate.yml` and executes those exact checks locally
- **For generic repos**: Auto-detects tech stack (Node.js, Python, Go, Rust, C#, bash) and runs appropriate linters, formatters, and type checkers
- **For any repo**: Fast feedback loop — fail locally in 30s instead of waiting 10m for CI

Optionally installs a `pre-push` git hook for automatic enforcement on every push.

Invoke when: "validate before push", "run CI checks locally", "install push hook", "check everything before pushing".

## Context needed

- Current repository root (auto-detected via `git rev-parse --show-toplevel`)
- `.github/workflows/validate.yml` (automatically detected if present)
- Desired strictness: `--strict` for full test + security suite, or default for fast checks only

## Features

- **Workflow-aware validation**: Detects and runs checks from `.github/workflows/validate.yml` if present
- **Tech-stack auto-detection**: Scans for package.json, pyproject.toml, Cargo.toml, go.mod, *.csproj, *.sh files
- **Progressive validation**: Stops at first failure (fast feedback)
- **Detailed reporting**: Lists all checks run, pass/fail status, and failure details
- **Optional enforcement**: Git hook prevents push if validation fails
- **Customizable**: `--skip-check <name>`, `--strict`, `--dry-run` modes
- **Multi-language support**: Node.js (npm), Python (pytest/black/flake8), Go (gofmt/go vet), Rust (cargo), C#/.NET, bash (shellcheck)

## Example invocation

```bash
# See what would run (dry-run)
bash pre-push-validation.sh --dry-run

# Actually run all checks
bash pre-push-validation.sh

# Install automatic pre-push hook
bash pre-push-validation.sh --install-hook

# Run with full test suite
bash pre-push-validation.sh --strict

# Skip a specific check
bash pre-push-validation.sh --skip-check eslint
```
bash pre-push-validation.sh --install-hook

# Strict mode (includes full test suite + security)
bash pre-push-validation.sh --strict

# Skip a specific check
bash pre-push-validation.sh --skip-check format
```

## Implementation notes

The script:
1. Detects project type by scanning for language-specific config files
2. Builds a checklist of applicable validations (lint, format, type, test, security)
3. Runs each check in sequence, collecting pass/fail + error output
4. Reports results with exit code 0 (all pass) or 1 (first failure)
5. Optionally registers itself as `.git/hooks/pre-push` for automatic enforcement

The `pre-push` hook template is included for git integration.
