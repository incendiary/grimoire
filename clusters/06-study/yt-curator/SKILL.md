# yt-curator

> **Status:** COMPLETE
> **Cluster:** 06-study

## Description
Takes a block of source text (study notes, a NotebookLM/Gemini summary, a course chapter
outline) and builds a private YouTube playlist from it. Claude derives focused search
queries from the text, runs them against the YouTube Data API, pre-filters by metrics,
AI-scores surviving videos for relevance, then adds the best to a new or existing private
playlist.

Invoke when: building a study playlist from a chapter of notes, collecting supplementary
videos for a course topic, or curating reference material for a specific technical subject.

## Context needed
- A block of source text (any length — paste directly after the invocation)
- Optional: a short playlist title override (otherwise derived from the text)
- Optional: `--min-views`, `--max-days`, `--max-duration` if defaults need adjusting

## One-time setup

**If you have previously used `youtube_cli.py auth`**, the token at
`~/.youtube-cli-token.json` is already valid — skip straight to step 2.

```bash
# 1. Install dependencies (use a venv)
cd ~/.claude/skills/yt-curator
python3 -m venv .venv && source .venv/bin/activate
pip install google-api-python-client google-auth-oauthlib isodate python-dotenv

# 2. Verify auth is working
python yt-curator.py playlists
# Should print your existing YouTube playlists as JSON
```

**First-time auth (no existing token):**
```bash
# Copy the .env from your youtube_cli.py project (contains CLIENT_ID + CLIENT_SECRET)
cp ~/tmp/claude_youtube/learning/tool/.env ~/.claude/skills/yt-curator/.env

# Run the auth flow (opens browser for Google consent)
python yt-curator.py auth
# Token saved to ~/.youtube-cli-token.json — shared with youtube_cli.py
```

The token at `~/.youtube-cli-token.json` is shared between `yt-curator.py` and
`youtube_cli.py`. Authenticating once in either tool covers both.

Required OAuth scope: `https://www.googleapis.com/auth/youtube`

## Invocation

```
/yt-curator
Topic: x64 syscall techniques          ← optional; used as playlist title prefix
[paste source text block here]
```

Or with overrides:
```
/yt-curator
Topic: Sleep masking
Min views: 500
Max age (days): 730
Max duration (min): 60
[paste text]
```

## Workflow

### Step 1 — Extract search queries from source text

Read the source text and generate **3–5 focused, varied search queries**. Good queries are:
- Specific (include technical terms, not generic topics)
- Varied (different angles: conceptual overview, implementation deep-dive, demo/walkthrough)
- YouTube-optimised (add terms like "tutorial", "explained", "walkthrough", "demo" where useful)

Example for an ODPC chapter on indirect syscalls:
```
"indirect syscalls windows evasion"
"NtAllocateVirtualMemory syscall stub tutorial"
"HalosGate dynamic SSN resolution explained"
"EDR hook bypass syscall demo 2023"
"windows kernel syscall number indirect jump"
```

### Step 2 — Search YouTube

For each query, run:
```bash
python yt-curator.py search \
  --query "QUERY" \
  --max 50 \
  --min-views 1000 \
  --max-days 1095 \
  --min-duration 4 \
  --max-duration 45
```

Merge all results. Deduplicate by video ID. You will typically have 50–150 candidates.

### Step 3 — Score and select

For each candidate video, evaluate against the source text:

**Score 0–10:**
- **8–10:** Title and description directly address the core topic; reputable channel;
  duration appropriate for depth (10–30 min for technical topics)
- **5–7:** Relevant but tangential, or highly relevant but very short/long
- **0–4:** Generic, off-topic, or poor signal

Select the **top 10–15 videos** by score. Break ties by view count.

Present the selection to the user before adding:
```
Selected 12 videos for playlist "x64 Syscall Techniques":

 1. [9] "Indirect Syscalls Deep Dive — bypassing EDR hooks" (32 min, 45k views)
 2. [8] "HalosGate implementation walkthrough" (18 min, 12k views)
 ...

Playlist name: "x64 Syscall Techniques — 2026-06-02"
Action: create new private playlist
```

