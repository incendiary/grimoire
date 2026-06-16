# python-black-ruff-authoring

> **Status:** COMPLETE
> **Cluster:** 05-technical
> **Type:** instructional

## Description
Write Python code that is compatible with standard lint/format pipelines on first pass,
especially Black + Ruff setups. Reduces avoidable lint churn by enforcing authoring
patterns that naturally satisfy common rules before checks run.

Invoke when: starting or editing Python code in repos that use `ruff`, `black`, or both.
Trigger phrases: "write clean Python", "make this pass ruff", "avoid linter churn",
"black-compatible style".

## Context needed
- Whether the repo uses `black`, `ruff format`, or both
- Ruff config source (`pyproject.toml`, `ruff.toml`, `.ruff.toml`)
- Line length and selected/ignored rule sets
- Whether type checking is enforced (`mypy`, `pyright`) and strictness level

## What to do

1. **Author for formatter stability.**
   - Prefer implicit line wrapping with parentheses over backslashes.
   - Use trailing commas in multiline literals/calls to keep Black diffs small.
   - Avoid manual vertical alignment and whitespace formatting.

2. **Author for Ruff correctness by default.**
   - Keep imports explicit and minimal; remove unused imports/locals immediately.
   - Use `_` or `_name` for intentionally unused variables.
   - Keep expressions simple and break apart overly long one-liners.
   - Prefer explicit exception types; avoid broad `except Exception` unless justified.

3. **Avoid broad suppression.**
   - Do not use file-wide `# noqa` unless there is a documented project exception.
   - If suppression is required, scope it to the smallest line/function and add rationale.

4. **Use a fast local check loop before commit.**
   ```bash
   ruff check .
   black --check .
   ```
   If formatting fails:
   ```bash
   black .
   ruff check . --fix
   ```

5. **Preserve readability while satisfying tools.**
   - Keep functions focused and short when practical.
   - Add concise docstrings/comments only where logic is non-obvious.
   - Prefer clear naming over abbreviation-heavy style.

## Gotchas
- `black` and `ruff format` can disagree in mixed setups. Follow project config and
  keep one formatter as canonical when both are present.
- Import-sort rules (`I`) and formatter choices can conflict if tooling is misconfigured.
  Respect repository defaults rather than forcing a global preference.
- Do not "fix" lint by adding blanket ignores. Treat ignores as exceptions with context.

## Suggested scripts
- Pre-commit hooks: `black` + `ruff check --fix` with pinned versions
- CI gate: `ruff check .` and `black --check .`
