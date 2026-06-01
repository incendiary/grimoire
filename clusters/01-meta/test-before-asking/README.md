# test-before-asking

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-05-24

Enforces a bias toward action and evidence over consultation. When Claude faces a choice
between two approaches, it should try the most likely one and report back — not present
a menu and wait. Extracted after the same consultation pattern appeared twice in a session
where the user had to say "just try it and tell me what happened."

---

## What this skill does

Establishes a standing rule for the session: if a question has a testable answer, test it.
Present decisions with evidence, not as binary choices with no information to guide them.

**Before this skill:**
> "Would you like me to use the existing virtual environment or create a new one?"

**After this skill:**
> "The existing venv was missing scipy. I've installed it and continued."

Carve-outs exist: destructive actions, expensive operations, and genuine preference
questions where there is no objectively better answer still require explicit confirmation.

---

## When to use it

Load this skill for any session where you expect Claude to be making repeated small
decisions — file operations, configuration choices, tool selection, dependency resolution.

It is most valuable in longer sessions where consultation overhead adds up. Not needed
for short one-shot sessions.

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/test-before-asking ~/.claude/skills/
```

No hook wiring required.

---

## How to invoke it in a session

```
/test-before-asking
```

Or just mention it at session start:

```
Load test-before-asking. Try things before asking me to decide.
```

---

## Decision threshold

| Situation | Correct behaviour |
|-----------|------------------|
| "Should I use X or Y?" and both are testable | Test X, report, proceed or narrow |
| Destructive action (rm -rf, force push, wipe) | Always ask first |
| Expensive operation (long CI, API call) | Ask first |
| Genuine preference (naming, style) | Ask — no test resolves this |
| "I'm not sure if this will work" | Try it, report what happened |

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Add concrete examples of ask vs test for common session types
- [ ] Test across 5 sessions to confirm the rule lands correctly
- [x] Ship: copy to `~/.claude/skills/test-before-asking/`
