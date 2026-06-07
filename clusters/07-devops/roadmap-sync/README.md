# roadmap-sync

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

Keeps the README roadmap in sync after merges and releases. Ticks completed items,
adds near-term planned items, removes stale ones. Extracted after the same roadmap
update pattern appeared 3 times in a DNSResolver session.

---

## What this skill does

After a PR merges or a release ships, reads the actual README, ticks the completed
items, and commits the update as a standalone documentation commit.

Enforces: always read before writing, keep planned items to 3–5 realistic ones, never
make a roadmap that looks abandoned.

---

## When to use it

- Immediately after `gh pr merge` or `gh release create`
- At the start of a new development sprint to review what is planned
- When the roadmap is known to be out of date

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/roadmap-sync ~/.claude/skills/
```

---

## How to invoke it in a session

```
/roadmap-sync
Completed: issues #56 and #57 (retry logic and output formatting)
New planned items: add --json flag, add IPv6 support
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `update_roadmap.py` (parse closed issues, propose checkbox diff)
- [ ] Test on DNSResolver and Slice-N-Dice
- [x] Ship: copy to `~/.claude/skills/roadmap-sync/`
