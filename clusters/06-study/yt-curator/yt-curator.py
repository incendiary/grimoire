#!/usr/bin/env python3
"""
yt-curator.py
Comprehensive YouTube CLI for the yt-curator Claude Code skill.
Covers two use cases:

  CURATION  — search public YouTube and build private playlists from study notes
  MANAGEMENT — manage your own channel (videos, upload, stats, metadata)

Claude is the intelligence layer for curation; management commands run directly.

Usage:
  Curation:
    python yt-curator.py auth
    python yt-curator.py search       --query TEXT [--max N] [--min-views N] [--max-days N]
                                      [--min-duration N] [--max-duration N]
    python yt-curator.py playlists    [--json]
    python yt-curator.py create       --title TEXT [--description TEXT]
    python yt-curator.py add          --playlist-id ID --video-ids id1,id2,...
    python yt-curator.py copy-playlist --url URL --playlist-id ID

  Channel management:
    python yt-curator.py videos       [--limit N] [--json]
    python yt-curator.py video-get    --video-id ID [--json]
    python yt-curator.py upload       --file PATH --title TEXT [--privacy private|unlisted|public]
                                      [--description TEXT] [--tags tag1,tag2] [--thumbnail PATH]
                                      [--playlist ID] [--publish-at ISO8601] [--json]
    python yt-curator.py video-update --video-id ID [--title TEXT] [--description TEXT]
                                      [--tags TAG,...] [--privacy STATUS] [--thumbnail PATH] [--json]
    python yt-curator.py video-delete --video-id ID --confirm
    python yt-curator.py stats        [--video-id ID] [--json]

Auth:
  Token:       ~/.youtube-cli-token.json  (shared across all YouTube tools)
  Credentials: YOUTUBE_CLIENT_ID + YOUTUBE_CLIENT_SECRET in .env (first-time auth only)

  If you have already run any YouTube tool's 'auth' command, you're already set up.

Requires:
  pip install google-api-python-client google-auth-oauthlib isodate python-dotenv
"""

from __future__ import annotations

import argparse
import http.client
import json
import os
import random
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from urllib.parse import parse_qs, urlparse

try:
    import isodate
    from dotenv import load_dotenv
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from googleapiclient.http import MediaFileUpload
except ImportError as e:
    print(f"ERROR: missing dependency — {e}", file=sys.stderr)
    print("Run: pip install google-api-python-client google-auth-oauthlib isodate python-dotenv",
          file=sys.stderr)
    sys.exit(1)

# ── Constants ─────────────────────────────────────────────────────────────────
TOKEN_PATH     = Path.home() / ".youtube-cli-token.json"
SCOPES         = ["https://www.googleapis.com/auth/youtube"]
MAX_RETRIES    = 10
RETRIABLE_CODES = (500, 502, 503, 504)
CHUNK_SIZE     = 256 * 1024 * 50   # ~12.5 MB

# Load .env from skill dir (CLIENT_ID + CLIENT_SECRET for first-time auth)
_skill_dir = Path(__file__).parent
load_dotenv(_skill_dir / ".env")

# ── Auth ──────────────────────────────────────────────────────────────────────

def get_service():
    """Return an authenticated YouTube service. Token must already exist."""
    if not TOKEN_PATH.exists():
        print(f"ERROR: No token at {TOKEN_PATH}", file=sys.stderr)
        print("  Run: python yt-curator.py auth", file=sys.stderr)
        sys.exit(1)
    creds = Credentials.from_authorized_user_file(str(TOKEN_PATH), SCOPES)
    if not creds.valid:
        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            TOKEN_PATH.write_text(creds.to_json())
        else:
            print("ERROR: Token invalid. Run: python yt-curator.py auth", file=sys.stderr)
            sys.exit(1)
    return build("youtube", "v3", credentials=creds)


