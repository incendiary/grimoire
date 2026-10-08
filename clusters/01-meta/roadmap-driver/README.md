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

## Chain

`repo-compass` -> `task-decomposer` -> `karpathy-framework` -> `karpathy-verify`

## Output

- Selected next item
- Reason for selection
- Atomic implementation steps
- Verification checklist
- Roadmap update instruction
