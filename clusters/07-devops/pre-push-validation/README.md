# pre-push-validation

Run your CI's validation checks **locally before pushing**, preventing avoidable GitHub Actions failures.

## Architecture: Workflow-Aware Validation

The script automatically detects your repository's CI configuration and runs the exact same checks locally:

1. **Check for `.github/workflows/validate.yml`** (or similar CI config)
2. **Extract and execute those exact checks** — before pushing
3. **Fall back to tech-stack detection** — if no CI workflows are found

**Why this matters**: Fail in 30 seconds locally, not after 10 minutes waiting for CI.

### Example: How it works on grimoire

Grimoire's `validate.yml` includes:
- Shellcheck on all .sh files
- Skill structure validation (SKILL.md + README.md required)
- MCP registry sync check
- README quality checks (multi-platform install docs)
- Stale path reference detection

When you run `pre-push-validation.sh` in grimoire, it automatically runs all 5 checks locally before allowing your push.

### Example: How it works on other repos

For a typical Node.js + Python project without explicit CI workflows defined:
- Auto-detects package.json → runs eslint, prettier, npm test (via `--strict`)
- Auto-detects pyproject.toml → runs black, flake8, pytest (via `--strict`)
- Auto-detects *.sh files → runs shellcheck on all scripts

The skill adapts to whatever your repository contains.

## Installation

### Claude Code

Copy to your Claude Code skills directory:

```bash
cp -r clusters/07-devops/pre-push-validation ~/.claude/skills/pre-push-validation
```

Then invoke with:
```
bash ~/.claude/skills/pre-push-validation/pre-push-validation.sh [options]
```

### VS Code / Copilot Chat

The skill is available as a prompt file via grimoire's prompt file system:

1. Add to VS Code settings: `"chat.promptFilesLocations": ["<grimoire-path>/prompts"]`
2. Access skill as: `#pre-push-validation` in Chat
3. Or run manually: `bash clusters/07-devops/pre-push-validation/pre-push-validation.sh [options]`

### MCP (grimoire only)

Available as a callable MCP action in grimoire's MCP server:

- Install MCP: `bash install-vscode.sh` (auto-detects support)
- Invoke via Copilot Chat: use `#pre-push-validation` tool
- Or call directly: `bash clusters/07-devops/pre-push-validation/pre-push-validation.sh [options]`

## Architecture: Repo-Aware Validation

The script uses a **repo-aware architecture**:

1. **Check for `.github/workflows/validate.yml`** — If found, this is the source of truth for what CI validates
2. **Extract and run those exact checks locally** — Before push, run the same commands that GitHub Actions would run
3. **Fall back to generic detection** — If no CI workflows exist, auto-detect tech stack and run appropriate checks

**Key benefit**: Your local validation mirrors your CI validation. Fail locally in 30s, not on GitHub in 10 minutes.

For grimoire specifically, this runs:
- Shellcheck on all .sh files (with grimoire exclusions)
- Skill directory structure validation (every skill must have SKILL.md + README.md)
- MCP registry sync check (Type:action skills must be registered)
- README quality check (multiplatform installation docs required)
- Stale path reference check

## Problem

Current workflow:
```
local commit → git push → GitHub Actions triggers → 10m CI job → failure email
```

Better workflow:
```
local commit → validate locally (30s) → git push → GitHub Actions triggers → fast CI (3m, no lint/format/type failure)
```

## Solution

`pre-push-validation.sh` runs **every feasible check** that your CI would run — locally:

- **Linting** (eslint, pylint, golint, clippy, rustfmt style)
- **Formatting** (prettier, black, gofmt, rustfmt, dotnet format)
- **Type checking** (tsc, mypy, go vet, cargo check)
- **Testing** (npm test, pytest, go test, cargo test) — optional via `--strict`
- **Security** (npm audit, bandit, cargo audit) — optional via `--strict`
- **Shell scripts** (shellcheck on all .sh files)
- **Custom repo validation** — extracted from your `.github/workflows/validate.yml`

