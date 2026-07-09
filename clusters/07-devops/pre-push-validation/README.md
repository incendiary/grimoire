# pre-push-validation

Run your repository's **own CI checks locally, before pushing** — fail in seconds instead of
waiting minutes for GitHub Actions to reject the push.

## How it works

The script is **workflow-driven and repo-agnostic**. It does not know or care what project it
is in:

1. Discovers every `.github/workflows/*.yml` / `*.yaml`.
2. Parses them with `python3` + PyYAML and extracts each job step's `run:` command.
3. Honours each step's effective `working-directory` (step → job `defaults.run` → workflow
   `defaults.run`).
4. Runs each runnable step locally and judges it by **exit code** — exactly as CI does.
5. Blocks the push (exit 1) if any step fails.

There is no hardcoded per-repo logic and no tech-stack guessing. **What CI runs is what runs
locally.** When the CI workflow changes, local validation follows automatically.

### CI-only steps are skipped explicitly

Steps that cannot meaningfully run outside GitHub Actions are skipped with a printed reason —
never a silent pass:

| Skipped when the command… | Reason shown |
|---|---|
| contains `${{ ... }}` | uses a GitHub Actions context |
| references `secrets.` | references secrets. |
| runs `gh release` | creates/edits a GitHub release |
| writes `$GITHUB_OUTPUT` / `$GITHUB_ENV` / `$GITHUB_STEP_SUMMARY` | writes a CI-only GITHUB_* file |
| runs `sudo` / `apt-get` / `yum install` / `apk add` | OS package/setup step — provisioned locally instead |

### Fail-closed

Judgement is by exit code only — no output-string matching. A missing tool surfaces as
command-not-found (non-zero exit) and blocks the push with its output shown. If `python3` or
PyYAML is missing, the script fails closed with an install hint rather than passing silently.

## Example (run against grimoire's 5 workflows)

```
=== Pre-Push Validation ===

Checking ci-mcp.yml › build... ✓ PASS            # ran in mcp-server/ (working-directory)
Checking validate.yml › Lint all shell scripts... ✓ PASS
Checking validate.yml › No stale path references... ✓ PASS
Skipped — CI-only: release-on-tag.yml › Create GitHub Release (creates/edits a GitHub release)
Skipped — CI-only: validate.yml › Install shellcheck (OS package/setup step — provisioned locally instead)

=== Results ===
Passed:  10
Failed:  0
Skipped: 6 (CI-only)
✓ All runnable checks passed
```

## Requirements

- `python3` with `PyYAML`. Fails closed if absent.
- Runs a repo's CI commands **verbatim**, so it inherits their behaviour — including any
  local/CI drift (a newer local `shellcheck` may flag more than CI's pinned one; a stale local
  `package-lock.json` legitimately fails `npm ci`). This is faithful mirroring, not a bug.

## Installation

### Claude Code

```bash
bash install-all.sh            # first install
bash install-all.sh --update   # update an existing copy (backs up the old one)
```

Then run in any repo:

```bash
bash ~/.claude/skills/pre-push-validation/pre-push-validation.sh
```

### VS Code (Copilot Chat, prompt file)

After `bash build.sh`, reference it as `#pre-push-validation` in Copilot Chat, or run the
script directly as above.

### MCP (VS Code / JetBrains)

Registered as the `pre-push-validation` action tool in grimoire's MCP server
(`mcp-server/registry.json`). Build with `cd mcp-server && npm ci && npm run build`, then invoke
the `pre-push-validation` tool from your MCP client.

## The pre-push hook (opt-in)

After a successful run in an interactive terminal, the script offers to install a `pre-push`
git hook. You can also install it non-interactively:

```bash
bash pre-push-validation.sh --install-hook
```

The hook:
- runs the validation before every `git push`
- calls the script by absolute path, so it works from any repo layout
- **never prompts when run as the hook** (no TTY) — it just validates and blocks on failure
- bypass once with `git push --no-verify`; uninstall with `rm .git/hooks/pre-push`
