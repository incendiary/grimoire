#!/usr/bin/env python3
"""
yt-curator.py
YouTube Data API v3 wrapper for the yt-curator Claude Code skill.
Handles search, playlist listing, playlist creation, and video insertion.

Claude is the intelligence layer — this script is a thin, reliable API client.

Usage:
    python yt-curator.py search   --query TEXT [--max N] [--min-views N]
                                  [--max-days N] [--min-duration N] [--max-duration N]
    python yt-curator.py playlists
    python yt-curator.py create   --title TEXT [--description TEXT]
    python yt-curator.py add      --playlist-id ID --video-ids id1,id2,...
    python yt-curator.py auth     (first-time setup only)

Auth:
    Token:       ~/.youtube-cli-token.json  (shared with youtube_cli.py)
    Credentials: YOUTUBE_CLIENT_ID + YOUTUBE_CLIENT_SECRET in .env (first-time auth only)

    If you have already run 'python youtube_cli.py auth', the token is already valid
    and no further setup is needed.

    For first-time setup, copy your .env to this skill directory:
        cp ~/tmp/claude_youtube/learning/tool/.env ~/.claude/skills/yt-curator/.env
    Then run: python yt-curator.py auth

Requires:
    pip install google-api-python-client google-auth-oauthlib isodate python-dotenv
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

try:
    import isodate
    from dotenv import load_dotenv
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
except ImportError as e:
    print(f"ERROR: missing dependency — {e}", file=sys.stderr)
    print("Run: pip install google-api-python-client google-auth-oauthlib isodate python-dotenv",
          file=sys.stderr)
    sys.exit(1)

# ── Paths ─────────────────────────────────────────────────────────────────────
# Shared token with youtube_cli.py — one auth setup covers both tools
TOKEN_PATH = Path.home() / ".youtube-cli-token.json"
SCOPES     = ["https://www.googleapis.com/auth/youtube"]

# Load .env from skill directory for first-time auth (CLIENT_ID + CLIENT_SECRET)
_skill_dir = Path(__file__).parent
load_dotenv(_skill_dir / ".env")

# ── Auth ──────────────────────────────────────────────────────────────────────

def get_authenticated_service():
    """Return an authenticated YouTube API service object.

    Uses ~/.youtube-cli-token.json (shared with youtube_cli.py).
    The token JSON contains client_id + client_secret inline, so refresh
    works without a separate credentials file.
    """
    if not TOKEN_PATH.exists():
        print(f"ERROR: No token found at {TOKEN_PATH}", file=sys.stderr)
        print("  If you have used youtube_cli.py before, re-run: python youtube_cli.py auth", file=sys.stderr)
        print("  For first-time setup, run: python yt-curator.py auth", file=sys.stderr)
        sys.exit(1)

    creds = Credentials.from_authorized_user_file(str(TOKEN_PATH), SCOPES)

    if not creds.valid:
        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            TOKEN_PATH.write_text(creds.to_json())
        else:
            print("ERROR: Token is invalid. Run: python yt-curator.py auth", file=sys.stderr)
            sys.exit(1)

    return build("youtube", "v3", credentials=creds)


def cmd_auth(_args):
    """First-time OAuth setup. Opens browser for consent. Saves token to ~/.youtube-cli-token.json."""
    client_id     = os.getenv("YOUTUBE_CLIENT_ID", "")
    client_secret = os.getenv("YOUTUBE_CLIENT_SECRET", "")

    if not client_id or not client_secret:
        print("ERROR: YOUTUBE_CLIENT_ID and YOUTUBE_CLIENT_SECRET not set.", file=sys.stderr)
        print(f"  Copy your .env to: {_skill_dir}/.env", file=sys.stderr)
        print(f"  Or: export YOUTUBE_CLIENT_ID=... YOUTUBE_CLIENT_SECRET=...", file=sys.stderr)
        sys.exit(1)

    client_config = {
        "installed": {
            "client_id":     client_id,
            "client_secret": client_secret,
            "auth_uri":      "https://accounts.google.com/o/oauth2/auth",
            "token_uri":     "https://oauth2.googleapis.com/token",
            "redirect_uris": ["http://localhost"],
        }
    }
    flow  = InstalledAppFlow.from_client_config(client_config, SCOPES)
    creds = flow.run_local_server(port=8080, prompt="consent", access_type="offline", open_browser=False)
    TOKEN_PATH.write_text(creds.to_json())
    print(f"Authentication successful. Token saved to {TOKEN_PATH}")


# ── Helpers ───────────────────────────────────────────────────────────────────

def iso_duration_to_minutes(iso: str) -> float:
    """Convert ISO 8601 duration (PT18M30S) to total minutes."""
    try:
        return isodate.parse_duration(iso).total_seconds() / 60
    except Exception:
        return 0.0


def published_days_ago(published_at: str) -> int:
    """Return how many days ago a video was published."""
    try:
        dt = datetime.fromisoformat(published_at.replace("Z", "+00:00"))
        return (datetime.now(timezone.utc) - dt).days
    except Exception:
        return 9999


# ── Commands ──────────────────────────────────────────────────────────────────

def cmd_search(youtube, args):
    """Search YouTube and print filtered results as JSON."""
    cutoff_date = (datetime.now(timezone.utc) - timedelta(days=args.max_days)).isoformat()

    try:
        search_resp = youtube.search().list(
            part="id,snippet",
            q=args.query,
            type="video",
            maxResults=args.max,
            order="relevance",
            publishedAfter=cutoff_date,
            videoDuration="any",      # we filter by duration ourselves
        ).execute()
    except HttpError as e:
        print(f"ERROR: YouTube API error during search: {e}", file=sys.stderr)
        sys.exit(1)

    video_ids = [item["id"]["videoId"] for item in search_resp.get("items", [])]
    if not video_ids:
        print("[]")
        return

    # Fetch full video statistics and content details
    try:
        details_resp = youtube.videos().list(
            part="snippet,statistics,contentDetails",
            id=",".join(video_ids),
        ).execute()
    except HttpError as e:
        print(f"ERROR: YouTube API error fetching video details: {e}", file=sys.stderr)
        sys.exit(1)

    results = []
    for item in details_resp.get("items", []):
        vid_id       = item["id"]
        snippet      = item.get("snippet", {})
        stats        = item.get("statistics", {})
        content      = item.get("contentDetails", {})

        duration_min = iso_duration_to_minutes(content.get("duration", "PT0S"))
        view_count   = int(stats.get("viewCount", 0))
        days_ago     = published_days_ago(snippet.get("publishedAt", ""))

        # Apply filters
        if view_count < args.min_views:
            continue
        if duration_min < args.min_duration or duration_min > args.max_duration:
            continue
        # days_ago already limited by publishedAfter in the search query, but double-check
        if days_ago > args.max_days:
            continue

        results.append({
            "id":           vid_id,
            "title":        snippet.get("title", ""),
            "description":  snippet.get("description", "")[:400],
            "channel":      snippet.get("channelTitle", ""),
            "published_at": snippet.get("publishedAt", ""),
            "days_ago":     days_ago,
            "view_count":   view_count,
            "duration_min": round(duration_min, 1),
            "url":          f"https://www.youtube.com/watch?v={vid_id}",
        })

    print(json.dumps(results, indent=2))


def cmd_playlists(youtube, _args):
    """List the authenticated user's playlists (title + id)."""
    try:
        resp = youtube.playlists().list(
            part="snippet",
            mine=True,
            maxResults=50,
        ).execute()
    except HttpError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    playlists = [
        {"id": item["id"], "title": item["snippet"]["title"]}
        for item in resp.get("items", [])
    ]
    print(json.dumps(playlists, indent=2))


