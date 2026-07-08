# github-actions-locally

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-07-01

Run GitHub Actions workflows locally before pushing. Discovers linting and test jobs from `.github/workflows/`, executes them on your machine, auto-fixes issues (black, ruff, prettier, eslint), and reports results. Catch CI failures fast, not after pushing.

---

## What this skill does

Shifts CI validation left by executing the same linting and test commands locally that GitHub Actions would run. Parses workflow files, runs jobs, captures failures, auto-applies fixes where possible, and generates a report. Always exits with status 0 (allow) so you see the report and decide what to do.

**Before:** Push → wait 5 min for CI → find linting error → fix → push again → repeat

**After:** Run locally → see failures immediately → auto-fix → commit → push (usually passes first time)

---

## When to use it

- "Run CI locally" / "test before pushing" — validate changes before committing
- "Check what linting will fail" — preview CI failures in real time
- "Shift left" — catch issues at developer time, not CI time
- Pre-commit hook — integrate with git hooks to auto-validate before commit
- Before opening a PR — ensure your branch will pass CI

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/github-actions-locally ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#github-actions-locally
```

### VS Code / MCP client (action skill)

Available as a tool via MCP after running `bash install-vscode.sh`. Callable automatically when relevant.

---

## Invocation

**Explicit:**
```
/github-actions-locally
<optional: --lint | --test | --workflow <name> | --dry-run>
```

**Implicit** — ask about local CI validation and Claude recognises the trigger:
```
Can we run the linting locally before pushing?
```

---

## Quick Start

### Run all discovered jobs (lint + test)
```bash
bash github-actions-locally.sh
```

Output:
```
=== GitHub Actions — Local Run ===
Discovered jobs: 5
  Linting: 3 (shellcheck, registry-sync, README-quality)
  Tests: 2 (ci-mcp/build, ci-mcp/test)

Running: validate/shellcheck...
✓ PASS

Running: validate/registry-sync...
✓ PASS

Running: validate/README-quality...
✗ FAIL — stale path reference in docs/README.md

Running: ci-mcp/build...
✓ PASS

Running: ci-mcp/test...
✓ PASS (auto-fixed 2 formatting issues with black)

=== Summary ===
Jobs: 5 total, 4 passed, 1 failed
Auto-fixed: 1 job (black formatting)
Manual attention needed: 1 job (README-quality — review path refs)

Status: Ready to push (1 issue requires manual review)
```

### Run only linting jobs
```bash
bash github-actions-locally.sh --lint
```

### Discover jobs without running them
```bash
bash github-actions-locally.sh --list
```

Output:
```
Discovered jobs in .github/workflows/:

LINTING:
  - validate/shellcheck (shell)
  - validate/registry-sync (python/bash)
  - validate/README-quality (bash)
  - ci-mcp/lint (typescript)

TESTS:
  - ci-mcp/build (typescript)
  - ci-mcp/test (typescript)
  - devops-check/version-sync (bash)

Total: 7 jobs (4 lint, 3 test)
```

### Dry-run (parse workflows, show what would run, exit)
```bash
bash github-actions-locally.sh --dry-run
```

---

## Examples

### Example 1: Before committing changes
```bash
# Make changes to code
vim src/utils.py

# Run local CI to check before committing
bash github-actions-locally.sh

# Output shows linting passed, tests passed
# Auto-fixed 1 formatting issue with black

# Safe to commit now
git add src/utils.py
git commit -m "refactor: extract utility function"
```

### Example 2: Debugging a CI failure
```bash
# PR failed linting on GitHub, need to understand why
bash github-actions-locally.sh --lint

# Run locally, see exact error
# ✗ ruff check failed: undefined import 'foo'

# Fix locally
vim src/file.py  # fix the import

# Re-run linting
bash github-actions-locally.sh --lint

# ✓ Now passes
# Push a fix commit
```

### Example 3: Auto-fix formatting before PR
```bash
# Developer work is done, but not sure about formatting
bash github-actions-locally.sh --lint

# Output: ✓ black check passed (auto-fixed 3 files)
#         ✓ ruff check passed (auto-fixed imports)
#         ✓ prettier check passed

# Changes are now formatted correctly; review and commit
git status
git add .
git commit -m "style: auto-format with black and prettier"
```

---

## Gotchas & Limitations

### Works Great For
- Python linting (black, ruff)
- JavaScript/TypeScript linting (prettier, eslint)
- Shell script linting (shellcheck)
- Test suites (pytest, jest, vitest)
- Custom validation scripts

### Doesn't Work For
- **Docker-based jobs** — requires Docker; will report "not available" if missing
- **Database-dependent tests** — skips jobs that need external services
- **OS-specific jobs** — e.g., Windows-only tests on Linux machines (warns and skips)
- **Jobs requiring secrets** — GitHub Actions secrets not available locally
- **Very long test suites** — may take 5–30+ minutes; shows progress

### Version Mismatches
Local tool versions (black, ruff, pytest) may differ from GitHub Actions pinned versions. The skill reports version mismatches so you can update tools if needed:
```
⚠️  Version mismatch: black v24.1.1 (local) vs v24.3.0 (Actions)
    Update with: pip install --upgrade black
```

---

## Workflow

Typical workflow with this skill:

```
1. Make code changes
2. Run: bash github-actions-locally.sh
3. If jobs fail:
   a. Auto-fixable → fixes applied, review diffs
   b. Manual fixes needed → fix locally, re-run step 2
4. All jobs pass → commit and push
5. GitHub Actions runs (usually passes on first try)
```

---

## Integration with Git Hooks

To run before every commit, add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run local CI before committing
bash clusters/07-devops/github-actions-locally/github-actions-locally.sh --lint

# Even if it fails, allow commit (exit 0)
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## Roadmap

- [x] SKILL.md completed
- [x] README.md completed
- [ ] github-actions-locally.sh — main implementation
- [ ] Job discovery from YAML (yq parsing)
- [ ] Auto-fix for black, ruff, prettier, eslint
- [ ] Docker detection and skip handling
- [ ] Tool version reporting
- [ ] Pre-commit hook integration template
- [ ] Parallel job execution (lint + test together)
- [ ] Caching of discovered jobs

---

## References

- [SKILL.md](SKILL.md) — Full framework and design
- `github-actions-locally.sh` — Main script
