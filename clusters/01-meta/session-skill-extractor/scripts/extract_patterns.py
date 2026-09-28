#!/usr/bin/env python3
"""
extract_patterns.py

Reads one or more Claude Code session JSONLs, condenses each, then calls the
claude CLI to detect repeated patterns worth extracting as skills. When more
than one session is analysed, patterns are aggregated across sessions:
recurrence across sessions (and concentration within a single project) is a
stronger signal than any one session's pattern count. Pipes structured JSON
to stdout for generate_stubs.py to consume.

Usage:
    python3 extract_patterns.py
    python3 extract_patterns.py --project-dir ~/.claude/projects/<hash>
    python3 extract_patterns.py --session-file <path-to.jsonl>
    python3 extract_patterns.py --sessions 5
    python3 extract_patterns.py | python3 generate_stubs.py
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

# -------------------------------------------------------------------
# Config defaults
# -------------------------------------------------------------------

DEFAULT_CONFIG = {
    "min_turns": 8,
    "min_pattern_count": 2,
    "model": "claude-opus-4-5",
    "tool_result_trim": 500,
    "max_session_chars": 60000,
    # Multi-session aggregation (manual runs only — the Stop hook always
    # passes a single --session-file and ignores this).
    "sessions": 1,
    # Confidence heuristic: base + (per-session weight * sessions the
    # pattern recurred in) + (per-count weight * total count), capped at
    # 1.0. This is a documented heuristic, not a calibrated/validated
    # score — tune the weights in config.json if it over- or
    # under-confidences against your own usage.
    "confidence_base": 0.25,
    "confidence_weight_sessions": 0.15,
    "confidence_weight_count": 0.05,
    "min_confidence": 0.0,
}

DETECTION_PROMPT = """You are analysing a Claude Code session transcript to identify repeated patterns
that suggest a reusable skill should be created. The user works across security, DevOps, and
software development — Python, C++, and C# projects on macOS.

Your job is to find patterns the user had to repeat, correct, or re-explain. You are not
summarising the session. You are identifying inefficiencies that a well-scoped SKILL.md
would prevent.

Pattern types to look for:
1. context_re_explanation: User explained the same architecture, constraint, or convention more than once.
2. correction_loop: Claude made the same class of mistake repeatedly (style, terminology, abstraction level, scope).
3. boilerplate_regeneration: Claude wrote the same scaffolding from scratch that it has likely written before.
4. style_correction: User corrected formatting, tone, British English, em dashes, Oxford comma, etc.
5. unstated_assumption: Claude assumed something the user had to override.

For each pattern found, return a JSON object in this exact schema. Output only valid JSON, no preamble, no markdown fences:

