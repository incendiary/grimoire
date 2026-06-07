#!/usr/bin/env python3
"""
update_roadmap.py
Parses closed GitHub issues and proposes checkbox diffs for README roadmap items.
Matches issue titles against unchecked roadmap items by keyword overlap and prints
a proposed diff — it never writes to disk without --apply.

Requires: gh CLI authenticated, run from inside the git repo.

Usage:
    python update_roadmap.py
    python update_roadmap.py --readme PATH/README.md
    python update_roadmap.py --limit 50        # how many closed issues to fetch
    python update_roadmap.py --apply           # write changes to disk
    python update_roadmap.py --dry-run         # default; print only
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def fetch_closed_issues(limit: int) -> list[dict]:
    """Return list of closed issues [{number, title, body}] via gh CLI."""
    try:
        result = subprocess.run(
            ["gh", "issue", "list", "--state", "closed", "--limit", str(limit),
             "--json", "number,title,body"],
            capture_output=True, text=True, check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] gh issue list failed: {e.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("[ERROR] gh CLI not found — install it and authenticate first.", file=sys.stderr)
        sys.exit(1)


def load_readme(path: Path) -> list[str]:
    if not path.exists():
        print(f"[ERROR] README not found: {path}", file=sys.stderr)
        sys.exit(1)
    return path.read_text().splitlines(keepends=True)


def extract_unchecked(lines: list[str]) -> list[tuple[int, str]]:
    """Return list of (line_index, item_text) for unchecked roadmap items."""
    items = []
    for i, line in enumerate(lines):
        m = re.match(r"^(\s*-\s\[ \]\s+)(.+)", line.rstrip())
        if m:
            items.append((i, m.group(2).strip()))
    return items


def keyword_match_score(issue_title: str, roadmap_item: str) -> int:
    """Simple keyword overlap score (case-insensitive)."""
    stop = {"a", "an", "the", "to", "in", "for", "of", "and", "or", "with", "on", "is", "are"}
    t_words = {w.lower() for w in re.split(r"\W+", issue_title) if len(w) > 2} - stop
    r_words = {w.lower() for w in re.split(r"\W+", roadmap_item) if len(w) > 2} - stop
    return len(t_words & r_words)


def main() -> None:
    parser = argparse.ArgumentParser(description="Propose roadmap checkbox diffs from closed issues.")
    parser.add_argument("--readme", default="README.md", help="Path to README file")
    parser.add_argument("--limit", type=int, default=30, help="Max closed issues to fetch")
    parser.add_argument("--min-score", type=int, default=1, help="Min keyword overlap score to match")
    parser.add_argument("--apply", action="store_true", help="Write changes to disk")
    parser.add_argument("--dry-run", action="store_false", dest="apply", help="Print only (default)")
    args = parser.parse_args()

    readme_path = Path(args.readme)
    lines = load_readme(readme_path)
    unchecked = extract_unchecked(lines)

    if not unchecked:
        print("No unchecked roadmap items found.")
        return

    issues = fetch_closed_issues(args.limit)
    if not issues:
        print("No closed issues found.")
        return

    print(f"=== update-roadmap ===")
    print(f"  README        : {readme_path}")
    print(f"  Closed issues : {len(issues)}")
    print(f"  Unchecked items: {len(unchecked)}")
    print("")

    proposed: list[tuple[int, str]] = []  # (line_index, matched_issue_title)

    for line_idx, item_text in unchecked:
        best_score = 0
        best_issue = None
        for issue in issues:
            score = keyword_match_score(issue["title"], item_text)
            if score > best_score:
                best_score = score
                best_issue = issue
        if best_issue and best_score >= args.min_score:
            proposed.append((line_idx, best_issue["title"], best_issue["number"]))

    if not proposed:
        print("  No confident matches found between closed issues and roadmap items.")
        print("  Try --min-score 1 (default) or review manually.")
        return

    print("--- Proposed changes ---")
    new_lines = list(lines)
    for line_idx, issue_title, issue_number in proposed:
        old_line = lines[line_idx].rstrip()
        new_line = old_line.replace("- [ ]", "- [x]", 1)
        new_lines[line_idx] = new_line + "\n"
        print(f"  Line {line_idx + 1}: matched issue #{issue_number} '{issue_title}'")
        print(f"    - {old_line.strip()}")
        print(f"    + {new_line.strip()}")
        print("")

    if args.apply:
        readme_path.write_text("".join(new_lines))
        print(f"  [DONE] {len(proposed)} item(s) ticked in {readme_path}")
        print(f"  Review the changes, then: git add {readme_path} && git commit -m 'docs: roadmap sync'")
    else:
        print(f"  {len(proposed)} item(s) would be ticked (dry run — pass --apply to write).")

    print("")
    print("=== update-roadmap complete ===")


if __name__ == "__main__":
    main()
