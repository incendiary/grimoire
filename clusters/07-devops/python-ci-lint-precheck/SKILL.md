# python-ci-lint-precheck

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Run pylint and ruff locally before committing to catch CI failures before they happen.
Adds standard disable comments for pytest fixtures and functions that legitimately exceed
local-variable limits.

Invoke when: a Python project uses pylint in CI, has pytest tests, or has crypto/
algorithm functions that routinely exceed pylint's `too-many-locals` threshold.
Trigger phrases: "set up lint", "pre-commit for this Python project", "CI kept failing
on pylint".

## Context needed
- Whether the project uses pylint in CI (vs ruff only)
- Whether the project has pytest tests (affects W0621 fixture handling)
- Line length setting from `pyproject.toml` or `setup.cfg`

## What to do

1. **Run ruff and pylint locally before every commit.** Do not rely on CI to catch
   lint errors — fix them before pushing:
   ```bash
   ruff check . && pylint <package>/ --disable=W0621,E0401
   ```

2. **Apply these standard disable comments at the point of declaration, not at the
   top of the file:**

   For pytest test files — unused import false positives:
   ```python
   # pylint: disable=W0621  # redefined-outer-name (pytest fixture)
   ```
   Add to the top of each test file that imports fixtures.

   For functions with more than 15 local variables (crypto, parsing, algorithm
   implementations):
   ```python
   def decrypt_payload(ciphertext, key, iv):  # pylint: disable=too-many-locals
   ```
   Add inline on the function definition, not as a file-wide disable.

3. **Do not add broad file-level disables.** Disable at the smallest scope
   (function or line) that addresses the specific violation. File-level disables
   hide real problems.

## Gotchas
- pytest fixtures trigger `W0621` (redefined-outer-name) because the fixture name
  shadows the import. This is a pylint false positive for pytest. Disable at test
  file level only, not globally.
- `E0401` (import-error) fires for pytest itself in some configurations. Add
  `extension-pkg-allow-list=pytest` to `.pylintrc` rather than disabling per-file.
- `R0914` (too-many-locals) in pycryptodome and similar libraries is expected.
  Disable at function level with an inline comment, not at file level.
- Black and ruff can conflict on import sort order if both are configured for isort.
  Use ruff's `isort` rules and disable isort in any black configuration.

## Suggested scripts
- `.pre-commit-config.yaml` hook: `ruff check` + `pylint --disable=W0621,E0401` on
  test files as a pre-commit check before any CI run
