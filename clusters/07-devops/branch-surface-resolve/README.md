# branch-surface-resolve

> Audits every branch in a repository, categorises it, and resolves what can be resolved via PRs.

## Purpose

When a repo accumulates branches across multiple sessions — local-only, pushed-but-no-PR,
stale, or conflicted — this skill provides a structured audit and resolution pass. The result
is a clean repo state: all work on `main` via squash-merge PRs, conflicts surfaced explicitly,
and nothing silently lost in a local branch.

---

## When to invoke

- "I have branches everywhere and don't know what's ready"
- "Clean up my branch state and land everything"
- Returning to a repo after a break
- Pre-release hygiene pass

---

## How it works

The script categorises every branch:

| Category | What it means | Script action with `--resolve` |
|----------|---------------|-------------------------------|
| `READY` | Ahead of main, no conflicts, no open PR | Push + create PR |
| `LOCAL-ONLY` | Not pushed to remote | Push first, then PR |
| `HAS-PR` | Open PR already exists | Show PR URL + status |
| `CONFLICT` | Merge conflict with main detected | Surface diff, stop — manual only |
| `STALE` | Zero commits ahead of main | List for pruning decision |

Conflicts are **never** auto-resolved — they are surfaced with commit list, file diff
summary, and three resolution options for deliberate human decision.

---

## Usage

```bash
# Report only — see what's in every branch
bash branch-surface-resolve.sh

# Report + push + create PRs for READY and LOCAL-ONLY branches
bash branch-surface-resolve.sh --resolve

# Also prompt to delete STALE branches
bash branch-surface-resolve.sh --resolve --prune-stale
```

---

## Installation

### Claude Code

```bash
bash install-all.sh  # copies all skills including branch-surface-resolve
```

### VS Code (Copilot Chat)

After running `bash build.sh`, reference with `#branch-surface-resolve` in Copilot Chat.

### MCP tool

Registered as `branch-surface-resolve` in `mcp-server/registry.json`.

---

## Chain

```
branch-surface-resolve --resolve     → land all READY/LOCAL-ONLY work via PRs
        ↓
[manual conflict resolution]         → for any CONFLICT branches
        ↓
repo-compass                         → verify final repo truth state
```

---

## Gotchas

- Requires `gh` CLI authenticated (`gh auth login`)
- Never force-pushes — only fast-forward pushes to new remote branches
- Conflict detection uses a dry-run `git merge --no-commit --no-ff` (always aborted cleanly)
- PR titles come from the latest commit subject on the branch — review before merging
- Stale branches (already merged into main) are only deleted with `--prune-stale` + confirmation
