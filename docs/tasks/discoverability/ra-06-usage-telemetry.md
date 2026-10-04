# Task RA-06: Cross-machine skill usage telemetry

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: none
> Effort: M
> Touches: `scripts/hooks/log-skill-use.sh` (new), `scripts/usage-report.sh` (new), `install-all.sh`, `uninstall-all.sh`, `mcp-server/src/logger.ts` or `server.ts`, `CHANGELOG.md`

## Objective
Record every grimoire skill use (Claude Code model-invoked, Claude Code slash command,
MCP tool call) to a local log on each machine, and provide a report that merges logs
from several machines.

## Background
- The review's usage data covers one Mac and Claude Code only. The owner also uses
  VS Code and JetBrains (MCP) on a second machine. No skill may be pruned (RA-23) on
  partial evidence, so this must ship early and run for 60 days.
- Privacy: log only `ISO-8601 timestamp<TAB>short hostname<TAB>surface<TAB>skill`.
  Never log prompt text, file paths, arguments, or repo names.
- Surfaces: `claude-skill` (Skill tool), `claude-slash` (`/name` typed by the user), `mcp`.
- Log location: `~/.claude/grimoire-usage.log` for Claude Code; the MCP server writes
  the same line format to `~/.claude/grimoire-usage.log` too (create `~/.claude` if absent;
  on machines with no Claude Code that is still fine).
- Only names of grimoire skills are logged. A name counts as grimoire if a directory of
  that name exists in the installed skills dir (`~/.claude/skills/<name>`) or, for MCP,
  if it is a registered tool.
- Claude Code hooks receive JSON on stdin. `PreToolUse` with matcher `Skill` gets
  `{"tool_name":"Skill","tool_input":{"skill":"<name>",...},...}`. `UserPromptSubmit` gets
  `{"prompt":"<text>",...}`; extract only a leading `/name` token from it.
- Installing hooks edits `~/.claude/settings.json`, which is outside the repo: make it
  opt-in (`--with-telemetry`), back up first, support `--dry-run`, and never remove
  existing hooks.

## Context files
- `install-all.sh`, `uninstall-all.sh`: flags, backup pattern, `--dry-run` style.
- `install-vscode.sh`: how it merges JSON settings safely (reuse that approach; Python 3 is available).
- `mcp-server/src/server.ts`, `mcp-server/src/logger.ts`: where tool calls are handled and logged.

## Steps
1. `scripts/hooks/log-skill-use.sh`: reads stdin JSON (use `python3 -c` for parsing,
   no `jq` dependency), decides surface from the presence of `tool_input` vs `prompt`,
   extracts the name, checks it is a grimoire skill (installed dir exists), and appends
   one line. Always exit 0 and print nothing (a hook must never block or slow the session).
2. `install-all.sh --with-telemetry [--dry-run]`: copies the hook script to
   `~/.claude/hooks/grimoire-log-skill-use.sh` and merges into `~/.claude/settings.json`:
   ```json
   {"hooks": {
     "PreToolUse": [{"matcher": "Skill", "hooks": [{"type": "command", "command": "bash ~/.claude/hooks/grimoire-log-skill-use.sh"}]}],
     "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash ~/.claude/hooks/grimoire-log-skill-use.sh"}]}]
   }}
   ```
   Append to existing arrays; skip if an identical command is already present. Back up
   `settings.json` to `settings.json.bak-YYYYMMDD-HHMMSS` before writing.
3. `uninstall-all.sh`: remove exactly those hook entries and the hook script (leave the log).
4. MCP server: on each tool call, append the same line format with surface `mcp`.
   Wrap in try/catch; a logging failure must not fail the tool call.
5. `scripts/usage-report.sh [log ...]` (default `~/.claude/grimoire-usage.log`): merges
   logs, prints per skill: total, per-surface counts, hosts, last used. Then a section
   `Never used:` listing every `clusters/*/*/` skill name with no entries, and the date
   range covered.
6. Document `--with-telemetry` in `README.md` Quick Start (two lines).
7. `CHANGELOG.md` → `### Added`: `- Opt-in skill usage telemetry (install-all.sh --with-telemetry) and scripts/usage-report.sh.`

## Constraints
- Never log prompt text. Test this explicitly (Done when).
- Do not enable telemetry by default.
- Hook must complete in under 100 ms in normal use (no network, no heavy work).

## Done when
- [ ] `echo '{"tool_name":"Skill","tool_input":{"skill":"local-ci"}}' | HOME=$tmp bash scripts/hooks/log-skill-use.sh` (with `$tmp/.claude/skills/local-ci/` existing) appends one `claude-skill` line.
- [ ] `echo '{"prompt":"/local-ci please check secret-token-123"}' | ...` appends a `claude-slash` line and `grep -c secret-token "$tmp/.claude/grimoire-usage.log"` prints `0`.
- [ ] A non-grimoire name appends nothing.
- [ ] `bash install-all.sh --with-telemetry --dry-run` prints the planned settings change and writes nothing; a real run against a temp `HOME` produces valid JSON (`python3 -m json.tool`) with prior hooks preserved.
- [ ] `cd mcp-server && npm run build && npm test` passes.
- [ ] `bash scripts/usage-report.sh a.log b.log` merges two sample logs correctly.
- [ ] shellcheck clean.

## Return signal
Commit message: `feat: opt-in skill usage telemetry and usage report`
Then follow Shared conventions step 7. Tell the owner in your return message to run
`bash install-all.sh --with-telemetry` on both machines, since the 60-day clock for RA-23 starts then.
