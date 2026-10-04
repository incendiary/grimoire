# Task RA-22: Delete "test on real X" validation items from skill roadmaps

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: XS
> Touches: `clusters/*/*/README.md` (`## Roadmap` sections only), `ROADMAP.md` (regenerated), `CHANGELOG.md`

## Objective
Remove unchecked roadmap items that can only be closed by observing real use, so the open
count reflects work that can actually be picked up.

## Background
- About 30 of 49 open items are of this kind. Nobody schedules them, they never close,
  and they hide actionable work. Decided by the owner (2026-10-04 audit): delete them.
  When real use turns up a gotcha, it goes into that skill's `## Gotchas` section at the time.
- `ROADMAP.md`'s open-items block is generated; never edit it by hand. Regenerate with
  `check-roadmap-sync.sh --fix`.

## Steps
1. List candidates:
   ```bash
   grep -nE '^- \[ \] .*([Tt]est on|[Tt]est across|[Tt]est end-to-end|requires real|from real usage|as they are encountered)' clusters/*/*/README.md
   ```
   Only lines inside a `## Roadmap` section count; check each hit's section by eye.
2. Delete those lines (only those; leave checked `- [x]` items and all other unchecked
   items). If a `## Roadmap` section is left with no unchecked items, leave the section as it is.
3. Regenerate: `bash clusters/07-devops/devops-practices/check-roadmap-sync.sh . --fix`
   (use `clusters/07-devops/ci-standards/...` if that path exists instead).
4. `CHANGELOG.md` → `### Removed`: `- "Test on real X" validation items from skill roadmaps (<N> items).` with N filled in.

## Done when
- [ ] Step 1 grep prints nothing.
- [ ] `check-roadmap-sync.sh . --check` exits 0, and the `**Open items:**` count in `ROADMAP.md` fell by N.
- [ ] `git diff main -- clusters` shows only deleted lines.

## Return signal
Commit message: `docs: remove unschedulable validation items from skill roadmaps`
Then follow Shared conventions step 7.
