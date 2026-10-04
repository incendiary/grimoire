# Task RA-23: Evidence-based prune report

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: none (owner decides)
> Depends on: RA-06, RA-15, and 60 days of transcripts on both machines (`cleanupPeriodDays` raised)
> Effort: S
> Touches: writes `docs/usage-review-<YYYY-MM-DD>.md` only

## Objective
Recommend keep, merge, or archive for every skill, based on usage across both machines.
The owner decides; this task deletes nothing.

## Background
- The original review (`REVIEW.md` 2.2) found about 40 skills never used on one machine,
  but could not see the second machine (VS Code and JetBrains). RA-06 added
  `scripts/usage-report.py`, which reads transcripts and MCP logs from any number of machines.
- `session-skill-extractor` runs from a Stop hook and is not counted; always `keep` it.
- A skill can be valuable but rare (for example `publish-history-wipe`, `incident-*`).
  Low use alone is not a reason to archive; "never used and duplicated elsewhere" is.
- Archive means: move to `archive/<name>/` (excluded from install). Not deletion.

## Steps
1. Ask the owner (stop with `CHUNK BLOCKED: RA-23 need usage data`) for paths to the other
   machine's copied `~/.claude/projects` directory and MCP log, unless the dispatch prompt provides them.
2. `python3 scripts/usage-report.py --projects ~/.claude/projects --projects <other> --mcp-log mcp-server/logs/mcp-server.log --mcp-log <other-log>`.
3. Write `docs/usage-review-<date>.md` with a table: skill, uses, surfaces, last used,
   recommendation (`keep` / `merge into <x>` / `archive`), one-line reason. Rules:
   - Used at least once in the window: `keep` unless clearly duplicated.
   - Never used, and a pathway entry or an incident/publish skill (rare by nature): `keep`, note "rare by nature".
   - Never used and its job is covered by another skill: `merge into <x>`.
   - Never used otherwise: `archive`.
4. Summarise counts per recommendation at the top.

## Done when
- [ ] Report covers every directory in `ls -d clusters/*/*/`.
- [ ] No files moved or deleted.

## Return signal
Commit message: `docs: usage review <date>`
Output: `CHUNK COMPLETE: RA-23 report ready for owner decision`.
