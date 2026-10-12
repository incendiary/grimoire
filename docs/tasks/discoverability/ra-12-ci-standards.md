# Task RA-12: Fold `devops-practices-updater` into `devops-practices` as `ci-standards`

> Status: done
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02
> Effort: S
> Touches: `clusters/07-devops/devops-practices/` → `clusters/07-devops/ci-standards/`, `clusters/07-devops/devops-practices-updater/` (deleted), `.pre-commit-config.yaml`, `.github/workflows/devops-check.yml`, `ROADMAP.md` (header text only), `CLAUDE.md`, `docs/tasks/discoverability/00-runbook.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `ci-standards`, holds the DevOps standard, its enforcement scripts, and the
procedure for evolving it.

## Background
- `devops-practices` (instructional + enforcement) has four scripts used by CI and
  pre-commit: `check-clone-refs.sh`, `check-roadmap-sync.sh`, `check-test-baseline.sh`,
  `check-version-sync.sh`. **Their paths are hard-coded** in `.pre-commit-config.yaml`,
  `.github/workflows/devops-check.yml`, the `ROADMAP.md` header prose, `CLAUDE.md`, and the
  runbook's Shared conventions step 6. Missing one breaks CI or the pre-commit hook.
- `devops-practices-updater` is a procedure for editing `devops-practices`; it is a section, not a skill.
- Note: `devops-practices` was the second most used skill in the review. Keep its routing table intact.

## New frontmatter description (use verbatim)
`Applies and audits the owner's standard DevOps practices on a repo (version sync, roadmap sync, clone-ref pinning, test baseline), routing to the right skill for each practice, and records new practices when a session reveals one. Use when setting up a new repo, auditing a repo against the standard, doing a periodic health check, or asked to 'add this to my devops practices'.`

## Steps
1. Merge procedure (Shared conventions step 9), with the base moved by
   `git mv clusters/07-devops/devops-practices clusters/07-devops/ci-standards`.
2. Add a `## Evolving this standard` section to `ci-standards/SKILL.md` containing
   the updater's procedure (condensed only where it repeats the main skill).
3. Update every path: `grep -rn 'devops-practices' . --exclude-dir=node_modules --exclude-dir=.git`
   and fix all hits except `CHANGELOG.md` history, `REVIEW.md`, `renamed-skills.txt`, and
   `docs/tasks/` (briefs mention old names on purpose). One exception inside `docs/tasks/`:
   in `00-runbook.md` Shared conventions step 6, change the `check-roadmap-sync.sh` path to
   `clusters/07-devops/ci-standards/check-roadmap-sync.sh` and delete the "(After RA-12 ...)" note.
4. Registry: neither source is `Type: action` today; if you keep `ci-standards` instructional, no registry change.

## Done when
- [ ] Parity checklist complete.
- [ ] `pre-commit run roadmap-sync --all-files` passes (or the equivalent `bash clusters/07-devops/ci-standards/check-roadmap-sync.sh . --check`).
- [ ] Each of the four check scripts runs from the new path on this repo with the same exit code as before.
- [ ] `grep -rn 'devops-practices' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude=renamed-skills.txt --exclude=discoverability-intents.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks` prints nothing.

## Return signal
Commit message: `feat!: merge devops-practices and its updater into ci-standards` with footer
`BREAKING CHANGE: devops-practices is now ci-standards; devops-practices-updater is a section of it.`
Then follow Shared conventions step 7.
