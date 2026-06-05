# task-handoff

> **Status:** COMPLETE
> **Cluster:** 01-meta

## Description
Packages the current session's state into a self-contained handoff document when
context pressure is already high. The handoff contains everything a fresh Claude Code
session needs to pick up the next discrete chunk of work — objective, decisions made,
files to read, constraints, success criteria, and return signal — without replaying
the current session's history.

Invoke **reactively**, when context is filling up mid-task. For proactive decomposition
before context pressure hits, use `task-decomposer` instead.

## Context needed
- The current session state (Claude reads this from the conversation and git)
- Optional: name the next chunk explicitly (otherwise Claude infers it)
- Optional: output path for the handoff file

## Invocation

```
/task-handoff
```

Or with a named next chunk:
```
/task-handoff
Next chunk: write the ios-signing scripts
```

Or to compact the current session after writing the handoff:
```
/task-handoff
Compact after: yes
```

## Signals that it's time to use this skill

- Context window visibly large (conversation is long, responses are slowing)
- About to start a phase that needs a lot of reading (many new files to load)
- A natural pause point: PR just merged, a chunk just completed
- Switching from one area of the codebase to a completely different one
- Claude is starting to lose track of earlier decisions or repeating questions

## Workflow

### Step 1 — Capture current git state

```bash
git status
git log --oneline -10
git branch
```

Record:
- Current branch
- Last commit (hash + message)
- Any uncommitted changes (files modified, staged)
- Whether the branch is ahead of main and by how many commits

### Step 2 — Summarise what this session accomplished

From the conversation history, extract:
- Work completed (commits landed, files written, PRs merged)
- Decisions made that the next session must know about
- Anything tried and rejected (so the next session doesn't retry it)
- Current VERSION / release state if relevant

Be concise — this is a summary, not a transcript.

### Step 3 — Identify the next chunk

Either use the name provided by the user, or infer from the outstanding work:
- What's the next discrete unit of work?
- What files does it touch?
- What's the verifiable done state?

If the next chunk is ambiguous or there are multiple options, ask the user to pick one
before writing the handoff.

### Step 4 — Write the handoff document

Write to `.claude/tasks/handoff-[date]-[slug].md` (or path specified by user).

**Format:**

```markdown
# Handoff: [next chunk title]

Generated: [ISO date]
Session context: [brief description of the parent task]

## Current state
- Branch: [branch name]
- Last commit: [hash] — [message]
- Uncommitted changes: [list, or "none"]
- VERSION: [current value]

## What was accomplished this session
- [achievement 1 — commit hash if applicable]
- [achievement 2]
- [decision made: description]

## Do not re-do or re-litigate
- [thing tried and rejected, and why]
- [decision that is final]

## Your job
[One precise sentence: what to accomplish in the next session]

## Context files — read these first
- `path/to/file` — [what it contains and why it matters]
- `path/to/README.md` — [specific section to check]

## Steps
1. [specific, actionable step]
2. [specific, actionable step]

## Constraints
- [what not to touch]
- [patterns to follow]
- [CI requirements]

## Done when
- [ ] [verifiable outcome]
- [ ] CI green on main

## Return signal
Commit message: `[prefix]: [description]`
Then output: `HANDOFF COMPLETE: [one-line summary]`

## Resuming the parent task
After this chunk is done:
[instructions for what to do next — either the next handoff or a specific action]
```

### Step 5 — Confirm and optionally compact

Show the user the handoff document path and a one-line summary of what was packaged.

If `Compact after: yes` was specified (or if you judge it appropriate):
- Remind the user to run `/compact` to reclaim context
- The handoff file persists on disk and survives compaction

```
Handoff written: .claude/tasks/handoff-2026-06-05-ios-scripts.md

Next chunk: write verify-ipa.sh and check-manifest.sh for ios-signing-risk
Start fresh session with: /task-handoff load (or just paste the file contents)

Run /compact now to reclaim context? (y/n)
```

## Loading a handoff in a fresh session

In the new session, either:

**Option A — Paste directly:**
```
[paste the contents of the handoff file]
```

**Option B — Reference the file:**
```
Read .claude/tasks/handoff-2026-06-05-ios-scripts.md and execute the task.
```

**Option C — Use the load shortcut:**
```
/task-handoff load .claude/tasks/handoff-2026-06-05-ios-scripts.md
```

When loading, Claude should:
1. Read and acknowledge the current state section
2. Read all listed context files
3. Confirm the objective before starting
4. Execute the steps, checking off done criteria as they complete
5. Output the return signal when finished

## What a good handoff contains vs what to leave out

| Include | Leave out |
|---------|-----------|
| Decisions made (final) | Reasoning that led to them |
| Files touched and why | Full file contents |
| What was tried and failed | Full error logs |
| The next chunk's steps | Every possible edge case |
| Verifiable done criteria | Vague aspirations |

A handoff should be readable in under 2 minutes. If it's longer, trim it.

## Gotchas

- **Don't try to capture everything.** The fresh session can read files. The handoff
  exists to carry *decisions and state*, not to duplicate the codebase.
- **"Do not re-litigate" is the most important section.** Without it, the fresh session
  will relitigate decisions and likely reach different conclusions.
- **Return signal matters.** Without a clear signal, the parent task can't tell if the
  child chunk completed correctly.
- **One chunk per handoff.** Don't bundle multiple chunks into one handoff — the fresh
  session will likely hit context limits too.
- **Compact timing.** Compact the parent session *after* the handoff file is written
  and confirmed, not before.

## Related skills

- `task-decomposer` — proactive complement: decomposes work before context pressure hits
- `mid-task-checkin` — periodic check-ins during a single chunk's execution
- `project-delivery-workflow` — delivery planning at the PR / release level
