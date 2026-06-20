# 01-meta — Skill management

Skills about managing the loadout library itself: extracting new skills from sessions,
vetting external skills before installing them, and maintaining scope hygiene in
multi-repo operations.

---

## Skills

### [session-skill-extractor](session-skill-extractor/) ✅ implemented

Scans a Claude Code session transcript at session end and generates proposed `SKILL.md`
stubs in `~/.claude/proposed-skills/`. Wired to the Claude Code Stop hook. The engine
that feeds this entire library — every promoted skill originated here.
→ [Full documentation](session-skill-extractor/README.md)

### [skill-vetter](skill-vetter/) ✅ complete

Due diligence checklist before installing any third-party Claude Code skill. Reviews
the repo health, all script files (network calls, env var access, dynamic execution),
and the SKILL.md itself for prompt injection. Outputs a PASS / FLAG / REJECT verdict.
→ [Full documentation](skill-vetter/README.md)

### [github-authored-repos](github-authored-repos/) ✅ complete

Prevents forks and reference clones from being included in multi-repo operations.
Enforces the canonical authored-repo list from CLAUDE.md. Extracted after forks were
incorrectly processed in three separate bulk operations.
→ [Full documentation](github-authored-repos/README.md)

### [test-before-asking](test-before-asking/) ✅ complete

Prevents unnecessary clarification requests by defining a decision threshold: try the
reasonable interpretation first, ask only for destructive, expensive, or preference-dependent
actions. Indexed by action type with carve-outs.
→ [Full documentation](test-before-asking/README.md)

### [cwd-verification](cwd-verification/) ✅ complete

Prevents bulk file operations running in the wrong directory. Enforces a session-start
cwd confirm and a pre-bulk-op confirm, with special handling for iCloud paths that
require quoting.
→ [Full documentation](cwd-verification/README.md)

### [verify-code-version](verify-code-version/) ✅ complete

Prevents debugging against the wrong code version. Enforces a version check after
every pull and before diagnosing unexpected output, comparing working tree against HEAD.
→ [Full documentation](verify-code-version/README.md)

### [mid-task-checkin](mid-task-checkin/) ✅ complete

Pauses at natural phase boundaries during long multi-step tasks and checks whether
new instructions have been added since execution started. One-line prompt, then
resumes. Activates on tasks with 3+ planned steps.
→ [Full documentation](mid-task-checkin/README.md)

### [karpathy-framework](karpathy-framework/) ✅ complete

Umbrella entry point for the Karpathy three-layer framework. Routes to the right layer
(spec, verify, environment) based on where you are in a task. No content of its own —
use when unsure which Karpathy layer to start with.
→ [Full documentation](karpathy-framework/README.md)

### [karpathy-spec](karpathy-spec/) ✅ complete

Layer 1 of the Karpathy framework. Transforms vague requests into precise, agile specs
before work begins. Defines success criteria upfront so `karpathy-verify` has something
concrete to test against.
→ [Full documentation](karpathy-spec/README.md)

### [karpathy-verify](karpathy-verify/) ✅ complete

Layer 2 of the Karpathy framework. Evaluates output against defined criteria via second
opinion (different model or role) and external signal (test claims against reality).
Feedback loops improve output quality 2–3× per invocation.
→ [Full documentation](karpathy-verify/README.md)

### [karpathy-environment](karpathy-environment/) ✅ complete

Layer 3 of the Karpathy framework. Builds the durable workspace that makes Layers 1 and 2
faster over time: CLAUDE.md, structured knowledge base, custom skills roadmap, and guardrails.
Compounds — each session setup is faster than the last.
→ [Full documentation](karpathy-environment/README.md)

### [roadmap-driver](roadmap-driver/) ✅ complete

Selects the next implementation-ready roadmap item from `ROADMAP.md` and outputs a
focused execution chain. Designed for "what should I work on next?" and "pick up from
the roadmap" prompts. Chains: `repo-compass` → `task-decomposer` → `karpathy-framework`
→ `karpathy-verify`.
→ [Full documentation](roadmap-driver/README.md)

### [grimoire-roadmap-status](grimoire-roadmap-status/) ✅ complete

MCP-friendly roadmap query utility for `ROADMAP.md`. Returns open/complete totals,
top clusters by outstanding items, and unresolved infrastructure actions.
→ [Full documentation](grimoire-roadmap-status/README.md)

### [skill-keyword-lookup](skill-keyword-lookup/) ✅ complete

