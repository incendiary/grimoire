# format-before-commit

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Enforces local format checks before every commit. Prevents the "fix formatting" commit
that appears after CI fails, and keeps PR diffs clean. Extracted after black formatting
failures occurred in CI across Phosphor, Slice-N-Dice, and DNSResolver in the same session.

---

## What this skill does

Establishes a two-step rule: check-mode first, auto-fix second, then re-stage and commit.
Provides the correct pre-commit hook snippet with pinned versions, and handles the
black-vs-ruff-format conflict on import sorting.

Pairs with `python-ci-lint-precheck` — run both before committing to any Python project
with CI.

---

## When to use it

Any Python project that runs `black --check` or `ruff format --check` in CI.

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/format-before-commit ~/.claude/skills/
```

---

## Quick reference

```bash
# Check mode (CI-equivalent)
black --check . && ruff format --check .

# Auto-fix mode
black . && ruff format .

# Re-stage after auto-fix
git add -u && git diff --staged   # review, then commit
```

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add `.pre-commit-config.yaml` snippet with current pinned versions
- [ ] Add pyproject.toml `[tool.black]` template with line-length
- [ ] Test on 3 Python repos
- [ ] Ship: copy to `~/.claude/skills/format-before-commit/`
