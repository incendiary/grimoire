# karpathy-environment

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-11

Layer 3 of the Karpathy framework. Builds the durable, improving-over-time workspace
that makes Layers 1 and 2 faster across sessions. Produces CLAUDE.md (session context),
a structured knowledge base, a custom skills roadmap, and explicit guardrails. A proper
environment saves ~50% of session setup time and compounds with each completed task.

---

## What this skill does

1. **Audits your current setup** — identifies what's missing and what would be highest ROI to formalise
2. **Builds CLAUDE.md** — the 5-section system file injected at every session start
3. **Designs a knowledge base** — folder hierarchy + entry points so Claude can find domain information efficiently
4. **Creates a skills roadmap** — top 3–5 repeatable workflows worth formalising
5. **Establishes guardrails** — Always Do / Ask First / Never Do matrix, with tool-level enforcement for critical rules

---

## When to use it

- Setting up a new project or workspace
- Sessions feel repetitive or require the same context re-explanation every time
- After completing 3–5 tasks — capture the patterns as reusable skills
- Compliance or consistency concerns (need explicit guardrails)

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/karpathy-environment ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#karpathy-environment
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Quick reference

```
# Setting up a new workspace
Invoke karpathy-environment to help me set up my workspace.
Current setup: [describe]
Domains: [list]
Pain points: [list]

# Auditing and improving an existing setup
Invoke karpathy-environment to audit and improve my setup.
```

---

## Pairs with

- `karpathy-spec` — the environment makes spec sessions faster; spec patterns become skills
- `karpathy-verify` — evaluation criteria that consistently work get captured into CLAUDE.md
- `karpathy-framework` — umbrella entry point if unsure which layer to start with

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Ship: copy to `~/.claude/skills/karpathy-environment/`
