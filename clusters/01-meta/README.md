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

### [grimoire-roadmap-status](grimoire-roadmap-status/) ✅ complete
MCP-friendly roadmap query utility for `ROADMAP.md`. Returns open/complete totals,
top clusters by outstanding items, and unresolved infrastructure actions.
→ [Full documentation](grimoire-roadmap-status/README.md)
