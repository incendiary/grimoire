# 05-technical — Platform context and conventions

Skills that enforce low-level coding conventions. These are loader skills — their job
is to establish grounding at session start so it does not need to be re-stated during
the session. Load one of these and the conventions apply for the rest of the session
without repetition.

---

## Skills

### [ci-tests](ci-tests/) ✅ complete

Adds a unit test layer to projects with no tests, or fills coverage gaps in partially
tested projects. Detects language/framework, scaffolds failing tests first (red-first),
implements assertions, and wires test execution into CI.
→ [Full documentation](ci-tests/README.md)

### [review-ui](review-ui/) ✅ complete

Production-grade UI/UX audit and implementation loop for frontend applications.
Evaluates product experience from code (hierarchy, consistency, responsiveness,
accessibility, states, design system quality), ranks findings by severity, and requires
an actionable implementation plan grouped into Today / This week / Later with exact files.
Chains with `plan-spec` and `plan-verify`.
→ [Full documentation](review-ui/README.md)

### [review-codebase](review-codebase/) ✅ complete

Structured, predictive review across 8 phases: architecture map, risk inventory,
failure prediction, test coverage gaps, dependency audit, CI/CD gap analysis, findings
document, and action roadmap. Produces a `REVIEW.md` with action items written in
enough detail for a lesser-capable agent to execute them independently. Chains to
`roadmap-sync` to extract items to a dedicated file.
→ [Full documentation](review-codebase/README.md)

---

## When to invoke — workflow guide

### Workflow 1: Test layer bootstrap

**Trigger:** "This project has no tests" / "Add coverage for this module"

```
ci-tests             → detect framework, scaffold failing tests, implement assertions
 ↓
[run tests]                → confirm red-first then green
 ↓
ci-python / ci-dotnet / workflow update
       → ensure CI enforces test execution
```

### Workflow 2: Holistic codebase review

**Trigger:** "Review this codebase" / "What will break as this scales?" / "Audit before a release"

```
plan-spec             → (large repos) define what "healthy" looks like first
        ↓
review-codebase  → 8-phase review: architecture, risks, failures, tests, deps, CI
        ↓
[REVIEW.md + action roadmap committed]
        ↓
roadmap-sync              → move items to ROADMAP.md if >15 items
        ↓
plan-decompose           → (optional) chunk items for multi-session execution
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `ci-tests` | Repo lacks tests or a changed module/class needs baseline coverage and CI wiring |
| `review-codebase` | Auditing a codebase holistically; predicting future failure modes; producing a detailed action roadmap before scaling or releasing |

---

## Adding project-specific context skills

Platform context skills (grounding a specific project's architecture, paths, and
conventions) are inherently personal. The pattern is: create a skill folder with
a `SKILL.md` that pre-loads your platform's key facts, then load it at the start of
any relevant session. See any existing skill in this cluster for the template.
