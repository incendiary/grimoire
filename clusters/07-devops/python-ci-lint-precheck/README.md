# python-ci-lint-precheck

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Prevents the push–fail–fix–push loop caused by pylint CI failures that could have been
caught locally. Bakes in the standard disable comments for pytest fixtures and
high-local-variable functions so they are applied correctly the first time.

Extracted after pylint CI failures occurred 6 times in a single session across multiple
repos, always for the same three violation types.

---

## What this skill does

Enforces a local lint run before every commit, and applies the correct scope-targeted
disable comments for recurring false positives:

| Violation | Context | Fix |
|-----------|---------|-----|
| `W0621` redefined-outer-name | Pytest fixture imports | File-level disable in test files |
| `E0401` import-error | Pytest in some configs | `extension-pkg-allow-list=pytest` in `.pylintrc` |
| `R0914` too-many-locals | Crypto/algorithm functions | Inline function-level disable |

---

## When to use it

Load this skill at the start of any Python session where:
- The project uses pylint in CI (not just ruff)
- The project has pytest tests
- Any function handles crypto, parsing, or algorithm work with many locals

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/python-ci-lint-precheck ~/.claude/skills/
```

---

## How to invoke it in a session

```
/python-ci-lint-precheck
Project uses: pylint + pytest
Functions to watch: decrypt_payload, parse_zone_file
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Add `.pylintrc` template with standard settings
- [x] Add ruff + pylint pre-commit hook snippet (via .pre-commit-config.yaml in format-before-commit)
- [ ] Test on Slice-N-Dice and DNSResolver
- [x] Ship: copy to `~/.claude/skills/python-ci-lint-precheck/`
