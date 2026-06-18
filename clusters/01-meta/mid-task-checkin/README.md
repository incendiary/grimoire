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

### Claude Code

```bash
cp -r clusters/01-meta/mid-task-checkin ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#mid-task-checkin
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


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

## Worked example — 10-step refactor session with two check-in points

**Task:** "Refactor the comms cluster READMEs: add worked examples, style rule references,
and tone-check annotations. Update CHANGELOG. Cut a release."

**Plan (10 steps):**
```
Step 1  — Read all three comms cluster READMEs, map what's missing
Step 2  — Add worked examples to executive-translate README
Step 3  — Add before/after pairs to human-rewrite README
Step 4  — Add tone-check annotated examples to tone-check README
Step 5  — Verify all three render correctly (links, headings, code blocks)
──── CHECK-IN POINT 1: end of content phase, start of release prep ────
Step 6  — Bump VERSION to next patch
Step 7  — Update CHANGELOG with what was added
Step 8  — Pre-commit run, stage, commit
Step 9  — Push branch and open PR
──── CHECK-IN POINT 2: before squash merge (irreversible shared state) ────
Step 10 — Merge, tag, push tag, wait for release workflow
```

**Check-in 1 — end of content, before release prep:**

> "Pausing here — anything new you've added that I should factor in before continuing?"

User: "Also tick the roadmap items in each README as you go."

Claude: "Understood — roadmap items ticked in each file as I added content.
Continuing to VERSION bump and CHANGELOG."

*Without the check-in, the roadmap ticks would have been missed and required a
follow-up commit.*

**Check-in 2 — before squash merge:**

> "About to merge PR #68 — anything to add before I proceed?"

User: "No, go ahead."

Claude: Merges, tags v1.6.7, pushes tag.

**What the skill prevented:**
- Running through all 10 steps on the original brief, then needing a fixup commit
  for the missing roadmap ticks
- Merging before the user had a chance to add any late context

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Consider a heuristic for detecting user typing mid-task (if tooling permits)
- [x] Add worked example: long 10-step refactor session with two check-in points shown