{
  "patterns": [
    {
      "type": "context_re_explanation | correction_loop | boilerplate_regeneration | style_correction | unstated_assumption",
      "count": <int>,
      "summary": "<one sentence>",
      "evidence": ["<short quote or paraphrase>"],
      "proposed_skill_name": "<kebab-case>",
      "proposed_skill_purpose": "<one sentence: what the skill prevents>",
      "context_needed": ["<item>"],
      "suggested_scripts": ["<script description>"],
      "gotchas": ["<known failure mode>"]
    }
  ],
  "low_confidence": [
    {
      "summary": "<pattern that only occurred once>",
      "type": "<type>"
    }
  ],
  "session_stats": {
    "turns": <int>,
    "dominant_project": "<project name if determinable>",
    "session_themes": ["<theme>"]
  }
}"""


# -------------------------------------------------------------------
# Session loading
# -------------------------------------------------------------------

def find_latest_session(projects_base: Path) -> Path | None:
    sessions = find_latest_sessions(projects_base, 1)
    return sessions[0] if sessions else None


def find_latest_sessions(projects_base: Path, n: int) -> list[Path]:
    """Most recent N session files (by mtime) across all projects under projects_base."""
    candidates = []
    for project_dir in projects_base.iterdir():
        if not project_dir.is_dir():
            continue
        for f in project_dir.glob("*.jsonl"):
            candidates.append((f.stat().st_mtime, f))
    candidates.sort(reverse=True)
    return [f for _, f in candidates[:n]]


def load_session(session_file: Path) -> list[dict]:
    entries = []
    with session_file.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return entries


def extract_turns(entries: list[dict], tool_result_trim: int = 500) -> list[dict]:
    """
    Extract human/assistant turns from raw JSONL entries.
    Trims tool results to avoid inflating the transcript size.
    Handles multiple JSONL schemas (Claude Code schema has evolved over versions).
    """
    turns = []

    for entry in entries:
        role = entry.get("role", "")
        entry_type = entry.get("type", "")

        # Schema variant 1: top-level role field with content blocks
        if role in ("user", "assistant"):
            content = entry.get("content", "")
            if isinstance(content, list):
                text_parts = []
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "text":
                        text_parts.append(block.get("text", ""))
                    elif block.get("type") == "tool_result":
                        result = str(block.get("content", ""))
                        text_parts.append(f"[tool_result: {result[:tool_result_trim]}]")
                    elif block.get("type") == "tool_use":
                        name = block.get("name", "")
                        inp = str(block.get("input", ""))[:200]
                        text_parts.append(f"[tool_use: {name} input={inp}]")
                content = "\n".join(text_parts)
            turns.append({"role": role, "text": str(content)[:2000]})

        # Schema variant 2: wrapped message object
        elif entry_type in ("user", "assistant") and "message" in entry:
            msg = entry["message"]
            content = msg.get("content", "")
            if isinstance(content, str):
                turns.append({"role": entry_type, "text": content[:2000]})
            elif isinstance(content, list):
                text_parts = [
                    block.get("text", "")[:1000]
                    for block in content
                    if isinstance(block, dict) and block.get("type") == "text"
                ]
                turns.append({"role": entry_type, "text": "\n".join(text_parts)[:2000]})

    return turns


def condense_transcript(turns: list[dict], max_chars: int = 60000) -> str:
    lines = []
    for t in turns:
        label = "USER" if t["role"] == "user" else "CLAUDE"
        lines.append(f"[{label}]: {t['text']}")
    full = "\n\n".join(lines)
    if len(full) > max_chars:
        third = max_chars // 3
        full = (
            full[:third]
            + "\n\n[... session condensed ...]\n\n"
            + full[-(max_chars - third):]
        )
    return full


# -------------------------------------------------------------------
# Pattern detection via claude CLI
# -------------------------------------------------------------------

def detect_patterns(transcript: str, model: str) -> dict:
    """
    Call the claude CLI with a non-interactive prompt and parse the JSON response.
    Uses the existing Claude Code session credentials - no separate API key needed.
    """
    if not shutil.which("claude"):
        print("ERROR: claude CLI not found in PATH. Is Claude Code installed and in PATH?", file=sys.stderr)
        sys.exit(1)

    full_prompt = f"{DETECTION_PROMPT}\n\nAnalyse this session transcript:\n\n{transcript}"

    try:
        result = subprocess.run(
            ["claude", "-p", full_prompt, "--model", model],
            capture_output=True,
            text=True,
            timeout=120,
        )
    except subprocess.TimeoutExpired:
        print("ERROR: claude CLI timed out after 120s.", file=sys.stderr)
        sys.exit(1)

    if result.returncode != 0:
        print(f"ERROR: claude CLI exited with code {result.returncode}", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)

    raw = result.stdout.strip()

    # Strip any accidental markdown fences the model may have added
    if raw.startswith("```"):
        parts = raw.split("```")
        raw = parts[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()

    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"ERROR: Could not parse model response as JSON: {e}", file=sys.stderr)
        print(f"Raw response:\n{raw}", file=sys.stderr)
        sys.exit(1)


# -------------------------------------------------------------------
# Per-session processing
# -------------------------------------------------------------------

def process_session(session_file: Path, config: dict) -> dict | None:
    """Run detection on one session file. Returns None if the session is too short to analyse."""
    entries = load_session(session_file)
    turns = extract_turns(entries, tool_result_trim=config["tool_result_trim"])

    if len(turns) < config["min_turns"]:
        print(
            f"  SKIP: {session_file} too short ({len(turns)} turns, minimum {config['min_turns']}).",
            file=sys.stderr
        )
        return None

    print(f"  Analysing {session_file} ({len(turns)} turns)...", file=sys.stderr)

    transcript = condense_transcript(turns, max_chars=config["max_session_chars"])
    return detect_patterns(transcript, config["model"])


# -------------------------------------------------------------------
# Multi-session aggregation
# -------------------------------------------------------------------

def _merge_unique(*lists: list[str]) -> list[str]:
    seen = []
    for lst in lists:
        for item in lst:
            if item not in seen:
                seen.append(item)
    return seen


def aggregate_patterns(results: list[dict], config: dict) -> dict:
    """
    Merge per-session detection results into one. Always applied, even for a
    single session, so every code path (including the Stop hook's normal
    single-session run) produces the same schema: patterns gain
    occurring_sessions, distinct_projects, project_concentration and
    confidence fields on top of the original per-session fields.
    """
    patterns_by_name: dict[str, dict] = {}
    low_confidence: list[dict] = []
    total_turns = 0
    project_counter: Counter[str] = Counter()
    themes: list[str] = []

    for result in results:
        stats = result.get("session_stats", {})
        total_turns += stats.get("turns", 0) or 0
        project = stats.get("dominant_project") or "unknown"
        project_counter[project] += 1
        for theme in stats.get("session_themes", []):
            if theme not in themes:
                themes.append(theme)

        for p in result.get("patterns", []):
            key = p.get("proposed_skill_name") or p.get("summary", "unnamed-pattern")
            acc = patterns_by_name.get(key)
            if acc is None:
                acc = {
                    **p,
                    "count": 0,
                    "occurring_sessions": 0,
                    "_project_counter": Counter(),
                }
                patterns_by_name[key] = acc

            acc["count"] += p.get("count", 0)
            acc["occurring_sessions"] += 1
            acc["_project_counter"][project] += 1
            acc["evidence"] = _merge_unique(acc.get("evidence", []), p.get("evidence", []))
            acc["context_needed"] = _merge_unique(acc.get("context_needed", []), p.get("context_needed", []))
            acc["suggested_scripts"] = _merge_unique(acc.get("suggested_scripts", []), p.get("suggested_scripts", []))
            acc["gotchas"] = _merge_unique(acc.get("gotchas", []), p.get("gotchas", []))

        for lc in result.get("low_confidence", []):
            if lc.get("summary") not in [x.get("summary") for x in low_confidence]:
                low_confidence.append(lc)

    patterns = []
    for acc in patterns_by_name.values():
        proj_counter = acc.pop("_project_counter")
        distinct_projects = len(proj_counter)
        most_common_count = proj_counter.most_common(1)[0][1] if proj_counter else 0
        acc["distinct_projects"] = distinct_projects
        acc["project_concentration"] = (
            round(most_common_count / acc["occurring_sessions"], 2)
            if acc["occurring_sessions"] else 0.0
        )
        acc["confidence"] = round(min(
            1.0,
            config["confidence_base"]
            + config["confidence_weight_sessions"] * acc["occurring_sessions"]
            + config["confidence_weight_count"] * acc["count"],
        ), 2)
        patterns.append(acc)

    # Strongest recurrence first: more sessions, then higher count.
    patterns.sort(key=lambda p: (p["occurring_sessions"], p["count"]), reverse=True)

    return {
        "patterns": patterns,
        "low_confidence": low_confidence,
        "session_stats": {
            "sessions_analyzed": len(results),
            "turns": total_turns,
            "dominant_project": project_counter.most_common(1)[0][0] if project_counter else "unknown",
            "session_themes": themes,
        },
    }


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Extract skill patterns from one or more Claude Code sessions using the claude CLI"
    )
    parser.add_argument("--project-dir", type=Path,
                        help="Path to a specific project dir (~/.claude/projects/<hash>)")
    parser.add_argument("--session-file", type=Path,
                        help="Path to a specific JSONL session file (always single-session, ignores --sessions)")
    parser.add_argument("--projects-base", type=Path,
                        default=Path.home() / ".claude" / "projects",
                        help="Base directory for all projects (default: ~/.claude/projects)")
    parser.add_argument("--config", type=Path,
                        default=Path.home() / ".claude" / "skills" / "session-skill-extractor" / "config.json")
    parser.add_argument("--min-turns", type=int,
                        help="Override min_turns from config")
    parser.add_argument("--sessions", type=int,
                        help="Analyse and aggregate the N most recent sessions instead of just one "
                             "(ignored if --session-file is given)")
    args = parser.parse_args()

    # Load config
    config = DEFAULT_CONFIG.copy()
    if args.config.exists():
        with args.config.open() as f:
            config.update(json.load(f))
    if args.min_turns:
        config["min_turns"] = args.min_turns
    if args.sessions:
        config["sessions"] = args.sessions

    # Resolve session file(s)
    if args.session_file:
        session_files = [args.session_file]
    elif args.project_dir:
        session_files = sorted(
            args.project_dir.glob("*.jsonl"),
            key=lambda f: f.stat().st_mtime,
            reverse=True
        )[:config["sessions"]]
    else:
        session_files = find_latest_sessions(args.projects_base, config["sessions"])

    session_files = [f for f in session_files if f.exists()]
    if not session_files:
        print("ERROR: No session file found.", file=sys.stderr)
        sys.exit(1)

    print(f"Analysing {len(session_files)} session(s)...", file=sys.stderr)

    results = []
    for session_file in session_files:
        result = process_session(session_file, config)
        if result is not None:
            results.append(result)

    if not results:
        print("No sessions had enough turns to analyse. Nothing to report.", file=sys.stderr)
        sys.exit(0)

    aggregated = aggregate_patterns(results, config)

    # Filter by min_pattern_count and min_confidence
    aggregated["patterns"] = [
        p for p in aggregated["patterns"]
        if p.get("count", 0) >= config["min_pattern_count"]
        and p.get("confidence", 1.0) >= config["min_confidence"]
    ]

    print(json.dumps(aggregated, indent=2))


if __name__ == "__main__":
    main()
