# karpathy-verify

> **Status:** COMPLETE
> **Cluster:** 01-meta

## Description
Layer 2 of the Karpathy framework. Evaluates output against precise criteria by routing
it through a second opinion and grounding claims in external signal. Feedback loops
improve output quality 2–3× per invocation (per Boris Chernsey, Claude Code creator).

Invoke when: output exists and needs quality evaluation before acceptance; specific
factual claims can be tested; previous similar work had errors or drift; before shipping,
publishing, submitting, or deploying anything.

**Don't invoke if**: task is exploratory (brainstorm, rough draft — verify later);
no measurable success criteria exist yet (use karpathy-spec first).

## Context needed
- The output to evaluate (code, document, plan, design)
- Evaluation criteria (from karpathy-spec Phase 3, or define fresh in Phase 1 below)
- Permission to test if verification involves running code or accessing live systems

## What to do

### Phase 1: Define evaluation criteria upfront

Define what "good" looks like *before* evaluating. This is the most important phase.
If criteria came from karpathy-spec Phase 3, paste them here and skip to Phase 2.

1. **List evaluation dimensions** (typically 4–6):
   - Correctness, format, tone, completeness, usability, safety — pick what applies

2. **Make each criterion specific**:
   - Vague: "Write clearly" → Precise: "Active voice; max 20 words per sentence; no jargon except [LIST]"
   - Vague: "Make it correct" → Precise: "Parses three sample inputs; output matches reference hexdump"
   - Vague: "Professional format" → Precise: "Three sections; Arial 11pt; max 2 pages"

3. **For each criterion, define how to verify it** — the test method must be runnable,
   not subjective.

**Format**:
```
Criterion 1: [ASPECT]
Precise definition: [What must be true]
How to verify: [Specific test method]

Criterion 2: ...
```

---

### Phase 2: Second opinion

Route the output to a different evaluator to catch what the first pass missed. Each
evaluator has different blind spots.

**Choose one method**:
- **Method A: Different LLM** — Use Gemini, GPT-4, or Claude Opus to critique the output
- **Method B: Fresh Claude pass** — Same Claude, fresh context window, no memory of original work
- **Method C: Specialist role** — Claude-as-security-auditor, Claude-as-editor, Claude-as-hostile-reviewer

**Run evaluation**:
1. Paste the evaluation criteria from Phase 1
2. Paste the output
3. Ask for specific critique: "For each criterion, does this output pass or fail? Provide evidence."

**Capture results**:
- For each criterion: ✓ (passes) or ✗ (fails) + evidence
- Identify top 3 improvements

---

### Phase 3: External signal

Ground output claims in reality by testing them — not trusting the AI's self-assessment.

**Examples**:
- Code claims to compile → actually compile it; report compiler output
- Report claims facts → spot-check 5 claims against source documents
- System claims deployment succeeded → check live system health, logs, version
- Document matches template → compare against historical examples

**Steps**:
1. List the testable claims in the output
2. For each: define the test (what tool, log, or reference)
3. Execute the test
4. Report pass/fail with evidence — if any fail, stop and report before accepting

---

### Phase 4: Iterate or accept

Tally results and decide.

| Result | Action |
|--------|--------|
| All criteria pass | Accept output; move forward |
| Critical failure (blocks progress) | Iterate — return to Claude with specific feedback from Phase 2 and 3 |
| Non-critical failure (improvement) | Accept or iterate depending on effort cost |

**If iterating**:
- Provide specific feedback from Phases 2 and 3
- State what changed and why
- Re-run Phase 2 and/or Phase 3 after revision (not Phase 1 — criteria don't change)

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Evaluation criteria too vague ("be good") | Run Phase 1 deliberately. Get specific. |
| Second opinion just rephrases the first | Use a genuinely different model or role |
| External signal skipped (trusting AI output) | Don't. Test claims. This is where drift is caught. |
| Iterating endlessly without a decision | Set pass/fail threshold upfront. "Good enough" is valid if critical criteria pass. |
| Criteria defined after seeing the output | Criteria defined post-hoc are biased toward the existing output. Define them first. |

## Completion

When output is accepted → move forward with the work. If this was part of a workspace
setup or you've identified recurring patterns worth capturing, invoke `karpathy-environment`
to formalise them.

```
Invoke karpathy-environment to capture patterns from this task.
```
