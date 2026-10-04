# Task RA-23: Evidence-based prune report

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: none (owner decides)
> Depends on: RA-06 installed on both machines for at least 60 days; RA-15
> Effort: S
> Touches: writes `docs/usage-review-<YYYY-MM-DD>.md` only

## Objective
Recommend keep, merge, or archive for every skill, based on usage across both machines.
The owner decides; this task deletes nothing.

## Background
- The original review (`REVIEW.md` 2.2) found about 40 skills never used on one machine,
  but could not see the second machine (VS Code and JetBrains). RA-06 added telemetry to
  close that gap.
- A skill can be valuable but rare (for example `publish-history-wipe`, `incident-*`).
  Low use alone is not a reason to archive; "never used and duplicated elsewhere" is.
- Archive means: move to `archive/<name>/` (excluded from install). Not deletion.

## Steps
1. Ask the owner (stop with `CHUNK BLOCKED: RA-23 need usage logs`) for the
   `~/.claude/grimoire-usage.log` files from both machines unless they are provided in the dispatch prompt.
2. `bash scripts/usage-report.sh <log1> <log2>`.
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
