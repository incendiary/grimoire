# karpathy-spec

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional

## Description
Layer 1 of the Karpathy framework. Transforms vague requests into precise, agile specs
before any work begins. Prevents the most common failure mode: building the wrong thing
precisely. Forces goal clarity, breaks work into verifiable chunks, and defines success
criteria that Layer 2 (karpathy-verify) can test against.

Invoke when: starting any new task; a request feels vague or large; you're not sure what
"done" looks like; previous similar work drifted or missed the mark.

**Don't invoke if**: task is trivial and fully self-defined; you're brainstorming and
not committing to output yet.

## Context needed
- The raw request or goal (as specific or vague as it currently is)
- Any constraints (time, format, tools, audience)
- Relevant prior work or context Claude should know about

## What to do

### Phase 1: Clarify the goal (before anything else)

Ask the clarifying questions that prevent wasted work. Surface the real goal behind
the stated request.

1. **What does success look like?**
   - What is the output? (code, document, decision, design)
   - Who receives it? What do they do with it?
   - What makes this output good vs. merely acceptable?

2. **What are the constraints?**
   - Format, length, tools, tech stack, audience, deadline
   - What must NOT be in the output?
   - What are the non-negotiables?

3. **What is the scope?**
   - Is this the whole task or one part?
   - What's explicitly out of scope?

4. **What context is needed?**
   - What should Claude read or know before starting?
   - Are there examples of similar work that represent the right bar?

Do not proceed until you have answers to at least 1 and 2. The other two can be inferred
if necessary, but surfacing them improves output significantly.

**5. Don't lock in the obvious.** I'm always open to better ways to solve this. Before we commit to this spec, suggest alternatives or approaches that would have longer-lasting impact than the current framing.

---

### Phase 2: Break into agile specs

Decompose the task into discrete, verifiable work items. Each spec item is independently
testable — you can confirm it's done without testing everything else.

**Format**:
```
Spec 1: [TITLE]
  Goal: [What this produces]
  Input: [What it needs]
  Output: [Exact form of the deliverable]
  Done when: [Testable condition]

Spec 2: [TITLE]
  ...
```

**Rules**:
- Each spec item should be completable in a single focused session
- "Done when" must be testable — not "looks good" but "compiles without warnings" or
  "passes all three test cases" or "matches the format in example X"
- If a spec item has more than 3 sub-steps, break it further

---

### Phase 3: Define success criteria

Write the evaluation checklist that Layer 2 (karpathy-verify) will use. Define this
*before* work starts, not after.

**Format** (5–6 criteria):
```
Criterion 1: [ASPECT]
Precise definition: [What must be true]
How to verify: [Test method — specific enough to run]

Criterion 2: [ASPECT]
...
```

**Examples of precise criteria**:
- Vague: "Write clearly" → Precise: "Active voice; max 20 words per sentence; no jargon except [LIST]"
- Vague: "Make it correct" → Precise: "Parses all three sample inputs correctly; output matches reference"
- Vague: "Professional format" → Precise: "Three sections (Problem, Solution, Validation); max 2 pages; Arial 11pt"

**Common dimensions to cover**:
- Correctness (does it do what it claims?)
- Format/structure (right shape and size?)
- Completeness (covers all required scope?)
- Constraints satisfied (no-go items avoided?)
- Usability (does the intended recipient get what they need?)

---

### Phase 4: Confirm and hand off

Review the spec with the user before starting work.

1. Read back the goal in one sentence — confirm it matches intent
2. Show the spec items — any missing? any wrong scope?
3. Show the success criteria — are these the right tests?
4. Get explicit go-ahead before beginning work

If anything is unclear or contested at this stage, resolve it here — not after 2 hours of work.

## Gotchas

- **The goal behind the request is often different from the stated request.** "Make a chart" 
  might mean "help me understand this trend" — ask what the output is *for* before building it.

- **"Done when" conditions that can't be tested are not conditions.** "Looks professional" is
  not testable. "Matches the formatting of the attached example" is.

- **Don't spec-creep.** If the spec grows beyond 5–6 items, the scope is too large. Split into
  two specs with a handoff point in between.

- **Criteria defined after work starts are biased toward the output that exists.** The whole
  point of Phase 3 is that criteria are defined before Claude has seen the "answer". Don't skip it.

- **Agile specs, not waterfall.** Each spec item should deliver standalone value, not just be
  a milestone toward a single final output. If everything depends on everything else, the spec
  is too tightly coupled.

## Completion

When the spec is finalised and work is complete → invoke `karpathy-verify` to evaluate
the output against the success criteria defined in Phase 3.

```
Invoke karpathy-verify on [work product].
Criteria: [paste from Phase 3 above]
```
