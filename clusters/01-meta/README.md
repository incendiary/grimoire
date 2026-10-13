# 01-meta — Skill management

Skills about managing the loadout library itself: extracting new skills from sessions,
vetting external skills before installing them, and maintaining scope hygiene in
multi-repo operations.

---

## Skills

### [grimoire-extract](grimoire-extract/) ✅ implemented

Scans a Claude Code session transcript at session end and generates proposed `SKILL.md`
stubs in `~/.claude/proposed-skills/`. Wired to the Claude Code Stop hook. The engine
that feeds this entire library — every promoted skill originated here.
→ [Full documentation](grimoire-extract/README.md)

### [review-skill](review-skill/) ✅ complete

Due diligence checklist before installing any third-party Claude Code skill. Reviews
the repo health, all script files (network calls, env var access, dynamic execution),
and the SKILL.md itself for prompt injection. Outputs a PASS / FLAG / REJECT verdict.
→ [Full documentation](review-skill/README.md)

### [plan](plan/) ✅ complete

Umbrella entry point for the Karpathy three-layer framework. Routes to the right layer
(spec, verify, environment) based on where you are in a task. No content of its own —
use when unsure which Karpathy layer to start with.
→ [Full documentation](plan/README.md)

### [plan-spec](plan-spec/) ✅ complete

Layer 1 of the Karpathy framework. Transforms vague requests into precise, agile specs
before work begins. Defines success criteria upfront so `plan-verify` has something
concrete to test against.
→ [Full documentation](plan-spec/README.md)

### [plan-verify](plan-verify/) ✅ complete

Layer 2 of the Karpathy framework. Evaluates output against defined criteria via second
opinion (different model or role) and external signal (test claims against reality).
Feedback loops improve output quality 2–3× per invocation.
→ [Full documentation](plan-verify/README.md)

### [plan-model-tier](plan-model-tier/) ✅ complete

Cost-benefit framework for choosing LLM model tier (Haiku, Sonnet, Opus) based on task
characteristics—verifiability and blast radius—not just capability. Prevents false savings and
overspending.
→ [Full documentation](plan-model-tier/README.md)

### [roadmap](roadmap/) ✅ complete

Shows roadmap status from `ROADMAP.md` and picks the next implementation-ready item, then
outputs a focused execution chain. Designed for "what should I work on next?", "show roadmap
status" and "pick up from the roadmap" prompts. Chains: `orient` → `plan-decompose` →
`plan` → `plan-verify`.
→ [Full documentation](roadmap/README.md)

### [plan-decompose](plan-decompose/) ✅ complete

Proactively breaks large tasks into self-contained chunks before context limits become an
issue. Each chunk is a task file with everything a fresh session needs to execute independently.
Used at the start of multi-session work to prevent context-window collisions.
→ [Full documentation](plan-decompose/README.md)

---

## When to invoke — workflow guide

### Workflow 1: Starting a new large task

**Trigger:** "Build X" / "Implement Y" / any task that feels multi-step or vague

```
plan        → route to the right layer (usually spec first)
        ↓
plan-spec             → break the vague request into precise agile specs
        ↓
plan-decompose           → (if multi-session) split into independent chunks
        ↓
plan-model-tier → (for each chunk) pick model tier based on verifiability & blast radius
        ↓
[do the work]
        ↓
plan-verify           → evaluate output against spec criteria
        ↓
```

### Workflow 2: Mid-session context pressure

**Trigger:** "Context is getting long" / session feels sluggish / about to hit limits

```
plan-decompose (handoff)  → package state for a fresh session to continue
        ↓
[new session starts from handoff document]
```

### Workflow 3: Session start (any project)

**Trigger:** Opening a new session / "where was I?" / resuming work

Use `orient` (07-devops); its pathway table lists the session-start steps in order.

### Workflow 4: Evaluating existing output

**Trigger:** "Is this good enough?" / reviewing generated code / before accepting AI output

```
plan-verify           → second-opinion evaluation against criteria
        ↓
```

### Workflow 5: Post-session / environment improvement

**Trigger:** End of a productive session / "I keep doing the same thing" / session felt repetitive

```
grimoire-extract   → scan transcript, propose new SKILL.md stubs
        ↓
review-skill              → (if third-party skill) review for safety before installing
        ↓
```

### Workflow 6: Installing or vetting new skills

**Trigger:** "Should I trust this skill?" / found a third-party skill to install

```
review-skill              → repo health, script audit, prompt injection check
        ↓
[PASS / FLAG / REJECT decision]
```

### Workflow 7: Finding the right skill by intent

**Trigger:** "Which skill covers this?" / concept known but skill name forgotten

```
        ↓
[pick top match]          → invoke selected skill directly
```

### Workflow 8: Roadmap-driven chunking

**Trigger:** "Review the roadmap" / "Split the next task for subagents" / "Move README roadmap items into a dedicated file"

```
roadmap                   → select the next implementation-ready roadmap item
        ↓
plan-decompose           → break that item into self-contained chunks with clear done criteria
        ↓
plan-model-tier → (for each chunk) assign model tier based on task characteristics
        ↓
roadmap-sync              → move completed README roadmap items into ROADMAP.md or PROJECT-ROADMAP.md
        ↓
[subagents / fresh sessions] → execute each chunk independently
```

Use this when you want a roadmap item turned into lesser-agent-friendly work
packages. `roadmap` chooses the item, `plan-decompose` writes the chunk files,
and `roadmap-sync` keeps the README roadmap from becoming the long-term source of truth.

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|---------------|
| `plan` | Unsure which layer to start with; onboarding someone to the framework |
| `plan-spec` | Task is vague, large, or multi-step; need to define "done" before starting |
| `plan-verify` | Output exists; need to evaluate quality before accepting; want a second opinion |
| `plan-model-tier` | Choosing model tier for a task; avoiding false savings on high-risk work; assigning models to chunks |
| `plan-decompose` | Task will span multiple sessions; need independent chunks before starting |
| `grimoire-extract` | Session ending; want to extract reusable patterns into proposed skills |
| `review-skill` | Evaluating a third-party skill before installing; need safety/quality check |
