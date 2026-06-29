# model-selection-framework

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional

## Description
Framework for selecting the appropriate LLM model tier (Haiku, Sonnet, Opus) for a task based on cost-benefit analysis, not just capability. Helps agents and humans avoid the false saving of using cheaper models on high-risk tasks, and avoid overspending on low-risk tasks.

Invoke when: "which model should I use for this task?", "should I use Haiku or Opus?", "is this task safe for a weak model?", choosing a model tier before delegating work.

## Context needed
- Task description or specification
- Understanding of what "done" looks like (success criteria)
- Knowledge of the blast radius if something goes wrong

---

## The Real Cost Equation

The price of a task is not the run cost alone. It's:

```
total cost = run cost + P(rework) × (cost to detect error + cost to fix it)
```

A cheap model only wins when `P(rework) × blast radius` is small.

When it's large, you pay **twice**:
1. Cost of the weak run
2. Cost of a strong model to untangle it
3. Your own review time (or missing bugs in production)

This is the **false saving** — apparent economy that creates hidden tax.

---

## The Two Variables That Decide It

### 1. Verifiability of "done" — can correctness be checked cheaply?

**This is the big one.** If there's a strong, deterministic gate (test suite, type checker, linter, compiler), then a weak model is *safe* even when wrong — because wrong is **visible and cheap**. The gate catches it, the model retries. You've outsourced judgment to the gate.

**The danger:** "wrong but green" — where a weak model produces something that passes the gate but is subtly incorrect.
- Example: migrate tests without weakening assertions. A weak model can make tests pass by *quietly loosening them*. Now the gate is green and the bug is invisible.
- When you can't gate-check correctness (test quality, documentation accuracy, algorithm subtlety, assertion strength), you need model strength as the safety net, because nothing else catches it.

**Ask:** Can a machine prove it's done right (tests, types, lint, compiler)?
- Yes → lean cheaper
- No → go stronger; the model *is* the gate

### 2. Blast radius — how expensive is a mistake to find and undo?

| Radius | Example | Cost to fix |
|--------|---------|------------|
| **Small** | Add a single function, fix a typo, improve a comment | Low — additive, isolated, easy to review |
| **Medium** | Add tests, document a feature, refactor within one file | Medium — changes are localized, easy to verify |
| **Large** | Delete/move code, touch many files, change public contracts, breaking refactor | High — changes ripple, dependencies break, reverting is risky |

**Ask:** Is the task destructive or wide?
- Additive, isolated → cheap model fine
- Deletes, moves, changes contracts → strong model

---

## Decision Checklist

Ask these in order. The first "yes" you hit often decides it.

1. **Can a machine prove it's done right?** (test suite, types, lint, compiler)
   - Yes → lean cheaper. The gate protects you.
   - No → proceed to next question.

2. **Can it be "wrong but green"?** (subtle correctness, doc facts, test quality, loosened assertions)
   - Yes → go stronger. The model *is* the gate.
   - No → proceed to next question.

3. **Is it destructive or wide?** (deletes, moves, changes contracts, irreversible)
   - Yes → stronger model.
   - No → proceed to next question.

4. **Is the spec exact or ambiguous?** (line numbers vs. "improve performance")
   - Exact, mechanical → cheaper model is safe.
   - Ambiguous, judgment-heavy → stronger model.

5. **What does a mistake cost to catch?** (time to review, risk if missed)
   - Cheap to catch (tests fail, obvious in diff) → cheap model.
   - Expensive/silent (needs forensic audit, breaks in production) → strong model.

---

## Task Matrix: Verifiability vs. Blast Radius

| | **High verifiability** (gate-checkable) | **Low verifiability** (model is the gate) |
|---|---|---|
| **Small blast radius** (additive, isolated) | ✅ **Haiku safe** — gate catches errors, fix is cheap | ✅ **Sonnet** — low risk, model strength overkill but acceptable |
| **Large blast radius** (destructive, wide, breaking) | ⚠️ **Sonnet** — gate helps, but breaking changes need strong judgment | ❌ **Opus required** — no safety net; model strength is the only protection |

**Worst quadrant:** low verifiability + large blast radius. Example: breaking refactor with "wrong but green" risk. This is where going cheap is almost always a false saving.

---

## How to Safely Use Cheaper Models

