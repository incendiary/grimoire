# 05-technical — Platform context and conventions

Skills that enforce low-level coding conventions. These are loader skills — their job
is to establish grounding at session start so it does not need to be re-stated during
the session. Load one of these and the conventions apply for the rest of the session
without repetition.

---

## Skills

### [pe-binary-analysis](pe-binary-analysis/) ✅ complete

Enforces manual PE structure parsing conventions: no WinAPI abstractions, no library
wrappers, direct struct access only. Covers `ImageNtHeader`, `ImageRvaToVa`,
and `ImageDirectoryEntryToData` replacements; RVA vs file offset annotation rules;
x86/x64 Magic field checks; and syscall hook detection patterns. Load at the start of
any PE parsing or binary introspection session.
→ [Full documentation](pe-binary-analysis/README.md)

### [test-bootstrap](test-bootstrap/) ✅ complete

Adds a unit test layer to projects with no tests, or fills coverage gaps in partially
tested projects. Detects language/framework, scaffolds failing tests first (red-first),
implements assertions, and wires test execution into CI.
→ [Full documentation](test-bootstrap/README.md)

### [ui-ux-product-audit](ui-ux-product-audit/) ✅ complete
Production-grade UI/UX audit and implementation loop for frontend applications.
Evaluates product experience from code (hierarchy, consistency, responsiveness,
accessibility, states, design system quality), ranks findings by severity, and requires
an actionable implementation plan grouped into Today / This week / Later with exact files.
Chains with `karpathy-spec` and `karpathy-verify`.
→ [Full documentation](ui-ux-product-audit/README.md)

### [python-black-ruff-authoring](python-black-ruff-authoring/) ✅ complete

Authoring guardrails for Python code that should pass Black and Ruff with minimal
rework. Focuses on writing-time patterns (formatter-stable structure, clean imports,
scoped suppressions) so code is lint/format-compatible by default before pre-commit
checks run.
→ [Full documentation](python-black-ruff-authoring/README.md)

---

## When to invoke — workflow guide

### Workflow 1: PE parsing and binary introspection

**Trigger:** "Parse this PE manually" / "Walk import table without helper APIs"

```
pe-binary-analysis         → enforce PE parsing and RVA/file-offset conventions
 ↓
[implement/verify parser]  → direct struct access + annotation discipline
 ↓
karpathy-verify            → validate correctness and edge-case handling
```

### Workflow 2: Test layer bootstrap

**Trigger:** "This project has no tests" / "Add coverage for this module"

```
test-bootstrap             → detect framework, scaffold failing tests, implement assertions
 ↓
[run tests]                → confirm red-first then green
 ↓
python-ci-template / dotnet-ci-template / workflow update
       → ensure CI enforces test execution
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `pe-binary-analysis` | Working on PE internals, imports/exports, RVA math, or syscall hook checks |
| `test-bootstrap` | Repo lacks tests or a changed module/class needs baseline coverage and CI wiring |
| `python-black-ruff-authoring` | Writing/refactoring Python code in repos that use black/ruff and you want fewer lint-fix follow-up commits |

---

## Adding project-specific context skills

Platform context skills (grounding a specific project's architecture, paths, and
conventions) are inherently personal. The pattern is: create a skill folder with
a `SKILL.md` that pre-loads your platform's key facts, then load it at the start of
any relevant session. See any existing skill in this cluster for the template.
