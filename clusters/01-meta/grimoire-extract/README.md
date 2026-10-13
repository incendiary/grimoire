# grimoire-extract

> **Cluster:** 01-meta | **Status:** implemented | **Added:** 2026-05-24 | **Reworked:** 2026-10-13

On request, scans recent Claude Code session transcripts for patterns that recur and
drafts `SKILL.md` stubs in `~/.claude/proposed-skills/`. When 20 or more stubs are
queued, it runs a review with you instead of adding more. There is no automatic hook.

---

## What this skill does

1. **Analyses recent session transcripts** for repeated corrections, re-explained context, and regenerated boilerplate.
2. **Writes stubs** only for patterns seen 3 or more times and not already covered by a skill or memory.
3. **Runs a review at 20 stubs:** groups them by theme and recurrence, turns real gaps into roadmap items, then moves the stubs to the Trash.

---

## Invocation

```
/grimoire-extract
```

Or ask "what patterns did we repeat?", "extract skills from this session", or "review proposed skills".

---

## Configuration

`config.json` in the skill directory:
- `model`: model used for transcript analysis (each run is a paid call)
- `min_pattern_count`: minimum occurrences to write a stub (3)
- `sessions`: default number of recent sessions to aggregate
- `confidence_base`, `confidence_weight_sessions`, `confidence_weight_count`, `min_confidence`:
  weights for the confidence heuristic (`base + weight_sessions × occurring_sessions +
  weight_count × count`, capped at 1.0); a heuristic, not a calibrated score

The review threshold (20 stubs) is `REVIEW_THRESHOLD` in `scripts/generate_stubs.py`.

---

## Roadmap

- [x] Multi-session aggregation, per-project weighting, confidence scoring
- [x] On demand only; review at 20 stubs (2026-10-13; the Stop hook was removed)
