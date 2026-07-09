# github-actions-locally

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Run GitHub Actions workflow jobs locally before pushing. Discovers every `.github/workflows/*.yml` with a real YAML parser, extracts each job's `run:` steps, executes them, and reports **only what actually ran** — auto-fixing failures where a known fixer exists (black, ruff) and re-running to confirm. Enables "shift left" CI validation without blocking anything (exit code is always 0; the report is the signal).

Invoke when: "run CI locally", "test before pushing", "check linting locally", "shift left testing", "preview what CI will do".

## Context needed
- `.github/workflows/*.yml` (nothing to do without at least one)
- `python3` with PyYAML (fails closed with an install hint if missing)
- Local tooling for whatever the discovered `run:` steps invoke (python, node, etc.)

---

## How it works

1. **Discover.** Parse every `.github/workflows/*.yml`/`*.yaml` with `python3` + PyYAML. For each job's steps with a `run:` key, honour the effective `working-directory` (step → job `defaults.run` → workflow `defaults.run`), same as `pre-push-validation`.
2. **Classify.**
   - **CI-only → skipped, never run**, with a printed reason: steps using `${{ }}` contexts, `secrets.`, `gh release`, `$GITHUB_OUTPUT`/`$GITHUB_ENV`/`$GITHUB_STEP_SUMMARY`, or OS package installs (`sudo`/`apt-get`/`yum install`/`apk add`).
   - Everything else is **runnable**.
   - Each job is also heuristically tagged `lint` / `test` / `other` by name (for `--lint`/`--test` filtering only — this tagging never affects pass/fail truth).
3. **Execute.** Every runnable step is actually run; judged by **exit code**, exactly as CI does.
4. **Auto-fix.** On failure, if the command mentions `black` or `ruff`, run the corresponding `--fix`/auto-format tool and re-run the original command once to confirm.
5. **Report.** Only counts steps that were actually executed. If nothing was runnable, the summary says so explicitly (`0 steps executed`) — it never claims a pass for work it didn't do.

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
- **Local tool versions can differ from CI's pinned versions**, which can produce results CI wouldn't (or vice versa) — this tool runs your local toolchain, not CI's exact environment.
- **CI-only steps are skipped, not simulated.** Anything gated on GitHub context, secrets, or OS package installs won't be verified locally; check those in CI.
- **Job/step names, not real job IDs**, are used for display and `--lint`/`--test` classification — a heuristic, not the job's actual GitHub Actions execution graph (dependencies between jobs, matrix expansion, etc. are not modelled).

---

## Integration with other skills

- **pre-push-validation:** fail-closed equivalent — use that as a git hook to block bad pushes; use this one for exploratory "what would CI say about my current changes" runs.
- **format-before-commit:** narrower, Python-only formatting check; this skill's auto-fix covers the same ground plus arbitrary `run:` steps.
- **github-morning-run:** use after pushing to catch what CI found on the morning audit.

---

## Roadmap

- [x] SKILL.md written
- [x] github-actions-locally.sh script (real YAML parsing + execution)
- [x] YAML parsing for job discovery (PyYAML-based, `jobs.*.steps[].run` only)
- [x] Auto-fix logic for black/ruff, with re-run confirmation
- [ ] Auto-fix for prettier/eslint (JS/TS projects)
- [ ] Job dependency graph (`needs:`) and matrix expansion awareness
- [ ] Caching of discovered jobs (skip re-parsing on each run)
