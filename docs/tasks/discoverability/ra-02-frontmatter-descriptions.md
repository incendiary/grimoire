# Task RA-02: Add frontmatter descriptions to every skill (dispatched as 4 scopes)

> Status: pending
> Scope A: pending | Scope B: done | Scope C: pending | Scope D: pending
> Parent: discoverability and consolidation programme
> Model: haiku (one agent per scope, run in parallel)
> Fallback: sonnet
> Depends on: RA-01, RA-07 (so deleted skills are already gone)
> Effort: M total (S per scope)
> Touches: the `SKILL.md` files in your scope only, `CHANGELOG.md` (scope A only)

## Objective
Add YAML frontmatter with a high-quality `description` to every `SKILL.md` in your scope,
so Claude Code can pick the right skill from a plain-language request.

## Your scope
The dispatch prompt names one scope. Work only on these directories:

| Scope | Directories |
|---|---|
| A | `clusters/01-meta/*/` (about 13 skills) |
| B | `clusters/02-comms/*/`, `clusters/03-incident/*/`, `clusters/04-security/*/`, `clusters/05-technical/*/` (about 11 skills) |
| C | `clusters/07-devops/*/` whose directory name starts with `a` to `n` (about 13 skills) |
| D | `clusters/07-devops/*/` whose directory name starts with `o` to `z` (about 15 skills) |

List yours with, for example, `ls -d clusters/07-devops/[a-n]*/`.

## Background
These decisions are already made. Do not change them:
- This is the single most important discoverability fix. The `description` is the only
  text Claude sees when deciding whether to load a skill, and the text the owner sees in
  `/` autocomplete. A vague description means the skill never fires.
- Skill names will change later (RA-15). Use the **current** directory name for `name:`.
- Exact format, inserted above the existing line 1 (keep everything else unchanged):
  ```
  ---
  name: <directory-name>
  description: "<description>"
  ---
  ```

## How to write a description
Template (three parts, in this order, as one line):

`<What it does, one sentence, starting with a verb>. Use when <3 to 5 trigger situations or phrases, comma-separated>. <Disambiguation clause from the table below, if the skill is listed>`

Rules:
1. Source every fact from the skill's own `SKILL.md` (`## Description` section and its
   "Invoke when" / "Trigger phrases" text). Do not invent capabilities.
2. Length: 150 to 400 characters. Hard limit 1024.
3. Trigger phrases should be how a person would actually ask, for example
   `"run CI locally"`, `"cut a release"`. Use single quotes inside the description, never
   double quotes (the value is wrapped in double quotes).
4. No em dashes. No colons immediately followed by a space inside the text (YAML-safe
   habit even though the value is quoted).
5. If the skill appears in the disambiguation table below, append its clause **verbatim**.

Worked example (for `clusters/07-devops/local-ci/SKILL.md`):
```
---
name: local-ci
description: "Runs this repo's GitHub Actions workflow steps locally, auto-fixes Black/Ruff when versions match CI, and can install pre-commit or pre-push hooks. Use when asked to 'run CI locally', 'test before pushing', 'preview what CI will do', or 'gate my pushes on CI'. Not for a quick Python lint only (use python-lint-gate)."
---
# local-ci
```

## Disambiguation clauses (append verbatim)

