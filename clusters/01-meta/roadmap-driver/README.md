# roadmap-driver

> Picks the next roadmap item and scaffolds an execution chain.

## Purpose

Removes decision friction at session start by selecting one implementation-ready
roadmap item and providing a clear action sequence.

## When to invoke

- "What should I work on next?"
- "Pick up from the roadmap"
- Session restart after interruption
- Need one atomic next task instead of broad backlog browsing

## Installation

### Claude Code

```bash
bash install-all.sh  # copies all skills including roadmap-driver
```

### VS Code (Copilot Chat)

After running `bash build.sh`, reference with `#roadmap-driver` in Copilot Chat.

### MCP tool

Registered as `roadmap-driver` in `mcp-server/registry.json`.

---

## Chain

`repo-compass` -> `task-decomposer` -> `karpathy-framework` -> `karpathy-verify`

## Output

- Selected next item
- Reason for selection
- Atomic implementation steps
- Verification checklist
- Roadmap update instruction
