# karpathy-environment

> **Status:** COMPLETE
> **Cluster:** 01-meta

## Description
Layer 3 of the Karpathy framework. Builds the durable, improving-over-time workspace
that makes Layers 1 and 2 faster and more accurate across sessions. Produces a CLAUDE.md
(session context file), a structured knowledge base, a custom skills roadmap, and
guardrails. Compounds — each session setup is faster than the last.

**Core principle**: A proper environment saves ~50% of session setup time and cuts errors
2–3× over 10 tasks.

Invoke when: setting up a new project or workspace; sessions feel repetitive or ad hoc;
you've completed 3–5 tasks and want to capture patterns as reusable skills; you want
Claude to operate consistently across sessions without re-explaining context.

**Don't invoke if**: you're doing a one-off task with no recurring patterns; you haven't
completed any specs yet (too early to capture patterns).

## Context needed
- How your current workspace is organised (folders, repos, files, tools)
- What domains you work in
- Repeatable tasks that would benefit from formalisation
- Safety or compliance concerns that need guardrails

## What to do

### Phase 1: Audit current setup

Understand what you have now and what's missing before building anything.

1. **Document your workspace**:
   - How is your work organised? (folders, repos, files, systems)
   - What tools do you use? (Claude, other LLMs, IDEs, databases)
   - How do you hand off work between sessions?
   - What do you repeat verbatim across sessions?

2. **Identify pain points**:
   - What takes the most setup time?
   - Where do errors happen most often?
   - What context gets lost between sessions?
   - What would you formalise if you had 2 hours?

3. **Claude proposes gaps** — based on your answers, identify the highest-ROI items to
   formalise first.

---

### Phase 2: Build CLAUDE.md

Create the system file that gets injected at the start of every Claude session.
Aim for 500–1000 words — specific enough to route correctly, concise enough to read
in under 2 minutes.

**Five sections**:

**Section A — Workspace overview**: What domains you work in; how your repo/workspace is
structured; key folders and what they contain.

**Section B — Custom skills and routing**: List of custom skills you own; when each is
invoked; how Claude should route tasks it hasn't seen before.

**Section C — Knowledge architecture**: Where to find information for each domain;
what file to read first; dependency order between files.

**Section D — Core working rules**: Principles that apply to all work. Examples:
"Always surface assumptions before coding", "Verify output before accepting",
"Break work into agile specs, not waterfall".

**Section E — Communication preferences**: Dialect, voice, code delivery style,
document style, response length. Be specific — "British English, active voice,
max 3 bullet points per response" is useful; "be professional" is not.

**Template**:
```
# CLAUDE.md

## Workspace Overview
[What you do; how your repo is structured; key paths]

## Custom Skills and Routing
- skill-name: Used when [TRIGGER]. Returns [OUTPUT].

## Knowledge Architecture
- For [DOMAIN] questions: read [PATH] first
- For [DOMAIN] questions: read [PATH] first

## Core Working Rules
- [RULE 1]
- [RULE 2]

## Communication Preferences
- Dialect: [BRITISH/AMERICAN]
- Voice: [DIRECT/TECHNICAL/ACCESSIBLE]
- Code: [FULL SOLUTION / CRITIQUE AFTER I ATTEMPT / STEP-BY-STEP]
```

---

### Phase 3: Design knowledge base structure

Organise domain knowledge so Claude can find it efficiently. Start with 50% coverage —
expand as you discover gaps.

1. **Identify knowledge domains** (your main areas of work)
2. **Design folder hierarchy**: top level = domains; subfolders = categories; files = reference material
3. **Define entry points**: for each domain, which file should Claude read first?
4. **Populate priority files** — the 3–5 most-referenced pieces of information per domain

**Example structure**:
```
knowledge_base/
├── DOMAIN_1/
│   ├── overview.md   ← START HERE
│   ├── reference/
│   └── lessons_learned.md
├── DOMAIN_2/
│   └── ...
```

---

### Phase 4: Build custom skills roadmap

Identify repeatable workflows worth formalising as SKILL.md files.

1. **List repeatable tasks** — what do you do more than once?
2. **Prioritise** — which would save the most time? Which is most error-prone?
3. **Plan top 3–5 skills**:
   - Trigger: when to invoke
   - Workflow: step-by-step
   - Inputs / outputs
   - Success criteria
4. **Create roadmap** — skill name, priority, status (backlog / in-progress / done)

Start with 3–5 skills. Go deep on each before adding more. Quality over quantity.

---

### Phase 5: Establish guardrails

Define what Claude can do autonomously, what needs approval, and what's forbidden.

**Three categories**:

| Category | Meaning | Example |
|----------|---------|---------|
| Always Do | Claude takes this action without asking | Verify output against criteria before returning |
| Ask First | Requires explicit approval before proceeding | Before publishing or submitting anything |
| Never Do | Absolutely forbidden | Modify files in /important_do_not_edit/ |

**Important**: Distinguish prompt-level rules (in CLAUDE.md — Claude can technically
ignore) from tool-level enforcement (hooks — enforced by the system). Critical "Never Do"
rules should be tool-level, not just a request in CLAUDE.md.

---

### Phase 6: Integrate and document

Wire everything together.

1. **Version control**: Store CLAUDE.md in repo root; SKILL.md files in `/loadout/` or equivalent
2. **Integration checklist**:
   - [ ] CLAUDE.md references correct skill paths
   - [ ] CLAUDE.md references correct knowledge base paths
   - [ ] Guardrails are documented (prompt-level in CLAUDE.md, tool-level in system hooks)
   - [ ] Knowledge base has at least 50% of key files populated
   - [ ] Top 3 skills have draft SKILL.md files
3. **Document the update process**: After every 5 tasks, spend 30 minutes refining CLAUDE.md,
   adding skills, expanding the knowledge base

## Gotchas

| Pitfall | Fix |
|---------|-----|
| CLAUDE.md is too detailed or too vague | Aim for 500–1000 words. Specific enough to route correctly, readable in <2 min. |
| Knowledge base too large — Claude gets lost | Start with 50% coverage. Expand only when you discover a gap. |
| Skills roadmap has 20 items | Prioritise to 3–5. Do these deeply, then add more. |
| Guardrails are only prompt-level | For critical rules, add tool-level enforcement (hooks). |
| Environment is built once and never updated | Review after every 5 tasks. It compounds only if refined. |

## No completion prompt

This is the terminal layer — it feeds back into Layers 1 and 2 by making future sessions
faster. After completing an environment setup, return to `karpathy-spec` for the next task
with a better-equipped workspace.
