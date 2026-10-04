# Task RA-13: Merge `grimoire-roadmap-status` into `roadmap-driver` as `roadmap`

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02, RA-22
> Effort: S
> Touches: `clusters/01-meta/roadmap-driver/` → `clusters/01-meta/roadmap/`, `clusters/01-meta/grimoire-roadmap-status/` (deleted), `mcp-server/registry.json`, `clusters/01-meta/README.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `roadmap`, answers both "show roadmap status" and "what should I work on next".

## Background
- `grimoire-roadmap-status` (action): compact view of `ROADMAP.md`: open/complete
  counts, top clusters by outstanding items, infrastructure progress.
- `roadmap-driver` (action): selects the next roadmap item and frames the chain
  (`repo-compass` → `task-decomposer` → `karpathy-framework` → `karpathy-verify`).
- Status is a subset of what the driver reads. After RA-22, `ROADMAP.md` separates
  actionable and validation counts: status mode should report both.
- `roadmap-sync` (tick items after a merge) and `project-delivery-workflow` stay separate
  skills; RA-15 renames the latter to `roadmap-deliver`.

## New frontmatter description (use verbatim)
`Shows roadmap status and picks the next implementation-ready item from ROADMAP.md or README roadmaps, then frames the execution chain (state, decompose, plan, verify). Use when asked 'what should I work on next', 'show roadmap status', 'what is still open', or 'pick up from the roadmap'. To tick items after a merge use roadmap-sync.`

## Steps
1. Merge procedure (Shared conventions step 9), base moved with
   `git mv clusters/01-meta/roadmap-driver clusters/01-meta/roadmap`.
2. Give the script a status mode (`--status`) that produces the old
   `grimoire-roadmap-status` output (port its script; keep its output format so existing
   readers do not break). Default mode stays "pick next".
3. Registry: one entry `roadmap`; remove both old entries.

## Done when
- [ ] Parity checklist complete.
- [ ] `--status` output on this repo matches the old status script's output (run the old one from `git show main:...` into a temp file and diff), apart from the new actionable/validation split.
- [ ] Default mode still selects an item.
- [ ] Shared conventions steps 5 and 6 pass; MCP tests pass.

## Return signal
Commit message: `feat!: merge grimoire-roadmap-status into roadmap-driver as roadmap` with footer
`BREAKING CHANGE: roadmap-driver is now roadmap; grimoire-roadmap-status is roadmap --status.`
Then follow Shared conventions step 7.