You don't have to just pick one tier — you can change the economics.

### Strategy 1: Strengthen the gate first, then let the cheap model run

1. **You (or a strong model) write the test harness / success criteria** — make "done" deterministic and checkable.
2. **Cheap model makes it pass.** Now wrong is *visible* — the gate catches it, the model retries.
3. This converts a "judgment" task into a "verifiable" task — now Haiku is safe because the gate is strong.

Example: WP2 (Haiku). The spec included explicit success criteria and "this test must fail on old code." That made the task gate-checkable. Haiku did the mechanical routing change correctly because wrong would have been visible.

### Strategy 2: Escalate on failure, don't pre-pay

1. **Run cheap.** Haiku tackles the task.
2. **If it fails the gate twice or the diff looks wrong on review, escalate that one task to a stronger model.**
3. You only pay for strength where it's actually needed.

This is "pay-per-risk" instead of "pre-buying insurance."

---

## Real Examples: Cost-Benefit in Practice

### WP2 (Haiku) — Correct, but one test missing

**Task:** Route output_dir parameter through export functions (mechanical, well-specified).

**Verdict:** Haiku is right.
- **Verifiability:** High — specific line numbers, specific function names, tests either pass or fail.
- **Blast radius:** Small — single feature, additive change, easy to revert.
- **Result:** Code fix is correct. One test missing (diarisation mock setup is awkward for weak model). Real cost: ~10 min cleanup.

**Lesson:** The cheap run *worked* — it just needs ~10 min cleanup. The false saving was ~$2 saved on the run, cost of ~10 min manual verification. That's still a win if you accept the verification tax.

### WP1 (Opus) — Breaking refactor, all tests migrated correctly

**Task:** Consolidate 4 modules into 1, migrate 200+ tests, change public interface.

**Verdict:** Opus necessary.
- **Verifiability:** Low — "assertions intact" can't be gate-checked programmatically; only human inspection catches if tests were weakened.
- **Blast radius:** Large — breaking change, deletes module dirs, all downstream code must adapt.
- **Result:** All tests migrated intact, no assertions weakened, interface correct. Self-report was honest about rough edges.

**Lesson:** This is the "wrong but green" danger zone. A cheap model could've made tests pass by loosening assertions silently. Opus got it right *and* didn't lie about rough edges. The run cost matters less than the risk of shipping broken code.

---

## Anti-Pattern: Claiming "All Criteria Met" When Tests Are Toothless

Watch for this in model outputs:

> "All 5 tests pass. RA-2.3 integration guard includes assertions for leaked sidecars."

Sounds done. But if those assertions are *vacuous* (the sidecars are never created in the test run), the gate is green but toothless — and a weak model won't tell you it skipped the hard part.

**Cheaper models tend to:**
- Claim clean success even when they took shortcuts
- Skip setup that's awkward (mocking libraries, enabling feature flags)
- Write tests that are structurally correct but semantically hollow

**Stronger models tend to:**
- Flag pre-existing failures
- Distinguish what they actually tested from what the spec asked for
- Self-report honestly about rough edges

This honesty gap itself is a quality signal worth paying for on high-risk tasks.

---

## Summary: When to Use Each Tier

| Model | Best for | Avoid for |
|-------|----------|-----------|
| **Haiku** | Mechanical, well-specified tasks with strong gates; additive changes; low blast radius. Acceptable false savings: ~10 min cleanup for $2-3 saved. | Breaking changes, subtly-correct code, tasks where "wrong but green" is possible. |
| **Sonnet** | Most general-purpose work. Tasks where verifiability is medium or blast radius is medium. Good balance of speed and safety. | Lowest-cost tier for high-risk work, but can be the "sweet spot" for many tasks. |
| **Opus** | High-risk: breaking refactors, low verifiability, large blast radius, subtle correctness requirements. Tasks where a weak model would create a false saving tax you can't absorb. | Low-risk, mechanical tasks (waste of money). |

---

## Roadmap

- [ ] Build interactive decision tree (`model-select.sh`) that walks an agent through the checklist
- [ ] Add per-language examples (Python, TypeScript, Go, Rust)
- [ ] Integrate with `task-decomposer` so agents self-select their tier when planning work
- [ ] Gather cost data from real work to validate the framework
