# Roadmap

> Auto-generated overview of outstanding work across all public skill clusters.
> The "Open items by cluster" section is kept in sync automatically — see
> `clusters/07-devops/ci-standards/check-roadmap-sync.sh`. To regenerate by hand,
> run `bash scripts/roadmap-collect.sh` (or `--json` for machine-readable output) and
> `bash clusters/07-devops/ci-standards/check-roadmap-sync.sh . --fix`.

**Last updated:** 2026-10-09
**Open items:** 9 | **Completed:** 213

---

## Priority legend

Most open items fall into two categories:

| Category | Description | Action needed |
|----------|-------------|---------------|
| 🧪 **Requires real session** | Item can only be closed during actual usage | Wait for opportunity |
| 📝 **Worked example** | Needs a concrete before/after or step-by-step | Author when time allows |

Items marked "Ship: copy to ~/.claude/skills/..." are legacy — the install path is now automated via `install-all.sh`.

---

## Discoverability and consolidation programme (priority: top)

Findings: [REVIEW.md](REVIEW.md) (2026-09-29). Programme goal: you can find the right skill
by intent (measured by RA-05) and by prefix autocomplete (after RA-15).

**To execute:** a master agent (Opus) starts at
[docs/tasks/discoverability/00-runbook.md](docs/tasks/discoverability/00-runbook.md), which
defines dispatch waves, the sub-agent prompt template, verification, escalation, and merge
order. Each brief is self-contained for a sub-agent with no context. Haiku briefs are
deliberately prescriptive (exact commands, pre-decided wording) so the cheaper tier is safe.
"Model" is the Agent tool `model` alias; "Fallback" is used if verification fails.

Tick the first column when a task's brief reaches `> Status: done`.

| | ID | Task | Model | Fallback | Wave | Brief |
|---|---|---|---|---|---|---|
| [x] | RA-01 | Frontmatter checker script | haiku | sonnet | 1 | [ra-01](docs/tasks/discoverability/ra-01-frontmatter-check.md) |
| [x] | RA-02 | Frontmatter descriptions on every skill (4 parallel scopes) | haiku ×4 | sonnet | 2 | [ra-02](docs/tasks/discoverability/ra-02-frontmatter-descriptions.md) |
| [x] | RA-03 | Single-source descriptions for prompts and MCP; frontmatter CI check | sonnet | opus | 3 | [ra-03](docs/tasks/discoverability/ra-03-single-source-descriptions.md) |
| [ ] | RA-04 | Generate `SKILLS.md`, retire hand-kept README index | haiku | sonnet | 3 | [ra-04](docs/tasks/discoverability/ra-04-skills-catalogue.md) |
| [x] | RA-05 | Discoverability spot-check list (owner checkpoint) | sonnet | opus | 1 | [ra-05](docs/tasks/discoverability/ra-05-discoverability-test.md) |
| [x] | RA-06 | Usage report from transcripts and MCP logs | haiku | sonnet | 1 | [ra-06](docs/tasks/discoverability/ra-06-usage-telemetry.md) |
| [x] | RA-07 | Delete five always-on skills | haiku | sonnet | 1 | [ra-07](docs/tasks/discoverability/ra-07-remove-always-on.md) |
| [ ] | RA-08 | `ci-local` = `local-ci` + `pre-push-validation` | opus | owner | 3 | [ra-08](docs/tasks/discoverability/ra-08-ci-local.md) |
| [ ] | RA-09 | `py-lint` = four Python lint skills | sonnet | opus | 3 | [ra-09](docs/tasks/discoverability/ra-09-py-lint.md) |
| [ ] | RA-10 | `deps-integrity` = npm/python lockfile + provenance | sonnet | opus | 3 | [ra-10](docs/tasks/discoverability/ra-10-deps-integrity.md) |
| [ ] | RA-11 | `tf-guardrails` = three terraform skills | haiku | sonnet | 3 | [ra-11](docs/tasks/discoverability/ra-11-tf-guardrails.md) |
| [x] | RA-12 | `ci-standards` = the DevOps standard + its updater | sonnet | opus | 3 | [ra-12](docs/tasks/discoverability/ra-12-ci-standards.md) |
| [ ] | RA-13 | `roadmap-driver` → `roadmap`; delete `grimoire-roadmap-status` | haiku | sonnet | 3 | [ra-13](docs/tasks/discoverability/ra-13-roadmap.md) |
| [ ] | RA-14 | `repo-compass` → `orient`, absorbing the push check | haiku | sonnet | 3 | [ra-14](docs/tasks/discoverability/ra-14-orient.md) |
| [ ] | RA-15 | Pathway-prefix rename (32 skills), install-side clean-up | sonnet + opus review | opus | 4 | [ra-15](docs/tasks/discoverability/ra-15-rename.md) |
| [ ] | RA-16 | Pathway tables in `orient`, `plan`, `release`, `publish` | haiku | sonnet | 5 | [ra-16](docs/tasks/discoverability/ra-16-pathway-entries.md) |
| [ ] | RA-17 | Delete `PROJECT-WORKFLOWS.md`, short README table | haiku | sonnet | 6 | [ra-17](docs/tasks/discoverability/ra-17-workflows-doc.md) |
| [ ] | RA-18 | Report old names outside the repo (read-only; owner approves edits) | haiku | sonnet | 5 | [ra-18](docs/tasks/discoverability/ra-18-cross-repo-report.md) |
| [x] | RA-19 | `npm audit fix` in `mcp-server` | haiku | sonnet | 1 | [ra-19](docs/tasks/discoverability/ra-19-npm-audit-dependabot.md) |
| [x] | RA-20 | Align TruffleHog, SHA-pin actions | haiku | sonnet | 1 | [ra-20](docs/tasks/discoverability/ra-20-pin-versions.md) |
| [x] | RA-22 | Delete unschedulable validation items | haiku | sonnet | 1 | [ra-22](docs/tasks/discoverability/ra-22-delete-validation-items.md) |
| [ ] | RA-23 | Evidence-based prune report (owner decides) | sonnet | owner | later | [ra-23](docs/tasks/discoverability/ra-23-usage-prune.md) |
| [x] | RA-24 | Remove per-skill Installation boilerplate and its CI job | haiku | sonnet | 1 | [ra-24](docs/tasks/discoverability/ra-24-readme-install-boilerplate.md) |
| [x] | RA-25 | Delete three unused scripts | haiku | sonnet | 1 | [ra-25](docs/tasks/discoverability/ra-25-dead-scripts.md) |
| [x] | RA-26 | Drop version-sync checks superseded by release-please | haiku | sonnet | 1 | [ra-26](docs/tasks/discoverability/ra-26-version-sync-ci.md) |
| [x] | RA-27 | Share duplicated installer functions | sonnet | opus | 1 | [ra-27](docs/tasks/discoverability/ra-27-installer-dedupe.md) |
| [ ] | RA-28 | Post-programme ponytail-debt ledger and ponytail-audit re-run | sonnet | opus | 7 | [ra-28](docs/tasks/discoverability/ra-28-ponytail-followup.md) |

