# Task RA-01: Frontmatter validator script and non-blocking CI job

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: S
> Touches: `scripts/check-frontmatter.sh` (new), `.github/workflows/validate.yml`, `CHANGELOG.md`

## Objective
Add `scripts/check-frontmatter.sh`, which verifies every skill's `SKILL.md` starts with
valid YAML frontmatter, and run it in CI as a non-blocking job.

## Background
These decisions are already made. Do not change them:
- Claude Code reads a skill's `name` and `description` from a YAML block at the very top of
  `SKILL.md`. No grimoire skill has one today, so Claude Code shows each skill's name as its
  description. RA-02 adds the frontmatter; this task only builds the checker.
- The required format is exactly:
  ```
  ---
  name: <skill-directory-name>
  description: "<one line of text containing the words Use when>"
  ---
  ```
  followed by the existing content (the `# title` line and so on) unchanged.
- The CI job must not block merges yet (`continue-on-error: true`). RA-03 makes it
  blocking once RA-02 is complete.

## Context files
Read these before starting:
- `.github/workflows/validate.yml`: see how the existing `structure` job is written; copy its style.
- `clusters/07-devops/devops-practices/check-roadmap-sync.sh`: an example of this repo's
  shell style (header comment, `set -e`, exit codes).

## Steps
1. Create `scripts/check-frontmatter.sh` with this behaviour:
   - Shebang `#!/usr/bin/env bash`, then `set -euo pipefail`, and a 3-line header comment
     (what it checks, usage, exit codes).
   - Arguments: zero or more `SKILL.md` paths. With none, check every file matching
     `clusters/*/*/SKILL.md` (run from repo root; `cd` to the repo root using
     `"$(dirname "$0")/.."` first, as `scripts/roadmap-collect.sh` does).
   - For each file, fail it (print `FAIL <path>: <reason>`) if any of these is false:
     1. Line 1 is exactly `---`.
     2. A second `---` line exists at line 3, 4, 5, or 6.
     3. Between those markers there is a line `name: <value>` where `<value>` equals the
        name of the directory containing the file (`basename "$(dirname "$path")"`).
     4. Between those markers there is a line starting `description: "` and ending `"`.
     5. The description text (between the quotes) is 50 to 1024 characters long.
     6. The description text contains `Use when`.
   - Print `OK <path>` for passing files only when `-v` is the first argument (default quiet).
   - At the end print `<passed>/<total> skills have valid frontmatter` and exit 1 if any
     file failed, else 0.
   - Use only bash, `sed`, `awk`, `grep`, `head`. No Python, no `yq`.
2. `chmod +x scripts/check-frontmatter.sh`.
3. In `.github/workflows/validate.yml`, add a new job after the `structure` job:
   ```yaml
     frontmatter:
       name: Skill frontmatter
       runs-on: ubuntu-latest
       # Non-blocking until RA-02 adds frontmatter to every skill; RA-03 removes this line.
       continue-on-error: true
       steps:
         - uses: actions/checkout@v7
         - name: Every SKILL.md has name/description frontmatter
           run: bash scripts/check-frontmatter.sh
   ```
   Match the file's existing indentation exactly.
4. Test it by hand:
   - `bash scripts/check-frontmatter.sh; echo "exit=$?"` must print 57 `FAIL` lines,
     `0/57 skills have valid frontmatter`, and `exit=1`.
   - Make a temporary copy to prove the pass path:
     ```bash
     tmp=$(mktemp -d); mkdir -p "$tmp/clusters/x/demo-skill"
     printf -- '---\nname: demo-skill\ndescription: "Does a demo thing for testing the checker script. Use when testing."\n---\n# demo-skill\n' > "$tmp/clusters/x/demo-skill/SKILL.md"
     bash scripts/check-frontmatter.sh "$tmp/clusters/x/demo-skill/SKILL.md"; echo "exit=$?"
     rm -rf "$tmp"
     ```
     Must print `1/1 ...` and `exit=0`. Then change `name: demo-skill` to `name: wrong` and
     confirm it fails with a `name` reason.
5. Add to `CHANGELOG.md` under `## [Unreleased]` → `### Added`:
   `- scripts/check-frontmatter.sh and a non-blocking validate.yml job checking SKILL.md frontmatter.`

## Constraints
- Do not add frontmatter to any `SKILL.md` (that is RA-02).
- Do not modify other jobs in `validate.yml`.
- Script must be shellcheck clean.

## Done when
- [ ] `shellcheck scripts/check-frontmatter.sh` prints nothing.
- [ ] `bash scripts/check-frontmatter.sh` exits 1 and reports `0/57`.
- [ ] The step 4 temporary-file test passes for the valid case and fails for the wrong name.
- [ ] `grep -n 'continue-on-error: true' .github/workflows/validate.yml` shows the new job.

## Return signal
Commit message: `ci: add SKILL.md frontmatter checker (non-blocking)`
Then follow Shared conventions step 7.
