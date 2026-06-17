# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.6.10] — 2026-06-18

Offsec taxonomy expansion and C2 integration checklist additions.

### Added
- `08-offsec/process-injection-taxonomy` — two new technique table rows (thread pool
  TpAllocWork, kernel-mode driver-based); Cobalt Strike delivery decision matrix
  (BOF vs post-ex DLL vs fork-and-run); link to `edr-test-loop` in validation step
- `08-offsec/c2-integration-checklist` — expanded Havoc demon module checklist
  (RegisterCommand, task dispatcher, sleep mask interaction, beacon vs demon comms
  model differences); DNS listener OPSEC checklist (TTL, NS delegation, SOA, canary
  domain split, wildcard record); post-engagement cleanup checklist (implant termination,
  artifact removal, infrastructure teardown, IOC handoff)

---

## [1.6.9] — 2026-06-18

DevOps GHA snippets, multi-arch Docker support, script enhancements.

### Added
- `07-devops/npm-lockfile-integrity` — CI workflow snippet (`npm ci` + audit + drift check)
- `07-devops/npm-provenance-attestation` — CI workflow snippet (`npm audit signatures` + critical package provenance check)
- `07-devops/docker-ghcr-publish` — multi-arch buildx guide (`linux/amd64,linux/arm64`) and
  GHA workflow for automated GHCR publish on tag push