Revised by the 2026-10-04 over-engineering audit (see `REVIEW.md`). Open owner decisions are listed at the end of `REVIEW.md`.

---

## Open items by cluster

<!-- ROADMAP-COLLECT:START (auto-generated — do not hand-edit; run check-roadmap-sync.sh --fix) -->
### 01-meta

  - **task-handoff**: Add `--auto` mode: triggered automatically when context exceeds a threshold

### 05-technical

  - **codebase-holistic-review**: Add worked example: Python web service holistic review (before/after findings)
  - **codebase-holistic-review**: Add worked example: Node.js monorepo review

### 07-devops

  - **local-ci**: Auto-fix for prettier/eslint (JS/TS projects)
  - **local-ci**: Pin detection for pyproject.toml / poetry.lock / constraints files
  - **local-ci**: Job dependency graph (`needs:`) and matrix expansion awareness
  - **local-ci**: Caching of discovered jobs (skip re-parsing on each run)
  - **portfolio-readme-generator**: Planned enhancement
  - **terraform-version-compat**: Add known-good version matrix for frequently used module combinations

---

**Summary:** 9 open items | 213 completed items
<!-- ROADMAP-COLLECT:END -->

> **08-offsec** roadmap items now live in the private `grimoire-offsec` submodule
> (`clusters-offsec/`) alongside the skills they track — outside the scan scope above
> (public `clusters/` only).

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

- [x] **Release automation (release-please migration)** — feature PRs no longer touch
  `VERSION` at all. `release-please-action` (`.github/workflows/release-please.yml`,
  replacing the retired `release-on-tag.yml`) maintains a standing
  "chore(release): vX.Y.Z" PR from conventional-commit messages; merging it bumps
  `VERSION` (`release-please-config.json`, `version-file: VERSION`), tags, and creates
  the GitHub Release atomically. `CHANGELOG.md` stays hand-written
  (`skip-changelog: true`) per the decided approach. Auth via a `RELEASE_PLEASE_TOKEN`
  repo secret (fine-grained PAT), not the default `GITHUB_TOKEN`, so the release PR
  actually triggers `pull_request`-scoped CI. See `CLAUDE.md`'s "Releases" section for
  the full flow.
  **Deliberately not done:** promoting `devops-check.yml`'s version-sync check to a
  required branch-protection check. It should now pass trivially on ordinary feature
  PRs, but will still trip on the release-please PR itself (which does legitimately
  bump `VERSION` ahead of the tag until it's merged) — branch protection can't exempt
  one specific PR from a required check, so it stays excluded, same as before. This is
  no longer a "recurs on every PR" problem though — it's now confined to the one PR
  type that's expected to show it.

- [x] **Roadmap sync check (local + CI)** — `ROADMAP.md`'s "Open items by cluster"
  section is now delimited (`<!-- ROADMAP-COLLECT:START/END -->`) and enforced by
  `clusters/07-devops/ci-standards/check-roadmap-sync.sh` (`--check` gate,
  `--fix` regenerator): wired into `devops-check.yml` as a 4th required check, and
  into `.pre-commit-config.yaml` as a local auto-fix hook triggered on any
  `clusters/*/*/README.md` change. Along the way, fixed a real bug in
  `devops-check.yml`: its three (now four) check steps lacked
  `continue-on-error: true`, so a version-sync failure (expected on every
  version-bump PR) was silently skipping clone-ref-pinning and test-baseline
  checks entirely — added a final "Fail if any check failed" step so the job's
  overall pass/fail is still accurate now that all steps always run.
