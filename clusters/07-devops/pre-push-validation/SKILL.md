# pre-push-validation

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description

Shift-left validation: runs your repo's own CI checks **locally before you push**, so you
fail in seconds instead of waiting minutes for GitHub Actions.

**Workflow-driven, repo-agnostic.** The script reads the repository's actual CI definitions —
every `.github/workflows/*.yml` — parses them with PyYAML, and runs each job's `run:` steps
locally. There is no hardcoded repo logic and no tech-stack guessing: what CI runs is what
runs locally. If CI changes, local validation changes with it automatically.

**Steps that can't run locally are skipped explicitly, never silently:**
- `${{ ... }}` GitHub Actions expression contexts
- steps referencing `secrets.`
- `gh release` creation/edits
- steps writing `$GITHUB_OUTPUT` / `$GITHUB_ENV` / `$GITHUB_STEP_SUMMARY`
- OS package installs (`sudo`, `apt-get`, `yum install`, `apk add`) — provisioned differently locally

Each skipped step prints `Skipped — CI-only: <name> (<reason>)`.

**Fail-closed.** Every runnable step is judged by its **exit code**, exactly as CI does. Any
non-zero exit — including a missing tool surfacing as command-not-found — blocks the push and
prints the step's output. No output-string heuristics.

Invoke when: "validate before push", "run CI checks locally", "install pre-push hook",
"check everything before pushing".

## Context needed

- Repository root (auto-detected via `git rev-parse --show-toplevel`)
- One or more `.github/workflows/*.yml` files (nothing to do without them)
- `python3` with `PyYAML` available (fails closed with an install hint if missing)

## Behaviour

1. Discover all `.github/workflows/*.yml` / `*.yaml`.
2. If a `venv/` or `.venv/` exists, activate it (so Python tools are on PATH).
3. Parse every workflow; for each job step with a `run:`:
   - honour the effective `working-directory` (step → job `defaults.run` → workflow `defaults.run`)
   - classify as **RUN** or **SKIP (CI-only)**
4. Run each RUN step; PASS on exit 0, FAIL (with output) on non-zero.
5. Print a summary: `Passed / Failed / Skipped`.
6. If anything failed, exit non-zero — **push blocked**.
7. If all passed and no pre-push hook is installed **and** stdin is a TTY, offer to install one.
   When invoked *as* the git hook (no TTY), it never prompts — it just validates.

## Usage

```bash
# Validate the current repo against its own CI workflows
bash pre-push-validation.sh

# Install the pre-push git hook non-interactively (for scripted setup)
bash pre-push-validation.sh --install-hook
```

Installed hook behaviour:
- runs this script before every `git push`
- bypass once with `git push --no-verify`
- uninstall with `rm .git/hooks/pre-push`

The hook calls the script by its absolute path, so it works regardless of where the repo lives.

## Requirements & limits

- **Faithful to CI, including CI's blind spots.** Local tooling can differ from CI (e.g. a newer
  local `shellcheck` flags more than CI's pinned version; local `node_modules`/`.venv` can widen a
  `find` in a CI command). The script runs CI's commands verbatim rather than second-guessing them.
- **`npm ci` / dependency steps run as written** — they are validation, not CI-only, so a stale
  local lockfile legitimately fails the check.
- Requires `python3` + `PyYAML`; fails closed if absent.
