# repo-publication-prep

> **Status:** complete
> **Cluster:** 07-devops
> **Merged from:** `precommit-bootstrap`, `repo-publication-prep`, `github-repo-prep`

## Description
End-to-end checklist for preparing a private repo for public release: file-size audit,
history sanitisation decision, and language-appropriate pre-commit wiring.

Invoke when: starting a session whose goal is to make a private repo public, or when
asked to "prep", "publish", or "clean up" a repo before pushing to GitHub.

## Context needed
- Whether the repo has meaningful commit history worth preserving
- Result of a `gitleaks detect --source . --no-git` scan on the working tree
- Target audience (portfolio / professional / open-source)
- Primary language(s) — used to select pre-commit hooks

## What to do

### 1. File audit
- Run `find . -size +10M` and report files by tier:
  - **>100 MB** — hard block; must be removed or moved to LFS
  - **10–100 MB** — flag for explicit approval; list in a `LARGE_FILES.md` or similar
  - **<10 MB** — fine
- Exclude compiled binaries (`*.exe`, `*.dll`, `*.so`, `*.o`), media (`*.mp4`, `*.mkv`, `*.swf`), and build artefacts

### 2. History sanitisation
Ask two questions before touching git:
1. Does the history contain sensitive strings? (`gitleaks detect --source . --log-opts="--all"`)
2. Does the commit history have portfolio value (meaningful messages, progression)?

Decision tree:
- **Secrets found + history has value** → `git filter-repo` targeting specific files/strings; verify with a second gitleaks pass
- **Secrets found + history is noise** → fresh init (clone to `/tmp`, remove `.git`, `git init`, force push); see `github-history-wipe` skill for the full procedure
- **No secrets + history has value** → proceed; review `.gitignore` only
- **No secrets + history is noise** → fresh init optional; user decides

> ⚠️ `filter-repo` can miss secrets embedded in commit message bodies. Always run a second `gitleaks` pass after filtering.

### 3. Pre-commit setup
Detect the primary language and write `.pre-commit-config.yaml`:

**Always include:**
```yaml
- repo: https://github.com/gitleaks/gitleaks
  rev: v8.24.3           # check https://github.com/gitleaks/gitleaks/releases
  hooks:
    - id: gitleaks
```

**Python projects** — add `ruff` + `black`:
```yaml
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.9.10           # check https://github.com/astral-sh/ruff/releases
  hooks:
    - id: ruff
      args: [--fix]
    - id: ruff-format

- repo: https://github.com/psf/black
  rev: 25.1.0            # check https://github.com/psf/black/releases
  hooks:
    - id: black
```

**.NET projects** — local hook (requires dotnet SDK):
```yaml
- repo: local
  hooks:
    - id: dotnet-format
      name: dotnet format
      language: system
      entry: dotnet format --verify-no-changes
      pass_filenames: false
```

**Shell scripts** — add `shellcheck`:
```yaml
- repo: https://github.com/shellcheck-py/shellcheck-py
  rev: v0.10.0.1         # check https://github.com/shellcheck-py/shellcheck-py/releases
  hooks:
    - id: shellcheck
```

**C/C++ projects** — add `clang-format`:
```yaml
- repo: https://github.com/pocc/pre-commit-clang-tools
  rev: v1.4.5            # check https://github.com/pocc/pre-commit-clang-tools/releases
  hooks:
    - id: clang-format
      args: [--style=Microsoft]
```

**Terraform projects** — add `terraform_fmt`:
```yaml
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: v1.99.4           # check https://github.com/antonbabenko/pre-commit-terraform/releases
  hooks:
    - id: terraform_fmt
    - id: terraform_validate
```

Pin all hook versions explicitly. Do not use `latest`.
Run `pre-commit autoupdate` before publishing to refresh pinned versions.

> ⚠️ Version pins above are current as of 2026-06. Always verify against the upstream
> release page before committing — old pins may have known vulnerabilities.

> ⚠️ Python 2 / Jython repos cannot run modern linters. VBA has no standard linter. Ask before adding hooks to these.

### 4. Final checks
- Verify `.gitignore` covers: `*.log`, `.env*`, `*.tar.gz`, `config.local.*`, `proposed-skills/`
- Confirm `README.md` exists and describes the project
- Run `pre-commit run --all-files` before the first public commit

## Gotchas
- `filter-repo` can miss secrets in commit message bodies — always do a second gitleaks pass
- Archived repos on GitHub must be unarchived before force push, then re-archived
- Author email in commit metadata survives content-based wipes — use `--env-filter` to override at commit time if needed
- User may have legitimate large files; always confirm before excluding

## Suggested scripts
- `find-large-files.sh` — report files by size tier (>100 MB, 10–100 MB, tracked binaries)
- `audit_history.sh` — gitleaks on full history, counts commits, recommends approach
- `detect-language.sh` — infer primary language from file extensions and suggest pre-commit hooks
