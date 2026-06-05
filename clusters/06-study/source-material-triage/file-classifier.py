#!/usr/bin/env python3
"""
file-classifier.py
Walks a directory and outputs a file listing with path, size, extension,
and SHA-256 hash. Skips files already recorded in triage-log.json
(incremental run support).

Usage:
    python file-classifier.py <directory>
    python file-classifier.py <directory> --log triage-log.json
    python file-classifier.py <directory> --skip-ext .iso .ova
    python file-classifier.py <directory> --max-size 209715200  # 200 MB in bytes
    python file-classifier.py <directory> --json   # output JSON instead of table
"""

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

DEFAULT_LOG = "triage-log.json"
DEFAULT_MAX_SIZE = 200 * 1024 * 1024  # 200 MB
DEFAULT_SKIP_EXTS = {".iso", ".ova", ".vmdk", ".vhd", ".vhdx"}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_log(log_path: Path) -> dict:
    """Load existing triage-log.json; return dict keyed by relative path."""
    if not log_path.exists():
        return {}
    try:
        with open(log_path) as f:
            entries = json.load(f)
        return {e["path"]: e for e in entries if "path" in e}
    except (json.JSONDecodeError, TypeError):
        print(f"[WARN] Could not parse {log_path} — starting fresh", file=sys.stderr)
        return {}


def save_log(log_path: Path, existing: dict, new_entries: list) -> None:
    """Merge new entries into existing log and write."""
    merged = dict(existing)
    for entry in new_entries:
        merged[entry["path"]] = entry
    with open(log_path, "w") as f:
        json.dump(list(merged.values()), f, indent=2)


def human_size(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} TB"


def classify_file(path: Path, root: Path, skip_exts: set, max_size: int, existing: dict) -> dict | None:
    """Return a file entry dict, or None if the file should be skipped entirely."""
    rel = str(path.relative_to(root))
    ext = path.suffix.lower()
    size = path.stat().st_size

    # Skip by extension
    if ext in skip_exts:
        return {"path": rel, "ext": ext, "size": size, "hash": None, "status": "SKIPPED_EXT"}

    # Skip oversized files
    if size > max_size:
        return {"path": rel, "ext": ext, "size": size, "hash": None, "status": "SKIPPED_SIZE"}

    # Skip if already in log
    if rel in existing:
        return None  # suppress from output — already processed

    file_hash = sha256(path)

    return {
        "path": rel,
        "ext": ext,
        "size": size,
        "hash": file_hash,
        "status": "NEW",
        "decision": "",
        "topic": "",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Walk directory and classify study files.")
    parser.add_argument("directory", help="Root directory to triage")
    parser.add_argument("--log", default=DEFAULT_LOG, help="Path to triage-log.json")
    parser.add_argument("--skip-ext", nargs="*", default=[], metavar="EXT",
                        help="Additional extensions to skip (e.g. .mp4 .zip)")
    parser.add_argument("--max-size", type=int, default=DEFAULT_MAX_SIZE,
                        help="Skip files larger than this size in bytes (default: 200 MB)")
    parser.add_argument("--json", action="store_true", help="Output JSON instead of table")
    args = parser.parse_args()

    root = Path(args.directory).resolve()
    if not root.is_dir():
        print(f"[ERROR] Not a directory: {root}", file=sys.stderr)
        sys.exit(1)

    log_path = Path(args.log)
    skip_exts = DEFAULT_SKIP_EXTS | {e.lower() if e.startswith(".") else f".{e.lower()}"
                                      for e in args.skip_ext}

    existing = load_log(log_path)
    results = []
    skipped_count = 0
    already_logged = 0

    for dirpath, dirnames, filenames in os.walk(root):
        # Skip hidden directories
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for filename in sorted(filenames):
            if filename.startswith("."):
                continue
            path = Path(dirpath) / filename
            try:
                entry = classify_file(path, root, skip_exts, args.max_size, existing)
            except OSError as e:
                print(f"[WARN] Could not read {path}: {e}", file=sys.stderr)
                continue

            if entry is None:
                already_logged += 1
                continue

            results.append(entry)
            if entry["status"].startswith("SKIPPED"):
                skipped_count += 1

    new_entries = [e for e in results if e["status"] == "NEW"]

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        # Table output
        if not results:
            print("No new files found.")
        else:
            col_w = 60
            print(f"{'Path':<{col_w}}  {'Ext':<8}  {'Size':>10}  {'Status':<14}  Hash")
            print("-" * (col_w + 50))
            for e in results:
                h = e["hash"][:16] + "..." if e["hash"] else "-"
                print(f"{e['path']:<{col_w}}  {e['ext']:<8}  {human_size(e['size']):>10}"
                      f"  {e['status']:<14}  {h}")

        print("")
        print(f"Summary:")
        print(f"  New files      : {len(new_entries)}")
        print(f"  Skipped        : {skipped_count}  (extension or size filter)")
        print(f"  Already logged : {already_logged}")
        print(f"  Log            : {log_path}")

    # Persist new entries to log
    if new_entries:
        save_log(log_path, existing, new_entries)
        if not args.json:
            print(f"\n  {len(new_entries)} new entries written to {log_path}")


if __name__ == "__main__":
    main()
