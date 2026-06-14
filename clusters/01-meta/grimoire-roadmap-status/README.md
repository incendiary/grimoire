# grimoire-roadmap-status

> MCP-friendly roadmap query utility for grimoire.

## Purpose

Provides a quick status snapshot from `ROADMAP.md`: open/completed totals, top clusters
by outstanding work, and unresolved infrastructure roadmap items.

## When to invoke

- "What should I work on next?"
- "Show me roadmap status"
- Starting a new implementation session
- Before planning a release batch

## Output

- Open checklist item count
- Completed checklist item count
- Top clusters by open items
- Open infrastructure roadmap items

## Example invocation

```text
give me roadmap status and top outstanding clusters
```

(When loaded via MCP registry as `grimoire_roadmap_status`, this runs automatically.)
