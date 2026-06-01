# mid-task-checkin

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-01

Pauses at natural phase boundaries during long tasks and checks whether you've added
new instructions since execution started. One line, then resumes. Prevents a
multi-step task from finishing on stale input when you've been adding to the
conversation mid-flight.

---

## What this skill does

Activates on any task with 3+ planned steps. At each phase boundary — end of
exploration, start of implementation, before a destructive operation, after an
unexpected finding — Claude pauses with a single-line check-in rather than running
straight through to completion on whatever was understood at the start.

---

## When to use it

- You often add context, constraints, or corrections while Claude is mid-task
- The task has 3 or more steps or spans multiple distinct phases
- You've said something like "I'll add more as you go" or typed into the chat
  while a long operation was in progress
- You want Claude to gate on phase boundaries before destructive operations

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/mid-task-checkin ~/.claude/skills/
```

---

## Invocation

Load explicitly at the start of a long session:

```
/mid-task-checkin
```

Or implicitly — Claude recognises when a task plan has 3+ steps and activates
phase-boundary pauses automatically.

---

## What the check-in looks like

At each phase boundary:

> "Pausing here — anything new you've added that I should factor in before continuing?"

That's it. One line. Claude then waits for your response before resuming.

---

## Workflow

```
Task starts → Claude counts planned steps
        ↓
< 3 steps: skill inactive, run to completion
≥ 3 steps: skill active, note phase boundaries
        ↓
Phase 1 completes → check-in → response → Phase 2 starts
        ↓
... repeat at each phase boundary ...
        ↓
Task complete
```

---

## What it won't do

- Check in after every individual step — that would be more disruptive than helpful
- Summarise progress at each pause — one line only
- Re-plan from scratch on a "continue" response — it resumes from exactly where it paused

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Consider a heuristic for detecting user typing mid-task (if tooling permits)
- [ ] Add worked example: long 10-step refactor session with two check-in points shown
