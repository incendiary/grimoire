# Task RA-07: Delete five always-on skills that duplicate built-in or global behaviour

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: S
> Touches: five skill directories (deleted), `mcp-server/registry.json`, `clusters/01-meta/README.md`, `clusters/07-devops/README.md`, `PROJECT-WORKFLOWS.md`, `README.md`, other skills' cross-references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
Remove five skills that describe standing behaviour. Their content is either already
built into Claude Code or belongs as one line in the owner's global `~/.claude/CLAUDE.md`.

## Background
Decided by the owner after the 2026-10-04 audit. Do not migrate these into rules files.

| Skill (delete) | Why it can go |
|---|---|
| `clusters/01-meta/test-before-asking` | Claude Code's auto mode already biases to action; the skill also contradicts the owner's global rule "if uncertain, ask" |
| `clusters/01-meta/mid-task-checkin` | Claude Code delivers queued user messages mid-task |
| `clusters/07-devops/pre-commit-aware-commits` | Claude Code's system prompt already covers hook failures (fix, re-stage, new commit) |
| `clusters/01-meta/cwd-verification` | One line in global CLAUDE.md (proposed below) |
| `clusters/01-meta/verify-code-version` | One line in global CLAUDE.md (proposed below) |

- `python-black-ruff-authoring` is **not** in this task; RA-09 folds it into `py-lint`.
- `cwd-verification`, `verify-code-version`, `pre-commit-aware-commits` have MCP registry
  entries (`Type: action`); remove them.
- You must not edit `~/.claude/CLAUDE.md`. You only propose lines; the owner applies them.

## Steps
1. Read `cwd-verification/SKILL.md` and `verify-code-version/SKILL.md`. Draft one line
   each (at most 30 words, imperative, British English, no em dashes) capturing the rule,
   for example: `Before bulk file operations, confirm the working directory with pwd when a project exists in both a local and an iCloud path.`
2. Delete the five directories:
   ```bash
   git rm -r clusters/01-meta/test-before-asking clusters/01-meta/mid-task-checkin clusters/07-devops/pre-commit-aware-commits clusters/01-meta/cwd-verification clusters/01-meta/verify-code-version
   printf '%s\t-\n' test-before-asking mid-task-checkin pre-commit-aware-commits cwd-verification verify-code-version >> scripts/renamed-skills.txt
   ```
3. Remove the three entries from `mcp-server/registry.json` whose `name` is
   `cwd-verification`, `verify-code-version`, or `pre-commit-aware-commits`. Keep JSON valid.
4. Find every reference and remove it (delete the list line or sentence; do not replace
   with another skill name):
   ```bash
   grep -rnwE 'test-before-asking|mid-task-checkin|pre-commit-aware-commits|cwd-verification|verify-code-version' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude=renamed-skills.txt --exclude=discoverability-intents.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks
   ```
   Repeat until it prints nothing.
5. `CHANGELOG.md` under `## [Unreleased]` → `### Removed`:
   `- test-before-asking, mid-task-checkin, pre-commit-aware-commits, cwd-verification, verify-code-version (duplicated Claude Code behaviour or belong in global CLAUDE.md).`

## Done when
- [ ] The five directories do not exist.
- [ ] Step 4 grep prints nothing.
- [ ] `python3 -m json.tool mcp-server/registry.json >/dev/null` succeeds and `cd mcp-server && npm ci && npm run build && npm test` passes.
- [ ] Shared conventions step 6 checks pass.

## Return signal
Commit message: `feat!: remove five always-on skills` with footer
`BREAKING CHANGE: test-before-asking, mid-task-checkin, pre-commit-aware-commits, cwd-verification and verify-code-version are removed.`
Then follow Shared conventions step 7, and include the two proposed CLAUDE.md lines in
your return message, labelled `PROPOSED GLOBAL CLAUDE.md LINES (owner to apply):`.
