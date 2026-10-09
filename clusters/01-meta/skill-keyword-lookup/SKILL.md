---
name: skill-keyword-lookup
description: "Finds the best matching grimoire skills from plain-language keywords when the concept is remembered but not the skill name. Use when asking 'which skill handles X?', 'find the skill for this workflow', 'find skill', or 'skill search'. Use when you cannot remember which grimoire skill fits."
---
# skill-keyword-lookup

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** action

## Description
Find the best matching grimoire skill(s) from plain-language keywords. Useful when you
remember the concept but not the exact skill name.

Invoke when: "which skill handles X?", "find the skill for this workflow", or when
starting from intent instead of a known skill identifier.
Trigger phrases: "find skill", "lookup skill", "which skill covers", "skill search".

## Context needed
- Keywords describing intent (for example: `devops`, `roadmap`, `readme`, `sync`)
- Whether private clusters should be included (`--include-private`)
- Optional result cap (`--limit`)
- Optional machine-readable output (`--json`)

## What to do

1. Run keyword lookup against all public skills:
   ```bash
   bash clusters/01-meta/skill-keyword-lookup/find-skill.sh devops roadmap readme
   ```

2. Limit output for quick scans:
   ```bash
   bash clusters/01-meta/skill-keyword-lookup/find-skill.sh --limit 5 lint black ruff
   ```

3. Include private clusters when needed:
   ```bash
   bash clusters/01-meta/skill-keyword-lookup/find-skill.sh --include-private odpc syscall
   ```

4. Get machine-readable output for downstream tooling:
   ```bash
   bash clusters/01-meta/skill-keyword-lookup/find-skill.sh --json devops roadmap
   ```

5. Pick the top matching skill(s) and invoke by name.

## Gotchas
- This is keyword scoring, not semantic search. Better keywords improve results.
- If a concept spans multiple skills, expect multiple high-scoring matches.
- `--include-private` searches any mounted `clusters-*/clusters` submodule (e.g. `clusters-private/`, `clusters-offsec/`).
- A small hardcoded synonym map (`synonyms_for()` in `find-skill.sh`) expands terms
  like `standards`/`practices` and `ci`/`pipeline`/`workflow` both ways. It is not
  exhaustive — unmapped terms search literally with no expansion.

## Suggested scripts
- `find-skill.sh` (included) — rank skills by keyword matches in SKILL.md + README.md
