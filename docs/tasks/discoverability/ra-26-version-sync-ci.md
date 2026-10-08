# Task RA-26: Drop version-sync checks from this repo's CI

> Status: done
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: XS
> Touches: `.github/workflows/validate.yml`, `.github/workflows/devops-check.yml`, `CLAUDE.md`, `CHANGELOG.md`

## Objective
Remove the two CI checks that compare `VERSION` with git tags. In this repo release-please
bumps `VERSION`, tags, and releases in one step, so the checks can only ever fail on the
release PR itself, where that is expected.

## Background
- `validate.yml` job `version-tag-sync` (at the end of the file) warns if `VERSION` does
  not match the latest tag. Delete the whole job.
- `devops-check.yml` runs `check-version-sync.sh` as step `id: version-sync`, and refers to
  `steps.version-sync.outcome` in "Report results" and "Fail if any check failed". Remove
  the step and both references.
- **Keep the script** `clusters/07-devops/devops-practices/check-version-sync.sh` (the
  directory may be `ci-standards` if RA-12 has landed). It is part of the standard applied
  to other repos that do not use release-please.
- `CLAUDE.md` has a paragraph explaining why version-sync is not a required check
  (starts "`devops-check.yml`'s version-sync check is deliberately **not**"). It becomes obsolete.

## Steps
1. `validate.yml`: delete from the line `  version-tag-sync:` to the end of that job.
2. `devops-check.yml`:
   - Delete the step block starting `      - name: Check version sync` through its `exit ${EXIT_CODE:-0}` line (and the blank line after it).
   - In "Report results", delete the 5-line `if [ "${{ steps.version-sync.outcome }}" ...` block (through its `fi`).
   - In "Fail if any check failed", delete the line `if [ "${{ steps.version-sync.outcome }}" != "success" ] || \` and change the next line's leading `[` so the condition starts with the clone-refs check: the result must read
     ```
     if [ "${{ steps.clone-refs.outcome }}" != "success" ] || \
        [ "${{ steps.test-baseline.outcome }}" != "success" ] || \
        [ "${{ steps.roadmap-sync.outcome }}" != "success" ]; then
     ```
   - If `fetch-depth: 0` on checkout was only for tags (comment says "Full history for git tag detection"), leave it; it is harmless.
3. `CLAUDE.md`: change "version sync, clone-ref pinning, test baseline, roadmap sync" to
   "clone-ref pinning, test baseline, roadmap sync", and delete the paragraph described in
   Background.
4. `CHANGELOG.md` → `### Removed`: `- VERSION/tag drift checks from this repo's CI (release-please keeps them in step).`

## Done when
- [ ] `grep -n 'version-sync\|version-tag-sync' .github/workflows/*.yml` prints nothing.
- [ ] Both workflow files parse: `python3 -c "import yaml,glob;[yaml.safe_load(open(f)) for f in glob.glob('.github/workflows/*.yml')]"`.
- [ ] `ls clusters/07-devops/*/check-version-sync.sh` still finds the script.

## Return signal
Commit message: `ci: drop version-sync checks superseded by release-please`
Then follow Shared conventions step 7.
