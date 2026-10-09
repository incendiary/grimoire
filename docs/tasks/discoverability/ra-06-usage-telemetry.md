# Task RA-06: Usage report from existing transcripts and MCP logs

> Status: done
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: S
> Touches: `scripts/usage-report.py` (new), `CHANGELOG.md`

## Objective
One script reports grimoire skill usage from data that already exists: Claude Code
transcripts and the MCP server log. No hooks, no settings changes.

## Background
- Claude Code stores every session as JSONL under `~/.claude/projects/*/*.jsonl`. Skill use
  appears as:
  - assistant content blocks `{"type":"tool_use","name":"Skill","input":{"skill":"<name>"}}`
  - MCP calls `{"type":"tool_use","name":"mcp__grimoire__<name>",...}`
  - slash commands as text containing `<command-name>/<name></command-name>` (in a
    string `message.content`, or in a text block's `text`).
- The MCP server logs `[<ISO time>] [INFO] [tool-call] Executing: <name>` lines to
  `mcp-server/logs/mcp-server.log` (VS Code and JetBrains use go through this).
- `session-skill-extractor` runs from a Stop hook, so it never appears in either source.
  Report it as `hook-driven (not counted)`.
- Transcripts are pruned after `cleanupPeriodDays` (Claude Code setting). The owner must
  raise it; you only tell them.
- The report merges data from several machines: the owner copies the other machine's
  `~/.claude/projects` and MCP log over and passes the paths.

## Steps
1. Write `scripts/usage-report.py` (Python 3 stdlib only):
   - Args: `--projects DIR` (repeatable, default `~/.claude/projects`), `--mcp-log FILE`
     (repeatable, default `mcp-server/logs/mcp-server.log` if it exists), `--repo DIR` (default: repo root).
   - Skill names = directory names of `clusters/*/*/` under `--repo`, plus every old name in
     `scripts/renamed-skills.txt`, mapped to its current name (follow chains; `-` = retired).
   - Parse each JSONL line with `json.loads` inside try/except; collect counts per skill
     per source (`skill-tool`, `slash`, `mcp`), and last-used date (the line's `timestamp`
     field if present, else the file mtime).
   - Print: date range covered; a table sorted by total (skill, total, skill-tool, slash,
     mcp, last used); then `Never used:` listing current skills with zero, excluding
     `session-skill-extractor` (print it under `Hook-driven (not counted):`).
2. `CHANGELOG.md` → `### Added`: `- scripts/usage-report.py: skill usage from Claude Code transcripts and MCP logs.`

## Done when
- [ ] `python3 scripts/usage-report.py` runs on this machine and lists `codebase-holistic-review` and `devops-practices` (or their renamed names) with non-zero counts.
- [ ] A temp dir with one hand-made JSONL line containing a `Skill` tool_use for `local-ci`, passed via `--projects`, reports exactly 1 use of `local-ci` (or its renamed name).
- [ ] A temp log with one `[tool-call] Executing: roadmap-sync` line, passed via `--mcp-log`, reports 1 `mcp` use.

## Return signal
Commit message: `feat: usage report from transcripts and MCP logs`
Then follow Shared conventions step 7. In your return message tell the owner:
`Set "cleanupPeriodDays": 120 in ~/.claude/settings.json on both machines so transcripts cover the RA-23 window.`
