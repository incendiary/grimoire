# study-burst-runner

> **Status:** COMPLETE
> **Cluster:** 06-study

## Description
Enforce the 35-minute study burst format for CAIML and maths reconditioning sessions.
One atomic objective per burst. Intuition-first teaching order. Required output at the end.

Invoke when: the user says "study burst", "start a session", "teach me [topic]",
"I have 35 minutes", or when a study session is about to exceed 35 minutes without
a defined output artefact.

## Context needed
- Topic for this burst: must be specific, not a broad subject area
  ("gradient descent update rule" is a valid topic; "machine learning" is not)
- Current baseline for this topic if known (helps calibrate depth)

## What to do

1. **Establish and state the objective.** One sentence, testable:
   "By the end of this burst, you will be able to [verb] [specific thing]."
   Refuse vague objectives like "understand gradient descent". Ask the user to
   narrow the scope if needed.

2. **Teach in this order — never start with notation:**
   - **Intuition first:** what does this concept do? What problem does it solve?
     What does it feel like geometrically or physically? Use an analogy if useful.
   - **Behaviour at the edges:** what happens when inputs are extreme? What breaks it?
     What does it assume?
   - **Worked example:** concrete numbers, no abstraction. Walk through step by step.
   - **Formal notation:** introduce only after the concept is grounded. "Here is how
     this is written formally" — not "here is the formula, let me explain it."
   - **Connection:** how does this connect to something the user already knows?

3. **State the required output at the start of the burst and produce it at the end.**
   The required output must be something the user writes or produces, not something
   Claude produces. Examples:
   - "Write the gradient descent update rule from memory"
   - "Explain backpropagation to an imaginary junior colleague in three sentences"
   - "Draw the computation graph for this expression"
   - "Implement this in 5 lines of Python without looking at references"
   Do not accept "read and understand" as a valid output. Production, not consumption.

4. **Time check:** if 30 minutes pass without reaching the required output, flag it:
   "We are at 30 minutes and have not reached the output yet. I am going to reduce
   scope — here is what we will focus on to reach the output in the remaining time."
   Reduce scope aggressively rather than letting the burst run over.

5. **Append to the study log** at the end of the burst:
   ```
   echo "## $(date -u +%Y-%m-%d) — <topic>" >> ~/.claude/study-log.md
   echo "Output produced: [yes/no]" >> ~/.claude/study-log.md
   echo "Notes: <one sentence>" >> ~/.claude/study-log.md
   ```

## Gotchas
- The required output must be something the user produces. Comprehension without
  production does not transfer. If the user wants to skip the output, acknowledge
  the request but note that retention will be lower.
- If the user is stuck, reduce scope aggressively. A smaller concept understood
  fully is better than a large concept half-understood.
- Dyslexia-aware formatting: short paragraphs only. No dense walls of text.
  Concrete before abstract. Examples before definitions. Always.
- Never open with notation. Opening with a formula before the intuition is the most
  common reason these sessions produce comprehension without retention.

## Suggested scripts
- `~/.claude/study-log.md` — append-only log of completed bursts, date, topic,
  and whether the required output was produced
