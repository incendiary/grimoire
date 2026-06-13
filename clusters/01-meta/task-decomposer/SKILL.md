# task-decomposer

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional

## Description
Decomposes a large task into discrete, self-contained chunks before context pressure
builds. Each chunk is written as a task file containing everything a fresh Claude Code
session needs to execute it cold — objective, background context, files to read,
constraints, success criteria, and return signal.

Invoke **at the start** of any task expected to span multiple Claude Code sessions, or
when handing a multi-step plan to an agent. Prevents context-window collisions
mid-execution rather than reacting after they happen.

## Context needed
- A description of the overall task (paste a plan, a list of steps, or free text)
- Optional: target directory for task files (default: `.claude/tasks/` in current project)
- Optional: max chunk size hint (default: "completable in one focused session")

## Invocation

```
/task-decomposer
Task: [paste overall task description, plan file contents, or bullet list of work]
```

With overrides:
```
/task-decomposer
Task: [description]
Output dir: ~/tasks/grimoire-cat5
Max chunks: 6
```

## Workflow

### Step 1 — Understand the task

Read the full task description. Identify:
- The overall goal (one sentence)
- Natural seams — points where work can be handed off cleanly
- Dependencies between pieces of work (what must land before what)
- Shared context (files, patterns, conventions) all chunks will need

### Step 2 — Draft chunk boundaries

Good chunks are:
- **Completable in one session** — not so large that they hit context limits themselves
- **Independently verifiable** — each has a clear "done" state that can be checked
  without knowing the internals of adjacent chunks
- **Minimal coupling** — a chunk only depends on the *outputs* of prior chunks
  (commits, files written), not on decisions made inside them
- **Concrete** — "write `foo.sh` and add it to the bar skill" not "improve the offsec cluster"

Aim for 3–8 chunks. If you need more, consider a two-level decomposition (phases → chunks).

### Step 3 — Write task files

For each chunk, write a file to the output directory:

**Filename:** `NN-short-name.md` (zero-padded index, e.g. `01-meta-scripts.md`)

**Format:**

```markdown
# Task NN: [title]

> Status: pending
> Parent: [overall task name]
> Chunk: N of M
> Depends on: [chunk N-1 title, or "none"]

## Objective
[One precise sentence: what this chunk accomplishes]

## Background
These decisions are already made — do not re-litigate:
- [key decision 1]
- [pattern to follow]
- [convention in use]

## Context files
Read these before starting:
- `path/to/file` — [what it contains and why it matters for this chunk]
- `VERSION`      — [current value; bump by 0.0.1 per merged PR]

## Steps
1. [specific, actionable step]
2. [specific, actionable step]
3. ...

## Constraints
- [what not to touch]
- [CI requirements that must stay green]
- [style/pattern to match]

## Done when
- [ ] [verifiable outcome — specific file exists, test passes, CI green, etc.]
- [ ] [verifiable outcome]

## Return signal
Commit message: `[conventional commit prefix]: [description]`
Then output exactly: `CHUNK COMPLETE: [one-line summary of what landed]`
```

### Step 4 — Write a run-book

After writing all chunk files, write `00-runbook.md` to the same directory:

```markdown
# Run-book: [overall task name]

Generated: [date]
Total chunks: N

## Execution order
1. `01-name.md` — [one-line description]
2. `02-name.md` — [one-line description] (depends on 01)
...

## Shared context
All chunks assume:
- [shared convention 1]
- [shared convention 2]

## Completion
All chunks done when: [overall success criteria]
```

### Step 5 — Confirm with user

Present the chunk list before writing any files:

```
Decomposed into N chunks:
  01  meta-scripts        — write verify-cwd.sh and verify_version.sh
  02  incident-templates  — write appendix-template.md and incident-ask-template.md
  03  ios-scripts         — write verify-ipa.sh and check-manifest.sh
  ...

Output: .claude/tasks/[task-name]/
Proceed?
```

Only write files once confirmed.

## Task file location conventions

| Context | Default location |
|---------|-----------------|
| Inside a git repo | `.claude/tasks/[task-name]/` |
| No git repo / cross-project | `~/.claude/tasks/[task-name]/` |
| Explicit override | Wherever the user specifies |

Task files are not committed to the project repo by default — they are working documents.
Add `.claude/tasks/` to `.gitignore` if needed.

## What makes a bad chunk

- **Too vague:** "improve the CI pipeline" — not verifiable
- **Too large:** "implement the entire auth system" — will hit context itself
- **Tightly coupled:** chunk 3 assumes knowledge of a decision made inside chunk 2
  rather than just its output — add that decision to chunk 3's Background instead
- **No return signal:** chunks that don't produce a commit or a clear artefact
  make it hard to know if the handoff worked

## Gotchas

- **Write Background liberally.** It feels redundant when writing chunk 1, but chunk 4
  genuinely needs to know what pattern chunk 1 established. Over-document decisions.
- **Verifiable done criteria matter most.** "CI green" and "file exists at path X" are
  verifiable. "Code is clean" is not.
- **The run-book is for the human, not Claude.** It lets you track which chunks are
  done and resume after interruptions without re-reading all the task files.
- **Re-decompose if scope changes.** If a chunk expands unexpectedly mid-session,
  stop, re-run `/task-decomposer` on the remaining work, and update the run-book.

## Related skills

- `task-handoff` — reactive complement: packages current session state mid-task
  when context pressure is already high
- `project-delivery-workflow` — higher-level delivery planning across PRs
- `mid-task-checkin` — periodic check-ins during execution of a single chunk