def cmd_create(youtube, args):
    """Create a new private playlist and print its id."""
    try:
        resp = youtube.playlists().insert(
            part="snippet,status",
            body={
                "snippet": {
                    "title":       args.title,
                    "description": args.description or "",
                },
                "status": {
                    "privacyStatus": "private",
                },
            },
        ).execute()
    except HttpError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    playlist_id = resp["id"]
    result = {
        "id":    playlist_id,
        "title": resp["snippet"]["title"],
        "url":   f"https://www.youtube.com/playlist?list={playlist_id}",
    }
    print(json.dumps(result, indent=2))


def cmd_add(youtube, args):
    """Add videos to a playlist. Prints a summary of inserted items."""
    video_ids = [v.strip() for v in args.video_ids.split(",") if v.strip()]
    if not video_ids:
        print("ERROR: no video IDs provided", file=sys.stderr)
        sys.exit(1)

    added = []
    errors = []
    for vid_id in video_ids:
        try:
            youtube.playlistItems().insert(
                part="snippet",
                body={
                    "snippet": {
                        "playlistId": args.playlist_id,
                        "resourceId": {
                            "kind":    "youtube#video",
                            "videoId": vid_id,
                        },
                    },
                },
            ).execute()
            added.append(vid_id)
        except HttpError as e:
            errors.append({"id": vid_id, "error": str(e)})

    result = {
        "playlist_id":  args.playlist_id,
        "playlist_url": f"https://www.youtube.com/playlist?list={args.playlist_id}",
        "added":        added,
        "added_count":  len(added),
        "errors":       errors,
    }
    print(json.dumps(result, indent=2))


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="YouTube Data API v3 wrapper for yt-curator Claude skill"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # search
    p_search = sub.add_parser("search", help="Search YouTube and return filtered video list")
    p_search.add_argument("--query",        required=True, help="Search query string")
    p_search.add_argument("--max",          type=int, default=50,   help="Max results (default 50)")
    p_search.add_argument("--min-views",    type=int, default=1000, help="Min view count (default 1000)")
    p_search.add_argument("--max-days",     type=int, default=1095, help="Max age in days (default 1095 = 3yr)")
    p_search.add_argument("--min-duration", type=float, default=4,  help="Min duration in minutes (default 4)")
    p_search.add_argument("--max-duration", type=float, default=45, help="Max duration in minutes (default 45)")

    # playlists
    sub.add_parser("playlists", help="List user's playlists (id + title)")

    # create
    p_create = sub.add_parser("create", help="Create a new private playlist")
    p_create.add_argument("--title",       required=True, help="Playlist title")
    p_create.add_argument("--description", default="",   help="Playlist description")

    # add
    p_add = sub.add_parser("add", help="Add videos to an existing playlist")
    p_add.add_argument("--playlist-id", required=True, help="Target playlist ID")
    p_add.add_argument("--video-ids",   required=True,
                       help="Comma-separated video IDs to add")

    # auth (first-time only)
    sub.add_parser("auth", help="First-time OAuth setup (opens browser)")

    args = parser.parse_args()

    # auth doesn't need an existing token
    if args.command == "auth":
        cmd_auth(args)
        return

    youtube = get_authenticated_service()

    dispatch = {
        "search":    cmd_search,
        "playlists": cmd_playlists,
        "create":    cmd_create,
        "add":       cmd_add,
    }
    dispatch[args.command](youtube, args)


if __name__ == "__main__":
    main()