### Step 4 — Check for existing playlist

```bash
python yt-curator.py playlists
```

If a playlist with a matching name already exists, ask:
> "Found existing playlist 'x64 Syscall Techniques' (23 videos). Append to it, or create new?"

Default: **create new** if user doesn't respond.

### Step 5 — Create or select playlist

To create new:
```bash
python yt-curator.py create \
  --title "x64 Syscall Techniques — 2026-06-02" \
  --description "Curated from ODPC Chapter 20-22 notes"
```

Returns `playlist_id`.

### Step 6 — Add videos

```bash
python yt-curator.py add \
  --playlist-id PLAYLIST_ID \
  --video-ids id1,id2,id3,...
```

### Step 7 — Confirm

Output:
```
✓ 12 videos added to: x64 Syscall Techniques — 2026-06-02
  https://www.youtube.com/playlist?list=PL...
```

## Default filter values

| Parameter | Default | Override flag |
|-----------|---------|---------------|
| Min views | 1 000 | `--min-views N` |
| Max age | 3 years (1 095 days) | `--max-days N` |
| Min duration | 4 min | `--min-duration N` |
| Max duration | 45 min | `--max-duration N` |
| Results per query | 50 | `--max N` |
| Videos to add | top 12 | (edit selection before adding) |

## Optional: copy an existing public playlist into a private one

If you have a curated source playlist (e.g. a course creator's public playlist) and want
a private copy, skip the search/score steps:

```bash
python yt-curator.py create --title "ODPC — Module 5 Evasion"
# note the returned playlist_id

python yt-curator.py copy-playlist \
  --url "https://www.youtube.com/playlist?list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab" \
  --playlist-id PL...
```

This fetches all video IDs from the source and adds them to your private playlist.

---

## Channel management commands

These operate on your own YouTube channel and run directly (no Claude scoring step needed).

```bash
# Channel statistics
python yt-curator.py stats

# Video statistics
python yt-curator.py stats --video-id VIDEO_ID

# List own videos
python yt-curator.py videos --limit 10

# Get full details of a video
python yt-curator.py video-get --video-id VIDEO_ID

# Upload a video (defaults to private)
python yt-curator.py upload \
  --file ~/recordings/demo.mp4 \
  --title "BOF demo — process enumeration" \
  --description "Walkthrough of the ODPC BOF exercise" \
  --privacy private \
  --thumbnail ~/recordings/thumb.png

# Schedule a publish date (must be private until that time)
python yt-curator.py upload --file video.mp4 --title "..." \
  --publish-at "2026-08-01T09:00:00Z"

# Update video metadata
python yt-curator.py video-update --video-id VIDEO_ID \
  --title "New title" --privacy unlisted

# Delete a video (safety flag required)
python yt-curator.py video-delete --video-id VIDEO_ID --confirm
```

All management commands support `--json` for machine-readable output.

---

## Gotchas

- **YouTube search quota:** Each search request costs ~100 units; default quota is 10 000/day.
  5 queries = ~500 units. Leave headroom for other YouTube API usage.
- **`isodate` for duration parsing:** YouTube returns ISO 8601 durations (e.g. `PT18M30S`).
  The `yt-curator.py search` command converts these to minutes automatically.
- **Private playlist visibility:** Playlists created via the API with `privacyStatus: private`
  are only visible to you. Verify in YouTube Studio if unsure.
- **Token expiry:** The cached OAuth token auto-refreshes. If it fails, run `python yt-curator.py auth` again.
- **Channel quality signal:** View count and recency are the only automated metrics.
  Claude's scoring should factor in channel name/reputation visible in the description field.
- **Upload safety:** Videos upload as `private` by default. Use `--privacy public` explicitly only when ready.

## Related skills

- `study-burst-runner` — structured study session that consumes the curated playlist
- `source-material-triage` — triage raw course files before turning them into search queries
- `edr-test-loop` — for ODPC content: test what you learned from the playlist
