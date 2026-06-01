#!/usr/bin/env python3
"""
generate_stubs.py

Reads the JSON output from extract_patterns.py and writes SKILL.md stubs
into the configured output directory. Each stub is a draft for the user
to review and promote to ~/.claude/skills/ when ready.

Usage:
    python3 extract_patterns.py | python3 generate_stubs.py
    python3 generate_stubs.py --input patterns.json --output-dir ~/.claude/proposed-skills
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime

STUB_TEMPLATE = """\
# {skill_name}

> **Status:** PROPOSED — review before promoting to ~/.claude/skills/
> **Generated:** {date}
> **Source pattern:** {pattern_type} (detected {count}x in session)

## Description
{purpose}

Invoke when: <!-- TODO: fill in specific trigger conditions -->

## Context needed
{context_items}

## What to do
<!-- TODO: expand with specific instructions based on your actual workflow -->

1. Load this skill at the start of any session where the following apply:
{context_items}

2. Apply these constraints throughout:
<!-- TODO: list the specific rules this skill enforces -->

## Gotchas
{gotchas}

## Suggested scripts
{scripts}

## Evidence from originating session
The following patterns triggered this stub:
{evidence}

## Promotion checklist
Before moving to ~/.claude/skills/{skill_name}/:
- [ ] Expand "What to do" with specific, tested instructions
- [ ] Fill in the trigger description so Claude knows when to invoke this
- [ ] Add a config.json if this skill needs user-provided settings
- [ ] Add any scripts referenced above
- [ ] Test on one real session before sharing
"""


def format_list(items: list[str], bullet: str = "- ") -> str:
    if not items:
        return f"{bullet}<!-- TODO -->"
    return "\n".join(f"{bullet}{item}" for item in items)


def slugify(name: str) -> str:
    """Ensure skill name is valid kebab-case."""
    return name.lower().replace(" ", "-").replace("_", "-")


def write_stub(pattern: dict, output_dir: Path) -> Path:
    skill_name = slugify(pattern.get("proposed_skill_name", "unnamed-skill"))
    skill_dir = output_dir / skill_name
    skill_dir.mkdir(parents=True, exist_ok=True)

    stub_path = skill_dir / "SKILL.md"
    # Don't overwrite an existing stub that's been manually edited
    if stub_path.exists():
        existing = stub_path.read_text()
        if "Status:** PROPOSED" not in existing:
            print(f"  SKIP: {stub_path} exists and appears manually edited.", file=sys.stderr)
            return stub_path

    content = STUB_TEMPLATE.format(
        skill_name=skill_name,
        date=datetime.now().strftime("%Y-%m-%d"),
        pattern_type=pattern.get("type", "unknown"),
        count=pattern.get("count", "?"),
        purpose=pattern.get("proposed_skill_purpose", "<!-- TODO: describe what this skill prevents -->"),
        context_items=format_list(pattern.get("context_needed", [])),
        gotchas=format_list(pattern.get("gotchas", ["None identified yet — add as you encounter them"])),
        scripts=format_list(
            [f"`{s}`" for s in pattern.get("suggested_scripts", [])],
            bullet="- "
        ) if pattern.get("suggested_scripts") else "- None suggested — add scripts as patterns become clear",
        evidence=format_list(
            [f'"{e}"' for e in pattern.get("evidence", [])],
            bullet="- "
        ),
    )

    stub_path.write_text(content)
    return stub_path


def write_session_summary(result: dict, output_dir: Path):
    """Write a top-level summary of the session analysis."""
    stats = result.get("session_stats", {})
    patterns = result.get("patterns", [])
    low_conf = result.get("low_confidence", [])

    lines = [
        f"# Session Skill Extraction Summary",
        f"",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"",
        f"## Session stats",
        f"- Turns: {stats.get('turns', '?')}",
        f"- Project: {stats.get('dominant_project', 'unknown')}",
        f"- Themes: {', '.join(stats.get('session_themes', [])) or 'none identified'}",
        f"",
        f"## Patterns above threshold ({len(patterns)} stubs generated)",
    ]
    for p in patterns:
        lines.append(f"- `{p.get('proposed_skill_name', '?')}` ({p.get('type', '?')}, {p.get('count', '?')}x): {p.get('summary', '')}")

    lines += ["", f"## Low confidence (occurred once, no stub generated)"]
    if low_conf:
        for l in low_conf:
            lines.append(f"- [{l.get('type', '?')}] {l.get('summary', '')}")
    else:
        lines.append("- None")

    lines += ["", "## Next steps", "1. Review each stub in this directory", "2. Expand TODO sections", "3. Promote to ~/.claude/skills/<name>/ when ready"]

    summary_path = output_dir / "_extraction-summary.md"
    summary_path.write_text("\n".join(lines))
    return summary_path


def main():
    parser = argparse.ArgumentParser(description="Generate SKILL.md stubs from detected patterns")
    parser.add_argument("--input", type=Path, help="JSON input file (default: stdin)")
    parser.add_argument("--output-dir", type=Path,
                        default=Path.home() / ".claude" / "proposed-skills",
                        help="Directory to write stubs into")
    args = parser.parse_args()

    if args.input:
        with args.input.open() as f:
            result = json.load(f)
    else:
        result = json.load(sys.stdin)

    output_dir = args.output_dir.expanduser()
    output_dir.mkdir(parents=True, exist_ok=True)

    patterns = result.get("patterns", [])
    if not patterns:
        print("No patterns above threshold. Nothing to generate.", file=sys.stderr)
        summary = write_session_summary(result, output_dir)
        print(f"Summary written to: {summary}")
        sys.exit(0)

    print(f"Generating {len(patterns)} stub(s) in {output_dir}", file=sys.stderr)

    for pattern in patterns:
        stub_path = write_stub(pattern, output_dir)
        print(f"  WROTE: {stub_path}")

    summary_path = write_session_summary(result, output_dir)
    print(f"  SUMMARY: {summary_path}")


if __name__ == "__main__":
    main()
