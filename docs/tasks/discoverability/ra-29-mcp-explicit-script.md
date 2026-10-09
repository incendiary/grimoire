# Task RA-29: MCP tools run one named script, not every bash block

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Review: opus (master reviews the full diff before integrating)
> Fallback: opus
> Depends on: RA-15 (registry names are final)
> Effort: M
> Touches: `mcp-server/src/loader.ts`, `mcp-server/src/executor.ts`, `mcp-server/registry.json`, `mcp-server/src/__tests__/*`, `.github/workflows/validate.yml` (registry-sync), `CHANGELOG.md`

## Objective
Calling a grimoire MCP tool runs exactly one script named in the registry, with
arguments the caller supplies. It never executes documentation code blocks from `SKILL.md`.

## Background
- Found during wave 3 (2026-10-09). `loader.ts` `extractCommands()` collects **every**
  ```` ```bash ```` / ```` ```sh ```` block in an action skill's `SKILL.md`, and `executor.ts`
  runs them all in sequence via `/bin/zsh`, in the caller-supplied `cwd`.
- Today nothing destructive runs, but only by accident: `publish-history-wipe`'s
  `rm -rf .git` and `git push --force` blocks begin with a `#` comment, which the
  extractor skips; `publish-secret-scan`'s loop with `rm -rf ${repo}` fails on a
  `<repo-list>` placeholder. Any edit to those examples could make a tool call destructive.
- The owner uses these tools from JetBrains and VS Code on a second machine.
- Decided: each registry entry gains a `script` field (path relative to repo root) and an
  optional `args` schema; the server runs only that script. Skills with no single safe
  script to run are removed from the registry (they stay as skills; Claude Code and prompt
  files are unaffected).

## Steps
1. For each entry in `mcp-server/registry.json`, open its `SKILL.md` and skill directory
   and choose the one script that is the tool's read-only or primary entry point (e.g.
   `orient` → `repo-compass.sh`). If the only scripts are destructive (history wipe, force
   push, bulk push, release creation), or there is no script, remove the entry and list it
   in the commit body with the reason.
2. `registry.json` entries become `{"name", "skill", "script"}`. Keep descriptions sourced
   from frontmatter (RA-03).
3. `loader.ts`: delete `extractCommands()`. Each tool takes an optional `args` string array
   and `cwd`; the executor runs `bash <repo>/<script> <args...>` using `execFile` (no shell),
   so arguments are never shell-interpolated.
4. `validate.yml` registry-sync: also assert every `script` path exists and is executable.
5. Tests: one per remaining tool asserting the resolved command is exactly
   `bash <script>`; one asserting that a SKILL.md containing `rm -rf /tmp/should-not-run`
   in a bash block does not execute it.
6. `CHANGELOG.md` → `### Security`: `- MCP tools run one registered script via execFile instead of every bash block in SKILL.md.`

## Done when
- [ ] `git grep -n extractCommands mcp-server/src` prints nothing.
- [ ] `cd mcp-server && npm ci && npm run build && npm test` passes, including the step 5 tests.
- [ ] Every registry entry has a `script` that exists and is executable.
- [ ] The commit body lists every removed entry with its reason.

## Return signal
Commit message: `fix!: MCP tools run one registered script, not SKILL.md code blocks` with footer
`BREAKING CHANGE: MCP tools take an args array and run a single script; some tools are removed from MCP.`
Then follow Shared conventions step 7.
