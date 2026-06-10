# karpathy-framework

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-11

Umbrella entry point for the Karpathy three-layer framework. Routes you to the right
layer (spec, verify, environment) based on where you are in a task. No content of its
own — exists so you don't need to remember which layer to start with.

---

## What this skill does

Provides a routing table and default sequence for the three Karpathy layers:

- **Layer 1 — `karpathy-spec`**: Define goals precisely before work starts
- **Layer 2 — `karpathy-verify`**: Evaluate output quality with second opinion + external signal  
- **Layer 3 — `karpathy-environment`**: Build a durable, improving workspace

---

## When to use it

- Starting a session and unsure which layer applies
- Explaining the framework to someone new
- Quick reference for the default spec → verify → environment sequence

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/karpathy-framework ~/.claude/skills/
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/karpathy-spec ~/.claude/skills/
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/karpathy-verify ~/.claude/skills/
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/karpathy-environment ~/.claude/skills/
```

---

## Quick reference

```
Starting new work         → /karpathy-spec
Evaluating existing output → /karpathy-verify
Setting up a workspace    → /karpathy-environment
Not sure which to use     → /karpathy-framework
```

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Ship: copy to `~/.claude/skills/karpathy-framework/`