- `07-devops/git-push-protocol-handler` — SSH agent start/add sequence with diagnosis table
- `07-devops/portfolio-readme-generator` — per-language README skeletons (Python CLI, C# Windows tool, C++ BOF)
- `07-devops/python-lint-gate` — `--staged` flag for staged-files-only mode; pytest F401
  conftest handling notes (`per-file-ignores` and `# noqa: F401` patterns)
- `07-devops/readme-version-pin` — `--pattern` flag on `pin_readme_version.sh` for
  custom install line formats; `VERSION_TAG` placeholder substitution

---

## [1.6.8] — 2026-06-18

Add worked examples to 01-meta and 05-technical skills.

### Added
- `01-meta/task-decomposer` — worked example: comms cluster decomposed into 3 chunks
  with run-book, per-chunk scope, verifiable done criteria, and reasoning notes
- `01-meta/task-handoff` — worked example: mid-session handoff document from a real
  grimoire documentation task, including decisions made, remaining work, and fresh-session
  load prompt
- `05-technical/python-black-ruff-authoring` — before/after examples for F401 (unused
  import), F841 (unused variable), E722 (bare except), and B904 (raise without from)

---

## [1.6.7] — 2026-06-18

Add worked examples to the 02-comms cluster skills.

### Added
- `02-comms/executive-translate` — 3 worked examples: finding → CISO brief,
  incident → board summary, risk → C-suite ask; covers CISO, C-suite, and board tiers
- `02-comms/human-rewrite` — before/after pair for each of the 9 style rules
- `02-comms/tone-check` — PASS, FLAG, and borderline example for each of the 4 axes
  (blame, authority, vagueness, softness) with full annotation block output

---

## [1.6.6] — 2026-06-16

Project workflow guide, two new Python skills, and changelog tidy for recent release lineage.

### Added
- `PROJECT-WORKFLOWS.md` — practical skill-stack playbooks for common project types
  (Node.js, Python, .NET, Terraform, security tooling, multi-repo operations)
- `README.md` — Project Workflows section linking to the new guide
- `05-technical/python-black-ruff-authoring` — authoring guide for writing Python
  that passes Black and Ruff first pass; covers common violation patterns (F401, F841, E722, B904)
- `07-devops/python-lint-gate` — unified Ruff + Black gate script with `--check`
  and `--fix` modes; registered as MCP action tool

### Changed
- `CHANGELOG.md` — backfilled release notes for v1.6.2 through v1.6.5
- `ROADMAP.md` — marked post-merge changelog tidy task complete in the
  infrastructure checklist

---

## [1.6.5] — 2026-06-16

Add `branch-surface-resolve` skill for surfacing and resolving scattered branches.

### Added
- `07-devops/branch-surface-resolve` — audit local/remote branches, categorize by state
  (READY/LOCAL-ONLY/HAS-PR/CONFLICT/STALE), optionally resolve via PR creation.
  Includes `--resolve` and `--prune-stale` modes for branch cleanup workflows.
- `clusters/07-devops/README.md` — Workflow 8 section documenting the full
  "Surface and resolve scattered branches" flow
- `mcp-server/registry.json` — registered `branch-surface-resolve` as action tool

---

## [1.6.4] — 2026-06-16

Add `devops-practices` and `devops-practices-updater` skills for grimoire maintenance.

### Added
- `07-devops/devops-practices` — enforcement suite for devops standards:
  version file sync, clone refs, test baseline, README quality gates
- `07-devops/devops-practices-updater` — audit grimoire against standards
  and propose fixes (script-based)
- Workflow 7 section in `clusters/07-devops/README.md` for "Audit grimoire against devops standards"
- `mcp-server/registry.json` — registered both skills as action tools

### Changed
- `ROADMAP.md` — added post-merge changelog tidy task to infrastructure section

---

## [1.6.3] — 2026-06-15

Infrastructure roadmap execution batch: MCP logging, install modes, uninstall scripts.

### Added
- `mcp-server/src/` — structured logging with Pino, health check endpoint,
  log rotation via pino-roll. Writes to `mcp-server/logs/` with cleanup on startup
- `install-all.sh` — `--update` mode (safely update existing installs),
  `--force` mode (overwrite without backup)
- `install-vscode.sh` — new `--apply` flag for non-interactive setup, `--dry-run` support
- `uninstall-all.sh` — remove grimoire-managed skills with `--dry-run` preview
- `uninstall-vscode.sh` — remove VS Code integration (prompts + MCP config)
- Timestamped backups for `settings.json` (keep last 5 versions) during install-vscode

### Fixed
- `install-vscode.sh` — now uses macOS `$HOME/Library/Application Support/Code/User/mcp.json`
  for MCP config (VS Code 1.100+ standard), not settings.json

---

## [1.6.2] — 2026-06-14

Fix MCP server compatibility with SDK 1.29.0 (Zod schema requirement).

### Fixed
- `mcp-server/src/index.ts` — replaced raw JSON Schema objects in `server.tool()`
  calls with Zod schemas. SDK 1.29.0+ no longer accepts JSON objects; this fixes
  "expected a Zod schema or ToolAnnotations" crash on startup

### Changed
- `mcp-server/package.json` — `@modelcontextprotocol/sdk` now at 1.29.0 (was 1.28.2)

---

## [1.6.1] — 2026-06-14

Fix MCP server registration to use VS Code's dedicated mcp.json file.

### Fixed
- `install-vscode.sh` now writes MCP server config to `mcp.json` instead of
  the legacy `settings.json` location (VS Code 1.100+ uses a dedicated file)
- Removes stale `"mcp"` key from `settings.json` during migration

### Added
- `.github/workflows/release-on-tag.yml` — auto-creates GitHub Release on tag push
- `scripts/release-backfill.sh` — reconciliation script for tag↔release drift
- Version-tag drift warning in `validate.yml` (annotation only, not a hard fail)
- CI enforcement section in `github-release-workflow` SKILL.md (reusable pattern)

---

## [1.6.0] — 2025-07-14

README standardisation across all public clusters + global roadmap.

### Added
- `ROADMAP.md` — auto-generated overview of 95 open items across 50 skills
- `scripts/roadmap-collect.sh` — generates roadmap from skill README checkboxes (supports `--json`)
- Multi-platform Installation section in all 50 public skill READMEs:
  - Claude Code (`cp -r` to `~/.claude/skills/`)
  - VS Code prompt file reference (`#skill-name` in Copilot Chat)
  - MCP tool registration note (action-type skills only)
- `> **Type:** action|instructional` metadata field added to all SKILL.md files

### Changed
- `validate.yml` readme-quality job now enforces standard on all public clusters
  (previously scoped to 01-meta only)
- Stale path references (`~/Claude/Skills/...`) replaced with relative paths

### Fixed
- 15 SKILL.md files in clusters 02-05 and 08-offsec were missing `Type:` metadata

---

## [1.5.0] — 2026-06-13

Public/private cluster split via git submodule.

### Added
- `clusters-private/` git submodule pointing to `incendiary/grimoire-private`
- `scripts/init-private-submodule.sh` — skeleton generator for colleagues to create
  their own private submodule with the correct structure
- `grimoire-private` repo with full security posture (gitleaks, TruffleHog,
  detect-secrets, dependabot, CI validation)

### Changed
- Moved `06-study` and `09-odpc` clusters to `grimoire-private` (personal content)
- `install-all.sh`: scans `clusters-private/clusters/` if submodule is initialised
- `build.sh`: generates prompt files from private clusters if present
- `validate.yml`: skips `clusters-private/` (private repo has its own CI)
- `README.md`: updated clusters table (7 public + 2 private), added Private
  Submodule section, updated Skills Index
- `clusters/README.md`: updated cluster index, added private cluster instructions
- `CHANGELOG.md`: back-filled v1.1.0–v1.3.4 with actual commit messages
- `VERSION`: 1.4.2 → 1.5.0

---

## [1.4.2] — 2026-06-13

Install script, documentation, and version alignment.

### Changed
- `install-vscode.sh`: auto-detects VS Code `settings.json` (macOS, Linux, Windows),
  deep-merges `chat.promptFilesLocations` and `mcp.servers.grimoire` using `node -e`.
  Supports `--apply` (non-interactive), `--dry-run`, and interactive confirmation.
- `README.md`: full rewrite for clarity — Quick Start / Architecture / Clusters /
  Skills Index structure. Removed Claude Code tutorial (moved to `clusters/README.md`).
  Added 13 missing skills to the index.
- `clusters/README.md`: added "How Claude Code skills work" section (moved from
  main README). Fixed stale `loadout/` reference. Updated cluster 05/06 descriptions.
- `mcp-server/package.json`: version aligned from `0.1.0` to `1.4.2` (single source
  of truth: `VERSION` file).

### Fixed
- `CHANGELOG.md`: back-filled entries for v1.1.0–v1.4.1 (previously undocumented).

---

## [1.4.1] — 2026-06-12

Dependency upgrades and identity sanitisation.

### Changed
- Bumped all npm dependencies to latest: `@modelcontextprotocol/sdk` 1.29.0,
  `vitest` 4.1.8, `typescript` 6.0.3, `eslint` 10.4.1, `tsx` 4.22.4.
- Resolved all npm audit vulnerabilities (esbuild transitive via vitest).

### Security
- Rewrote git history with `git-filter-repo` to remove corporate email from
  author/committer fields across all commits.

---

## [1.4.0] — 2026-06-11

Multi-platform delivery: VS Code prompt files + MCP server.

### Added
- `mcp-server/` — TypeScript MCP server exposing action skills as callable tools.
  Uses `@modelcontextprotocol/sdk`, stdio transport, reads `registry.json` at startup.
- `mcp-server/registry.json` — declares 16 action skills (3 from 01-meta, 13 from 07-devops).
- `mcp-server/src/__tests__/registry.test.ts` — bidirectional validation (7 tests):
  every registry entry has a valid `SKILL.md`, every action `SKILL.md` is in the registry.
- `build.sh` — generates `.prompt.md` files from `SKILL.md` source to `prompts/` (gitignored).
- `install-vscode.sh` — one-command VS Code setup (build MCP + generate prompts).
- `.github/workflows/ci-mcp.yml` — TypeScript CI (build, lint, test), path-filtered.
- `.github/workflows/secret-scan.yml` — gitleaks v3 + TruffleHog on push/PR.
- `Type:` field added to all skills (`instructional` or `action`).

### Changed
- `validate.yml`: added `registry-sync` job for bidirectional SKILL.md ↔ registry validation.
- `CLAUDE.md`: documented multi-platform delivery architecture.

---

## [1.3.0] — 2026-06-06

Final Cat 5 delivery: c2-preflight.sh.

### Added
- `08-offsec/c2-integration-checklist`: `c2-preflight.sh` script

---

## [1.3.1] — 2026-06-07

### Added
- `07-devops/npm-lockfile-integrity` — content-hash dependency verification skill

---

## [1.3.2] — 2026-06-07

### Added
- `07-devops/npm-provenance-attestation` — Sigstore build transparency verification skill

---

## [1.3.3] — 2026-06-08

### Added
- `07-devops/python-lockfile-integrity` — content-hash enforcement for
  pip, poetry, pipenv, and uv lockfiles

---

## [1.3.4] — 2026-06-09

### Added
- `01-meta/karpathy-spec` — spec generation skill
- `01-meta/karpathy-verify` — implementation verification skill
- `01-meta/karpathy-environment` — environment/context gathering skill
- `CLAUDE.md` — project-level delivery workflow conventions

---

## [1.2.0] — 2026-06-04

Offsec scripts, ODPC C1–C5, devops utilities. Roadmap sync across 30 READMEs.

### Added
- `08-offsec/shellcode-dev-conventions`: `null-byte-audit.sh`, `size-report.sh`
- `08-offsec/api-hashing-conventions`: `hash-api.py`, `collision-check.py`
- `08-offsec/bof-dev-conventions`: BOF build and validate scripts
- `08-offsec/edr-test-loop`: `run-log.sh`, `static-audit.sh`
- `09-odpc/syscall-techniques`: NtCreateThreadEx stub, SSN table, `syscall-stubs.asm`
- `09-odpc/call-stack-spoofing`: unwind data reference, before/after stack walk
- `09-odpc/etw-evasion`: per-provider ETW patch and detection signatures
- `09-odpc/pe-resource-shellcode`: `encrypt.py`, `shellcode.rc`
- `09-odpc/caro-kann-injection`: QueueUserAPC variant, heap encryption, x86 PEB walk
- `07-devops`: utility scripts for four skills

### Changed
- Roadmap-sync: ticked Ship items across 30 skill READMEs

---

## [1.2.1] — 2026-06-04

### Added
- `05-technical/test-bootstrap` skill

---

## [1.2.2] — 2026-06-04

### Added
- `06-study/yt-curator` skill

---

## [1.2.3] — 2026-06-04

### Fixed
- `yt-curator`: aligned auth with existing `youtube_cli.py` token model

---

## [1.2.4] — 2026-06-04

### Changed
- Consolidated `youtube_cli.py` into `yt-curator` — full YouTube CLI skill

---

## [1.2.5] — 2026-06-05

### Added
- `01-meta/task-decomposer` skill
- `01-meta/task-handoff` skill

---

## [1.2.6] — 2026-06-05

### Added
- Cat 5 D1: meta utility scripts

---

## [1.2.7] — 2026-06-05

### Added
- Cat 5 D2: incident and risk templates

---

## [1.2.8] — 2026-06-05

### Added
- Cat 5 D3: iOS signing scripts

---

## [1.2.9] — 2026-06-05

### Added
- Cat 5 D4: `source-material-triage` file-classifier

---

## [1.2.10] — 2026-06-05

### Added
- `07-devops/readme-version-pin` skill

---

## [1.2.11] — 2026-06-05

### Added
- `07-devops/docker-ghcr-publish` skill

---

## [1.2.12] — 2026-06-06

### Added
- Cat 5 D5: devops remaining scripts and config templates

### Changed
- `validate.yml`: added `workflow_dispatch` trigger

---

## [1.1.0] — 2026-06-02

### Added
- `09-odpc` cluster — White Knight Labs ODPC chapter-mapped skills (7 skills:
  odpc-lab-setup, pe-resource-shellcode, syscall-techniques, call-stack-spoofing,
  dotnet-offensive, etw-evasion, caro-kann-injection)

### Changed
- Updated invocation example in main README to use `repo-compass`

---

## [1.0.0] — 2026-06-01

Full roadmap delivery. All promoted skills built out and verified.
Repo migrated from `loadout` to `grimoire`; employer references removed from working tree and history.

### Added
- `07-devops/repo-compass` — new skill: session-start orientation combining GitHub platform
  state with README roadmap cross-check; prevents "all clean" false reports
- `07-devops/repo-publication-prep`: `find-large-files.sh`, `audit_history.sh`, `detect-language.sh`;
  expanded SKILL.md pre-commit version pinning section
- `07-devops/github-history-wipe`: `capture-releases.sh`, `recreate-releases.sh`;
  archived-repo unarchive/re-archive step; author email override guidance
- `07-devops/repo-security-bootstrap`: `bootstrap-security.sh` (handles archived repos),
  `gitleaks-config-template.toml` with parameterised corporate-refs placeholders
- `07-devops/python-ci-template`: `check-ci-ready.sh`, `ci-no-tests.yml`, `ci-requirements-only.yml`;
  variant selection table; Jython exception section with minimal CI template
- `07-devops/dotnet-ci-template`: `format-check.sh`, `ci-cross-platform.yml`, `ci-windows-only.yml`;
  variant selection table; net6.0 → net8.0 upgrade path
- `07-devops/project-delivery-workflow`: monorepo variant section; required-reviewer guidance;
  post-delivery 7-step checklist
- `01-meta/skill-vetter`: `vetting-checklist.md`; PyPI reputation step; session-skill-extractor cross-link
- `01-meta/github-authored-repos`: `list-authored.sh`; fork-detection one-liner; CLAUDE.md sync guidance

### Changed
- Repo renamed `loadout` → `grimoire`
- All employer/platform references removed (working tree and history wiped)
- Skills Index updated: all `📋 promoted` entries promoted to `✅ complete`

---

## [0.1.0] — 2026-06-01

Initial versioned release. Establishes the versioning scheme, changelog, and CI
validation pipeline. All skills built out prior to this version are captured below
as pre-release history.

### Added
- `VERSION` file (semver baseline)
- `CHANGELOG.md` (this file)
- `.github/workflows/validate.yml` — shellcheck on all `.sh` files + skill structure
  validation (every skill directory must have `SKILL.md` and `README.md`)

---

## Pre-release history

The following work was completed before versioning was introduced. Recorded here for
reference; no version numbers are associated with these changes.

### Skills built out (complete)
- `01-meta`: `session-skill-extractor`, `skill-vetter`, `test-before-asking`,
  `cwd-verification`, `verify-code-version`, `mid-task-checkin`
- `02-comms`: `tone-check`, `human-rewrite`, `executive-translate`
- `03-incident`: `incident-ask-builder`, `incident-appendix`, `risk-to-action`
- `04-security`: `ios-signing-risk`
- `05-technical`: `pe-binary-analysis`
- `06-study`: `study-burst-runner`, `source-material-triage`
- `07-devops`: `python-ci-lint-precheck`, `format-before-commit`,
  `portfolio-readme-generator`, `pre-commit-aware-commits`, `github-release-workflow`,
  `git-push-protocol-handler`, `roadmap-sync`, `terraform-checkov-skips`,
  `terraform-aws-syntax`, `terraform-version-compat`, `project-delivery-workflow`
- `08-offsec`: `shellcode-dev-conventions`, `api-hashing-conventions`,
  `process-injection-taxonomy`, `edr-test-loop`, `bof-dev-conventions`,
  `c2-integration-checklist`

### Skills promoted (extracted, pending build-out)
- `01-meta`: `github-authored-repos`
- `07-devops`: `repo-publication-prep`, `github-history-wipe`, `repo-security-bootstrap`,
  `python-ci-template`, `dotnet-ci-template`
