# Roadmap

> Auto-generated overview of outstanding work across all public skill clusters.
> Run `bash scripts/roadmap-collect.sh` to regenerate, or `bash scripts/roadmap-collect.sh --json` for machine-readable output.

**Last updated:** 2026-09-28
**Open items:** 57 | **Completed:** 222

---

## Priority legend

Most open items fall into two categories:

| Category | Description | Action needed |
|----------|-------------|---------------|
| 🧪 **Requires real session** | Item can only be closed during actual usage | Wait for opportunity |
| 📝 **Worked example** | Needs a concrete before/after or step-by-step | Author when time allows |

Items marked "Ship: copy to ~/.claude/skills/..." are legacy — the install path is now automated via `install-all.sh`.

---

## Open items by cluster

### 01-meta

- **cwd-verification**: Add all known path pairs as they are encountered
- **github-authored-repos**: Test on one multi-repo session (requires real session)
- **github-authored-repos**: Document any new gotchas from real usage (requires real usage)
- **mid-task-checkin**: Consider a heuristic for detecting user typing mid-task (if tooling permits)
- **session-skill-extractor**: Multi-session aggregation (combine patterns across sessions)
- **session-skill-extractor**: Per-project pattern weighting
- **session-skill-extractor**: Confidence scoring improvements
- **skill-keyword-lookup**: Add synonym map (for example: "standards" -> "practices")
- **skill-keyword-lookup**: Add `--json` output mode for machine consumers
- **skill-vetter**: Test on 3 real third-party skills (requires real sessions)
- **task-decomposer**: Add example: subagent execution guide for running chunks one-by-one
- **task-decomposer**: Add `--resume` mode: reads existing run-book, skips completed chunks
- **task-handoff**: Add `--auto` mode: triggered automatically when context exceeds a threshold
- **test-before-asking**: Test across 5 sessions to confirm the rule lands correctly
- **verify-code-version**: Test on DNSResolver and Slice-N-Dice sessions

### 02-comms

- **executive-translate**: Test on 3 real findings
- **human-rewrite**: Test on 5 real outputs from other skills
- **human-rewrite**: Add any further rules that emerge from real usage
- **tone-check**: Test on 5 real drafts across different audience tiers

### 03-incident

- **incident-appendix**: Test on 2 real investigation write-ups
- **incident-ask-builder**: Test on 2 real incident scenarios
- **risk-to-action**: Test on 3 real risk items

### 04-security

- **ios-signing-risk**: Test on a real IPA integrity scenario

### 05-technical

