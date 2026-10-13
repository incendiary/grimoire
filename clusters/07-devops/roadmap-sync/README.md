# roadmap-sync

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Keeps the README roadmap in sync after merges and releases. Ticks completed items
and removes stale ones; it never adds items. Extracted after the same roadmap
update pattern appeared 3 times in a DNSResolver session.

---

## What this skill does

After a PR merges or a release ships, reads the actual README, ticks the completed
items, and commits the update as a standalone documentation commit.

Enforces: always read before writing; never add items (new work enters the roadmap
only when the owner asks).

---

## When to use it

- Immediately after `gh pr merge` or `gh release create`
- When the roadmap is known to be out of date

---

## How to invoke it in a session

```
/roadmap-sync
Completed: issues #56 and #57 (retry logic and output formatting)
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `update_roadmap.py` (parse closed issues, propose checkbox diff)
- [x] Ship: copy to `~/.claude/skills/roadmap-sync/`