def cmd_auth(_args):
    """First-time OAuth setup. Opens browser; saves token to ~/.youtube-cli-token.json."""
    client_id     = os.getenv("YOUTUBE_CLIENT_ID", "")
    client_secret = os.getenv("YOUTUBE_CLIENT_SECRET", "")
    if not client_id or not client_secret:
        print("ERROR: YOUTUBE_CLIENT_ID and YOUTUBE_CLIENT_SECRET not set.", file=sys.stderr)
        print(f"  Create .env in {_skill_dir}/ with those values.", file=sys.stderr)
        sys.exit(1)
    flow = InstalledAppFlow.from_client_config(
        {"installed": {
            "client_id": client_id, "client_secret": client_secret,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "redirect_uris": ["http://localhost"],
        }}, SCOPES
    )
    creds = flow.run_local_server(port=8080, prompt="consent", access_type="offline",
                                  open_browser=False)
    TOKEN_PATH.write_text(creds.to_json())
    print(f"Authentication successful. Token saved to {TOKEN_PATH}")


# ── Shared helpers ────────────────────────────────────────────────────────────

def handle_api_error(e: HttpError) -> None:
    try:
        body   = json.loads(e.content.decode("utf-8"))
        errors = body.get("error", {}).get("errors", [])
        reason = errors[0].get("reason", "") if errors else ""
        msg    = body.get("error", {}).get("message", str(e))
    except Exception:
        reason, msg = "", str(e)
    if reason == "quotaExceeded":
        print("ERROR: YouTube API quota exceeded.", file=sys.stderr)
    elif reason == "youtubeSignupRequired":
        print("ERROR: Authenticated account has no YouTube channel.", file=sys.stderr)
    else:
        print(f"ERROR: YouTube API ({e.resp.status}): {msg}", file=sys.stderr)
    sys.exit(1)


def resumable_upload(insert_request):
    """Retry-safe resumable upload. Returns the API response."""
    response = error = None
    retry = 0
    while response is None:
        try:
            _, response = insert_request.next_chunk()
        except HttpError as e:
            if e.resp.status in RETRIABLE_CODES:
                error = f"Retriable HTTP error {e.resp.status}"
            else:
                raise
        except (http.client.HTTPException, OSError) as e:
            error = f"Retriable error: {e}"
        if error:
            retry += 1
            if retry > MAX_RETRIES:
                print("ERROR: Max upload retries exceeded.", file=sys.stderr)
                sys.exit(1)
            sleep = random.random() * (2 ** retry)
            print(f"  Sleeping {sleep:.1f}s before retry {retry}/{MAX_RETRIES}...",
                  file=sys.stderr)
            time.sleep(sleep)
            error = None
    return response


def iso_duration_to_minutes(iso: str) -> float:
    try:
        return isodate.parse_duration(iso).total_seconds() / 60
    except Exception:
        return 0.0


def published_days_ago(published_at: str) -> int:
    try:
        dt = datetime.fromisoformat(published_at.replace("Z", "+00:00"))
        return (datetime.now(timezone.utc) - dt).days
    except Exception:
        return 9999


def parse_url(url: str) -> tuple[str, str]:
    """Parse a YouTube URL → ('video', id) | ('playlist', id) | ('skip', url)."""
    parsed = urlparse(url)
    qs = parse_qs(parsed.query)
    if "list" in qs and "v" not in qs:
        return "playlist", qs["list"][0]
    if "v" in qs:
        return "video", qs["v"][0]
    return "skip", url


def get_playlist_video_ids(youtube, playlist_id: str) -> list[str]:
    """Fetch all video IDs from a playlist (handles pagination)."""
    ids, page_token = [], None
    while True:
        kwargs: dict = dict(part="contentDetails", playlistId=playlist_id, maxResults=50)
        if page_token:
            kwargs["pageToken"] = page_token
        try:
            resp = youtube.playlistItems().list(**kwargs).execute()
        except HttpError as e:
            print(f"  WARNING: Could not fetch playlist {playlist_id} "
                  f"(private or unavailable): {e.resp.status}", file=sys.stderr)
            return ids
        for item in resp.get("items", []):
            vid = item["contentDetails"].get("videoId")
            if vid:
                ids.append(vid)
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return ids


# ── Curation commands ─────────────────────────────────────────────────────────

