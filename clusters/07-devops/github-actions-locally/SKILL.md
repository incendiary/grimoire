# github-actions-locally

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Run GitHub Actions workflows locally before pushing. Discovers and executes linting and test jobs from `.github/workflows/*.yml`, auto-fixes fixable issues (black, ruff, etc.), and reports results without blocking merges. Enables "shift left" CI validation — catch failures locally, not in Actions.

Invoke when: "run CI locally", "test before pushing", "check linting locally", "shift left testing", "preview what CI will do".

## Context needed
- `.github/workflows/` directory with workflow files
- Local tooling installed for discovered jobs (python, node, etc.)
- Repository root (or explicit path via `--repo` flag)

---

## The Real Problem

CI failures are caught too late:
1. Developer pushes code
2. GitHub Actions runs (2-5 min wait)
3. Linting or test fails
4. Developer fixes locally and re-pushes
5. Repeat

**Cost:** ~5-15 minutes per failed CI run × how many times it fails before being fixed = hours of wasted time.

**Solution:** Run the same validations locally before pushing. Fail fast. Auto-fix what's fixable. See exactly what CI will complain about.

---

## How It Works

### 1. Discover Jobs
- Parse `.github/workflows/*.yml` for all jobs
- Filter to **linting jobs** (identified by keywords: lint, ruff, black, shellcheck, prettier, eslint, etc.)
- Filter to **test jobs** (identified by keywords: test, pytest, jest, go test, vitest, etc.)
- Output discovered jobs with their commands

### 2. Run Locally
For each discovered job:
- Extract the shell commands (`run:` sections)
- Detect language/tool (Python, JavaScript, Shell, Go, etc.)
- Run the command in the repo root
- Capture stdout, stderr, exit code

### 3. Auto-Fix
If a job failed and fixable:
- **Python**: `black --fix`, `ruff check --fix`
- **JavaScript**: `prettier --write`, `eslint --fix`
- **Shell**: (no auto-fix for shellcheck; report only)
- **Other**: Report failure; user fixes manually

After auto-fixing, **re-run the job** to confirm it passes.

### 4. Report
Output summary:
```
=== GitHub Actions — Local Run ===
Discovered jobs: 8
  Linting: 5
  Tests: 3

=== Results ===
✓ validate/shellcheck — PASS
✓ validate/skill-structure — PASS
✓ validate/registry-sync — PASS
✗ validate/README-quality — FAIL (path references; manual review needed)
✓ ci-mcp/build — PASS
✓ ci-mcp/lint — PASS (auto-fixed with ruff)
✓ ci-mcp/test — PASS
✓ devops-check/version-sync — PASS

⚠️  1 issue requires manual attention:
  - validate/README-quality: stale path found in docs/README.md

✅ 7/8 jobs passed. Ready to push.
```

Exit **0 (allow)** even if jobs failed — the report is the signal, not the exit code.

---

## Usage

### Basic: Discover and run all jobs
```bash
github-actions-locally
```

### Run only linting jobs
```bash
github-actions-locally --lint
```

### Run only test jobs
```bash
github-actions-locally --test
```

### Run specific workflow
```bash
github-actions-locally --workflow validate.yml
```

### Run specific job pattern
```bash
github-actions-locally --job "*shellcheck*"
```

### Dry-run (discover only, don't execute)
```bash
github-actions-locally --dry-run
```

### Show which jobs would run and exit
```bash
github-actions-locally --list
```

---

## Implementation Strategy

### Phase 1: Job Discovery
- Use `yq` or inline bash/Python to parse YAML
- Extract job names, run steps, shell language
- Build a structured job list (name, commands, language)

### Phase 2: Local Execution
- For each job, execute its `run:` commands
- Detect tool (black, ruff, pytest, etc.)
- Capture output and exit code

### Phase 3: Auto-Fix
- Parse failures for fixable patterns
- Run auto-fix tools (ruff --fix, black --fix, etc.)
- Re-run job to verify fix

### Phase 4: Reporting
- Aggregate results (pass/fail/fixed)
- Highlight issues needing manual attention
- Output structured summary
- Exit 0 (always allow)

---

## Limitations & Gotchas

- **Docker-based jobs:** Only runs if `docker` is available locally; skips otherwise (reports "not available")
- **External services:** Jobs requiring databases, APIs, external services are skipped with a note
- **OS-specific commands:** `run-on: ubuntu-latest` jobs may have Linux-specific commands; macOS/Windows users get a warning
- **Secrets:** Workflow secrets are not available locally; jobs using them are skipped with a note
- **Expensive jobs:** Some jobs (e.g., full test suites on large repos) may take a while; show progress
- **Tool versions:** Local tool versions may differ from GitHub Actions versions; report if mismatch detected

---

## Integration with Other Skills

- **pre-commit-aware-commits:** Run this before committing to catch issues early
- **format-before-commit:** Use this skill to find and fix formatting issues automatically
- **github-morning-run:** Use after pushing to catch what CI found on the morning audit
- **roadmap-driver:** Use before working on a roadmap item to ensure local environment is valid

---

## Roadmap

- [x] SKILL.md written
- [ ] github-actions-locally.sh script (core implementation)
- [ ] YAML parsing for job discovery (yq-based or Python)
- [ ] Auto-fix logic for common tools (black, ruff, prettier, eslint)
- [ ] Docker job detection and skip reporting
- [ ] Tool version detection and warnings
- [ ] Integration with pre-commit hooks
- [ ] Caching of discovered jobs (skip re-parsing on each run)
- [ ] Parallel job execution (run lint + test in parallel, not sequentially)
