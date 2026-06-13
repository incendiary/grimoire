# cwd-verification

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Prevents working-directory mismatches when a project has both a local path and an
iCloud-synced path. Extracted after Claude operated on the wrong project path because
it assumed the local copy when the user was working in the iCloud-synced one.

---

## What this skill does

Enforces a "confirm before you operate" rule for working directory at session start
and before any bulk file operation. Particularly important for projects with two
possible roots: a local path vs the iCloud equivalent.

Also enforces correct quoting of iCloud paths — they contain spaces and will fail
silently without quotes in shell commands.

---

## When to use it

Load this skill for any session involving:
- A project that has both a local copy and an iCloud-synced copy
- Sessions that start with "continue from where we left off" (CWD may not be what Claude expects)
- Any bulk file operation across a project directory

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/cwd-verification ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#cwd-verification
```

### MCP client

This is an `action` type skill — it's available as a callable tool via the grimoire
MCP server after running `bash install-vscode.sh`. Invoked automatically when relevant.


---

## How to invoke it in a session

```
/cwd-verification
Working in: /Users/<user>/<project> (local copy, not iCloud)
```

Or at session start:

```
Load cwd-verification. We're working in the local copy, not iCloud.
```

---

## Known path pairs

| Project | Local | iCloud |
|---------|-------|--------|
| Claude Skills | `~/Claude/Skills/` | `~/Library/Mobile Documents/com~apple~CloudDocs/gits/Claude/Skills/` |

Add your own project path pairs here as you encounter them.

iCloud paths always contain spaces — always quote them in shell commands.

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add all known path pairs as they are encountered
- [x] Add a `verify-cwd.sh` that runs `pwd && ls` and reports which known root is active
- [x] Ship: copy to `~/.claude/skills/cwd-verification/`
