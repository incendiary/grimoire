# skill-keyword-lookup

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-20

A fast keyword-to-skill lookup utility. Use this when you know the behavior you want
("roadmap sync", "release flow", "lint gate") but cannot remember the skill name.

---

## What this skill does

- Searches all skill folders under `clusters/` (and optional private clusters)
- Scores each skill by keyword hits in `SKILL.md` and `README.md`
- Boosts matches where keywords appear in the skill directory name
- Returns ranked candidates with path + matched terms

---

## When to use it

- "Which skill handles this?"
- "I know the concept, not the skill name"
- Onboarding someone new to grimoire

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/skill-keyword-lookup ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:

```
#skill-keyword-lookup
```

### VS Code / MCP client

This is an `action` skill and is available as a tool via the grimoire MCP server.

---

## Invocation

**Explicit:**

```bash
/skill-keyword-lookup
keywords: devops roadmap readme sync
```

**CLI quick use:**

```bash
bash clusters/01-meta/skill-keyword-lookup/find-skill.sh devops roadmap readme sync
```

---

## Example from your use case

Query:

```bash
bash clusters/01-meta/skill-keyword-lookup/find-skill.sh devops roadmap readme sync standard
```

Expected top matches:

- `devops-practices` (standard devops practices)
- `roadmap-sync` (move/tick roadmap items in README based on actual completion)
- `repo-compass` (cross-check README roadmap against real repo state)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Add keyword lookup script
- [ ] Add synonym map (for example: "standards" -> "practices")
- [ ] Add `--json` output mode for machine consumers
