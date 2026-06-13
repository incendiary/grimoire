# task-decomposer

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-05

Decomposes a large multi-session task into discrete, self-contained chunk files before
context pressure builds. Each chunk contains everything a fresh Claude Code session
needs to execute it cold.

---

## What this skill does

Prevents context-window collisions by planning the handoff structure **up front**,
rather than scrambling when the context window is already full. Writes a set of
numbered task files (`.claude/tasks/`) and a run-book, so work can be paused and
resumed cleanly across sessions.

---

## When to use it

- Starting any task that will clearly span more than one Claude Code session
- Before delegating chunks to sub-agents
- When a plan file or delivery roadmap exists and needs to be sliced into executable pieces

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/task-decomposer ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#task-decomposer
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/task-decomposer
Task: [paste plan, description, or bullet list of work]
```

---

## Output

```
.claude/tasks/[task-name]/
├── 00-runbook.md       ← execution order + shared context
├── 01-first-chunk.md
├── 02-second-chunk.md
└── ...
```

---

## Roadmap

- [x] SKILL.md written: decomposition principles, chunk format, run-book format, gotchas
- [x] README.md written
- [x] Ship: copy to `~/.claude/skills/task-decomposer/`
- [ ] Add example: grimoire Cat 5 decomposed into 6 chunks (worked example)
- [ ] Add `--resume` mode: reads existing run-book, skips completed chunks
