# karpathy-framework

> **Status:** COMPLETE
> **Cluster:** 01-meta

## Description
Entry point for the Karpathy three-layer framework — a meta-system for doing better
work with Claude. Routes you to the right layer based on where you are in a task.
Each layer is a standalone skill; this skill exists so you never have to remember
which one to start with.

Invoke when: unsure which Karpathy layer to use; starting a new session and wanting
to apply the framework; onboarding someone to the three-layer approach.

## Context needed
- Where you are in the work: starting fresh, evaluating output, or setting up a workspace

## Routing table

| Layer | Skill | Use when |
|-------|-------|----------|
| 1 — Spec | `karpathy-spec` | Starting new work; task is vague, large, or multi-step; need to define what "done" looks like |
| 2 — Verify | `karpathy-verify` | Output already exists; need to evaluate quality before accepting it |
| 3 — Environment | `karpathy-environment` | Setting up a workspace; sessions feel repetitive or ad hoc; want Claude to operate consistently across sessions |

## Default sequence

For a complete workflow, run the layers in order:

```
karpathy-spec       → define the goal and break it into agile specs
        ↓
[do the work]
        ↓
karpathy-verify     → evaluate output against the criteria spec defined
        ↓
[iterate if needed]
        ↓
karpathy-environment → capture patterns, update CLAUDE.md, formalise reusable skills
```

You don't have to run all three every time. Use whichever layer matches your current need.

## When to skip layers

- **Skip spec** if the task is trivial or already fully defined
- **Skip verify** if the output is exploratory (brainstorm, rough draft) — verify later when it matters
- **Skip environment** if you're in a one-off session with no repeating patterns worth capturing

## Layer summaries

**Layer 1 — karpathy-spec**: Breaks vague requests into precise, agile specs. Defines
success criteria before work starts. Prevents the most common failure mode: building the
wrong thing precisely.

**Layer 2 — karpathy-verify**: Evaluates output against criteria defined in Layer 1.
Routes work through a second opinion (different model, role, or fresh pass) and grounds
claims in external signal (test execution, source checks, live system verification).
Feedback loops improve output quality 2–3× per invocation.

**Layer 3 — karpathy-environment**: Builds the durable workspace that makes Layers 1
and 2 faster over time. Produces CLAUDE.md (session context), a structured knowledge
base, a custom skills roadmap, and guardrails. Compounds — each session setup is faster
than the last.