Keyword-to-skill lookup utility for grimoire. Ranks matching skills from plain-language
queries (intent keywords) so you can find the right skill even when you do not remember
its exact name.
→ [Full documentation](skill-keyword-lookup/README.md)

### [task-decomposer](task-decomposer/) ✅ complete

Proactively breaks large tasks into self-contained chunks before context limits become an
issue. Each chunk is a task file with everything a fresh session needs to execute independently.
Used at the start of multi-session work to prevent context-window collisions.
→ [Full documentation](task-decomposer/README.md)

### [task-handoff](task-handoff/) ✅ complete

Reactively packages the current session's state into a handoff document when context pressure
is building mid-task. Captures git state, completed work, decisions made, and next chunk with
verifiable done criteria. Enables a fresh session to pick up cleanly without replaying history.
→ [Full documentation](task-handoff/README.md)

---

## When to invoke — workflow guide

### Workflow 1: Starting a new large task

**Trigger:** "Build X" / "Implement Y" / any task that feels multi-step or vague

```
karpathy-framework        → route to the right layer (usually spec first)
        ↓
karpathy-spec             → break the vague request into precise agile specs
        ↓
task-decomposer           → (if multi-session) split into independent chunks
        ↓
[do the work]
        ↓
karpathy-verify           → evaluate output against spec criteria
        ↓
karpathy-environment      → (if patterns emerged) capture in CLAUDE.md / skills
```

### Workflow 2: Mid-session context pressure

**Trigger:** "Context is getting long" / session feels sluggish / about to hit limits

```
mid-task-checkin           → pause, check for new instructions, confirm direction
        ↓
task-handoff              → package state for a fresh session to continue
        ↓
[new session starts from handoff document]
```

### Workflow 3: Session start (any project)

**Trigger:** Opening a new session / "where was I?" / resuming work

```
cwd-verification          → confirm you're in the right directory
        ↓
verify-code-version       → confirm working tree matches HEAD (no stale code)
        ↓
github-authored-repos     → (if multi-repo) scope to authored repos only
```

### Workflow 4: Evaluating existing output

**Trigger:** "Is this good enough?" / reviewing generated code / before accepting AI output

```
karpathy-verify           → second-opinion evaluation against criteria
        ↓
test-before-asking        → try the reasonable interpretation rather than asking
```

### Workflow 5: Post-session / environment improvement

**Trigger:** End of a productive session / "I keep doing the same thing" / session felt repetitive

```
session-skill-extractor   → scan transcript, propose new SKILL.md stubs
        ↓
skill-vetter              → (if third-party skill) review for safety before installing
        ↓
karpathy-environment      → update CLAUDE.md, knowledge base, skill roadmap
```

### Workflow 6: Installing or vetting new skills

**Trigger:** "Should I trust this skill?" / found a third-party skill to install

```
skill-vetter              → repo health, script audit, prompt injection check
        ↓
[PASS / FLAG / REJECT decision]
```

### Workflow 7: Finding the right skill by intent

**Trigger:** "Which skill covers this?" / concept known but skill name forgotten

```
skill-keyword-lookup      → rank likely matching skills from keywords
        ↓
[pick top match]          → invoke selected skill directly
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|---------------|
| `karpathy-framework` | Unsure which layer to start with; onboarding someone to the framework |
| `karpathy-spec` | Task is vague, large, or multi-step; need to define "done" before starting |
| `karpathy-verify` | Output exists; need to evaluate quality before accepting; want a second opinion |
| `karpathy-environment` | Session felt repetitive; patterns emerged worth capturing; setting up CLAUDE.md |
| `task-decomposer` | Task will span multiple sessions; need independent chunks before starting |
| `task-handoff` | Context pressure building mid-task; need to hand off cleanly to a fresh session |
| `mid-task-checkin` | Long multi-step task in progress; natural phase boundary reached; 3+ steps planned |
| `session-skill-extractor` | Session ending; want to extract reusable patterns into proposed skills |
| `skill-vetter` | Evaluating a third-party skill before installing; need safety/quality check |
| `github-authored-repos` | Multi-repo operation starting; need to exclude forks and reference clones |
| `cwd-verification` | Starting a session; about to run bulk file operations; path might be wrong |
| `verify-code-version` | After a pull; before debugging unexpected output; code might be stale |
| `test-before-asking` | About to ask the user a clarifying question; check if you should just try first |
| `skill-keyword-lookup` | You know the workflow concept but not the skill name; need ranked skill matches |
