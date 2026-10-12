# Task RA-09: Merge four Python lint skills into `py-lint`

> Status: done
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02
> Effort: S
> Touches: `clusters/07-devops/python-lint-gate/`, `format-before-commit/`, `python-ci-lint-precheck/`, `clusters/05-technical/python-black-ruff-authoring/` (all deleted), `clusters/07-devops/py-lint/` (new), `mcp-server/registry.json`, `clusters/07-devops/README.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `py-lint`, covers the Python lint/format gate, the standard Black/Ruff config,
and pylint exceptions.

## Background
- Sources and what each contributes:
  - `python-lint-gate`: `lint-gate.sh` (Ruff + Black check, optional safe fix and re-check). Action skill, in the registry.
  - `format-before-commit`: `pyproject.toml` Black/Ruff config template and the "format before every commit" practice. Action skill, in the registry.
  - `python-ci-lint-precheck`: pylint and ruff before commit; standard disable comments for pytest fixtures and long crypto/algorithm functions. Action skill, in the registry.
  - `python-black-ruff-authoring` (in `clusters/05-technical/`): authoring patterns that pass Black/Ruff first time. Instructional, no registry entry. Becomes a section of `py-lint`.
- Running the whole CI workflow is `ci-local` (RA-08); `py-lint` is the fast, Python-only gate.

## New frontmatter description (use verbatim)
`Runs a Ruff and Black gate on Python code (check, then optional safe fixes and re-check), with a standard pyproject config template and pylint exceptions for pytest fixtures and long algorithm functions. Use when asked to 'lint this', 'fix ruff and black', 'set up formatting', or when CI fails on Python formatting. For the whole CI workflow use ci-local.`

## Context files
- All four source skills, in full.
- `00-runbook.md` Shared conventions step 9.

## Steps
1. Merge procedure (Shared conventions step 9). New directory `clusters/07-devops/py-lint/`, `Type: action`.
2. `SKILL.md` sections, in order: Writing code that passes first time (from
   `python-black-ruff-authoring`), Gate (`lint-gate.sh` usage), Config template
   (`pyproject.toml`), pylint exceptions (from `python-ci-lint-precheck`), Related (`ci-local`).
3. Keep `lint-gate.sh` and `pyproject.toml` names. If `python-ci-lint-precheck` had a
   script, keep it under its name and document it.
4. One registry entry `py-lint`; remove the three source registry entries.

## Done when
- [ ] Parity checklist complete in the commit body.
- [ ] `bash clusters/07-devops/py-lint/lint-gate.sh --help` (or its usage path) works; running it against a temp dir containing a badly formatted `.py` file reports the failure, and with its fix flag fixes it.
- [ ] Shared conventions steps 5 and 6 pass. MCP tests pass.

## Return signal
Commit message: `feat!: merge Python lint skills into py-lint` with footer
`BREAKING CHANGE: python-lint-gate, format-before-commit, python-ci-lint-precheck and python-black-ruff-authoring are replaced by py-lint.`
Then follow Shared conventions step 7.
