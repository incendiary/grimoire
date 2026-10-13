---
name: roadmap-sync
description: "Updates a repo README roadmap after a PR merges, an issue closes, or a release ships, ticking completed items and removing stale ones; it never adds items. Use when a PR has been merged, an issue closed, or a version released, or asked to 'update the roadmap', 'mark this as done in the README', or 'sync the roadmap'. To choose what to work on next use roadmap."
---
# roadmap-sync

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
After merging a PR or closing an issue, update the README roadmap section to reflect
the new state — tick completed items and strip stale entries. It never adds items.

Invoke when: a PR has been merged, an issue closed, or a version released, and the
README roadmap section needs to reflect the current state. Trigger phrases: "update
the roadmap", "mark this as done in the README", "sync the roadmap".

## Context needed
- The README structure: where the roadmap section lives and what format it uses
- The issue numbers or PR titles that have been completed

## What to do

1. **Read the current README roadmap section** before making any changes. Do not
   write from memory — the actual state on disk may differ from what was discussed.

2. **Tick completed items.** Change `- [ ]` to `- [x]` for items corresponding
   to merged PRs or closed issues. Match by description, not issue number (issue
   numbers in roadmaps become opaque over time).

3. **Remove or archive stale items.** Items that are no longer planned, were
   superseded, or no longer make sense should be removed. Do not leave items that
   create a misleading picture of the project's direction.

4. **Commit the README update as a standalone commit** after the feature/release commit,
   not bundled with it. The roadmap update is a documentation change and should be
   separable in `git log`:
   ```bash
   git add README.md
   git commit -m "docs: roadmap: mark [feature] complete"
   ```

## Gotchas
- Do not strip version numbers from historical completed items — they provide context
  for when things were delivered.
- Never add new items. New work enters the roadmap only when the owner asks for it.
- If the README uses a different roadmap format (table, prose, numbered list), match
  the existing format — do not convert to checkboxes.

## Suggested scripts
- `update_roadmap.py` — parses closed GitHub issues, matches against roadmap text,
  and proposes a diff of checkbox updates for review
