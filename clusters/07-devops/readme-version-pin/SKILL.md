# readme-version-pin

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Keeps README install instructions pinned to the latest tagged release rather than
`main`/`master`. Ensures users clone or pip-install a stable, reproducible version.
Provides a check script that can run as a pre-commit hook or CI step to block commits
that reference a stale version.

Invoke when: cutting a new release, asked to "pin the version in the README", or
whenever README install instructions reference `main`, `master`, or an old tag.

## Context needed
- Whether the project uses a `VERSION` file, git tag, or `pyproject.toml` for its
  canonical version (the script detects all three in order)
- Which README files contain install instructions to update
- Whether to wire the check into pre-commit or CI (or both)

## What to do

### Step 1 — Determine the current release version

```bash
bash pin_readme_version.sh --dry-run
```

This prints the detected version and lists every README line that would change,
without modifying any files.

### Step 2 — Apply the pins

```bash
bash pin_readme_version.sh
```

Updated patterns (all READMEs in the repo):
- `git clone -b main` → `git clone -b v1.2.9`
- `git clone -b master` → `git clone -b v1.2.9`
- `@main` → `@v1.2.9`
- `@master` → `@v1.2.9`
- `@v1.2.8` (any older tag) → `@v1.2.9`
- `pip install git+https://...@main` → `@v1.2.9`

### Step 3 — Verify with the check script

```bash
bash check_readme_version.sh
```

Exits 0 if all README version pins match the current version. Exits 1 and prints
a diff if any mismatch is found. Use this as a pre-commit hook or CI gate.

### Step 4 — Wire into pre-commit (optional)

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: readme-version-pin
      name: README version pin check
      language: script
      entry: bash clusters/07-devops/readme-version-pin/check_readme_version.sh
      pass_filenames: false
      always_run: true
```

Or for a project not using grimoire directly:

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

### Step 5 — Wire into CI (optional)

Add a step to your CI workflow:

```yaml
- name: Check README version pins
  run: bash check_readme_version.sh
```

## Release workflow integration

This skill fits naturally after `github-release-workflow`:

1. `release.sh` bumps VERSION, tags, pushes tag, creates GitHub Release
2. `pin_readme_version.sh` rewrites README install instructions to the new tag
3. `check_readme_version.sh` verifies the result
4. Commit the README changes to main

Or automate step 2–3 inside `release.sh` itself — add a call to
`pin_readme_version.sh` before the `git push`.

## Version detection order

1. `VERSION` file in the repo root (trimmed)
2. `git describe --tags --abbrev=0` (latest tag)
3. `version = "..."` in `pyproject.toml`

If none are found the scripts exit 1 with a clear message.

## Gotchas

- **Only rewrites recognisable patterns.** If your README uses a non-standard install
  format, `pin_readme_version.sh` won't touch it — add the pattern to the script's
  `SED_PATTERNS` array.
- **Commit the README changes.** Running `pin_readme_version.sh` modifies files but
  does not commit. Stage and commit after verifying with `check_readme_version.sh`.
- **Check script should run before `git commit`, not after.** Wire it into pre-commit
  so the commit is blocked until the pins are correct, not discovered in CI after push.
- **Tags must be pushed before running.** `git describe --tags` only sees pushed tags.
  If you're using a local-only tag, push it first or set the `VERSION` file.

## Related skills

- `github-release-workflow` — the release mechanics this skill follows
- `pre-commit-aware-commits` — pre-commit hook discipline and re-stage workflow
- `verify-code-version` — runtime version checks (post-pull, not README-facing)
