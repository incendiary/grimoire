# pre-commit-aware-commits

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Run pre-commit checks before attempting `git commit` to avoid the commit-fail-fix-recommit
loop. When hooks modify files, always re-stage and review before committing again.

Invoke when: a project has a `.pre-commit-config.yaml`. Applies for all commit
attempts in the session once loaded.

## Context needed
- Location of `.pre-commit-config.yaml` in the project
- Which hooks are configured (affects what may be auto-modified)

## What to do

1. **Before any `git commit`, run pre-commit on all staged files:**
   ```bash
   pre-commit run
   ```
   If hooks modify files (black reformats, isort reorders imports, etc.), the commit
   will be aborted by the hook. This is expected — do not retry the commit yet.

2. **When a hook modifies files, review the changes before re-staging:**
   ```bash
   git diff           # see what hooks changed
   git add -u         # re-stage all modified tracked files
   git status         # confirm staging is correct
   git commit ...     # now commit
   ```
   Do not blindly `git add -u` without looking at the diff first.

3. **For gitleaks failures:** if gitleaks blocks the commit, examine what it flagged.
   Do not add a `.gitleaksignore` entry without the user reviewing the finding first.
   If it is a false positive (e.g. a test fixture), add the allowlist entry with an
   explicit comment explaining why.

## Gotchas
- Some hooks run only on staged files; `pre-commit run --all-files` catches more but
  may modify unstaged files too. Be aware of which mode you are using.
- flake8 and ruff can flag imports that were unused after another hook (isort, black)
  reorganised the file. Fix the import, then re-run.
- `F401` (unused import) after a format pass often means the formatter removed an
  inline use and left the import dangling. Check before removing the import blindly.
- Never skip hooks with `--no-verify` unless the user explicitly asks. If a hook is
  failing unexpectedly, diagnose it.

## Suggested scripts
- `pre_commit_check.sh` — runs `pre-commit run --all-files`, reports pass/fail,
  lists modified files for re-staging
