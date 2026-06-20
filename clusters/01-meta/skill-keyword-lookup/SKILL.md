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

4. Pick the top matching skill(s) and invoke by name.

## Gotchas
- This is keyword scoring, not semantic search. Better keywords improve results.
- If a concept spans multiple skills, expect multiple high-scoring matches.
- `--include-private` requires `clusters-private/` submodule to be present.

## Suggested scripts
- `find-skill.sh` (included) — rank skills by keyword matches in SKILL.md + README.md
