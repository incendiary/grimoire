# github-actions-locally

> **Cluster:** 07-devops | **Status:** complete | **Updated:** 2026-07-09

Run GitHub Actions workflow jobs locally before pushing. Discovers every `.github/workflows/*.yml` with a real YAML parser, executes each job's `run:` steps, auto-fixes what it can (black, ruff), and reports **only what actually ran** — never a fake pass for work it skipped.

---

## What this skill does

Activates the repo's own `venv`/`.venv` first — never the caller's global PATH — so lint/format tools resolve to the same install CI actually uses, not whatever happens to be on `$PATH`. Parses every workflow file with `python3` + PyYAML (not a line-grep), extracts each job's `run:` steps, and executes them locally — honouring `working-directory` the same way GitHub Actions does. Steps that can only run in CI (GitHub Actions `${{ }}` contexts, `secrets.`, `gh release`, `$GITHUB_OUTPUT`/`$GITHUB_ENV`/`$GITHUB_STEP_SUMMARY`, OS package installs) are **skipped with a printed reason**, never silently treated as passing.

Every executed step is judged by its **exit code**, exactly as CI does. Always exits 0 itself — this tool never blocks anything; the printed report is the signal. For a fail-closed pre-push gate, use the `pre-push-validation` skill instead.

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
#github-actions-locally
```

### MCP (VS Code / JetBrains)

Registered as the `github-actions-locally` action tool in grimoire's MCP server (`mcp-server/registry.json`). Build with `cd mcp-server && npm ci && npm run build`, then invoke the `github-actions-locally` tool from your MCP client.

---

## Usage

```bash
# Discover and run every runnable step in every workflow
bash github-actions-locally.sh

# Only steps from jobs whose name looks lint-related
bash github-actions-locally.sh --lint

# Only steps from jobs whose name looks test-related
bash github-actions-locally.sh --test

# Restrict to one workflow file (substring match on filename)
bash github-actions-locally.sh --workflow validate.yml

# Show what would run, without executing anything
bash github-actions-locally.sh --dry-run

# Same discovery output as --dry-run, explicit alias
bash github-actions-locally.sh --list
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

## Auto-fix

On failure, if the failing command mentions `black` or `ruff` **and a project `venv`/`.venv` was activated**, the corresponding fixer runs (`black .` / `ruff check --fix .`) and the original command is re-run once to confirm. Any other failure — or any failure when no venv was found — is reported only, never auto-fixed: running `black`/`ruff` from an arbitrary global install can silently apply a different formatting style than CI's pinned version wants, so this refuses rather than guesses.

---

## Limitations

- **Auto-fix covers black/ruff only, and only inside an activated venv** — no prettier/eslint auto-fix yet (see Roadmap), and no auto-fix at all if the repo has no `venv`/`.venv`.
- **A venv doesn't guarantee an exact version match with CI** — only that it's not the caller's unrelated global PATH. If a stale venv hasn't been reinstalled since CI's pin last bumped, results can still diverge; compare `<tool> --version` against the workflow's install step if a result looks wrong.
- **CI-only steps are skipped, not simulated.** Verify those in CI, not here.
- **No job dependency graph.** `needs:` ordering and matrix (`strategy.matrix`) expansion aren't modelled — steps run in file order, not GitHub Actions' scheduling order.

---

## Integration with other skills

- **pre-push-validation** — the fail-closed counterpart. Use that as an installed git hook to actually block bad pushes; use this skill for exploratory "what does CI currently say" runs that never block anything.
- **format-before-commit** — narrower, Python-only formatting check.
- **github-morning-run** — use after pushing, to catch what CI found on the morning audit.

---

## Roadmap

- [x] SKILL.md and README.md accurate to shipped behaviour
- [x] Real YAML parsing (PyYAML) for job/step discovery — no line-grep
- [x] Real execution of discovered `run:` steps, judged by exit code
- [x] CI-only step detection (contexts, secrets, releases, OS package installs)
- [x] Auto-fix for black/ruff with re-run confirmation
- [x] Activate the target repo's own venv/.venv before running anything; disable auto-fix without one
- [x] Distinct "toolchain issue" reporting for command-not-found / broken shim failures
- [ ] Auto-fix for prettier/eslint (JS/TS projects)
- [ ] Job dependency graph (`needs:`) and matrix expansion awareness
- [ ] Caching of discovered jobs (skip re-parsing on each run)

---

## References

- [SKILL.md](SKILL.md) — full behaviour reference
- `github-actions-locally.sh` — the script
