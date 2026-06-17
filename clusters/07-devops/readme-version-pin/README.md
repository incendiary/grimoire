# readme-version-pin

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-07

Keeps README install instructions pinned to the latest tagged release. Prevents users
from cloning `main` (which may be ahead of or behind the last stable release) by
rewriting install code blocks on every release cut.

---

## What this skill does

- Detects the current version from `VERSION` file, git tag, or `pyproject.toml`
- Rewrites `@main`, `@master`, and old tag refs in all README files to the current version
- Provides a check script that exits 1 on any mismatch — usable as a pre-commit hook or CI gate

---

## When to use it

- After cutting a new release (run `pin_readme_version.sh`, commit, done)
- Any time README install instructions reference `main` or an outdated tag
- To add a CI gate that keeps pins fresh automatically

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/readme-version-pin ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#readme-version-pin
```

### MCP client

Register the grimoire MCP server — this skill is exposed as tool `readme_version_pin`.

> **Note:** This is an `action` type skill — available as MCP tool, prompt file, and Claude Code.


---

## Quick start

```bash
# Dry run — see what would change
bash pin_readme_version.sh --dry-run

# Apply pins
bash pin_readme_version.sh

# Verify (pre-commit / CI)
bash check_readme_version.sh
```

---

## Pre-commit hook

```yaml
- repo: local
  hooks:
    - id: readme-version-pin
      name: README version pin check
      language: script
      entry: bash check_readme_version.sh
      pass_filenames: false
      always_run: true
```

---

## Roadmap

- [x] SKILL.md written: workflow, patterns, release integration, pre-commit wiring
- [x] README.md written
- [x] Write `pin_readme_version.sh` — detect version, rewrite README pins, `--dry-run` flag
- [x] Write `check_readme_version.sh` — assert all pins match current version, exit 1 on mismatch
- [x] Ship: copy to `~/.claude/skills/readme-version-pin/`
- [x] Add `--pattern` flag to `pin_readme_version.sh` for custom install line formats
- [ ] Test on DNSResolver and Slice-N-Dice release cuts
