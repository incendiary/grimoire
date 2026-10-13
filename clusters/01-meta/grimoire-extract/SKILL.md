---
name: grimoire-extract
description: "On request, analyses recent session transcripts for patterns that recur (repeated corrections, re-explained context, regenerated boilerplate) and drafts skill stubs; when 20 or more stubs are queued it runs a review with the owner instead. Use when asked 'what patterns did we repeat?', 'extract skills from this session', or 'review proposed skills'. To vet a third-party skill use review-skill."
---
# grimoire-extract

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional

## Description
Turns patterns that genuinely recur into proposed skills, and keeps the proposal queue
small enough to review. Runs only when asked; there is no hook.

## When to run
- The owner asks for it ("what patterns did we repeat?", "extract skills from this session",
  "session retrospective").
- The owner asks to review proposed skills.

Never run it unprompted.

## What to do

1. **Check the queue first.** Count directories in `~/.claude/proposed-skills/`. If there
   are 20 or more, skip extraction and go to step 4.
2. **Extract.** Analyse the last few sessions, not just one, so recurrence is visible:
   ```bash
   python3 ~/.claude/skills/grimoire-extract/scripts/extract_patterns.py --sessions 5 \
     | python3 ~/.claude/skills/grimoire-extract/scripts/generate_stubs.py
   ```
   A pattern needs at least 3 occurrences (`min_pattern_count` in `config.json`).
   `generate_stubs.py` refuses to write when 20 or more stubs are already queued and prints
   `REVIEW DUE`.
3. **Drop what is already covered** before keeping any stub: check the pattern against
   `SKILLS.md` in the grimoire repo, the installed skills list, and the memory index
   (`MEMORY.md`). A preference or correction belongs in memory or CLAUDE.md, not in a skill.
   Delete stubs that duplicate either.
4. **Review with the owner** (when asked, or when the queue reaches 20):
   - Group stubs by theme and count how many distinct days each theme recurred on. A theme
     recurring across many days is a signal; one noisy session is not.
   - For each theme, say whether it is a gap, already covered (name the skill), or
     project-specific (belongs in that repo's CLAUDE.md).
   - Turn agreed gaps into roadmap items with scope and a done-when check, usually as an
     extension of an existing skill rather than a new one.
   - Move the reviewed stubs to the macOS Trash: `mv ~/.claude/proposed-skills ~/.Trash/proposed-skills-<date>`.

## Pattern types
1. **Context re-explanation:** the owner explains the same thing more than once.
2. **Correction loops:** the same class of mistake is corrected repeatedly.
3. **Boilerplate regeneration:** the same scaffolding is written from scratch repeatedly.
4. **Unstated assumptions:** the owner corrects an assumption Claude made.

## Gotchas
- `extract_patterns.py` calls a model (`model` in `config.json`). Each run costs usage;
  that is why there is no automatic hook.
- If `ANTHROPIC_API_KEY` is unset, the script prints a structured summary instead of calling the API.
- Stubs are drafts. Run `review-skill` on any stub before promoting it.
- The 2026-10-13 review found that an automatic Stop hook plus a bar of 2 occurrences in
  one session produced 1,788 stubs in five months, and that promoted stubs were a main
  source of skill creep.

## Files
```
grimoire-extract/
├── SKILL.md
├── config.json
└── scripts/
    ├── extract_patterns.py   detection and model call
    └── generate_stubs.py     writes stubs; enforces the 20-stub review threshold
```
