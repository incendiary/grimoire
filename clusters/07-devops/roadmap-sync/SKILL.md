# roadmap-sync

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
After merging a PR or closing an issue, update the README roadmap section to reflect
the new state — tick completed items, add new planned items, and strip stale entries.

Invoke when: a PR has been merged, an issue closed, or a version released, and the
README roadmap section needs to reflect the current state. Trigger phrases: "update
the roadmap", "mark this as done in the README", "sync the roadmap".

## Context needed
- The README structure: where the roadmap section lives and what format it uses
- The issue numbers or PR titles that have been completed
- Any new planned items to add

## What to do

1. **Read the current README roadmap section** before making any changes. Do not
   write from memory — the actual state on disk may differ from what was discussed.

2. **Tick completed items.** Change `- [ ]` to `- [x]` for items corresponding
   to merged PRs or closed issues. Match by description, not issue number (issue
   numbers in roadmaps become opaque over time).

3. **Add new planned items** at the bottom of the relevant section. Use the
   `- [ ]` checkbox format. Be specific — "Add IPv6 support" not "improve functionality".

4. **Remove or archive stale items.** Items that are no longer planned, were
   superseded, or no longer make sense should be removed. Do not leave items that
   create a misleading picture of the project's direction.

5. **Commit the README update as a standalone commit** after the feature/release commit,
   not bundled with it. The roadmap update is a documentation change and should be
   separable in `git log`:
   ```bash
   git add README.md
   git commit -m "Update roadmap: mark [feature] complete, add [next-item]"
   ```

## Gotchas
- Do not strip version numbers from historical completed items — they provide context
  for when things were delivered.
- Do not add planned items that are speculative or not actually intended. A roadmap
  with 20 unchecked items looks abandoned. Keep it to 3–5 realistic near-term items.
- If the README uses a different roadmap format (table, prose, numbered list), match
  the existing format — do not convert to checkboxes.

## Suggested scripts
- `update_roadmap.py` — parses closed GitHub issues, matches against roadmap text,
  and proposes a diff of checkbox updates for review
