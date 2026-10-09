# Task RA-03: Make frontmatter the only description source (prompts and MCP)

> Status: done
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02
> Effort: S
> Touches: `build.sh`, `mcp-server/src/loader.ts`, `mcp-server/registry.json`, `mcp-server/src/__tests__/registry.test.ts`, `.github/workflows/validate.yml`, `CHANGELOG.md`

## Objective
Prompt files (VS Code) and MCP tools (VS Code, JetBrains) take their descriptions from
`SKILL.md` frontmatter, so one edit updates all three surfaces; and CI enforces the
frontmatter.

## Background
- The owner uses Claude Code, VS Code prompt files, and JetBrains MCP on two machines.
  All three must route on the same description.
- Today `build.sh` (around line 49) scrapes the first 5 lines of `## Description` and
  truncates to 200 characters, and `mcp-server/registry.json` holds a separate
  hand-written `description` per tool. Both drift.
- Decided: the MCP server reads descriptions from frontmatter at load time. The
  `description` field is removed from `registry.json` entries (entries keep `name` and `skill`).
- RA-02 has added frontmatter to every `SKILL.md` (format:
  `description: "<text>"` on one line inside the leading `---` block).

## Context files
- `build.sh`: the description extraction and the YAML it writes into `.prompt.md` files.
- `mcp-server/src/loader.ts`: how `registry.json` is read and tools are built.
- `mcp-server/src/__tests__/registry.test.ts`: existing registry tests (note it
  hard-codes `clusters/01-meta` and `clusters/07-devops`; leave that for RA-15).
- `.github/workflows/validate.yml`: the `structure` job (copy its style), and the
  `registry-sync` job (its python one-liner reads `t['skill']`, which stays valid).

## Steps
1. `build.sh`: replace the `## Description` scrape with extraction of the frontmatter
   `description` value (text between the quotes on the `description:` line within the
   first 6 lines). Remove the 200-character truncation. Keep the existing escaping for
   the YAML it writes. If a skill has no frontmatter, fall back to the old scrape and
   print a warning to stderr.
2. `mcp-server/src/loader.ts`: when loading each registry entry, read the referenced
   `SKILL.md`, parse the frontmatter `description`, and use it as the tool description.
   Fall back to the registry entry's `description` if present, else the skill name, and
   log a warning via the existing logger.
3. Remove the `description` field from every entry in `mcp-server/registry.json`.
4. Add a test in `registry.test.ts`: for every registry entry, the loaded tool
   description equals the frontmatter description of its `SKILL.md`.
5. In `validate.yml`, add a step at the end of the `structure` job:
   ```yaml
         - name: Every SKILL.md has name/description frontmatter
           run: bash scripts/check-frontmatter.sh
   ```
6. `CHANGELOG.md` → `### Changed`: `- build.sh and the MCP server now read descriptions from SKILL.md frontmatter; registry.json no longer carries descriptions.`

## Constraints
- Do not change tool names or the registry's `name`/`skill` fields.
- Keep the MCP server's fail-open behaviour (a bad skill must not crash the server).

## Done when
- [ ] `bash scripts/check-frontmatter.sh` exits 0 (all skills).
- [ ] `bash build.sh` succeeds; `grep -c 'Use when' prompts/*.prompt.md | grep ':0' ` prints nothing.
- [ ] `cd mcp-server && npm ci && npm run build && npm test` passes, including the new test.
- [ ] `grep -c '"description"' mcp-server/registry.json` prints `0`.
- [ ] Editing one skill's frontmatter description and re-running `build.sh` and the MCP test shows the new text in both (revert the edit afterwards).

## Return signal
Commit message: `feat: single-source skill descriptions from frontmatter`
Then follow Shared conventions step 7.
