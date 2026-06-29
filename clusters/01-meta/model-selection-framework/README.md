# model-selection-framework

Cost-benefit framework for choosing LLM model tier (Haiku, Sonnet, Opus) based on task characteristics, not just capability.

## Quick Start

**Ask these 5 questions:**

1. Can a machine prove it's done right? (test suite, types, lint)
2. Can it be "wrong but green"? (subtle correctness, test quality)
3. Is it destructive or wide? (breaks things, changes contracts)
4. Is the spec exact or ambiguous?
5. What does a mistake cost to catch?

**Then use the matrix:**

| Verifiability | Blast Radius | Model |
|---|---|---|
| High | Small | Haiku ✅ |
| High | Large | Sonnet ⚠️ |
| Low | Small | Sonnet ✅ |
| Low | Large | Opus ❌ required |

## Examples

### Example 1: Add a new utility function (Haiku is fine)

**Task:** Add `sanitize_filename()` to `utils/strings.py` with tests.

**Analysis:**
- Verifiability: High (tests must pass, coverage % measurable)
- Blast radius: Small (new file, no breaking changes)
- Matrix → Haiku ✅

**Cost calculation:**
- Run: $0.10 (Haiku)
- Risk: Low (new code, easy to review, test-gated)
- False saving: Negligible

### Example 2: Migrate tests between modules (Sonnet recommended)

**Task:** Move 50 tests from `old_module.py` to `new_module.py`, update imports.

**Analysis:**
- Verifiability: Medium (tests pass, but test *quality* isn't gate-checked)
- Blast radius: Medium (many files touched, but additive)
- Risk of "wrong but green": Medium (tests could be accidentally weakened)
- Matrix → Sonnet ✅

**Cost calculation:**
- Run: $0.50 (Sonnet) vs $0.15 (Haiku)
- Risk: Haiku might silently weaken assertions
- Real cost: $0.35 extra, avoid ~30 min forensic audit
- Worth it ✅

### Example 3: Breaking refactor consolidating 4 modules into 1 (Opus required)

**Task:** Consolidate `auth/token.py`, `auth/session.py`, `auth/permission.py`, `auth/cache.py` into single `auth/core.py` with new public interface. Migrate 200+ tests.

**Analysis:**
- Verifiability: Low (no gate checks if assertions were weakened, no type-checker for semantic correctness)
- Blast radius: Large (breaks all downstream imports, deletes 4 modules, changes public contracts)
- Matrix → Opus ❌ required

**Cost calculation:**
- Run: $2.50 (Opus) vs $0.15 (Haiku) = $2.35 extra
- Risk of Haiku: Very high. Could ship with silently-weakened tests or missing assertions. Cost to catch: ~4 hours forensic audit + hotfix. Cost if missed: production bug.
- Real cost: $2.35 extra prevents $500+ of rework
- Worth it ✅✅

### Example 4: Document a feature (Sonnet, not Opus)

**Task:** Write `docs/features/webhook-retries.md` explaining the retry logic.

**Analysis:**
- Verifiability: Low (no gate; doc accuracy is subjective)
- Blast radius: Small (docs only, easy to fix)
- Matrix → Sonnet ✅

**Cost calculation:**
- Run: $0.30 (Sonnet) vs $0.75 (Opus)
- Risk: Medium (weak model might get details wrong), but blast radius is small
- This is exactly where you escalate on failure: try Sonnet, if the review finds major errors, re-run with Opus
- Worth it ✅

## The Decision Tool

Use `model-select.sh` to walk through the framework interactively:

```bash
bash model-select.sh
```

It will:
1. Ask the 5 decision questions
2. Plot your task on the verifiability/blast-radius matrix
3. Recommend a model tier
4. Explain the cost-benefit

### Running interactively

```bash
$ bash model-select.sh

=== Model Selection Framework ===

Task description: Add a new utility function to handle file uploads
Specification detail: exact (I have line numbers and a test suite)

Question 1: Can a machine prove it's done right?
- Test suite?   [y/n] y
- Type checker? [y/n] n
- Linter/compiler? [y/n] y
Score: HIGH verifiability ✅

Question 2: Can it be "wrong but green"?
- Risk of subtle correctness issues? [y/n] n
- Risk of test weakening? [y/n] n
Score: LOW risk ✅

Question 3: Blast radius?
- Additive change (new code)? [y/n] y
- Single file or tightly scoped? [y/n] y
- Breaking changes? [y/n] n
Score: SMALL blast radius ✅

=== RECOMMENDATION ===
Matrix position: HIGH verifiability + SMALL blast radius
→ Haiku is appropriate ✅
Cost: ~$0.10, risk is low (gate-protected)
```

## When to Escalate

Even if your analysis suggests Haiku:

1. **Task fails the gate twice** (tests don't pass) → escalate to Sonnet
2. **Diff looks subtly wrong** (assertions weakened, logic seems off) → escalate to Sonnet
3. **You find "wrong but green"** (gate passes, but review reveals the bug) → that was the one that needed Opus; learn for next time

## Integration with other skills

- **task-decomposer:** When breaking a large task into chunks, use this framework to recommend model tier for each chunk
- **roadmap-driver:** When assigning work from the roadmap, select model tier based on task characteristics
- **karpathy-framework:** Use this to decide which model should run the spec/verification phases

## References

- [SKILL.md](SKILL.md) — Full framework with theory and examples
- `model-select.sh` — Interactive decision tool
