# session-skill-extractor

## Description
Invoke this skill when a Claude Code session is ending, when the user asks "what patterns did we repeat?", or when the user says "extract skills from this session". Analyse the current session transcript for repeated patterns — context re-explanation, correction loops, style fixes, boilerplate regeneration — and generate SKILL.md stubs in the configured output directory for the user to review and promote.

Do not invoke automatically on short sessions (fewer than 8 turns). Do not generate stubs for patterns that only occurred once.

## Purpose
This skill implements the principle that rules should get smarter with every session. It is the mechanism by which repeated one-off runs become structured, reusable skills.

## Invocation
- Automatic: via Stop hook at session end (configured in ~/.claude/settings.json)
- Manual: "extract skills from this session", "what should become a skill?", "session retrospective"

## What to detect

### Pattern types (in priority order)
1. **Context re-explanation** — user explaining the same thing more than once (architecture, constraints, naming conventions, audience). Signals a missing grounding skill.
2. **Correction loops** — Claude making the same class of mistake repeatedly in one session (style, terminology, scope, abstraction level). Signals a Gotchas section is missing from an existing or needed skill.
3. **Boilerplate regeneration** — Claude writing the same scaffolding from scratch each session (imports, file structure, error handling patterns). Signals a code template skill.
4. **Style corrections** — user correcting tone, format, British English, no em dashes, Oxford comma. Signals the human-rewrite or tone-check skills need updating.
5. **Unstated assumptions** — Claude making assumptions the user had to correct (e.g. using WinAPI when manual parsing was expected). Signals missing constraint documentation.

### Minimum threshold
Only flag a pattern for stub generation if it occurred **at least twice** in the session. Single instances go into a low-confidence list for the user to review but do not generate stubs.

## Output

Run the detection script:
```bash
python3 ~/.claude/skills/session-skill-extractor/scripts/extract_patterns.py \
  --project-dir "$CLAUDE_PROJECT_DIR" \
  --output-dir ~/.claude/proposed-skills/
```

For each pattern above threshold, a stub is written to:
```
~/.claude/proposed-skills/<skill-name>/SKILL.md
```

The user reviews stubs and promotes them to `~/.claude/skills/<skill-name>/` when ready.

## Config
Located at `~/.claude/skills/session-skill-extractor/config.json`

```json
{
  "min_turns": 8,
  "min_pattern_count": 2,
  "output_dir": "~/.claude/proposed-skills",
  "model": "claude-opus-4-5",
  "max_session_tokens": 40000
}
```

## Promotion workflow

Proposed stubs are drafts — review before promoting:

1. Read the stub at `~/.claude/proposed-skills/<name>/SKILL.md`
2. Run `/skill-vetter` on the stub before copying to `~/.claude/skills/`
3. Adjust the stub's trigger condition, constraints, and gotchas from real session context
4. Copy to `~/.claude/skills/<name>/` and commit to `loadout` under the appropriate cluster

## Gotchas
- Sessions with very long tool outputs (file reads, bash output) inflate token count fast. The extraction script trims tool results to 500 chars before sending to the model.
- Stop hooks fire after every turn, not just at session end. The hook script checks that the session is actually ending before running the full extraction.
- Proposed stubs are drafts. Always review before promoting. The model may conflate distinct patterns or miss context.
- If ANTHROPIC_API_KEY is not set in the shell environment, the script falls back to printing a structured summary to stdout rather than calling the API.

## File structure
```
~/.claude/skills/session-skill-extractor/
├── SKILL.md                    ← this file
├── config.json
├── scripts/
│   ├── extract_patterns.py     ← main extraction + API call
│   ├── generate_stubs.py       ← writes SKILL.md stubs from detected patterns
│   └── stop_hook.sh            ← Stop hook entry point
├── templates/
│   └── skill-stub.md           ← template for generated stubs
└── proposed-skills/
    └── .gitkeep
```
