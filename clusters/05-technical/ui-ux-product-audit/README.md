# ui-ux-product-audit

> Production-grade UI/UX audit and implementation workflow.

## Purpose

Turns a broad "make the UI better" ask into a structured product-quality review with
specific, code-level recommendations and immediate high-impact improvements.

## When to invoke

- A UI feels functional but not polished
- Need stakeholder/customer-ready interface quality
- Preparing for launch/demo and want production-grade UX
- Auditing design system consistency and accessibility debt

## What it guarantees

- Product understanding first (user + workflows + critical screens)
- Severity-ranked findings tied to exact files/components
- Prioritized fixes (Top 10, quick wins, accessibility, responsive)
- Concrete implementation plan (`Today`, `This week`, `Later`) with file paths
- Roadmap-ready output snippet
- Direct implementation of highest-impact improvements where requested

## Required chain

`karpathy-spec` -> `ui-ux-product-audit` -> `karpathy-verify`

Use `task-decomposer` if implementation scope is large.

## Output sections

1. Product understanding
2. Findings by severity
3. Top 10 improvements by impact
4. `Today` / `This week` / `Later` checklist with files
5. Roadmap integration snippet
6. Implemented changes summary + verification results

## Related skills

- `karpathy-spec` (01-meta)
- `karpathy-verify` (01-meta)
- `task-decomposer` (01-meta)
- `human-rewrite` (02-comms)
- `tone-check` (02-comms)
