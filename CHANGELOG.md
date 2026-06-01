# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