**Optional git hook**: Automatically blocks pushes that fail validation.

## Supported Workflows

The skill currently supports validation workflows that execute shell commands. It parses your CI workflow file and runs those same commands locally.

Common examples:
- **Node.js projects**: eslint, prettier, TypeScript, npm test, npm audit
- **Python projects**: black, flake8, mypy, pytest, bandit
- **Go projects**: gofmt, go vet, go test
- **Rust projects**: cargo fmt, cargo clippy, cargo test, cargo audit
- **C# projects**: dotnet format, dotnet test
- **Any repo with .sh files**: shellcheck
- **Custom validation**: Any shell command in your CI workflow

## Usage

### Manual validation (before push)

```bash
cd /path/to/repo
bash pre-push-validation.sh
```

Sample output:
```
=== Pre-Push Validation for /path/to/repo ===

Detected: Node.js repository (via .github/workflows/validate.yml)

=== Running CI checks ===

⏳ shellcheck... ✅
⏳ eslint... ✅
⏳ prettier... ✅

=== Results ===

Passed:  3
Skipped: 0
Failed:  0

PASS: all checks completed successfully
```

### Install automatic pre-push hook

```bash
cd /path/to/repo
bash pre-push-validation.sh --install-hook
```

Now every `git push` will validate first. To bypass (emergency only):

```bash
git push --no-verify
```

### Strict mode (full test + security suite)

```bash
bash pre-push-validation.sh --strict
```

Runs everything: linting, formatting, type checking, **full test suite**, and security scans.

### Skip specific checks

```bash
bash pre-push-validation.sh --skip-check eslint
```

### Dry-run mode

```bash
bash pre-push-validation.sh --dry-run
```

Shows what would be validated without running checks.

## Supported stacks

| Language   | Detection         | Lint              | Format           | Type Check       | Test      |
|------------|-------------------|-------------------|------------------|------------------|-----------|
| Node.js    | package.json      | eslint            | prettier         | tsc              | npm test  |
| Python     | pyproject.toml    | pylint / flake8   | black            | mypy             | pytest    |
| Go         | go.mod            | golint            | gofmt            | go vet           | go test   |
| Rust       | Cargo.toml        | cargo clippy      | cargo fmt        | cargo check      | cargo test|
| C#/.NET    | *.csproj          | dotnet analyzers  | dotnet format    | implicit (build) | dotnet test |
| Bash       | *.sh              | shellcheck        | —                | —                | —         |

## How the pre-push hook works

The `--install-hook` option creates `.git/hooks/pre-push` that automatically runs validation before each push:

```bash
#!/bin/bash
# Pre-push validation hook — runs local checks before push
set -e
cd "$(git rev-parse --show-toplevel)"

# Find the validation script (works for any repo layout)
SCRIPT_PATH=""
if [ -f "clusters/07-devops/pre-push-validation/pre-push-validation.sh" ]; then
  SCRIPT_PATH="clusters/07-devops/pre-push-validation/pre-push-validation.sh"
elif [ -f "scripts/pre-push-validation.sh" ]; then
  SCRIPT_PATH="scripts/pre-push-validation.sh"
fi

if [ -z "$SCRIPT_PATH" ]; then
  echo "⚠️  pre-push-validation.sh not found"
  exit 0
fi

bash "$SCRIPT_PATH"
```

To disable: `chmod -x .git/hooks/pre-push` or `git push --no-verify`.

## Behavior on different repository types

**Repository with `.github/workflows/validate.yml`:**
- Automatically parses the workflow file
- Runs the exact same checks that GitHub Actions would run
- Example: grimoire runs shellcheck, skill structure checks, registry sync

**Generic repository (no CI workflows):**
- Auto-detects tech stack (Node.js, Python, Go, etc.)
- Runs appropriate linters and formatters for each detected language
- Minimal but effective validation

**Repository without any checks:**
- If no CI workflows and no recognized files, gracefully exits
- No false positives or errors
