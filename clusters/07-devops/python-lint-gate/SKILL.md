# python-lint-gate

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Runs a pre-commit quality gate for Python projects using Ruff and Black. First checks
for lint/format failures, then optionally applies safe fixes and re-validates. Designed
for fast feedback loops before commits and PRs.

Invoke when: about to commit Python code; CI repeatedly fails on Ruff/Black; you want
an automatic gate that catches common issues early.
Trigger phrases: "run python lint gate", "check this before commit", "fix ruff and black".

## Context needed
- Target path (`.` by default)
- Whether auto-fix mode is allowed (`--fix`) or check-only is required
- Repo policy on suppressions (`# noqa`, pylint disables)

## What to do

1. Run check mode by default:
   ```bash
   bash clusters/07-devops/python-lint-gate/lint-gate.sh --check
   ```

2. If issues are expected and safe auto-fix is desired:
   ```bash
   bash clusters/07-devops/python-lint-gate/lint-gate.sh --fix
   ```

3. Gate only a specific path when needed:
   ```bash
   bash clusters/07-devops/python-lint-gate/lint-gate.sh --check --target src/
   ```

4. If failures remain after `--fix`, follow the printed targeted guidance and keep
   suppressions narrow with rationale.

## Gotchas
- `--fix` is intentionally conservative; not all Ruff rules are auto-fixable.
- Black may reflow code after Ruff fixes; re-check is required and built in.
- Missing `ruff` or `black` exits with dependency error (exit code 2).
- This gate complements `python-black-ruff-authoring` (writing patterns) and
  `python-ci-lint-precheck` (broader lint strategy with pylint).

## Suggested scripts
- `lint-gate.sh` (included) — unified local gate for Ruff + Black
