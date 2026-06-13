# task-handoff

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-05

Packages the current session's state into a self-contained handoff document when
context pressure is high mid-task. The fresh session that picks it up needs no
knowledge of the current session's history.

---

## What this skill does

Reactive context management: when the current session is filling up, captures decisions
made, work accomplished, and the next discrete chunk into a single portable document.
The document lives on disk and survives `/compact`, so the parent session can reclaim
context without losing state.

---

## When to use it

- Context window is visibly large and the task isn't finished
- About to start a phase requiring many new file reads
- Natural pause point (PR merged, chunk complete)
- Switching between unrelated areas of the codebase

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/task-handoff ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#task-handoff
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/task-handoff
```

```
/task-handoff
Next chunk: write the ios-signing scripts
Compact after: yes
```

---

## Output

```
.claude/tasks/handoff-YYYY-MM-DD-[slug].md
```

Load in a fresh session:
```
/task-handoff load .claude/tasks/handoff-2026-06-05-ios-scripts.md
```

---

## Roadmap

- [x] SKILL.md written: workflow, format template, load protocol, gotchas
- [x] README.md written
- [x] Ship: copy to `~/.claude/skills/task-handoff/`
- [ ] Add worked example: mid-session handoff from a real grimoire Cat 5 chunk
- [ ] Add `--auto` mode: triggered automatically when context exceeds a threshold
