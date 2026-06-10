# karpathy-spec

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-11

Layer 1 of the Karpathy framework. Transforms vague requests into precise, agile specs
before any work begins. Defines success criteria upfront so Layer 2 (`karpathy-verify`)
has something concrete to test against. Prevents the most common failure mode: building
the wrong thing precisely.

Based on Karpathy's framework for working effectively with AI systems — the spec layer
forces goal clarity and breaks work into independently verifiable chunks.

---

## What this skill does

1. **Clarifies the real goal** — surfaces the difference between the stated request and
   the actual need before any work starts
2. **Breaks work into agile specs** — discrete, independently testable items each with
   a clear "done when" condition
3. **Defines evaluation criteria** — the checklist Layer 2 will test against; written
   before work begins, not after

---

## When to use it

- Starting any non-trivial task
- A request feels vague or underspecified
- Previous similar work drifted or missed the mark
- You need to define what "done" looks like before committing effort

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/karpathy-spec ~/.claude/skills/
```

---

## Quick reference

```
Invoke karpathy-spec on: [task description]

Or:

I need to [GOAL].
Constraints: [CONSTRAINTS]
Use karpathy-spec to break this into agile specs before we start.
```

---

## Pairs with

- `karpathy-verify` — runs after spec; uses the criteria from Phase 3 to evaluate output
- `karpathy-environment` — captures recurring spec patterns into reusable skills
- `karpathy-framework` — umbrella entry point if unsure which layer to start with

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Ship: copy to `~/.claude/skills/karpathy-spec/`