- **codebase-holistic-review**: Add worked example: Python web service holistic review (before/after findings)
- **codebase-holistic-review**: Add worked example: Node.js monorepo review
- **codebase-holistic-review**: Test on 3 real repos and capture recurring finding patterns
- **codebase-holistic-review**: Add language-specific risk pattern tables (Python, TypeScript, C#, Go)
- **python-black-ruff-authoring**: Test on 3 Python repos with different Ruff profiles

### 07-devops

- **docker-ghcr-publish**: Test on pdf2john-docker and bgp_rogue
- **dotnet-ci-template**: Test on one new repo (requires real session)
- **dotnet-ci-template**: Document any new gotchas from real usage (requires real session)
- **format-before-commit**: Test on 3 Python repos
- **git-push-protocol-handler**: Test on a representative set of repos
- **github-history-wipe**: Test on one repo end-to-end (requires real session)
- **github-history-wipe**: Document any new gotchas from real usage (requires real session)
- **github-release-workflow**: Test on DNSResolver v2 release
- **local-ci**: Auto-fix for prettier/eslint (JS/TS projects)
- **local-ci**: Pin detection for pyproject.toml / poetry.lock / constraints files
- **local-ci**: Job dependency graph (`needs:`) and matrix expansion awareness
- **local-ci**: Caching of discovered jobs (skip re-parsing on each run)
- **npm-lockfile-integrity**: Test on 3 Node.js repos
- **npm-provenance-attestation**: Test on 3 Node.js repos with mixed provenance coverage
- **portfolio-readme-generator**: Planned enhancement
- **pre-commit-aware-commits**: Test on DNSResolver and Slice-N-Dice
- **python-ci-lint-precheck**: Test on Slice-N-Dice and DNSResolver
- **python-ci-template**: Test on one new repo (requires real session)
- **python-ci-template**: Document any new gotchas from real usage (requires real session)
- **python-lockfile-integrity**: Test on 3 Python repos (pip-tools, poetry, uv variants)
- **readme-version-pin**: Test on DNSResolver and Slice-N-Dice release cuts
- **repo-compass**: Test on 3 repos with varying states (tidy, lagged, genuinely outstanding)
- **repo-publication-prep**: Test end-to-end on one new repo (requires real session)
- **repo-publication-prep**: Document any new gotchas from real usage (requires real usage)
- **repo-security-bootstrap**: Test on one repo end-to-end (requires real session)
- **repo-security-bootstrap**: Document any new gotchas from real usage (requires real session)
- **roadmap-sync**: Test on DNSResolver and Slice-N-Dice
- **terraform-aws-syntax**: Add resource type gotchas as they are encountered
- **terraform-version-compat**: Add known-good version matrix for frequently used module combinations

> **08-offsec** roadmap items now live in the private `grimoire-offsec` submodule
> (`clusters-offsec/`) alongside the skills they track.

> Regenerated from `scripts/roadmap-collect.sh` on 2026-09-28. Previous manual entries
> (legacy "Ship: copy to ~/.claude/skills/..." items, stale worked-example asks already
> superseded in-source) were dropped — the per-skill README `## Roadmap` sections are the
> source of truth; this file is a snapshot of them.

---

## Infrastructure roadmap

These are repo-level improvements not tied to individual skills:

- [x] Add grimoire-private cluster README standardisation (mirror public format)
- [x] Add `scripts/roadmap-close.sh` — marks items done by skill name + index
- [x] Add MCP tool for roadmap query (`grimoire-roadmap-status`)
- [x] Investigate semantic search across SKILL.md content for skill discovery
- [x] Add skill dependency graph generation (which skills reference others)
- [x] Add `uninstall-vscode.sh` — removes grimoire entry from mcp.json, removes prompt path from settings.json, deletes prompts/ build output
- [x] Add `uninstall-all.sh` — removes grimoire-managed skills from a target skills directory (default: `~/.claude/skills`)
- [x] Timestamped versioned backups for `install-all.sh` (Claude Code) — same pattern as install-vscode.sh (date-stamped, keep last 5)
- [x] Add `--update` mode to `install-all.sh` — backs up existing skill to `.backups/<skill>-YYYYMMDD-HHMMSS/`, overwrites with latest, prunes to 5 backups. `--force` to overwrite without backup. Default remains skip-if-exists for safety.
- [x] Add `roadmap-driver` skill (01-meta) — reads outstanding roadmap items, selects next work item, invokes karpathy-framework to plan and execute. Chains: repo-compass (assess) → task-decomposer (break down) → karpathy-framework (plan) → karpathy-verify (confirm). Trigger: "what should I work on next?" / "pick up from the roadmap"
- [x] Cluster README "when to use" enhancement — each cluster README gains a workflow section explaining when/how each skill should be invoked, with trigger phrases and ideal sequencing. ~~Start with 07-devops as template, then roll out to all clusters (01-meta through 09-odpc)~~ completed for public clusters (2026-06-15); private clusters were handled in `grimoire-private` (06-study and 09-odpc).
- [x] Add MCP server logging — file-based + stderr, structured format with timestamps, context, and metadata (`mcp-server/src/logger.ts`)
- [x] Add fail-open error handling — tool failures return error content instead of crashing the server; registry load failure starts with 0 tools; global uncaught exception/rejection handlers keep server alive
- [x] Add MCP server health-check tool — a no-op `grimoire_health` tool that returns server uptime, tool count, and log file path for diagnostics
- [x] Add MCP server log rotation — prevent unbounded log growth (rotate at 10MB, keep 3)
- [x] Add `install-jetbrains.sh` — JetBrains MCP support (bypasses corporate VS Code MCP policy). Includes path auto-detection, `--mcp-path` override, backup support, and dry-run/apply modes.
- [x] Post-merge changelog tidy pass — sync `CHANGELOG.md` with latest merged PRs and release notes after each infrastructure batch.
- [x] `install-jetbrains.sh` + `install-vscode.sh`: resolve full Node.js path at install time — write the absolute path to node >=22 into mcp.json rather than bare `node`, so the config works correctly when the IDE launches without the user's shell PATH (nvm aliases are not inherited by GUI apps).

### Release automation (release-please migration)

> **Context:** `main` branch protection (added 2026-09-28) requires 6 status checks
> (README quality, Registry sync, Shellcheck, Skill structure, gitleaks, trufflehog) but
> deliberately excludes `devops-check.yml`'s "DevOps Compliance" job, which runs
> `check-version-sync.sh` and hard-fails (`exit 1`) whenever `VERSION` != latest git tag
> != latest GitHub release. That's structurally unavoidable under the current delivery
> loop (documented in `CLAUDE.md`): `VERSION` is bumped *inside* the feature PR, and the
> tag/release are only created *after* merge (`git tag vX.Y.Z && git push origin vX.Y.Z`
> triggers `release-on-tag.yml`). So every version-bumping PR necessarily shows this
> check red for its entire lifetime — requiring it as a branch-protection gate would
> permanently block every release PR from merging. This is not a bug in the check's
> comparison logic (exact equality is the right invariant for `main` post-release); it's
> a mismatch between a PR-time gate and a merge-then-tag-after workflow.
>
> There's already a correctly-scoped, non-blocking version of this same check in
> `validate.yml`'s `version-tag-sync` job — it only runs `on: push` to `main` (never on
> PRs) and only emits `::warning::`, never `exit 1`. `devops-check.yml`'s job is the
> newer, stricter, mis-scoped duplicate.
>
> **The fix:** adopt a release-please-style flow (or `semantic-release`/`changesets`) so
> feature PRs never touch `VERSION` at all. Merges to `main` accumulate normally; a bot
> maintains a standing "chore(release): vX.Y.Z" PR (built from conventional-commit
> messages) that's only merged when cutting a release, and merging *that* PR bumps
> `VERSION`, creates the tag, and publishes the release as one atomic step. Once that's
> live, ordinary feature PRs will trivially pass the version-sync check (they never touch
> `VERSION`), so it can be safely promoted to a required branch-protection check —
> excepting the release-please PR itself, which should stay exempted or reviewed by hand.
>
> **Scope for whoever picks this up** (real engineering work, not mechanical — suggest a
> capable model, not a lightweight one, given it touches release infra and CHANGELOG
> format):
> 1. Evaluate `release-please` (Google, GitHub Action, config-file driven, supports
>    arbitrary `release-type: simple` for a bare `VERSION` file) vs `changesets` (more
>    manual per-PR changeset files, common in JS monorepos — less natural fit here since
>    this repo isn't primarily an npm package) — recommend `release-please`.
> 2. Wire up `.release-please-manifest.json` + `release-please-config.json` (or the
>    simpler single-package config) targeting the root `VERSION` file.
> 3. Decide whether `CHANGELOG.md`'s existing hand-written style (see any entry above)
>    stays hand-written pre-release and release-please just appends, or whether it
>    switches to fully generated entries from conventional-commit messages — hand-written
>    entries have more narrative detail than typical auto-generated ones, worth discussing
>    with the user before deciding.
> 4. Retire `devops-check.yml`'s `devops-check` job's hard-fail version-sync step (keep
>    clone-ref pinning and test-baseline checks — those aren't affected by this).
> 5. Once merge PRs no longer touch `VERSION`, add `DevOps Compliance` (or whatever the
>    surviving check is renamed to) back into `main`'s required status checks via
>    `gh api --method PUT repos/incendiary/grimoire/branches/main/protection`.
> 6. Update `CLAUDE.md`'s "Delivery loop" section — the manual `bump VERSION` /
>    `git tag vX.Y.Z && git push origin vX.Y.Z` steps go away entirely.

### Roadmap sync check (local + CI)

> **Context:** This `ROADMAP.md` file is meant to be a generated snapshot of the
> `## Roadmap` sections in every skill's own `README.md` (the source of truth), produced
> by `scripts/roadmap-collect.sh`. Nothing enforces that it's actually regenerated —
> it drifted for over two months (last regenerated 2025-07-14) and was showing 7 items
> as open that were already `[x]` in their skill READMEs, discovered and fixed
> 2026-09-28. There's no mechanism today, local or in CI, that would catch this drift
> again before it recurs.
>
> Do not confuse this with the existing `roadmap-sync` skill (`clusters/07-devops/`) —
> that's a *generic, distributable* skill for maintaining a single README's roadmap
> section in any downstream repo a user installs it into. This item is grimoire's own
> internal problem: keeping one aggregated file in sync with dozens of per-skill
> README sections. Don't reuse that skill's name or slot for this.
>
> **The fix belongs in the `devops-practices` skill's `check-*.sh` family**
> (`clusters/07-devops/devops-practices/`: `check-version-sync.sh`,
> `check-clone-refs.sh`, `check-test-baseline.sh`) — that's the established convention
> for "does committed state match a derivable truth" checks, already wired into both
> `devops-check.yml` (CI) and the local pre-push hook via `local-ci.sh`. Extending it
> avoids adding a fifth place this class of check lives.
>
> **Scope for whoever picks this up** (moderate, well-bounded implementation work —
> a capable general-purpose model can handle it; no deep judgment calls beyond the
> design below, which is already settled):
> 1. **Delimit the generated block** in `ROADMAP.md` with HTML comment markers
>    (`<!-- ROADMAP-COLLECT:START -->` / `<!-- ROADMAP-COLLECT:END -->`) wrapping only
>    the "Open items by cluster" section + summary line. Leave the Priority legend and
>    this Infrastructure roadmap section (including the release-automation and
>    mlx-agent-server subsections) outside the markers — that content is editorial,
>    not mechanically derivable, and must not be touched by the tooling.
> 2. **New `check-roadmap-sync.sh`** alongside the other three check scripts: reuses
>    `scripts/roadmap-collect.sh`'s collection logic, diffs it against the delimited
>    block.
>    - `--check` (default): exit 1 and print a diff if stale — this is the gate.
>    - `--fix`: rewrites the block in place — this is the auto-fixer.
> 3. **Pre-commit hook (local, auto-fix):** if any staged file matches
>    `clusters/*/*/README.md`, run `--fix` and re-stage `ROADMAP.md` — same pattern
>    Black/Ruff already use in this repo's pre-commit slot.
> 4. **Pre-push hook + `devops-check.yml` (fail-closed):** run `--check` — catches
>    drift from edits made outside a normal commit flow (GitHub web UI edits,
>    `--no-verify` commits, hook not installed on a fresh clone).
> 5. Use **one script for all three callers** (pre-commit, pre-push, CI) — do not
>    let the check logic diverge across them. `devops-check.yml`'s version-sync job and
>    `validate.yml`'s `version-tag-sync` job already diverged this way (see the
>    release-automation item above) — don't repeat that mistake here.

### mlx-agent-server integration

> Integration with `mlx-agent-server` (`~/Projects/mlx-agent-server`): a local MLX
> inference server + agent runtime for authorized offensive work on Apple Silicon. Its
> roadmap items G.1/G.2 make it an **MCP client** of Grimoire's stdio server so a local
> (uncensored) model can call Grimoire's offsec + devops action-skills as tools. These
> items are Grimoire's side of that contract. Action once `mlx-agent-server` reaches an
> operational state (its v0.3.0 agent runtime).

- [ ] **Verify action-skills are externally consumable via MCP**: audit `mcp-server/registry.json` so every 07-devops and 08-offsec action-skill exposes a clear description + input schema usable by an external MCP client (not just Claude Code). Priority skills for the consumer: `git-push-protocol-handler`, `project-delivery-workflow`, `github-release-workflow`, `bof-dev-conventions`, `shellcode-dev-conventions`, `process-injection-taxonomy`.
- [ ] **Document the external-MCP-client contract**: short doc on how a non-Claude client (e.g. `mlx-agent-server`) launches the stdio server, lists tools, and calls them; note the consumer namespaces skills as `grimoire.<skill>`. Cross-reference `mlx-agent-server` ROADMAP items G.1/G.2 (raw URL: `https://github.com/incendiary/mlx-agent-server/blob/main/ROADMAP.md`).
- [ ] **Local-model backend option (opsec)**: for Grimoire flows that invoke an LLM, allow targeting a local MLX backend (`mlx-agent-server`, OpenAI-compatible at `http://127.0.0.1:8080/v1`) instead of cloud, so offensive-skill reasoning stays on-box. Investigate which skills/scripts call models and add a configurable `base_url`/model.
