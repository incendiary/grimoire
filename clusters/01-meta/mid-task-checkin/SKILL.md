# mid-task-checkin

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional

## Description
Pause at natural phase boundaries during long tasks and check whether the user has
added new instructions or context since execution started. Prevents finishing a
multi-step task on stale input when the user has been adding to the conversation
mid-flight.

Invoke when: a task has 3 or more planned steps, spans multiple phases, or the user
has signalled they will be adding more context as the session progresses.

## Context needed
- The current task plan and which phase is about to start
- Whether the user has been visibly active in the conversation window

## What to do

1. **At the start of any multi-step task, count the planned steps.** If there are
   3 or more, this skill is active for the session. Note the natural phase boundaries
   in the plan — these are the check-in gates.

   A phase boundary is a logical seam in the work:
   - End of exploration / start of implementation
   - End of one cluster of files / start of another
   - End of build / start of test
   - Any point where a wrong decision now would require significant rework

2. **Use the decision table to determine whether to pause:**

   | Situation | Action |
   |-----------|--------|
   | End of a named phase, task continues | ✅ Pause and check in |
   | About to perform a destructive or irreversible operation | ✅ Pause and check in |
   | Unexpected discovery that changes scope or raises a question | ✅ Pause and check in |
   | ~5 sequential steps completed on an open-ended task | ✅ Pause and check in |
   | Between individual small steps within a single phase | ❌ Continue — do not interrupt |
   | Mid-operation (compile, test run, sequential file writes) | ❌ Continue — do not interrupt |
   | Task has fewer than 3 steps and scope is clearly bounded | ❌ Skip — not needed |

3. **Deliver the check-in as a single line, then stop.** Do not summarise progress
   at length or ask multiple questions. The user knows what you have been doing.

   Exact phrasing:
   > "Pausing here — anything new you've added that I should factor in before continuing?"

   Variations for specific contexts:
   - Before a destructive op: "About to [action] — anything to add before I proceed?"
   - After an unexpected finding: "Found [X] which changes [Y] — any input before I adjust?"

4. **Handle the response and continue:**

   | Response | Action |
   |----------|--------|
   | No response, "no", "continue", "carry on" | Resume immediately from where you paused |
   | New instructions or context | Acknowledge, state how the plan adjusts, then continue |
   | "Wait" or substantial new direction | Stop, re-read all new input, re-state the revised plan, confirm before resuming |
   | "Start over" or contradicts completed work | Flag the conflict explicitly before acting |

## Gotchas
- Do not check in after every step — that defeats the purpose and is more disruptive
  than the problem it solves. One check per phase boundary, maximum.
- Do not pad the check-in with a progress summary. The user can scroll up. One
  sentence, then wait.
- If the user typed something that you can already see in the conversation, you have
  already received it — do not check in to ask about it, just incorporate it.
- The check-in is a pause, not a handover. If the user says "continue", resume
  immediately without re-planning or re-summarising.
- On very short tasks (1–2 steps), skip the skill entirely. Adding a pause to a
  30-second task is worse than missing a mid-task addition.

## Suggested scripts
- None — this skill is a behavioural convention, not a script
