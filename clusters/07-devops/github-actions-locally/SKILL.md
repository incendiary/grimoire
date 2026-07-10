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

## The core model (why earlier versions kept breaking)

"Run CI locally" hides a fork: CI is a hermetic from-scratch environment (exact pinned tools, stop-on-first-failure, no leftover state); your laptop is persistent and messy (global tools on PATH, stale venvs, leftover `node_modules`). Past bugs all came from doing a CI-thing and a laptop-thing at once — the worst being *auto-fixing files with a global-PATH tool version that CI doesn't use*, silently corrupting correct code.

The rule that resolves it, and that everything below follows from:

> **This tool only *writes* (auto-fixes) when it has *verified* its tool version matches what CI pins. Otherwise it reads and reports only.**

## How it works

1. **Activate the project's venv.** `venv/`/`.venv/` at the repo root is activated first (never the caller's global PATH). If absent, a warning prints and checks run against PATH tools as-is.
2. **Discover.** Parse every `.github/workflows/*.yml`/`*.yaml` with `python3` + PyYAML. Honour each step's effective `working-directory` (step → job `defaults.run` → workflow `defaults.run`). Also parse the versions CI **pins** for its tools (from `pip install X==Y` steps and `-r requirements*.txt` files).
3. **Classify.**
   - **CI-only → skipped, never run**, with a printed reason: `${{ }}` contexts, `secrets.`, `gh release`, `$GITHUB_OUTPUT`/`$GITHUB_ENV`/`$GITHUB_STEP_SUMMARY`, or OS package installs (`sudo`/`apt-get`/`yum install`/`apk add`).
   - Everything else is **runnable**.
   - Each job is heuristically tagged `lint`/`test`/`other` by name (for `--lint`/`--test` filtering only — never affects pass/fail).
4. **Toolchain vs CI.** For each fixable tool the run will use (`black`/`ruff`), compare the locally-resolved version to CI's pin and print the verdict: **match** (auto-fix enabled), **mismatch** (auto-fix disabled, report-only, suggests `--sync`), **CI unpinned** (unverifiable → report-only), or **not installed**.
5. **Execute** in file order. Every runnable step actually runs, judged by **exit code**. A job **stops at its first failed step** — later steps in that job are skipped, exactly as CI does, so stale local state can't make them look like they passed. A `command not found`-class failure (exit 127 / missing `pyenv` shim) is reported as a distinct **toolchain issue**, not a code failure.
6. **Auto-fix — only when version-verified.** On a `black`/`ruff` failure, the fixer runs **only if** step 4 confirmed the version matches CI's pin (or `--sync` built a matched env). Otherwise it's skipped with a message. This is the guarantee that it can never corrupt correct files with the wrong formatter version.
7. **Report.** Counts only steps actually executed; says `0 steps executed` explicitly when nothing ran.
8. **Offer/install the hook.** If `.git/hooks/pre-commit` doesn't exist: prompt when interactive, else install automatically (safe — never blocks). Skipped if a `pre-commit` hook already exists.

**`--sync`** builds CI's exact pinned toolchain in an ephemeral venv inside `.git/` (never your own venv, never global, never in the work tree), so mismatched tools become verified and auto-fix becomes safe. Falls back to report-only if pins can't be found or `pip install` fails.

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

# Build CI's exact pinned toolchain (ephemeral venv in .git/) and run against
# it — makes mismatched black/ruff versions match CI, enabling safe auto-fix
bash github-actions-locally.sh --sync

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
- **Version parity is only verified for black/ruff.** Other tools (pytest, mypy, eslint, etc.) run with whatever's on PATH/in the venv; the tool doesn't check their versions against CI. It never *writes* with them, so this is a reporting-accuracy caveat, not a corruption risk.
- **Pin detection covers `pip install X==Y` and `-r requirements*.txt`.** A pin expressed some other way (constraints files, `pyproject.toml`/`poetry.lock`, a version baked into a container image) reads as "CI unpinned" → report-only. Use `--sync`… only helps if the pin is one it can parse; otherwise the honest fallback is report-only.
- **Without a venv and without `--sync`, `pip install` steps run against your ambient Python** (they're real CI commands, so they execute) — which can touch your user/global site-packages. Use a project `venv`/`.venv`, or `--sync` (isolated ephemeral env), to keep installs contained.
- **CI-only steps are skipped, not simulated.** Anything gated on GitHub context, secrets, or OS package installs won't be verified locally; check those in CI.
- **No cross-job graph.** `needs:` ordering and `strategy.matrix` expansion aren't modelled — steps run in file order. Stop-on-failure is enforced *within* a job, not across dependent jobs.

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
- [x] venv/.venv activation before running anything
- [x] Distinct "toolchain issue" reporting (command not found, broken shims)
- [x] Self-installs a non-blocking pre-commit hook (prompts if interactive, auto-installs otherwise — never conflicts with pre-push-validation's pre-push hook)
- [x] Stop a job at its first failed step (mirror CI), disambiguate unnamed steps
- [x] Parse CI's pinned tool versions; gate auto-fix on verified version match (never write with an unverified version)
- [x] `--sync`: build CI's exact pinned toolchain in an ephemeral `.git/` venv to enable safe auto-fix
- [ ] Auto-fix for prettier/eslint (JS/TS projects)
- [ ] Pin detection for `pyproject.toml`/`poetry.lock`/constraints files
- [ ] Job dependency graph (`needs:`) and matrix expansion awareness
- [ ] Caching of discovered jobs (skip re-parsing on each run)
