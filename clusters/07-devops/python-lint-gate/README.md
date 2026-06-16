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
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Add gate script for check/fix modes
- [ ] Add optional staged-files-only mode
- [ ] Add pytest import handling hints for mixed Ruff/Pylint repos
