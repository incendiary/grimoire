#!/usr/bin/env python3
"""Report grimoire skill usage from Claude Code transcripts and MCP server logs.

Read-only. Stdlib only. Needs no hooks and no settings changes.

Sources:
  skill-tool  Skill tool_use blocks in Claude Code transcripts
  slash       <command-name>/<name></command-name> in transcript text
  mcp         "[tool-call] Executing: <name>" lines in the MCP server log (transcript
              mcp__grimoire__ calls are not counted: the log already records them)
"""

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

HOOK_DRIVEN = {"session-skill-extractor"}
LOG_RE = re.compile(r"^\[([^\]]+)\].*\[tool-call\] Executing: (\S+)")
SLASH_RE = re.compile(r"<command-name>/([^<\s]+)</command-name>")
SOURCES = ("skill-tool", "slash", "mcp")


def parse_ts(value):
    if not isinstance(value, str):
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def file_ts(path):
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc)


def load_current(repo):
    clusters = repo / "clusters"
    if not clusters.is_dir():
        return set()
    return {
        skill.name
        for cluster in clusters.iterdir()
        if cluster.is_dir()
        for skill in cluster.iterdir()
        if skill.is_dir()
    }


def load_renames(repo):
    mapping = {}
    path = repo / "scripts" / "renamed-skills.txt"
    if not path.exists():
        return mapping
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) == 2 and parts[0].strip():
            mapping[parts[0].strip()] = parts[1].strip()
    return mapping


class Usage:
    def __init__(self, current, renames):
        self.current = current
        self.renames = renames
        self.stats = {
            name: {**{s: 0 for s in SOURCES}, "last": None} for name in current
        }
        self.first = None
        self.last = None

    def note(self, when):
        if when is None:
            return
        if self.first is None or when < self.first:
            self.first = when
        if self.last is None or when > self.last:
            self.last = when

    def resolve(self, name):
        seen = set()
        while name not in self.current and name in self.renames and name not in seen:
            seen.add(name)
            name = self.renames[name]
            if name == "-":
                return None
        return name if name in self.current else None

    def record(self, raw_name, source, when):
        name = self.resolve(raw_name)
        if name is None:
            return
        entry = self.stats[name]
        entry[source] += 1
        if when and (entry["last"] is None or when > entry["last"]):
            entry["last"] = when

    def scan_transcript(self, path):
        fallback = file_ts(path)
        with path.open(encoding="utf-8", errors="replace") as fh:
            for line in fh:
                try:
                    obj = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(obj, dict):
                    continue
                when = parse_ts(obj.get("timestamp")) or fallback
                self.note(when)
                message = obj.get("message")
                content = message.get("content") if isinstance(message, dict) else None
                texts = [content] if isinstance(content, str) else []
                for block in content if isinstance(content, list) else []:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "tool_use":
                        self._tool_use(block, when)
                    elif block.get("type") == "text" and isinstance(block.get("text"), str):
                        texts.append(block["text"])
                for text in texts:
                    for name in SLASH_RE.findall(text):
                        self.record(name, "slash", when)

    def _tool_use(self, block, when):
        name = block.get("name")
        tool_input = block.get("input")
        if name == "Skill" and isinstance(tool_input, dict) and tool_input.get("skill"):
            self.record(str(tool_input["skill"]), "skill-tool", when)

    def scan_log(self, path):
        fallback = file_ts(path)
        with path.open(encoding="utf-8", errors="replace") as fh:
            for line in fh:
                match = LOG_RE.match(line)
                if not match:
                    continue
                when = parse_ts(match.group(1)) or fallback
                self.note(when)
                self.record(match.group(2), "mcp", when)


def fmt_date(when):
    return when.date().isoformat() if when else "-"


def print_report(usage):
    if usage.first is None:
        print("Coverage: no events found")
    else:
        print(f"Coverage: {fmt_date(usage.first)} to {fmt_date(usage.last)}")
    print()

    rows = []
    for name, entry in usage.stats.items():
        total = sum(entry[s] for s in SOURCES)
        if total:
            rows.append((total, name, entry))
    rows.sort(key=lambda row: (-row[0], row[1]))

    print(f"{'skill':<36}{'total':>6}{'skill-tool':>12}{'slash':>7}{'mcp':>6}  last used")
    for total, name, entry in rows:
        print(
            f"{name:<36}{total:>6}{entry['skill-tool']:>12}{entry['slash']:>7}"
            f"{entry['mcp']:>6}  {fmt_date(entry['last'])}"
        )
    print()

    used = {name for _, name, _ in rows}
    never = sorted(n for n in usage.stats if n not in used and n not in HOOK_DRIVEN)
    print("Never used:")
    for name in never:
        print(f"  {name}")
    print()

    print("Hook-driven (not counted):")
    for name in sorted(HOOK_DRIVEN & set(usage.stats)):
        print(f"  {name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument(
        "--projects",
        action="append",
        type=Path,
        help="Claude Code projects dir (repeatable; default ~/.claude/projects)",
    )
    parser.add_argument(
        "--mcp-log",
        action="append",
        type=Path,
        help="MCP server log file (repeatable; default mcp-server/logs/mcp-server.log)",
    )
    parser.add_argument(
        "--repo",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="repo root (default: parent of scripts/)",
    )
    args = parser.parse_args()

    repo = args.repo.resolve()
    projects = args.projects or [Path.home() / ".claude" / "projects"]
    logs = args.mcp_log
    if logs is None:
        default_log = repo / "mcp-server" / "logs" / "mcp-server.log"
        logs = [default_log] if default_log.exists() else []

    usage = Usage(load_current(repo), load_renames(repo))

    for root in projects:
        if not root.is_dir():
            print(f"warning: projects dir not found: {root}", file=sys.stderr)
            continue
        for path in sorted(root.rglob("*.jsonl")):
            usage.scan_transcript(path)

    for path in logs:
        if not path.is_file():
            print(f"warning: MCP log not found: {path}", file=sys.stderr)
            continue
        usage.scan_log(path)

    print_report(usage)


if __name__ == "__main__":
    main()
