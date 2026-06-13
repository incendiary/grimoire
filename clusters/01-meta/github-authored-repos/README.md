# github-authored-repos

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Prevents fork/clone inclusion in multi-repo operations by enforcing the canonical
authored-repo list. Extracted after forks were incorrectly included in 3 separate operations.

---

## What this skill does

Maintains a canonical list of repos you actually authored (vs forks, upstream clones,
or org repos you contributed to). Uses `list-authored.sh` to query GitHub and filter
by push access + non-fork status. Prevents multi-repo operations (CI setup, secret
scanning, publication prep) from accidentally including third-party repos.

---

## When to use it

- Running any operation across multiple repos (batch CI, batch security, batch publish)
- Before assuming a repo list from `gh repo list` is only your own work
- When a fork or upstream clone is getting included where it shouldn't be

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/github-authored-repos ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#github-authored-repos
```

### MCP client

This is an `action` type skill — it's available as a callable tool via the grimoire
MCP server after running `bash install-vscode.sh`. Invoked automatically when relevant.

---

## Invocation

```
/github-authored-repos
```

Or implicitly when Claude detects a multi-repo operation is about to begin.

---

## Roadmap

- [x] Extracted from archive session (3x — agency-agents, ScallOps misclassified)
- [x] Promoted to `clusters/01-meta/github-authored-repos/`
- [x] Add `list-authored.sh` script
- [x] Add fork-detection one-liner to SKILL.md examples
- [x] Set up process to keep the authored list in sync with CLAUDE.md
- [ ] Test on one multi-repo session (requires real session)
- [ ] Document any new gotchas from real usage (requires real usage)
- [x] Ship: copy to `~/.claude/skills/github-authored-repos/`
