# ui-ux-product-audit

> **Status:** COMPLETE
> **Cluster:** 05-technical
> **Type:** instructional

## Description
Production-grade UI/UX audit and implementation loop for web applications. Reviews code
as a product experience (not just bugs), prioritizes fixes by impact, and requires a
phased plan with exact files: `Today`, `This week`, `Later`.

Invoke when: "audit the UI", "make this app feel polished", "review design system quality",
"improve UX and implement top fixes".

## Context needed
- Project root and primary UI entry points (routes/pages/screens)
- Frontend stack (React/Next/Vue/Svelte, Tailwind/CSS, component library)
- Whether implementation changes should be made immediately after audit

## Karpathy framing (required)

Before starting, apply:
1. `karpathy-spec` — define app goal, user, critical workflows, and success criteria.
2. Audit + improvements (this skill).
3. `karpathy-verify` — validate that implemented changes improved UX quality and did not regress behavior.

If the task is broad, chain with `task-decomposer` before implementation.

## Output contract (required)

Every run must produce:
1. **Product understanding**
: what the app does, likely user, core workflows, critical screens/components.
2. **Findings list** ordered by severity
: each finding includes severity, location, what is wrong, why it matters, recommendation, implementation approach.
3. **Prioritized improvements**
: Top 10 by impact, quick wins (<1h), bigger design-system work, accessibility must-fix, responsive/mobile must-fix, strengths.
4. **Implementation plan with checkboxes** grouped into:
   - `Today`
   - `This week`
   - `Later`
   Each task must include exact files likely to change.
5. **Roadmap integration artifact**
: concise items suitable to paste into `ROADMAP.md` or project plan.

## Review order (strict)

1. Understand the app and workflows.
2. Map UI entry points: routes/pages/layouts/components/forms/nav/modals/tables/state components.
3. Evaluate quality dimensions:
   - visual hierarchy
   - spacing/layout
   - typography
   - color/contrast
   - consistency
   - responsiveness
   - accessibility
   - interaction states
   - forms UX
   - loading/error/empty states
   - copy/microcopy
   - design system quality
   - edge cases
4. Prioritize improvements by user impact.
5. Implement highest-impact changes directly (focused, reusable, no unnecessary dependencies).
6. Run lint/tests/build when possible.
7. Summarize files changed and why.

## Severity model

- **Critical**: blocks core workflow, severe accessibility/compliance issue, broken responsive behavior.
- **High**: significantly harms usability or trust for primary workflows.
- **Medium**: noticeable friction, inconsistency, or unclear behavior.
- **Low**: polish and maintainability issues with limited immediate user impact.

## Guardrails

- Do not rewrite the whole app.
- Preserve existing functionality.
- Prefer reusable component/token improvements over one-off patches.
- Do not add dependencies unless justified by clear quality gains.
- Avoid vague advice; every recommendation must be code-tied and actionable.

## Roadmap output template

Use this template for paste-ready roadmap entries:

```markdown
### UI/UX audit batch (<project-or-module>)
- [ ] Critical: <fix summary> (files: <path1>, <path2>)
- [ ] High: <fix summary> (files: <path1>)
- [ ] High: <fix summary> (files: <path1>, <path2>)
- [ ] Medium: <design system improvement> (files: <path1>, <path2>)
- [ ] Medium: <responsive/accessibility hardening> (files: <path1>)
```

## Verification checklist (karpathy-verify handoff)

- [ ] Top 3 highest-impact issues resolved in code
- [ ] No regressions in tests/build/lint
- [ ] Accessibility checks for modified UI paths (focus, labels, contrast)
- [ ] Mobile/desktop snapshots manually reviewed
- [ ] Plan updated (`Today`/`This week`/`Later`) and roadmap snippet produced

## Roadmap

- [ ] Add worked example: SaaS dashboard audit with 10 prioritized fixes
- [ ] Add stack-specific heuristics (React + Tailwind + component library patterns)
- [ ] Test on 3 real frontend repos and collect recurring anti-patterns
