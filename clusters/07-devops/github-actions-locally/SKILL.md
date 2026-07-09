# github-actions-locally

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Run GitHub Actions workflow jobs locally before pushing. Discovers every `.github/workflows/*.yml` with a real YAML parser, extracts each job's `run:` steps, executes them, and reports **only what actually ran** — auto-fixing failures where a known fixer exists (black, ruff) and re-running to confirm. Enables "shift left" CI validation without blocking anything (exit code is always 0; the report is the signal).

> **Self-installs as a `pre-commit` hook — informational only, never blocks.** After a run
> with no hook present, it installs one automatically (asks first if there's an interactive
> terminal; installs without asking otherwise, since this tool always exits 0 — it can never
> block a commit). Deliberately a **different** hook slot than `pre-push-validation`'s
> blocking `pre-push` hook — the two compose rather than conflict. Uninstall any time with
> `rm .git/hooks/pre-commit`.

Invoke when: "run CI locally", "test before pushing", "check linting locally", "shift left testing", "preview what CI will do".

## Context needed
- `.github/workflows/*.yml` (nothing to do without at least one)
- `python3` with PyYAML (fails closed with an install hint if missing)
- Local tooling for whatever the discovered `run:` steps invoke (python, node, etc.) — ideally inside the repo's own `venv`/`.venv`

---

## How it works

1. **Activate the project's own venv.** If `venv/` or `.venv/` exists at the repo root, it's activated before anything runs — never the caller's global PATH. This matters: a `black`/`ruff` resolved from a different environment than CI's pinned install can format differently between versions, and auto-fix would then "correct" files to a style CI doesn't actually want. If no venv is found, a warning is printed and **auto-fix is disabled** for that run (checks still execute against whatever's on PATH, but nothing gets rewritten with an unverified tool version).
2. **Discover.** Parse every `.github/workflows/*.yml`/`*.yaml` with `python3` + PyYAML. For each job's steps with a `run:` key, honour the effective `working-directory` (step → job `defaults.run` → workflow `defaults.run`), same as `pre-push-validation`.
3. **Classify.**
   - **CI-only → skipped, never run**, with a printed reason: steps using `${{ }}` contexts, `secrets.`, `gh release`, `$GITHUB_OUTPUT`/`$GITHUB_ENV`/`$GITHUB_STEP_SUMMARY`, or OS package installs (`sudo`/`apt-get`/`yum install`/`apk add`).
   - Everything else is **runnable**.
   - Each job is also heuristically tagged `lint` / `test` / `other` by name (for `--lint`/`--test` filtering only — this tagging never affects pass/fail truth).
4. **Execute.** Every runnable step is actually run; judged by **exit code**, exactly as CI does. A `command not found`-class failure (exit 127, or a missing `pyenv` shim) is reported as a distinct **toolchain issue**, not a code failure.
5. **Auto-fix.** On failure, if the command mentions `black` or `ruff` **and a project venv was activated**, run the corresponding fixer and re-run the original command once to confirm. Skipped (with a message) if no venv was found.
6. **Report.** Only counts steps that were actually executed. If nothing was runnable, the summary says so explicitly (`0 steps executed`) — it never claims a pass for work it didn't do.
7. **Offer/install the hook.** If `.git/hooks/pre-commit` doesn't exist yet: prompt to install when there's a terminal to prompt on, otherwise install it automatically without asking (safe, since it never blocks). Skipped entirely once a `pre-commit` hook already exists.

Exit code is always **0** — this tool never blocks a push. For a fail-closed pre-push gate, use `pre-push-validation` instead.

## Usage

```bash
# Discover and run every runnable step in every workflow
bash github-actions-locally.sh

# Only steps from jobs whose name looks lint-related
bash github-actions-locally.sh --lint

# Only steps from jobs whose name looks test-related
bash github-actions-locally.sh --test

# Restrict to one workflow file (substring match)
bash github-actions-locally.sh --workflow validate.yml

# Show what would run, without executing anything
bash github-actions-locally.sh --dry-run

# List discovered steps (run + skipped) and exit — same output as --dry-run
bash github-actions-locally.sh --list

# Install the pre-commit hook directly, without running anything first
bash github-actions-locally.sh --install-hook
```

## Example output

```
=== GitHub Actions — Local Run ===

=== Discovered ===
  run   validate.yml › shellcheck › Lint all shell scripts
  skip  validate.yml › shellcheck › Install shellcheck  (OS package/setup step)
  run   ci-mcp.yml › build › build

Runnable: 2   Skipped (CI-only): 1

Running: validate.yml › shellcheck › Lint all shell scripts...
✓ PASS
Running: ci-mcp.yml › build › build...
✗ FAIL (exit 1)
npm error ...

=== Summary ===
Ran: 2 executed, 1 passed, 1 failed, 1 skipped (CI-only)
Manual attention needed: 1 job(s)
  - ci-mcp.yml › build › build
⚠️  1 issue(s) require manual review.
```

## Limitations

- **No auto-fix beyond black/ruff.** Other failures are reported only; fix manually.
- **Local tool versions can still differ from CI's exact pinned versions even inside a venv** (e.g. a stale venv that hasn't been reinstalled since CI bumped a pin) — activating the repo's venv avoids the worst case (global-PATH tools entirely), but doesn't guarantee an exact version match. If a check result looks surprising, compare `<tool> --version` locally against what the workflow's install step pins.
- **CI-only steps are skipped, not simulated.** Anything gated on GitHub context, secrets, or OS package installs won't be verified locally; check those in CI.
- **Job/step names, not real job IDs**, are used for display and `--lint`/`--test` classification — a heuristic, not the job's actual GitHub Actions execution graph (dependencies between jobs, matrix expansion, etc. are not modelled).

---

## Integration with other skills

- **pre-push-validation:** fail-closed equivalent, installed as the `pre-push` hook to actually block bad pushes. This skill installs as `pre-commit` instead — different hook slot, so both can be active on the same repo at once: `pre-commit` surfaces issues on every commit (informational), `pre-push` blocks the push itself if CI's real checks fail.
- **format-before-commit:** narrower, Python-only formatting check; this skill's auto-fix covers the same ground plus arbitrary `run:` steps.
- **github-morning-run:** use after pushing to catch what CI found on the morning audit.

---

## Roadmap

- [x] SKILL.md written
- [x] github-actions-locally.sh script (real YAML parsing + execution)
- [x] YAML parsing for job discovery (PyYAML-based, `jobs.*.steps[].run` only)
- [x] Auto-fix logic for black/ruff, with re-run confirmation
- [x] venv/.venv activation before running anything; auto-fix disabled without one
- [x] Distinct "toolchain issue" reporting (command not found, broken shims)
- [x] Self-installs a non-blocking pre-commit hook (prompts if interactive, auto-installs otherwise — never conflicts with pre-push-validation's pre-push hook)
- [ ] Auto-fix for prettier/eslint (JS/TS projects)
- [ ] Job dependency graph (`needs:`) and matrix expansion awareness
- [ ] Caching of discovered jobs (skip re-parsing on each run)
