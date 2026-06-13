# session-skill-extractor

> **Cluster:** 01-meta | **Status:** implemented | **Added:** 2026-05-24

Scans a Claude Code session transcript for repeated patterns and generates `SKILL.md`
stubs in `~/.claude/proposed-skills/`. Wired to the Claude Code Stop hook so it
runs automatically at the end of every session.

---

## What this skill does

Identifies recurring workflow patterns across your coding sessions and proposes them
as new skills. Runs passively at session end — no manual invocation required.

1. **Analyses the session transcript** for repeated context-setting, rule enforcement, or multi-step procedures
2. **Generates stub SKILL.md files** in `~/.claude/proposed-skills/`
3. **Flags stubs for vetting** via the `skill-vetter` promotion workflow

---

## When to use it

Installed once and runs automatically. Useful when:
- You find yourself re-explaining the same rules or patterns
- A workflow keeps appearing across sessions
- You want to grow grimoire organically from real usage

---

## Installation

### Claude Code

```bash
cp -r clusters/01-meta/session-skill-extractor ~/.claude/skills/
bash ~/.claude/skills/session-skill-extractor/install.sh
```

The `install.sh` script wires the Claude Code Stop hook for automatic extraction.

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#session-skill-extractor
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.

---

## Invocation

**Automatic** — runs at session end via the Stop hook.

**Manual** — if you want to extract mid-session:
```
/session-skill-extractor
```

---

## Configuration

Edit `config.json` in the skill directory:
- `model`: which model to use for transcript analysis
- `threshold`: minimum pattern repetition count to generate a stub

---

## Roadmap

- [x] `extract_patterns.py` — transcript analysis via claude CLI
- [x] `generate_stubs.py` — writes SKILL.md stubs from JSON patterns
- [x] `install.sh` — wires the Stop hook
- [x] `config.json` — model and threshold configuration
- [x] `proposed-skills/` — output directory (gitignored)
- [ ] Multi-session aggregation (combine patterns across sessions)
- [ ] Per-project pattern weighting
- [ ] Confidence scoring improvements
- [x] `skill-vetter` integration — promotion workflow documented in SKILL.md
