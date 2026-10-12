# plan

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-11

Umbrella entry point for the Karpathy three-layer framework. Routes you to the right
layer (spec, verify, environment) based on where you are in a task. No content of its
own — exists so you don't need to remember which layer to start with.

---

## What this skill does

Provides a routing table and default sequence for the three Karpathy layers:

- **Layer 1 — `plan-spec`**: Define goals precisely before work starts
- **Layer 2 — `plan-verify`**: Evaluate output quality with second opinion + external signal
- **Layer 3 — `plan-environment`**: Build a durable, improving workspace

---

## When to use it

- Starting a session and unsure which layer applies
- Explaining the framework to someone new
- Quick reference for the default spec → verify → environment sequence

---

---

## Quick reference

```
Starting new work         → /plan-spec
Evaluating existing output → /plan-verify
Setting up a workspace    → /plan-environment
Not sure which to use     → /plan
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Ship: copy to `~/.claude/skills/plan/`
