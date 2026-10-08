# Skill README template

Use this template when creating or updating a skill's `README.md`. Every skill
directory **must** contain both `SKILL.md` and `README.md` (CI-enforced).

---

## Template

```markdown
# <skill-name>

> **Cluster:** <NN-name> | **Status:** complete | **Added:** <YYYY-MM-DD>

One-paragraph description: what problem does this skill solve, in what context.

---

## What this skill does

2–4 sentences expanding on the description. What does it enforce, generate, or check?
What failure mode does it prevent?

---

## When to use it

Bullet list of trigger conditions or scenarios:
- "When you are doing X..."
- "Before starting Y..."
- Explicit trigger phrases that Claude recognises

---

Installation is covered by the root README; do not repeat it here.

---

## Invocation

**Explicit:**
```
/<skill-name>
<any required context or parameters>
```

**Implicit** — describe your task and Claude recognises the trigger:
```
<natural language example that triggers this skill>
```

---

## Workflow

```
Step 1
   ↓
Step 2
   ↓
Step 3 (with decision point noted)
   ↓
Output
```

---

## What it won't do

- Boundary 1 (what's explicitly out of scope)
- Boundary 2
- Boundary 3

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Outstanding item 1
- [ ] Outstanding item 2
```

---

## Notes

- **Status field:** Use `complete` for shipped skills, `promoted` for stubs awaiting expansion.
- **Installation section:** Always include all three platforms (Claude Code, prompt file, MCP). For `instructional` type skills, note that MCP is not applicable.
- **Action vs instructional:** Only `action` type skills get an MCP subsection. Check the skill's `SKILL.md` for the `Type:` field.
- **Invocation examples:** Should be realistic — use actual repo names or plausible scenarios.
- **Roadmap:** Keep up to date. Tick items as they ship. Outstanding items guide future work.