def cmd_search(youtube, args):
    """Search public YouTube; print filtered results as JSON."""
    cutoff = (datetime.now(timezone.utc) - timedelta(days=args.max_days)).isoformat()
    try:
        search_resp = youtube.search().list(
            part="id,snippet", q=args.query, type="video",
            maxResults=args.max, order="relevance", publishedAfter=cutoff,
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    video_ids = [item["id"]["videoId"] for item in search_resp.get("items", [])]
    if not video_ids:
        print("[]")
        return

    try:
        details = youtube.videos().list(
            part="snippet,statistics,contentDetails", id=",".join(video_ids),
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    results = []
    for item in details.get("items", []):
        snippet      = item.get("snippet", {})
        stats        = item.get("statistics", {})
        content      = item.get("contentDetails", {})
        duration_min = iso_duration_to_minutes(content.get("duration", "PT0S"))
        view_count   = int(stats.get("viewCount", 0))
        days_ago     = published_days_ago(snippet.get("publishedAt", ""))

        if view_count < args.min_views:
            continue
        if not (args.min_duration <= duration_min <= args.max_duration):
            continue
        if days_ago > args.max_days:
            continue

        results.append({
            "id":           item["id"],
            "title":        snippet.get("title", ""),
            "description":  snippet.get("description", "")[:400],
            "channel":      snippet.get("channelTitle", ""),
            "published_at": snippet.get("publishedAt", ""),
            "days_ago":     days_ago,
            "view_count":   view_count,
            "duration_min": round(duration_min, 1),
            "url":          f"https://www.youtube.com/watch?v={item['id']}",
        })
    print(json.dumps(results, indent=2))


def cmd_playlists(youtube, args):
    """List the user's playlists."""
    try:
        resp = youtube.playlists().list(
            part="snippet,contentDetails", mine=True, maxResults=50,
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    items = resp.get("items", [])
    if args.json:
        output = [
            {"id": pl["id"], "title": pl["snippet"]["title"],
             "video_count": pl["contentDetails"].get("itemCount", 0)}
            for pl in items
        ]
        print(json.dumps(output, indent=2))
    else:
        print(f"{'Title':<50} {'Videos':<8} {'ID'}")
        print("-" * 90)
        for pl in items:
            t = pl["snippet"]["title"]
            t = (t[:48] + "..") if len(t) > 50 else t
            print(f"{t:<50} {pl['contentDetails'].get('itemCount', 0):<8} {pl['id']}")
        print(f"\n{len(items)} playlist(s).")


def cmd_create(youtube, args):
    """Create a new private playlist."""
    try:
        resp = youtube.playlists().insert(
            part="snippet,status",
            body={
                "snippet": {"title": args.title, "description": args.description or ""},
                "status":  {"privacyStatus": "private"},
            },
        ).execute()
    except HttpError as e:
        handle_api_error(e)
    pid = resp["id"]
    print(json.dumps({
        "id": pid, "title": resp["snippet"]["title"],
        "url": f"https://www.youtube.com/playlist?list={pid}",
    }, indent=2))


def cmd_add(youtube, args):
    """Add video IDs to an existing playlist."""
    video_ids = [v.strip() for v in args.video_ids.split(",") if v.strip()]
    added, errors = [], []
    for vid in video_ids:
        try:
            youtube.playlistItems().insert(
                part="snippet",
                body={"snippet": {
                    "playlistId": args.playlist_id,
                    "resourceId": {"kind": "youtube#video", "videoId": vid},
                }},
            ).execute()
            added.append(vid)
        except HttpError as e:
            errors.append({"id": vid, "error": str(e)})
    print(json.dumps({
        "playlist_id": args.playlist_id,
        "playlist_url": f"https://www.youtube.com/playlist?list={args.playlist_id}",
        "added_count": len(added), "added": added, "errors": errors,
    }, indent=2))


def cmd_copy_playlist(youtube, args):
    """Copy all videos from a source URL into an existing target playlist."""
    kind, ref = parse_url(args.url)
    if kind == "video":
        video_ids = [ref]
    elif kind == "playlist":
        print(f"Fetching videos from source playlist {ref}...", file=sys.stderr)
        video_ids = get_playlist_video_ids(youtube, ref)
        print(f"Found {len(video_ids)} video(s).", file=sys.stderr)
    else:
        print(f"ERROR: Could not parse URL: {args.url}", file=sys.stderr)
        sys.exit(1)

    if not video_ids:
        print("No videos to add.", file=sys.stderr)
        return

    # Reuse cmd_add logic
    class _AddArgs:
        playlist_id = args.playlist_id
        video_ids = ",".join(video_ids)

    cmd_add(youtube, _AddArgs())


# ── Channel management commands ───────────────────────────────────────────────

def cmd_videos(youtube, args):
    """List own channel's recent videos."""
    try:
        search_resp = youtube.search().list(
            part="snippet", forMine=True, type="video",
            maxResults=args.limit, order="date",
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    vids = [item["id"]["videoId"] for item in search_resp.get("items", [])]
    if not vids:
        print("No videos found.")
        return

    try:
        details = youtube.videos().list(
            part="snippet,contentDetails,statistics,status", id=",".join(vids),
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    items = details.get("items", [])
    if args.json:
        print(json.dumps([{
            "video_id":    v["id"],
            "title":       v["snippet"].get("title", ""),
            "published_at":v["snippet"].get("publishedAt", ""),
            "privacy":     v["status"].get("privacyStatus", ""),
            "duration":    v["contentDetails"].get("duration", ""),
            "view_count":  v["statistics"].get("viewCount", "0"),
            "url":         f"https://youtu.be/{v['id']}",
        } for v in items], indent=2))
    else:
        print(f"{'Title':<55} {'Privacy':<10} {'Views':<8} {'Published':<12} ID")
        print("-" * 115)
        for v in items:
            t = v["snippet"].get("title", "")
            t = (t[:51] + "..") if len(t) > 53 else t
            print(f"{t:<55} {v['status'].get('privacyStatus', ''):<10} "
                  f"{v['statistics'].get('viewCount', '0'):<8} "
                  f"{v['snippet'].get('publishedAt', '')[:10]:<12} {v['id']}")
        print(f"\n{len(items)} video(s).")


def cmd_video_get(youtube, args):
    """Get full details of a single video."""
    try:
        resp = youtube.videos().list(
            part="snippet,contentDetails,statistics,status", id=args.video_id,
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    items = resp.get("items", [])
    if not items:
        print(f"ERROR: Video '{args.video_id}' not found.", file=sys.stderr)
        sys.exit(1)

    v = items[0]
    if args.json:
        print(json.dumps(v, indent=2))
    else:
        s = v["snippet"]
        st = v["status"]
        stats = v["statistics"]
        cd = v["contentDetails"]
        print(f"Title:     {s.get('title', '')}")
        print(f"ID:        {v['id']}  →  https://youtu.be/{v['id']}")
        print(f"Channel:   {s.get('channelTitle', '')}")
        print(f"Published: {s.get('publishedAt', '')}")
        print(f"Privacy:   {st.get('privacyStatus', '')}")
        print(f"Duration:  {cd.get('duration', '')}")
        print(f"Views:     {stats.get('viewCount', '0')}")
        print(f"Likes:     {stats.get('likeCount', '0')}")
        desc = s.get("description", "")
        if desc:
            print(f"Desc:      {desc[:300]}{'...' if len(desc) > 300 else ''}")


def cmd_upload(youtube, args):
    """Upload a video file with metadata."""
    filepath = os.path.expanduser(args.file)
    if not os.path.exists(filepath):
        print(f"ERROR: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    tags = [t.strip() for t in args.tags.split(",") if t.strip()] if args.tags else []
    body: dict = {
        "snippet": {
            "title": args.title,
            "description": args.description or "",
            "tags": tags,
            "categoryId": str(args.category),
        },
        "status": {"privacyStatus": args.privacy, "selfDeclaredMadeForKids": False},
    }
    if args.publish_at:
        body["status"]["privacyStatus"] = "private"
        body["status"]["publishAt"] = args.publish_at

    size_mb = os.path.getsize(filepath) / 1024 / 1024
    print(f"Uploading: {os.path.basename(filepath)} ({size_mb:.1f} MB) → {args.title}",
          file=sys.stderr)

    try:
        resp = resumable_upload(youtube.videos().insert(
            part="snippet,status", body=body,
            media_body=MediaFileUpload(filepath, mimetype="video/*", resumable=True,
                                       chunksize=CHUNK_SIZE),
        ))
    except HttpError as e:
        handle_api_error(e)

    vid_id = resp.get("id", "")

    if args.thumbnail:
        tp = os.path.expanduser(args.thumbnail)
        if os.path.exists(tp):
            try:
                youtube.thumbnails().set(
                    videoId=vid_id,
                    media_body=MediaFileUpload(tp, mimetype="image/*"),
                ).execute()
                print("  Thumbnail set.", file=sys.stderr)
            except HttpError as e:
                print(f"  WARNING: Thumbnail failed: {e}", file=sys.stderr)

    if args.playlist:
        try:
            youtube.playlistItems().insert(
                part="snippet",
                body={"snippet": {
                    "playlistId": args.playlist,
                    "resourceId": {"kind": "youtube#video", "videoId": vid_id},
                }},
            ).execute()
            print(f"  Added to playlist {args.playlist}.", file=sys.stderr)
        except HttpError as e:
            print(f"  WARNING: Playlist add failed: {e}", file=sys.stderr)

    result = {"video_id": vid_id, "title": args.title,
              "privacy": body["status"]["privacyStatus"],
              "url": f"https://youtu.be/{vid_id}"}
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"\nUploaded: {result['url']}")


def cmd_video_update(youtube, args):
    """Update video metadata (fetches current data first; merges changes)."""
    try:
        resp = youtube.videos().list(
            part="snippet,status", id=args.video_id,
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    items = resp.get("items", [])
    if not items:
        print(f"ERROR: Video '{args.video_id}' not found.", file=sys.stderr)
        sys.exit(1)

    snippet = items[0]["snippet"]
    status  = items[0]["status"]

    if args.title is not None:       snippet["title"] = args.title
    if args.description is not None: snippet["description"] = args.description
    if args.tags is not None:        snippet["tags"] = [t.strip() for t in args.tags.split(",") if t.strip()]
    if args.privacy is not None:     status["privacyStatus"] = args.privacy

    try:
        result = youtube.videos().update(
            part="snippet,status",
            body={"id": args.video_id, "snippet": snippet, "status": status},
        ).execute()
    except HttpError as e:
        handle_api_error(e)

    if args.thumbnail:
        tp = os.path.expanduser(args.thumbnail)
        if os.path.exists(tp):
            try:
                youtube.thumbnails().set(
                    videoId=args.video_id,
                    media_body=MediaFileUpload(tp, mimetype="image/*"),
                ).execute()
            except HttpError as e:
                print(f"WARNING: Thumbnail failed: {e}", file=sys.stderr)

    out = {"video_id": args.video_id,
           "title": result["snippet"].get("title", ""),
           "privacy": result["status"].get("privacyStatus", ""),
           "updated": True}
    if args.json:
        print(json.dumps(out, indent=2))
    else:
        print(f"Updated: {args.video_id} — {out['title']} ({out['privacy']})")


def cmd_video_delete(youtube, args):
    """Delete a video (requires --confirm)."""
    if not args.confirm:
        print("ERROR: --confirm required for delete.", file=sys.stderr)
        sys.exit(1)
    try:
        youtube.videos().delete(id=args.video_id).execute()
    except HttpError as e:
        handle_api_error(e)
    out = {"video_id": args.video_id, "deleted": True}
    if args.json:
        print(json.dumps(out, indent=2))
    else:
        print(f"Deleted: {args.video_id}")


def cmd_stats(youtube, args):
    """Channel stats, or stats for a specific video."""
    if args.video_id:
        try:
            resp = youtube.videos().list(
                part="snippet,statistics", id=args.video_id,
            ).execute()
        except HttpError as e:
            handle_api_error(e)
        items = resp.get("items", [])
        if not items:
            print(f"ERROR: Video '{args.video_id}' not found.", file=sys.stderr)
            sys.exit(1)
        v = items[0]
        stats = v["statistics"]
        if args.json:
            print(json.dumps({"video_id": v["id"],
                               "title": v["snippet"].get("title", ""), **stats}, indent=2))
        else:
            print(f"Video:    {v['snippet'].get('title', '')}")
            print(f"Views:    {stats.get('viewCount', '0')}")
            print(f"Likes:    {stats.get('likeCount', '0')}")
            print(f"Comments: {stats.get('commentCount', '0')}")
    else:
        try:
            resp = youtube.channels().list(
                part="snippet,statistics", mine=True,
            ).execute()
        except HttpError as e:
            handle_api_error(e)
        items = resp.get("items", [])
        if not items:
            print("ERROR: No channel found for this account.", file=sys.stderr)
            sys.exit(1)
        ch = items[0]
        stats = ch["statistics"]
        if args.json:
            print(json.dumps({"channel_id": ch["id"],
                               "title": ch["snippet"].get("title", ""), **stats}, indent=2))
        else:
            print(f"Channel:     {ch['snippet'].get('title', '')}")
            print(f"Subscribers: {stats.get('subscriberCount', '0')}")
            print(f"Views:       {stats.get('viewCount', '0')}")
            print(f"Videos:      {stats.get('videoCount', '0')}")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="yt-curator — YouTube curation + channel management CLI"
    )
    sub = parser.add_subparsers(dest="command", required=True)
    J = {"action": "store_true", "help": "Output as JSON"}

    # auth
    sub.add_parser("auth", help="First-time OAuth setup (opens browser)")

    # ── Curation ──────────────────────────────────────────────────────────────
    p = sub.add_parser("search", help="Search public YouTube")
    p.add_argument("--query",        required=True)
    p.add_argument("--max",          type=int,   default=50)
    p.add_argument("--min-views",    type=int,   default=1000)
    p.add_argument("--max-days",     type=int,   default=1095)
    p.add_argument("--min-duration", type=float, default=4)
    p.add_argument("--max-duration", type=float, default=45)

    p = sub.add_parser("playlists", help="List own playlists")
    p.add_argument("--json", **J)

    p = sub.add_parser("create", help="Create private playlist")
    p.add_argument("--title",       required=True)
    p.add_argument("--description", default="")

    p = sub.add_parser("add", help="Add video IDs to a playlist")
    p.add_argument("--playlist-id", required=True)
    p.add_argument("--video-ids",   required=True, help="Comma-separated video IDs")

    p = sub.add_parser("copy-playlist",
                       help="Copy all videos from a source URL into a target playlist")
    p.add_argument("--url",         required=True, help="Source YouTube playlist or video URL")
    p.add_argument("--playlist-id", required=True, help="Target playlist ID")

    # ── Channel management ────────────────────────────────────────────────────
    p = sub.add_parser("videos", help="List own channel videos")
    p.add_argument("--limit", type=int, default=20)
    p.add_argument("--json", **J)

    p = sub.add_parser("video-get", help="Get video details")
    p.add_argument("--video-id", required=True)
    p.add_argument("--json", **J)

    p = sub.add_parser("upload", help="Upload a video")
    p.add_argument("--file",        required=True)
    p.add_argument("--title",       required=True)
    p.add_argument("--description", default="")
    p.add_argument("--tags",        default="")
    p.add_argument("--category",    type=int, default=22)
    p.add_argument("--privacy",     default="private",
                   choices=["private", "unlisted", "public"])
    p.add_argument("--thumbnail")
    p.add_argument("--playlist",   help="Playlist ID to add video to after upload")
    p.add_argument("--publish-at", help="Scheduled publish time (ISO 8601)")
    p.add_argument("--json", **J)

    p = sub.add_parser("video-update", help="Update video metadata")
    p.add_argument("--video-id",    required=True)
    p.add_argument("--title")
    p.add_argument("--description")
    p.add_argument("--tags")
    p.add_argument("--privacy",     choices=["private", "unlisted", "public"])
    p.add_argument("--thumbnail")
    p.add_argument("--json", **J)

    p = sub.add_parser("video-delete", help="Delete a video (requires --confirm)")
    p.add_argument("--video-id", required=True)
    p.add_argument("--confirm",  action="store_true")
    p.add_argument("--json", **J)

    p = sub.add_parser("stats", help="Channel or video statistics")
    p.add_argument("--video-id")
    p.add_argument("--json", **J)

    args = parser.parse_args()

    if args.command == "auth":
        cmd_auth(args)
        return

    yt = get_service()

    dispatch = {
        "search":        cmd_search,
        "playlists":     cmd_playlists,
        "create":        cmd_create,
        "add":           cmd_add,
        "copy-playlist": cmd_copy_playlist,
        "videos":        cmd_videos,
        "video-get":     cmd_video_get,
        "upload":        cmd_upload,
        "video-update":  cmd_video_update,
        "video-delete":  cmd_video_delete,
        "stats":         cmd_stats,
    }
    dispatch[args.command](yt, args)


if __name__ == "__main__":
    main()
