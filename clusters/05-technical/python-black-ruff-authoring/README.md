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

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Add before/after examples for common Ruff violations (F401, F841, E722, B904)
- [ ] Test on 3 Python repos with different Ruff profiles
