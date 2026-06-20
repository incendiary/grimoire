# codebase-holistic-review

> **Cluster:** 05-technical | **Status:** complete | **Added:** 2026-06-20

Structured, predictive codebase review across 8 phases — architecture mapping, risk
inventory, failure scenario prediction, test coverage gaps, dependency audit, and CI
gap analysis. Produces a findings document and action roadmap written in enough detail
for a lesser-capable agent to execute items independently.

---

## What this skill does

- Guides a top-to-bottom review of a codebase across 8 structured phases
- Predicts failure modes before they occur (not just current bugs)
- Writes findings to `REVIEW.md` (or the repo README)
- Generates an action roadmap with context, success criteria, and file paths per item
- Chains to `roadmap-sync` to extract and dedicate the roadmap if it grows large

---

## When to use it

- "Review this codebase holistically"
- "What issues should I expect as this scales?"
- "Predict where this will break"
- "Do a full code audit before the next major release"
- "What should be fixed before we onboard more developers?"

---

## Installation

### Claude Code

```bash
cp -r clusters/05-technical/codebase-holistic-review ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#codebase-holistic-review
```

### VS Code / MCP

This is an `instructional` skill — loaded as prompt context, not an MCP action tool.

---

## Invocation

**Explicit:**
```
/codebase-holistic-review
Repo: src/
Known pain points: CSV import is slow on large files, auth module has no tests
```

**Natural language:**
```
Do a holistic review of this codebase. Predict what will break. Output a REVIEW.md.
```

---

## Phases

| # | Phase | Output |
|---|---|---|
| 1 | Architecture map | Module table with concerns |
| 2 | Risk inventory | Scored risk table (Security / Scalability / Reliability / Maintainability / Dependency) |
| 3 | Predictive failure analysis | One failure scenario per risk ≥ 3 |
| 4 | Test coverage gaps | Uncovered critical paths with test type needed |
| 5 | Dependency audit | Pinning status, age, CVE summary |
| 6 | CI/CD gap analysis | Missing pipeline steps with YAML snippet fixes |
| 7 | Review document | Full compiled `REVIEW.md` |
| 8 | Embed + roadmap-sync | Roadmap items extracted and optionally moved to dedicated file |

---

## Workflow

```
karpathy-spec             → (optional, large codebases) define "healthy" baseline
        ↓
codebase-holistic-review  → run all 8 phases
        ↓
[REVIEW.md + action roadmap committed]
        ↓
roadmap-sync              → move to dedicated ROADMAP.md if >15 items
        ↓
task-decomposer           → (optional) chunk items for multi-session execution
        ↓
karpathy-verify           → verify review completeness against phase checklist
```

---

## Key design principle: detail for lesser agents

Every action roadmap item must be self-contained:

- **Context:** what the problem is and exactly where
- **Success criteria:** how to know it is done (testable, observable)
- **Files to change:** explicit relative paths
- **Estimated effort:** XS / S / M / L / XL

Items written as "improve X" are not acceptable. Write as if explaining to someone
who has never seen the repo.

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Add worked example: Python web service holistic review (before/after findings)
- [ ] Add worked example: Node.js monorepo review
- [ ] Test on 3 real repos and capture recurring finding patterns
- [ ] Add language-specific risk pattern tables (Python, TypeScript, C#, Go)
