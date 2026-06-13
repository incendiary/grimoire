# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

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
