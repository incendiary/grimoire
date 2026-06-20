# python-lint-gate

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-16

Unified pre-commit gate for Python repos using Ruff + Black. It gives a single command
for check-only validation or safe auto-fix + re-check, with targeted guidance for
common remaining violations.

---

## What this skill does

- Runs `ruff check` and `black --check` in one gate command
- Supports `--fix` mode (`ruff check --fix` + `black`) then re-validates
- Prints practical guidance for common issues (`F401`, `F841`, `E722`, `B904`)
- Fails fast when dependencies are missing

This pairs well with:

- `python-black-ruff-authoring` for writing-time patterns
- `python-ci-lint-precheck` for pylint-aware lint workflows
- `format-before-commit` for formatting discipline

---

## When to use it

Use this skill when:

- You are about to commit Python code
- CI keeps failing on Black/Ruff
- You want one gate command for local validation

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/python-lint-gate ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:

```
#python-lint-gate
```

### VS Code / MCP client

This is an `action` skill and is available as a tool via the grimoire MCP server
after installation.

---

## Invocation

**Explicit:**

```bash
/python-lint-gate
Target: .
Mode: --check
```

**Natural language:**
"Run the Python lint gate and auto-fix what is safe."

---

## Quick reference

```bash
# Check only
bash clusters/07-devops/python-lint-gate/lint-gate.sh --check

# Safe auto-fix + re-check
bash clusters/07-devops/python-lint-gate/lint-gate.sh --fix

# Scope to a path
bash clusters/07-devops/python-lint-gate/lint-gate.sh --check --target src/

# Staged files only (pre-commit workflow)
bash clusters/07-devops/python-lint-gate/lint-gate.sh --check --staged
```

## pytest import handling

Ruff commonly flags `conftest.py` and `__init__.py` fixtures because their imports
are used implicitly by pytest's fixture injection, not via explicit import statements.

**Common false positive — F401 on conftest.py fixture:**

```python
# conftest.py
from mypackage.db import database_session  # Ruff flags this as F401
```

pytest uses `database_session` as a fixture name — Ruff can't see that. Fix options:

**Option 1 — per-file ignore in `pyproject.toml` (preferred):**
```toml
[tool.ruff.lint.per-file-ignores]
"conftest.py" = ["F401"]
"tests/__init__.py" = ["F401"]
```

**Option 2 — inline suppression (use when only one or two imports are affected):**
```python
from mypackage.db import database_session  # noqa: F401 — pytest fixture
```

**Pylint in the same repo:** if both Ruff and Pylint run, Pylint's `C0114`/`C0115`
(missing docstrings) will flag test files Ruff ignores. Add to `.pylintrc` or
`pyproject.toml`:
```toml
[tool.pylint."MESSAGES CONTROL"]
disable = ["C0114", "C0115", "C0116"]  # suppress missing-docstring for tests
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Add gate script for check/fix modes
- [x] Add optional staged-files-only mode
- [x] Add pytest import handling hints for mixed Ruff/Pylint repos
