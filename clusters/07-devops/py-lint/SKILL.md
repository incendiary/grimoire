---
name: py-lint
description: "Runs a Ruff and Black gate on Python code (check, then optional safe fixes and re-check), with a standard pyproject config template and pylint exceptions for pytest fixtures and long algorithm functions. Use when asked to 'lint this', 'fix ruff and black', 'set up formatting', or when CI fails on Python formatting. For the whole CI workflow use ci-local."
---
# py-lint

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Fast, Python-only lint and format gate: Ruff and Black in check mode, optional safe
auto-fix with built-in re-check, a standard `pyproject.toml` and `.pre-commit-config.yaml`
to drop into a project, and the scoped pylint exceptions that stop recurring CI failures.
Never commit Python that has not passed a local check.

Invoke when: about to commit Python code; CI fails on Ruff, Black or pylint; setting up
formatting or pre-commit for a Python project; writing Python in a repo that uses Ruff or Black.
Trigger phrases: "lint this", "fix ruff and black", "set up formatting", "pre-commit for
this project", "run python lint gate", "check this before commit", "write clean Python",
"make this pass ruff", "avoid linter churn", "black-compatible style", "set up lint",
"CI kept failing on pylint".

## Context needed
- Target path (`.` by default)
- Whether auto-fix mode is allowed (`--fix`) or check-only is required
- Whether the project uses black, ruff format, or both, and where Ruff config lives
  (`pyproject.toml`, `ruff.toml`, `.ruff.toml`)
- Line length and selected/ignored rule sets (default 88)
- Whether the project uses pylint in CI and has pytest tests
- Whether type checking is enforced (`mypy`, `pyright`) and its strictness
- Repo policy on suppressions (`# noqa`, pylint disables)

## Writing code that passes first time

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

## Gate

1. Run check mode by default (Ruff check + Black check):
   ```bash
   bash clusters/07-devops/py-lint/lint-gate.sh --check
   ```

2. If issues are expected and safe auto-fix is desired (Ruff fix + Black, then re-check):
   ```bash
   bash clusters/07-devops/py-lint/lint-gate.sh --fix
   ```
   Review `git diff`, re-stage with `git add -u`, then commit.

3. Gate only a specific path, or only staged Python files:
   ```bash
   bash clusters/07-devops/py-lint/lint-gate.sh --check --target src/
   bash clusters/07-devops/py-lint/lint-gate.sh --check --staged
   ```

4. If failures remain after `--fix`, follow the printed targeted guidance and keep
   suppressions narrow with rationale.

5. When a format check fails in CI, fix locally before pushing another commit. Do not
   add a "fix formatting" commit on top of the broken one: squash or amend before the
   PR is reviewed.

Exit codes: 0 gate passed, 1 issues remain, 2 usage or dependency error (missing `ruff`
or `black`; `.venv/bin` binaries are used as a fallback).

## Config template

`pyproject.toml` (in this directory) holds the standard `[tool.black]`, `[tool.ruff]`,
`[tool.ruff.lint]` (rules E, W, F, I, B, C4, UP; E501 and B008 ignored), isort,
per-file-ignores, pytest and coverage settings. Always read the project's own config
first: a custom `line-length` wins over the template.

`.pre-commit-config.yaml` (in this directory) runs gitleaks, file hygiene hooks, black,
ruff, ruff-format and shellcheck with pinned revisions. Pin versions; never use `latest`.
Minimal formatting-only form:
```yaml
- repo: https://github.com/psf/black
  rev: 24.3.0
  hooks:
    - id: black
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.3.4
  hooks:
    - id: ruff-format
```

## pylint exceptions

Only for repos that run pylint in CI. `.pylintrc` (in this directory) is the baseline.

1. **Run ruff and pylint locally before every commit.** Do not rely on CI:
   ```bash
   ruff check . && pylint <package>/ --disable=W0621,E0401
   ```

2. **Apply these standard disable comments at the point of declaration, not at the top
   of the file.**

   Pytest test files, redefined-outer-name false positive (add at the top of each test
   file that imports fixtures):
   ```python
   # pylint: disable=W0621  # redefined-outer-name (pytest fixture)
   ```

   Functions with more than 15 local variables (crypto, parsing, algorithm
   implementations), inline on the definition:
   ```python
   def decrypt_payload(ciphertext, key, iv):  # pylint: disable=too-many-locals
   ```

3. **Do not add broad file-level disables.** Disable at the smallest scope (function or
   line) that addresses the specific violation.

### pytest import handling
Ruff flags `conftest.py` and `__init__.py` fixture imports as F401 because pytest uses
them implicitly. Preferred fix, per-file ignore in `pyproject.toml`:
```toml
[tool.ruff.lint.per-file-ignores]
"conftest.py" = ["F401"]
"tests/__init__.py" = ["F401"]
```
Or inline when only one or two imports are affected:
```python
from mypackage.db import database_session  # noqa: F401 (pytest fixture)
```
If both Ruff and pylint run, pylint's `C0114`/`C0115` (missing docstrings) flag test
files Ruff ignores:
```toml
[tool.pylint."MESSAGES CONTROL"]
disable = ["C0114", "C0115", "C0116"]
```

## Gotchas
- `--fix` is intentionally conservative; not all Ruff rules are auto-fixable.
- Black may reflow code after Ruff fixes; the re-check is built in.
- `black --check` exiting non-zero means files need formatting, not that black failed.
- Blank line changes are a common black modification and are correct (PEP 8).
- Black and `ruff format` can conflict if both manage import sort order. Use Ruff's
  `isort` rules (`select = ["I"]`) and keep one formatter canonical; disable isort in
  any black configuration. Respect repository defaults rather than forcing a preference.
- pytest fixtures trigger `W0621` (redefined-outer-name): a pylint false positive.
  Disable at test-file level only, not globally.
- `E0401` (import-error) fires for pytest itself in some configurations. Add
  `extension-pkg-allow-list=pytest` to `.pylintrc` rather than disabling per-file.
- `R0914` (too-many-locals) in pycryptodome and similar libraries is expected. Disable
  at function level with an inline comment.
- Do not "fix" lint by adding blanket ignores. Treat ignores as exceptions with context.

## Related
- `ci-local`: runs the whole CI workflow locally. `py-lint` is the fast Python-only gate.

## Suggested scripts
- `lint-gate.sh` (included): unified local gate for Ruff + Black
- `pyproject.toml`, `.pre-commit-config.yaml`, `.pylintrc` (included): config templates
