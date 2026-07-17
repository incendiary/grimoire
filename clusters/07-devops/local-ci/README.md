# local-ci

> **Cluster:** 07-devops | **Status:** complete | **Updated:** 2026-07-10 | **Formerly:** `github-actions-locally`

Run your GitHub Actions workflows locally before pushing. Discovers every `.github/workflows/*.yml` with a real YAML parser, executes each job's `run:` steps, auto-fixes what it can (black, ruff), and reports **only what actually ran** — never a fake pass for work it skipped.

> **Two hook modes in one skill, and it never clobbers an existing hook.**
> `--install-hook pre-commit` = fast lint, informational (never blocks a commit).
> `--install-hook pre-push` = full workflow, fail-closed (`--gate`, blocks a red push) — also the
> auto-install default on a normal run. A pre-existing hook in the slot (the pre-commit framework,
> gitleaks, your own) is preserved as `.git/hooks/<slot>.local-ci-prev` and **still runs first** —
> installs *complement*, they don't overwrite. Uninstall with `rm .git/hooks/<slot>`.

---

## What this skill does

Parses every workflow file with `python3` + PyYAML (not a line-grep), extracts each job's `run:` steps, and executes them locally — honouring `working-directory` the same way GitHub Actions does, in file order, **stopping a job at its first failed step** just like CI (so stale local state can't make later steps look like they passed). Steps that can only run in CI (GitHub Actions `${{ }}` contexts, `secrets.`, `gh release`, `$GITHUB_OUTPUT`/`$GITHUB_ENV`/`$GITHUB_STEP_SUMMARY`, OS package installs) are **skipped with a printed reason**, never silently treated as passing.

**The safety rule that makes it trustworthy:** it only ever *writes* to your files (auto-fix with black/ruff) when it has **verified its tool version matches what CI pins** in the workflow. It parses CI's pins (`pip install X==Y`, `-r requirements*.txt`), compares them to your locally-resolved versions, and if they don't match it reports the failure but **refuses to auto-fix** — because a mismatched formatter version can rewrite correct files to a style CI doesn't want. Pass `--sync` to build CI's exact pinned toolchain in an ephemeral venv (inside `.git/`, never touching your own env) and enable safe auto-fixing.

Every executed step is judged by its **exit code**. A normal run always exits 0 (never breaks your shell); under `--gate` — what the installed `pre-push` hook runs — it exits non-zero on a genuine failure so the push is blocked.

**Before:** Push → wait for CI → find a failure → fix → push again → repeat
**After:** Run locally → see the same failures immediately → fix (or let it auto-fix black/ruff issues) → push

---

## When to use it

- "Run CI locally" / "test before pushing"
- "Check what linting will fail" — preview real CI failures before pushing
- "Shift left" — catch issues at developer time, not CI time
- Before opening a PR, to see what the workflow files will actually run

---

## Installation

### Claude Code

```bash
bash install-all.sh            # first install (all grimoire skills)
bash install-all.sh --update   # update an existing copy
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#local-ci
```

### MCP (VS Code / JetBrains)

Registered as the `local-ci` action tool in grimoire's MCP server (`mcp-server/registry.json`). Build with `cd mcp-server && npm ci && npm run build`, then invoke the `local-ci` tool from your MCP client.

---

## Usage

```bash
# Discover and run every runnable step in every workflow
bash local-ci.sh

# Only steps from jobs whose name looks lint-related / test-related
bash local-ci.sh --lint
bash local-ci.sh --test

# Restrict to one workflow file (substring match on filename)
bash local-ci.sh --workflow validate.yml

# Show what would run, without executing anything (side-effect free)
bash local-ci.sh --dry-run
bash local-ci.sh --list

# Build CI's exact pinned toolchain (ephemeral venv in .git/) and run against
# it — makes mismatched black/ruff match CI, enabling safe auto-fix
bash local-ci.sh --sync

# Install a hook directly — chains any existing hook, never clobbers:
bash local-ci.sh --install-hook pre-commit   # fast lint, informational
bash local-ci.sh --install-hook pre-push      # full CI, fail-closed gate
bash local-ci.sh --install-hook               # defaults to pre-push
```

## Example (run against grimoire's own workflows)

```
=== GitHub Actions — Local Run ===

=== Discovered ===
  run   validate.yml › shellcheck › Lint all shell scripts
  skip  validate.yml › shellcheck › Install shellcheck  (OS package/setup step)
  run   ci-mcp.yml › build › build
  run   ci-mcp.yml › test › test

Runnable: 3   Skipped (CI-only): 1

Running: validate.yml › shellcheck › Lint all shell scripts...
✓ PASS
Running: ci-mcp.yml › build › build...
✗ FAIL (exit 1)
npm error code EUSAGE ...
Running: ci-mcp.yml › test › test...
✓ PASS

=== Summary ===
Ran: 3 executed, 2 passed, 1 failed, 1 skipped (CI-only)
Manual attention needed: 1 job(s)
  - ci-mcp.yml › build › build
⚠️  1 issue(s) require manual review.
```

