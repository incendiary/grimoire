# local-ci

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action
> **Formerly:** `github-actions-locally` (renamed in v1.6.36)

## Description
Run your GitHub Actions workflows locally before pushing. Discovers every `.github/workflows/*.yml` with a real YAML parser, extracts each job's `run:` steps, executes them, and reports **only what actually ran** — auto-fixing failures where a known fixer exists (black, ruff) *only when the tool version matches CI's pin*. A normal run exits 0; it never breaks your shell.

> **Two hook modes, in one skill — and it never clobbers an existing hook.**
> - `--install-hook pre-commit` → runs the **fast lint subset**, informational (never blocks a commit).
> - `--install-hook pre-push` → runs the **full workflow, fail-closed** (`--gate`): blocks a red push.
>
> A pre-existing hook in the slot (the pre-commit framework, gitleaks, your own) is **preserved
> as a sidecar and still runs first** — installs *complement*, never overwrite. A normal run with
> no local-ci hook yet auto-installs the pre-push gate (chaining anything present). Uninstall with
> `rm .git/hooks/<slot>` (and `mv .git/hooks/<slot>.local-ci-prev` back if it chained one).

Invoke when: "run CI locally", "test before pushing", "check linting locally", "shift left testing", "preview what CI will do", "gate my pushes on CI".

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
8. **Offer/install the hook.** If no local-ci hook exists in either slot: auto-install the **pre-push gate** (prompt when interactive, else install), *chaining* any hook already there — never clobbering. Skipped once a local-ci hook is present, and never offered when running as a hook itself (`--gate`).

**`--sync`** builds CI's exact pinned toolchain in an ephemeral venv inside `.git/` (never your own venv, never global, never in the work tree), so mismatched tools become verified and auto-fix becomes safe. Falls back to report-only if pins can't be found or `pip install` fails.

**Exit code.** A normal run always exits **0** (never breaks your shell). Under `--gate` (used by the fail-closed pre-push hook) it exits non-zero on a genuine check failure so the push is blocked — but a *local toolchain gap* (a tool CI has that you don't) is reported and does **not** gate, since it isn't evidence the push is bad.

## Hooks — commit vs push, never clobber

The commit and push slots do different jobs, and this one skill installs into either:

| Slot | `--install-hook` | Runs | Behaviour |
|------|------------------|------|-----------|
| `pre-commit` | `--install-hook pre-commit` | fast **lint** subset | informational — never blocks a commit |
| `pre-push` | `--install-hook pre-push` (also the auto-install default) | **full** workflow, `--gate` | fail-closed — blocks a red push (`git push --no-verify` to bypass once) |

**Chaining, not clobbering.** If the slot already holds a hook you didn't install here (the pre-commit framework, gitleaks, your own), it's moved to `.git/hooks/<slot>.local-ci-prev` and the installed wrapper **runs it first, honouring its exit code** — so a chained secret-scanner keeps its blocking power. Re-installing our own hook is idempotent (it won't chain itself). This is the fix for the trap where the old version silently overwrote a framework's `pre-commit` hook and disabled secret scanning.

## Usage

```bash
# Discover and run every runnable step in every workflow
bash local-ci.sh

# Only steps from jobs whose name looks lint-related / test-related
bash local-ci.sh --lint
bash local-ci.sh --test

# Restrict to one workflow file (substring match)
bash local-ci.sh --workflow validate.yml

# Show what would run, without executing anything (side-effect free)
bash local-ci.sh --dry-run
bash local-ci.sh --list

# Build CI's exact pinned toolchain (ephemeral venv in .git/) and run against
# it — makes mismatched black/ruff match CI, enabling safe auto-fix
bash local-ci.sh --sync

# Install a hook directly (chains any existing hook, never clobbers):
bash local-ci.sh --install-hook pre-commit   # fast lint, informational
bash local-ci.sh --install-hook pre-push      # full CI, fail-closed gate
bash local-ci.sh --install-hook               # defaults to pre-push

# Exit non-zero on a real failure (what the pre-push hook runs under the hood)
bash local-ci.sh --gate
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

- **pre-push-validation:** an older, `validate.yml`-focused fail-closed pre-push gate. `local-ci` now covers the same ground more generally (all workflows, version parity, stop-on-failure) and can itself install a fail-closed `pre-push` gate — so on a repo using `local-ci` you typically won't also need `pre-push-validation`. They both write `.git/hooks/pre-push`; pick one owner per repo.
- **format-before-commit:** narrower, Python-only formatting check; this skill's auto-fix covers the same ground plus arbitrary `run:` steps.
- **github-morning-run:** use after pushing to catch what CI found on the morning audit.

---

## Roadmap

- [x] local-ci.sh script (real YAML parsing + execution)
- [x] YAML parsing for job discovery (PyYAML-based, `jobs.*.steps[].run` only)
- [x] Auto-fix logic for black/ruff, with re-run confirmation
- [x] venv/.venv activation before running anything
- [x] Distinct "toolchain issue" reporting (command not found, broken shims)
- [x] Stop a job at its first failed step (mirror CI), disambiguate unnamed steps
- [x] Parse CI's pinned tool versions; gate auto-fix on verified version match (never write with an unverified version)
- [x] `--sync`: build CI's exact pinned toolchain in an ephemeral `.git/` venv to enable safe auto-fix
- [x] Two hook slots (fast `pre-commit` lint / fail-closed `pre-push` gate via `--gate`), chosen at install
- [x] Chaining hook installer — preserves any existing hook as a sidecar, never clobbers (fixes the framework-hook-destroyed trap)
- [x] Renamed from `github-actions-locally` → `local-ci`
- [ ] Auto-fix for prettier/eslint (JS/TS projects)
- [ ] Pin detection for `pyproject.toml`/`poetry.lock`/constraints files
- [ ] Job dependency graph (`needs:`) and matrix expansion awareness
- [ ] Caching of discovered jobs (skip re-parsing on each run)
