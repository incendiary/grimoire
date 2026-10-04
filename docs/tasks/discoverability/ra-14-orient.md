# Task RA-14: Rename `repo-compass` to `orient`, absorbing the push check

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-02
> Effort: S
> Touches: `clusters/07-devops/repo-compass/` → `clusters/07-devops/orient/`, `clusters/07-devops/git-push-protocol-handler/` (deleted), `mcp-server/registry.json`, `clusters/07-devops/README.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
The session-start skill is called `orient` (the entry of the orient pathway) and also
covers the SSH push check, so the owner types one name at the start of a session.

## Background
- `repo-compass` is already the most-used session-start skill; renaming it is cheaper than
  building a new orchestrator. Its script keeps its file name, `repo-compass.sh`.
- `git-push-protocol-handler` (`check_push_protocol.sh`): verify SSH agent; on failure
  switch the remote to HTTPS via `gh`. It becomes a section of `orient`.
- Both are `Type: action` with MCP registry entries.

## New frontmatter description (use verbatim)
`Session-start orientation for a GitHub repo: true state from PRs, issues, CI and releases cross-checked against README roadmap items, plus an SSH push check with HTTPS fallback. Use when starting or resuming work on a repo, asked 'where are we on this project', 'what is outstanding', or when a push fails on SSH. For branch clean-up use branch-surface-resolve; for routine upkeep use github-morning-run.`

## Steps
1. Move files:
   ```bash
   git mv clusters/07-devops/repo-compass clusters/07-devops/orient
   git mv clusters/07-devops/git-push-protocol-handler/check_push_protocol.sh clusters/07-devops/orient/
   ```
2. `clusters/07-devops/orient/SKILL.md`: frontmatter `name: orient` and the description
   above; heading `# orient`; then append, before `## Gotchas` (or at the end if absent), a
   section `## Push protocol check` containing the `## What to do` and `## Gotchas`
   content of `git-push-protocol-handler/SKILL.md` with headings demoted one level and the
   script path changed to `orient/check_push_protocol.sh`.
3. `clusters/07-devops/orient/README.md`: replace `repo-compass` with `orient` in the title
   and install commands (not in the script name `repo-compass.sh`); append the push
   handler README's usage section under `## Push protocol check`; append its `## Roadmap`
   unchecked items to `orient`'s `## Roadmap`.
4. Delete and record:
   ```bash
   git rm -r clusters/07-devops/git-push-protocol-handler
   printf 'repo-compass\torient\ngit-push-protocol-handler\torient\n' >> scripts/renamed-skills.txt
   ```
5. `mcp-server/registry.json`: entry `repo-compass` becomes `"name": "orient"`,
   `"skill": "clusters/07-devops/orient/SKILL.md"`; delete the `git-push-protocol-handler` entry.
6. Fix references (word match; the pattern does not touch `repo-compass.sh`):
   ```bash
   grep -rnP '(?<![A-Za-z0-9-])(repo-compass|git-push-protocol-handler)(?![A-Za-z0-9-]|\.sh)' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude=renamed-skills.txt --exclude=discoverability-intents.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks
   ```
   (macOS: use `ggrep -P` if available, else `python3 -c` with the same regex.) Replace each
   with `orient`; merge duplicate list lines. Leave `- [x]` history lines in `ROADMAP.md`.
7. `CHANGELOG.md` → `### Changed`: `- repo-compass renamed to orient; git-push-protocol-handler folded into it.`

## Done when
- [ ] `bash clusters/07-devops/orient/repo-compass.sh --help` (or its normal invocation) still works.
- [ ] `bash clusters/07-devops/orient/check_push_protocol.sh` runs and `git remote -v` is unchanged unless it reports an SSH failure.
- [ ] Step 6 search prints nothing except `- [x]` lines.
- [ ] `bash scripts/check-frontmatter.sh clusters/07-devops/orient/SKILL.md` exits 0; MCP tests pass; Shared conventions step 6 passes.

## Return signal
Commit message: `feat!: rename repo-compass to orient, absorbing git-push-protocol-handler` with footer
`BREAKING CHANGE: repo-compass is now orient; git-push-protocol-handler is part of orient.`
Then follow Shared conventions step 7.
