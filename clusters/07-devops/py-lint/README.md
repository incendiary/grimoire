# py-lint

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-10-09

One fast Python-only gate: Ruff and Black check (with optional safe auto-fix and
re-check), a standard config template, and the scoped pylint exceptions for recurring
false positives. Replaces four earlier Python lint skills (see
`scripts/renamed-skills.txt`).

---

## What this skill does

- Runs `ruff check` and `black --check` in one command (`lint-gate.sh`), or `--fix`
  (`ruff check --fix` + `black`) then re-validates, optionally on staged files only
- Ships `pyproject.toml`, `.pre-commit-config.yaml` (pinned revisions) and `.pylintrc`
  templates
- Documents writing-time patterns that pass Black and Ruff first time
- Applies scope-targeted pylint disables:

| Violation | Context | Fix |
|-----------|---------|-----|
| `W0621` redefined-outer-name | Pytest fixture imports | File-level disable in test files |
| `E0401` import-error | Pytest in some configs | `extension-pkg-allow-list=pytest` in `.pylintrc` |
| `R0914` too-many-locals | Crypto/algorithm functions | Inline function-level disable |

---

## When to use it

- You are about to commit Python code
- CI fails on Ruff, Black or pylint
- You are setting up formatting or pre-commit for a Python project
- You are writing Python in a repo that uses Ruff or Black

For the whole CI workflow use `ci-local`.

---

## Invocation

**Explicit:**
```
/py-lint
Target: .
Mode: --check
```

**Implicit** — describe your task and Claude recognises the trigger:
```
Run the Python lint gate and auto-fix what is safe.
```

---

## Quick reference

```bash
# Check only
bash clusters/07-devops/py-lint/lint-gate.sh --check

# Safe auto-fix + re-check
bash clusters/07-devops/py-lint/lint-gate.sh --fix

# Scope to a path, or staged files only
bash clusters/07-devops/py-lint/lint-gate.sh --check --target src/
bash clusters/07-devops/py-lint/lint-gate.sh --check --staged
```

---

## Workflow

```
Write code using formatter-stable + Ruff-friendly patterns
   ↓
lint-gate.sh --check
   ↓
Failures? --fix, review git diff, re-stage
   ↓
Remaining: narrow, justified suppressions only (pylint repos: see SKILL.md)
   ↓
Commit
```

---

## What it won't do

- Replace project-specific lint policy (`ruff.toml`, `pyproject.toml` still win)
- Force blanket `# noqa` or broad pylint disables
- Run non-Python CI steps (use `ci-local`)

---

## Common violations: before/after

**F401: module imported but unused**

```python
# Before
import os
import json
from pathlib import Path

def read_config(path: str) -> dict:
    with open(path) as f:
        return json.load(f)
```

```python
# After: remove the unused imports
import json

def read_config(path: str) -> dict:
    with open(path) as f:
        return json.load(f)
```

*If the import is needed at runtime but not at type-check time (e.g. a plugin loaded
via `importlib`), use `# noqa: F401` with a comment explaining why.*

---

**F841: local variable is assigned but never used**

```python
# Before
def process(items: list[str]) -> int:
    result = [item.strip() for item in items]  # assigned but never returned/used
    return len(items)
```

```python
# After: remove the unused assignment or use it
def process(items: list[str]) -> int:
    return len(items)
```

*Common cause: a variable computed during refactoring whose use was removed. Check
before deleting, as the computation may have a side effect you need to preserve.*

---

**E722: bare `except` clause**

```python
# Before
try:
    data = fetch_remote()
except:
    data = None
```

```python
# After: name the exceptions you expect
try:
    data = fetch_remote()
except (ConnectionError, TimeoutError):
    data = None
```

*If you genuinely need to catch everything (e.g. a top-level crash handler), use
`except Exception` and log the error. Bare `except` also catches `KeyboardInterrupt`
and `SystemExit`, which is almost never what you want.*

---

**B904: `raise` inside `except` without `from`**

```python
# Before: loses the original traceback
def load(path: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError:
        raise ValueError(f"Invalid JSON in {path}")
```

```python
# After: chain the exception to preserve context
def load(path: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError as err:
        raise ValueError(f"Invalid JSON in {path}") from err
```

*`from err` preserves the original exception as `__cause__`, making tracebacks far
more useful in production.*

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Gate script for check/fix modes, with staged-files-only mode
- [x] `.pre-commit-config.yaml`, `pyproject.toml` and `.pylintrc` templates
- [x] pytest import handling hints for mixed Ruff/pylint repos
- [x] Before/after examples for common Ruff violations (F401, F841, E722, B904)
