# yt-curator

> **Cluster:** 06-study | **Status:** complete | **Added:** 2026-06-02

Takes a block of source text (study notes, a NotebookLM/Gemini summary, a course chapter
outline) and builds a private YouTube playlist from it. Claude derives focused search
queries from the text, pre-filters by metrics, AI-scores surviving videos for relevance,
and adds the best to a new or existing private playlist.

---

## What this skill does

Eliminates the manual cycle of: read notes → think of search terms → search YouTube →
evaluate results → add to playlist. Instead: paste your notes, confirm the selection,
get a playlist URL.

---

## When to use it

- Building a supplementary video playlist from a course chapter or study notes
- Collecting reference material on a specific technical topic
- Adding curated YouTube content to a named study playlist you maintain per topic

---

## Installation

```bash
cp -r ~/Claude/skills/grimoire/clusters/06-study/yt-curator ~/.claude/skills/

# One-time dependency install (use a venv)
cd ~/.claude/skills/yt-curator
python3 -m venv .venv && source .venv/bin/activate
pip install google-api-python-client google-auth-oauthlib isodate
```

Then follow the one-time auth setup in `SKILL.md`.

---

## Invocation

```
/yt-curator
Topic: x64 syscall techniques
[paste ODPC chapter notes or Gemini summary here]
```

---

## Workflow

```
Paste source text
        ↓
Claude extracts 3–5 search queries
        ↓
yt-curator.py search (per query, YouTube Data API v3)
        ↓
Metrics pre-filter (views, age, duration)
        ↓
Claude scores survivors on relevance → selects top 12
        ↓
Check existing playlists → ask append/new
        ↓
yt-curator.py create (if new) + add videos
        ↓
Return playlist URL
```

---

## Roadmap

- [x] SKILL.md written: full workflow, scoring criteria, filter defaults, gotchas
- [x] README.md written
- [x] Write `yt-curator.py` (search, playlists, create, add subcommands)
- [x] Ship: copy to `~/.claude/skills/yt-curator/`
- [ ] Add `--channel-allowlist` / `--channel-blocklist` flags
- [ ] Add `--export-json` flag to save curation results without adding to playlist
- [ ] Add support for updating playlist description after creation
