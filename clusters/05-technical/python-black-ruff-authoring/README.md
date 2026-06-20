# python-black-ruff-authoring

> **Cluster:** 05-technical | **Status:** complete | **Added:** 2026-06-16

Authoring guardrails for Python code that should pass Black and Ruff with minimal rework.
The goal is to write code in a style that is lint/format compatible by default, instead
of relying on post-hoc cleanup.

---

## What this skill does

This skill sets writing-time conventions that reduce lint churn:

- formatter-stable structure (parenthesized wrapping, trailing commas)
- Ruff-friendly patterns (clean imports, explicit unused vars, scoped exceptions)
- narrow suppression policy (line/function-level only, with rationale)
- short local check loop before commits

It complements `format-before-commit` and `python-ci-lint-precheck`:

- this skill guides **how to write**
- those skills enforce **how to validate before push**

---

## When to use it

Load this at the start of Python implementation sessions when:

- you are generating or refactoring Python code
- the repo uses `black`, `ruff`, or both
- you want fewer formatter/linter follow-up commits

---

## Installation

### Claude Code

```bash
cp -r clusters/05-technical/python-black-ruff-authoring ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:

```
#python-black-ruff-authoring
```

### VS Code / MCP

This is an `instructional` skill (guidance only), not an MCP action tool.
Use it as prompt context in chat sessions.

---

## Invocation

**Explicit:**

```
/python-black-ruff-authoring
Repo uses black + ruff. Generate module code in compatible style.
```

**Implicit:**

```
Write this Python module so it is likely to pass standard black/ruff checks.
```

---

## Workflow

```
Load skill before coding
   ↓
Write code using formatter-stable + Ruff-friendly patterns
   ↓
Run ruff check + black --check locally
   ↓
Apply targeted fixes (no blanket suppressions)
   ↓
Commit
```

---

## What it won't do

- Replace project-specific lint policy (`ruff.toml`, `pyproject.toml` still win)
- Force blanket `# noqa` or broad pylint disables
- Replace CI enforcement or pre-commit hooks

---

## Common violations — before/after

One pair per violation. Each "before" is code that triggers the rule; each "after"
is the fix. All examples are minimal and self-contained.

---

**F401 — module imported but unused**

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
# After — remove the unused imports
import json

def read_config(path: str) -> dict:
    with open(path) as f:
        return json.load(f)
```

*If the import is needed at runtime but not at type-check time (e.g. a plugin loaded
via `importlib`), use `# noqa: F401` with a comment explaining why.*

---

**F841 — local variable is assigned but never used**

```python
# Before
def process(items: list[str]) -> int:
    result = [item.strip() for item in items]  # assigned but never returned/used
    return len(items)
```

```python
# After — remove the unused assignment or use it
def process(items: list[str]) -> int:
    return len(items)
```

*Common cause: a variable computed during refactoring whose use was removed. Check
before deleting — the computation may have a side effect you need to preserve.*

---

**E722 — bare `except` clause**

```python
# Before
try:
    data = fetch_remote()
except:
    data = None
```

```python
# After — name the exceptions you expect
try:
    data = fetch_remote()
except (ConnectionError, TimeoutError):
    data = None
```

*If you genuinely need to catch everything (e.g. a top-level crash handler), use
`except Exception` and log the error. Bare `except` also catches `KeyboardInterrupt`
and `SystemExit`, which is almost never what you want.*

---

**B904 — `raise` inside `except` without `from`**

```python
# Before — loses the original traceback
def load(path: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError:
        raise ValueError(f"Invalid JSON in {path}")
```

```python
# After — chain the exception to preserve context
def load(path: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError as err:
        raise ValueError(f"Invalid JSON in {path}") from err
```

*`from err` preserves the original exception as `__cause__`, making tracebacks
far more useful in production. Ruff flags the missing `from` to prevent silent
context loss.*

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Add before/after examples for common Ruff violations (F401, F841, E722, B904)
- [ ] Test on 3 Python repos with different Ruff profiles
