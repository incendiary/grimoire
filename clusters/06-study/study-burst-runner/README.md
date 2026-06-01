# study-burst-runner

> **Cluster:** 06-study | **Status:** complete | **Added:** 2026-05-24

Enforces a structured 35-minute study burst format designed around production over
consumption. Intuition before notation. One atomic objective per session. A required
output artefact you write, not Claude. Appends to a study log for tracking coverage.

---

## What this skill does

Takes a specific topic and runs a structured teaching session:

1. States a testable objective up front
2. Teaches in order: intuition → edge cases → worked example → notation → connection
3. Requires a production output from you at the end (write it, explain it, implement it)
4. Time-checks at 30 minutes and reduces scope if needed rather than running over
5. Logs the burst to `~/.claude/study-log.md`

Designed for CAIML postgraduate certificate study and maths reconditioning. Dyslexia-aware
formatting built in: short paragraphs, concrete before abstract, examples before definitions.

---

## When to use it

- You have 35 minutes and a specific topic to cover
- You want to learn something and actually retain it (not just read it)
- You are working through the CAIML syllabus and need structured bursts
- Any time a "study session" risks turning into a long reading session with no output

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/06-study/study-burst-runner ~/.claude/skills/
```

No hook wiring required.

---

## How to invoke it in a session

```
/study-burst-runner
Topic: gradient descent update rule
Baseline: I know calculus basics but have not implemented it before
```

Or:

```
Start a study burst. I have 35 minutes. Topic: the chain rule in backpropagation.
```

---

## Workflow

```
User provides topic (must be specific, not broad)
              ↓
State testable objective: "By the end of this burst, you will be able to [verb] [thing]"
              ↓
Teach in order:
  1. Intuition (what does it do, what does it feel like)
  2. Behaviour at edges (what breaks it, what it assumes)
  3. Worked example (concrete numbers, no abstraction)
  4. Formal notation (introduced last)
  5. Connection (link to something already known)
              ↓
30-minute check: if output not reached, reduce scope
              ↓
Required output: user writes / explains / implements
              ↓
Append to ~/.claude/study-log.md
```

---

## Teaching order rules (non-negotiable)

| Step | Rule |
|------|------|
| Intuition | Always first — never open with a formula |
| Worked example | Always before formal notation |
| Notation | Always after the concept is grounded |
| Output | Always something you produce, not read |

---

## What it will NOT do

- Accept "read and understand" as a valid output
- Open with formal notation before intuition
- Let a burst run past 35 minutes without a scope reduction
- Produce walls of text — paragraph length is limited throughout

---

## Study log format

Appended to `~/.claude/study-log.md` after each burst:

```markdown
## 2026-05-24 — Gradient descent update rule
Output produced: yes
Notes: Derived the update rule from scratch; struggled with learning rate intuition
```

Use this log to track what has been covered and where gaps remain.

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Create `~/.claude/study-log.md` template
- [ ] Add CAIML syllabus topic list so objectives can be matched to modules
- [ ] Add variant for pure maths reconditioning (calculus, linear algebra)
- [ ] Test on 5 real study bursts
- [x] Ship: copy to `~/.claude/skills/study-burst-runner/`
