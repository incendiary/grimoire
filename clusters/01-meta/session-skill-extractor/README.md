# session-skill-extractor

> **Cluster:** 01-meta | **Status:** implemented | **Added:** 2026-05-24

Scans a Claude Code session transcript for repeated patterns and generates `SKILL.md`
stubs in `~/.claude/proposed-skills/`. Wired to the Claude Code Stop hook so it
runs automatically at the end of every session.

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