If nothing runnable is found (e.g. every step is CI-only, or no workflows exist), the summary says so explicitly — it never prints a pass for work that didn't happen.

---

## Auto-fix (version-gated)

On a `black`/`ruff` failure, the fixer runs **only if the local tool version is verified to match CI's pin** — either because your venv already has the pinned version, or because you passed `--sync` to build one. On a mismatch (or CI leaving the tool unpinned), the failure is reported but **never auto-fixed**: a different formatter version can rewrite correct files to a style CI doesn't want, so the tool refuses rather than guesses. This is the guarantee that it can't corrupt your working tree with the wrong formatter.

The report tells you exactly where you stand per tool, e.g.:
```
=== Toolchain vs CI ===
  ⚠ black local 26.3.1 ≠ CI pin 24.4.2 — results may differ; auto-fix disabled (report-only). Re-run with --sync to match CI.
```

---

## Hooks — commit vs push, chained not clobbered

| Slot | Install | Runs | Behaviour |
|------|---------|------|-----------|
| `pre-commit` | `--install-hook pre-commit` | fast **lint** subset | informational — never blocks a commit |
| `pre-push` | `--install-hook pre-push` (auto-install default) | **full** workflow (`--gate`) | fail-closed — blocks a red push (`git push --no-verify` bypasses once) |

If a slot already holds a hook this skill didn't write (the pre-commit framework, gitleaks, your own), it's moved to `.git/hooks/<slot>.local-ci-prev` and the installed wrapper **runs it first and honours its exit code** — so a chained secret-scanner keeps its blocking power. Installing our own hook again is idempotent. On a normal run with no local-ci hook anywhere, the **pre-push gate** is auto-installed (chaining anything present). This fixes the earlier trap where installing silently overwrote a framework's `pre-commit` hook and disabled secret scanning.

---

## Limitations

- **Version parity is verified for black/ruff only.** Other tools (pytest, mypy, eslint…) run with whatever's on PATH/in the venv and aren't version-checked — but the tool never *writes* with them, so it's a reporting caveat, not a corruption risk.
- **Pin detection covers `pip install X==Y` and `-r requirements*.txt`.** Pins expressed via `pyproject.toml`/`poetry.lock`/constraints files or baked into a container read as "CI unpinned" → report-only.
- **Without a venv and without `--sync`, `pip install` steps run against your ambient Python** (they're real CI commands) and can touch your user/global site-packages. Use a project `venv`/`.venv` or `--sync` to keep installs contained.
- **CI-only steps are skipped, not simulated.** Verify those in CI, not here.
- **No cross-job graph.** `needs:` ordering and `strategy.matrix` aren't modelled; steps run in file order. Stop-on-failure is enforced within a job, not across dependent jobs.

---

## Integration with other skills

- **pre-push-validation** — an older `validate.yml`-focused fail-closed pre-push gate. `local-ci` now covers the same ground more generally and installs its own fail-closed `pre-push` gate, so a repo using `local-ci` usually won't also need it. Both write `.git/hooks/pre-push` — pick one owner per repo.
- **format-before-commit** — narrower, Python-only formatting check.
- **github-morning-run** — use after pushing, to catch what CI found on the morning audit.

---

## Roadmap

- [x] SKILL.md and README.md accurate to shipped behaviour
- [x] Real YAML parsing (PyYAML) for job/step discovery — no line-grep
- [x] Real execution of discovered `run:` steps, judged by exit code
- [x] CI-only step detection (contexts, secrets, releases, OS package installs)
- [x] Auto-fix for black/ruff with re-run confirmation
- [x] Activate the target repo's own venv/.venv before running anything
- [x] Distinct "toolchain issue" reporting for command-not-found / broken shim failures
- [x] Stop a job at its first failed step (mirror CI); disambiguate unnamed steps
- [x] Parse CI's pinned versions; gate auto-fix on verified version match
- [x] `--sync`: build CI's exact pinned toolchain in an ephemeral `.git/` venv
- [x] Two hook slots — fast `pre-commit` lint / fail-closed `pre-push` gate (`--gate`)
- [x] Chaining hook installer — preserves any existing hook, never clobbers
- [x] Renamed `github-actions-locally` → `local-ci`
- [ ] Auto-fix for prettier/eslint (JS/TS projects)
- [ ] Pin detection for pyproject.toml / poetry.lock / constraints files
- [ ] Job dependency graph (`needs:`) and matrix expansion awareness
- [ ] Caching of discovered jobs (skip re-parsing on each run)

---

## References

- [SKILL.md](SKILL.md) — full behaviour reference
- `local-ci.sh` — the script
