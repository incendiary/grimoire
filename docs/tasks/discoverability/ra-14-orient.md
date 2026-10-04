# Task RA-14: `orient` entry skill (session start)

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02, RA-07
> Effort: M
> Touches: `clusters/01-meta/orient/` (new), `clusters/07-devops/git-push-protocol-handler/` (deleted), `rules/scripts/` (scripts moved out), `rules/grimoire-cwd.md`, `rules/grimoire-code-version.md`, `mcp-server/registry.json`, `clusters/01-meta/README.md`, `clusters/07-devops/README.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
A single `orient` command runs the three session-start checks and points to the next step,
so the owner types one name at the start of every session.

## Background
- The review found the most common chain starts with orientation (`repo-compass`, then
  `devops-practices`). RA-15 renames `repo-compass` to `orient-repo-state`; until then refer
  to it by its current name.
- Inputs:
  - cwd check: script moved to `rules/scripts/` by RA-07 (from `cwd-verification`).
  - code-version check: script or commands from `verify-code-version`, now in `rules/scripts/` or in `rules/grimoire-code-version.md`.
  - push protocol: `clusters/07-devops/git-push-protocol-handler/check_push_protocol.sh`
    (SSH agent check; switch remote to HTTPS via `gh` on failure). That skill is deleted here.
- `orient` is an **action** skill, in `clusters/01-meta/` (the registry CI check only
  scans `01-meta` and `07-devops`).
- The rules files stay (they are the always-on behaviour); they should now point to
  `orient` for the scripted check.

## New frontmatter description (use verbatim)
`Session-start orientation for a repo: confirms the working directory, checks the running code matches HEAD, checks SSH push works (falls back to HTTPS), then points to the full repo state check. Use when starting or resuming work on a repo, after a pull or branch switch, or when a push fails on SSH. Next step is repo-compass.`

## Steps
1. Create `clusters/01-meta/orient/` (SKILL.md with the frontmatter above,
   `Type: action`; README per template).
2. `git mv` the cwd and code-version scripts from `rules/scripts/` and
   `check_push_protocol.sh` from `git-push-protocol-handler/` into `orient/`.
3. Write `orient/orient.sh` that runs, in order, each check, printing one
   `PASS|WARN|FAIL <check>: <detail>` line per check, then a short "Next" block:
   `repo-compass` (full state), `branch-surface-resolve` (branch clean-up),
   `github-morning-run` (routine upkeep). It must not modify anything unless
   `--fix-push` is given (then it may switch the remote to HTTPS, as the old skill did).
   Exit 0 unless a check is `FAIL`.
4. Update the two rules files to reference `orient` scripts.
5. Merge procedure steps 9.4 to 9.7 for `git-push-protocol-handler` (registry entry
   `orient` added; `git-push-protocol-handler` entry removed).

## Done when
- [ ] `bash clusters/01-meta/orient/orient.sh` in this repo prints three result lines and the Next block, and exits 0.
- [ ] Without `--fix-push`, `git remote -v` is unchanged after running it.
- [ ] Shared conventions steps 5 and 6 pass for `git-push-protocol-handler`; MCP tests pass.

## Return signal
Commit message: `feat!: add orient entry skill, absorbing git-push-protocol-handler` with footer
`BREAKING CHANGE: git-push-protocol-handler is replaced by orient.`
Then follow Shared conventions step 7.
