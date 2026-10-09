# Task RA-24: Remove per-skill Installation boilerplate and the CI job enforcing it

> Status: done
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none (run in wave 1, before merges create new READMEs)
> Effort: S
> Touches: `clusters/*/*/README.md` (`## Installation` sections only), `.github/workflows/validate.yml`, `docs/skill-readme-template.md`, `CHANGELOG.md`

## Objective
Delete the `## Installation` section copied into every skill README (about 1,170 lines in
total) and the `readme-quality` CI job that forces it. Installation is documented once, in
the root `README.md` Quick Start.

## Background
- Every skill installs the same way (`install-all.sh`, `install-vscode.sh`,
  `install-jetbrains.sh`), so 57 copies of the same instructions add nothing, and every new
  skill must repeat them to pass CI.
- The `readme-quality` job in `.github/workflows/validate.yml` has two steps: "Migrated
  clusters must have multi-platform install" (the enforcer; delete) and "No stale path
  references" (keep: move it into the `structure` job).

## Steps
1. For every `clusters/*/*/README.md`, delete from the line `## Installation` up to (not
   including) the next line starting `## `. Use this and check the diff:
   ```bash
   for f in clusters/*/*/README.md; do
     awk '/^## Installation/{skip=1;next} skip && /^## /{skip=0} !skip' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
   done
   ```
2. Inspect `git diff --stat` and spot-check five READMEs. If any deleted section contained
   something other than install commands (for example a skill-specific prerequisite such as
   "requires gh" or "requires Node 22"), restore that sentence under a new `## Requirements`
   heading in that README.
3. In `validate.yml`: move the "No stale path references" step (with its `run:` block) to
   the end of the `structure` job's steps, then delete the whole `readme-quality` job.
4. In `docs/skill-readme-template.md`, delete its `## Installation` section and add one
   line where it was: `Installation is covered by the root README; do not repeat it here.`
5. `CHANGELOG.md` → `### Removed`: `- Per-skill README Installation sections and the readme-quality CI job (installation is documented once in README.md).`

## Done when
- [ ] `grep -l '^## Installation' clusters/*/*/README.md` prints nothing.
- [ ] `grep -n 'readme-quality' .github/workflows/validate.yml` prints nothing, and `grep -n 'No stale path references' .github/workflows/validate.yml` still finds the step.
- [ ] `python3 -c "import yaml;yaml.safe_load(open('.github/workflows/validate.yml'))"` succeeds.
- [ ] `git diff main -- clusters` shows only deleted lines, plus any `## Requirements` lines from step 2.

## Return signal
Commit message: `docs: remove duplicated per-skill installation sections`
Then follow Shared conventions step 7.
