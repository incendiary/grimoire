# branch-surface-resolve

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description

Audits all local and remote branches in a repository, surfaces what each one contains,
and routes it to the correct resolution: open a PR, push first then PR, flag for manual
conflict resolution, or prune as stale.

The goal is a clean repo state: work lands on `main` via squash PRs; nothing is lost in
local-only branches; conflicts are surfaced for deliberate resolution rather than silently
accumulated.

Invoke when:
- "I have branches everywhere and I don't know what's in them"
- "Clean up my branch state and land everything that's ready"
- Pre-release hygiene pass
- Returning to a repo after a break and finding scattered WIP

---

## Context needed
- Repository root (script auto-detects via `git rev-parse --show-toplevel`)
- GitHub remote named `origin` with `gh` CLI authenticated
- Optional: `--resolve` flag to auto-act on READY branches (push + create PR)

---

## Execution chain

```
branch-surface-resolve        → categorise all branches
        ↓
[READY branches]              → push + gh pr create (if --resolve)
[LOCAL-ONLY branches]         → push first, then PR path
[CONFLICT branches]           → surface diff summary for manual decision
[HAS-PR branches]             → show open PR status + merge readiness
[STALE branches]              → list for pruning decision
        ↓
repo-compass                  → verify final repo truth state post-resolution
```

---

## Branch categories

| Category | Condition | Auto-action (--resolve) |
|----------|-----------|------------------------|
| `READY` | ahead of main, no merge conflicts, no open PR | push + create PR |
| `LOCAL-ONLY` | not pushed to remote | push, then treat as READY |
| `HAS-PR` | open PR exists | show PR status + CI state |
| `CONFLICT` | merge conflict with main detected | surface + stop; needs manual |
| `STALE` | zero commits ahead of main | list for deletion decision |

---

## What to do (AI instructions)

When this skill is active, run `branch-surface-resolve.sh` first. Then for each
`CONFLICT` branch in the output:

1. Run `git diff main...<branch> --stat` to understand scope
2. Show which files conflict and their full diff
3. Suggest one of:
   - Cherry-pick individual commits onto a clean branch
   - Rebase interactively to isolate the useful commits
   - Create a new branch with just the specific files changed
4. Do not auto-merge anything with conflicts — present options and wait

For `READY` and `LOCAL-ONLY` branches, use `--resolve` mode unless the user has
said otherwise. Write PR titles and bodies from the branch name + commit log.

---

## Gotchas

- Never `git push --force` to resolve divergence without user confirmation
- Do not squash a branch into main directly — always via PR
- If a branch name has no clear semantic meaning, show commits before acting
- `main` is the canonical target; check for `master` as fallback
- Dry-run merge detection uses `git merge --no-commit --no-ff`; always abort after

---

## Roadmap
- [ ] Add `--dry-run` mode (report only, no push/PR actions)
- [ ] Add `--target <branch>` to use a non-main base
- [ ] Add confidence score per branch (commit count, recency, author)
- [ ] Add PR body template population from commit messages