| Skill | Clause |
|---|---|
| `local-ci` | `Not for a quick Python lint only (use python-lint-gate).` |
| `pre-push-validation` | `Prefer local-ci, which supersedes this skill.` |
| `python-lint-gate` | `Not for running the full CI workflow (use local-ci).` |
| `format-before-commit` | `Provides the Black/Ruff config; to run the check use python-lint-gate.` |
| `python-ci-lint-precheck` | `Only for repos using pylint; for Black/Ruff only use python-lint-gate.` |
| `python-black-ruff-authoring` | `Guidance while writing code; to check existing code use python-lint-gate.` |
| `npm-lockfile-integrity` | `For Python lockfiles use python-lockfile-integrity; for package provenance use npm-provenance-attestation.` |
| `python-lockfile-integrity` | `For Node lockfiles use npm-lockfile-integrity.` |
| `npm-provenance-attestation` | `For lockfile hash checks use npm-lockfile-integrity.` |
| `terraform-aws-syntax` | `For provider version conflicts use terraform-version-compat; for checkov skips use terraform-checkov-skips.` |
| `terraform-checkov-skips` | `For AWS argument syntax use terraform-aws-syntax.` |
| `terraform-version-compat` | `For AWS argument syntax use terraform-aws-syntax.` |
| `roadmap-driver` | `To tick items after a merge use roadmap-sync; for full repo state use repo-compass.` |
| `grimoire-roadmap-status` | `Only for this grimoire repo's ROADMAP.md; to choose the next item use roadmap-driver.` |
| `roadmap-sync` | `To choose what to work on next use roadmap-driver.` |
| `repo-compass` | `For routine PR/dependabot upkeep use github-morning-run; for branch clean-up use branch-surface-resolve.` |
| `github-morning-run` | `For a single repo's true state at session start use repo-compass.` |
| `branch-surface-resolve` | `For overall repo state use repo-compass.` |
| `project-delivery-workflow` | `To pick a single next item use roadmap-driver.` |
| `devops-practices` | `To add a new practice to this standard use devops-practices-updater.` |
| `devops-practices-updater` | `To apply the standard to a repo use devops-practices.` |
| `task-decomposer` | `Use before work starts; if context is already full use task-handoff.` |
| `task-handoff` | `Use when context is already full; to split work up front use task-decomposer.` |
| `karpathy-framework` | `Entry point when unsure; routes to karpathy-spec, karpathy-verify, or karpathy-environment.` |
| `karpathy-spec` | `Use before work starts; to evaluate finished output use karpathy-verify.` |
| `karpathy-verify` | `Use after output exists; to define criteria first use karpathy-spec.` |
| `karpathy-environment` | `For per-task specs use karpathy-spec.` |
| `tone-check` | `Annotates only; to rewrite use human-rewrite, for leadership audiences use executive-translate.` |
| `human-rewrite` | `For a leadership audience use executive-translate; to only review tone use tone-check.` |
| `executive-translate` | `To remove AI style without changing audience use human-rewrite.` |
| `incident-ask-builder` | `To write up collected evidence use incident-appendix.` |
| `incident-appendix` | `To plan what evidence to request use incident-ask-builder.` |
| `risk-to-action` | `For live incident evidence requests use incident-ask-builder.` |
| `repo-publication-prep` | `Entry point for going public; history rewrite is github-history-wipe, secret scanning is repo-security-bootstrap, README is portfolio-readme-generator.` |
| `github-history-wipe` | `Part of publishing; start with repo-publication-prep.` |
| `repo-security-bootstrap` | `Part of publishing; start with repo-publication-prep.` |
| `portfolio-readme-generator` | `Part of publishing; start with repo-publication-prep.` |
| `github-release-workflow` | `For README version pins use readme-version-pin; for container images use docker-ghcr-publish.` |
| `readme-version-pin` | `Part of releasing; start with github-release-workflow.` |
| `docker-ghcr-publish` | `Part of releasing; start with github-release-workflow.` |
| `skill-keyword-lookup` | `Use when you cannot remember which grimoire skill fits.` |
| `session-skill-extractor` | `To vet a third-party skill use skill-vetter.` |
| `skill-vetter` | `To create skills from your own sessions use session-skill-extractor.` |
| `codebase-holistic-review` | `For UI/UX quality use ui-ux-product-audit.` |
| `ui-ux-product-audit` | `For whole-codebase risk review use codebase-holistic-review.` |

## Steps
1. List the `SKILL.md` files in your scope.
2. For each file:
   1. Read the whole file.
   2. Write the description using the template, rules, and table above.
   3. Insert the frontmatter block above line 1. Do not change any other line.
   4. Run `bash scripts/check-frontmatter.sh <that file>`; fix until it passes.
3. When all files in scope pass, run `bash scripts/check-frontmatter.sh <all files in scope>`.
4. Scope A only: add to `CHANGELOG.md` under `## [Unreleased]` → `### Added`:
   `- YAML frontmatter (name, description) on every SKILL.md, so Claude Code can select skills by intent.`
5. In this task file, change your scope's entry in the second header line from
   `pending` to `done`. Set `> Status: done` only if all four scopes now read `done`.

## Constraints
- Only files in your scope. Other agents are editing the other scopes in parallel.
- Do not edit `README.md` files, scripts, or the registry.
- Do not reword existing content below the frontmatter.

## Done when
- [ ] `bash scripts/check-frontmatter.sh <your scope's SKILL.md files>` exits 0.
- [ ] `git diff --stat` shows only `SKILL.md` files in your scope (plus `CHANGELOG.md` and this task file for scope A).
- [ ] `git diff` shows only added lines, all at the top of each file (4 lines per file).
- [ ] Every skill in the disambiguation table that is in your scope ends with its clause verbatim:
      for each, `grep -F '<clause>' <path>` finds it.

## Return signal
Commit message: `feat: add frontmatter descriptions to <scope> skills` (e.g. `01-meta`).
Then follow Shared conventions step 7 (tick RA-02 in `ROADMAP.md` only if all scopes are done).
