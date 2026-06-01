# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

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
