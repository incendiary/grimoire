# Task RA-07: Move always-on behaviour from skills into rules files

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: none
> Effort: M
> Touches: `rules/` (new), `install-all.sh`, `uninstall-all.sh`, `build.sh`, six skill directories (deleted), `mcp-server/registry.json`, `clusters/01-meta/README.md`, `clusters/07-devops/README.md`, `PROJECT-WORKFLOWS.md`, `README.md`, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
Six skills that describe standing behaviour become short rules files that are always in
context for Claude Code and Copilot; the six skill directories are removed.

## Background
- Skills load only when triggered, so a skill that says "active for all sessions" is never
  actually always active. Rules files are loaded into every session.
- Decided by the owner: move these to rules.

| Skill (delete) | Rule file (create) | Scripts |
|---|---|---|
| `clusters/01-meta/test-before-asking` | `rules/grimoire-test-before-asking.md` | none |
| `clusters/01-meta/mid-task-checkin` | `rules/grimoire-mid-task-checkin.md` | none |
| `clusters/01-meta/cwd-verification` | `rules/grimoire-cwd.md` | move any script to `rules/scripts/` (RA-14 later moves it into the `orient` skill) |
| `clusters/01-meta/verify-code-version` | `rules/grimoire-code-version.md` | move any script to `rules/scripts/` |
| `clusters/07-devops/pre-commit-aware-commits` | `rules/grimoire-pre-commit.md` | move `pre_commit_check.sh` to `rules/scripts/` |
| `clusters/05-technical/python-black-ruff-authoring` | `rules/grimoire-python-authoring.md` | none |

- Surfaces: Claude Code reads `~/.claude/rules/*.md`. Copilot reads `*.instructions.md`
  files with frontmatter `applyTo:`; `build.sh` already writes prompt files to `prompts/`,
  which VS Code is pointed at. JetBrains has no rules channel via MCP; do not attempt one.
- `cwd-verification`, `verify-code-version`, `pre-commit-aware-commits` are `Type: action`
  with MCP registry entries; those entries must be removed.

## Context files
- The six `SKILL.md` and `README.md` files above (read fully: you are condensing them).
- `install-all.sh`, `uninstall-all.sh`, `build.sh`.
- `~/.claude/rules/git-ci.md` (read only): an example of the rules-file style the owner already uses.

## Steps
1. For each skill, write its rule file, at most 40 lines:
   ```
   # <Rule title>

   <The rule in 1 to 3 sentences, imperative.>

   **Why:** <1 to 2 sentences from the skill's rationale.>

   **How to apply:**
   - <bullet>
   - <bullet>
   ```
   Keep concrete checks and commands the skill had (for example the cwd check commands).
   Drop installation sections, roadmaps, and examples.
2. Move scripts to `rules/scripts/` with `git mv` (keep names), and update the rule file to reference them.
3. `install-all.sh`: also copy `rules/*.md` to `~/.claude/rules/` and `rules/scripts/` to
   `~/.claude/rules/scripts/`, honouring the existing skip-if-exists / `--update` / `--force`
   behaviour. `uninstall-all.sh`: remove `~/.claude/rules/grimoire-*.md` and the copied scripts.
4. `build.sh`: for each `rules/grimoire-*.md`, write `prompts/<name>.instructions.md` with
   frontmatter `applyTo: "**"` (`"**/*.py"` for `grimoire-python-authoring`) followed by the rule body.
5. `git rm -r` the six skill directories. Append each to `scripts/renamed-skills.txt` as `<old><TAB>-`.
6. Remove the three registry entries from `mcp-server/registry.json`.
7. Remove or update every reference (Shared conventions step 5): cluster READMEs, other
   skills' "Related skills" sections (point them to the rule file instead),
   `PROJECT-WORKFLOWS.md`, `README.md`.
8. `CHANGELOG.md` → `### Added`: rules files; `### Removed`: the six skills (one line naming them).

## Constraints
- Do not edit `~/.claude/rules/git-ci.md` or anything else under `~/.claude` from this task, except via the install script you are changing, and do not run the install for real.
- Rules must be short. If a rule exceeds 40 lines, cut it.

## Done when
- [ ] `ls rules/grimoire-*.md | wc -l` prints `6`, and `wc -l rules/grimoire-*.md` shows each at most 40.
- [ ] The six skill directories no longer exist; `scripts/renamed-skills.txt` lists them.
- [ ] Shared conventions step 5 grep is clean for all six names.
- [ ] `bash build.sh` produces six `prompts/grimoire-*.instructions.md` files with `applyTo` frontmatter.
- [ ] `HOME=$(mktemp -d) bash install-all.sh` installs the rules into `$HOME/.claude/rules/`.
- [ ] `cd mcp-server && npm ci && npm run build && npm test` passes; validate.yml registry-sync logic passes (run its two loops locally).

## Return signal
Commit message: `feat!: move six always-on skills to rules files` with footer
`BREAKING CHANGE: test-before-asking, mid-task-checkin, cwd-verification, verify-code-version, pre-commit-aware-commits and python-black-ruff-authoring are now rules, not skills.`
Then follow Shared conventions step 7.
