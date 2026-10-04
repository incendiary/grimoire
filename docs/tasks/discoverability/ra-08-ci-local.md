# Task RA-08: Merge `pre-push-validation` into `local-ci` as `ci-local`

> Status: pending
> Parent: discoverability and consolidation programme
> Model: opus
> Fallback: none (escalate to owner)
> Depends on: RA-02, RA-22
> Effort: M
> Touches: `clusters/07-devops/local-ci/` → `clusters/07-devops/ci-local/`, `clusters/07-devops/pre-push-validation/` (deleted), `mcp-server/registry.json`, `clusters/07-devops/README.md`, references across the repo, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `ci-local`, runs repo workflows locally with the full feature set of both
`local-ci` and `pre-push-validation`.

## Background
- Both skills parse `.github/workflows/*.yml` and run each job's `run:` steps locally.
  This is the clearest duplication in the repo, and the risk of the merge is silently
  losing a behaviour. That is why this task is Opus.
- `local-ci` is the base: it has hook installation (pre-commit informational, pre-push
  fail-closed, chaining existing hooks), version-matched Black/Ruff auto-fix, `--sync`
  (ephemeral venv with CI's pinned tools), `--list`, `--dry-run`.
- `pre-push-validation` has: an explicit list of CI-only skip reasons with a printed
  `Skipped — CI-only: <name> (<reason>)` line, fail-closed by exit code, PyYAML parsing.
- The owner's global rule file (`~/.claude/rules/git-ci.md`, outside this repo, do not
  edit) runs `bash local-ci.sh --list`, `--dry-run`, `--sync`, `--install-hook pre-commit`,
  `--install-hook pre-push`, and warns that `local-ci` and `pre-push-validation` both own
  `.git/hooks/pre-push`. **Keep the script name `local-ci.sh` and every one of those flags.**
- Decided: no compatibility shim for `pre-push-validation.sh`. RA-18 updates the owner's
  global config.

## New frontmatter description (use verbatim)
`Runs this repo's GitHub Actions workflow steps locally before pushing, auto-fixes Black/Ruff when tool versions match CI, and installs pre-commit (fast, informational) or pre-push (full, blocking) hooks. Use when asked to 'run CI locally', 'test before pushing', 'preview what CI will do', or 'gate my pushes on CI'. For a quick Python lint only use py-lint.`

## Context files
- Both skills' `SKILL.md`, `README.md`, and scripts, in full.
- `00-runbook.md` Shared conventions step 9 (merge procedure).

## Steps
1. Parity checklist (step 9.1). Compare the two scripts behaviour by behaviour, including:
   skip rules (expression contexts, `secrets.`, `gh release`, `$GITHUB_OUTPUT`/`ENV`/`STEP_SUMMARY`,
   OS package installs), exit-code semantics, output format, YAML parsing, hook handling.
2. Port anything `local-ci.sh` lacks into it. Where the two differ in default behaviour
   (for example fail-closed by default), keep `local-ci`'s default and expose the other
   as a flag; record the decision in the parity checklist.
3. `git mv clusters/07-devops/local-ci clusters/07-devops/ci-local`; update its `SKILL.md`
   frontmatter and `# heading`; fold any `pre-push-validation` documentation that still
   applies into `SKILL.md`/`README.md` (including a short "Migrating from
   pre-push-validation" note: the hook it installed must be removed before installing
   `ci-local`'s pre-push hook).
4. Steps 9.4 to 9.7 of the merge procedure.

## Done when
- [ ] Parity checklist complete in the commit body; no unexplained `DROPPED`.
- [ ] On this repo, `bash clusters/07-devops/ci-local/local-ci.sh --list` and `--dry-run` run, and every step that `pre-push-validation.sh` (from `git show main:clusters/07-devops/pre-push-validation/pre-push-validation.sh`) would skip is also reported as skipped with a reason.
- [ ] `--install-hook pre-push` into a temp repo with an existing `pre-push` hook chains it (existing hook still runs).
- [ ] Shared conventions step 5 and step 6 checks pass. MCP tests pass.

## Return signal
Commit message: `feat!: merge pre-push-validation into local-ci as ci-local` with footer
`BREAKING CHANGE: local-ci is now ci-local; pre-push-validation is removed (use ci-local --install-hook pre-push).`
Then follow Shared conventions step 7.
