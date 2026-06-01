#!/usr/bin/env python3
"""
collision-check.py
Validates a target function list against a DLL's full export table,
checking for hash collisions across common algorithms.

A collision occurs when two different export names produce the same hash —
this would cause your PEB/EAT walker to resolve the wrong function.

Usage:
    python collision-check.py <path-to-dll> <func1> [func2 ...] [--algo ror13|djb2|fnv1a]

Examples:
    python collision-check.py kernel32.dll VirtualAlloc VirtualProtect WriteProcessMemory
    python collision-check.py ntdll.dll NtAllocateVirtualMemory NtWriteVirtualMemory --algo djb2

Requires: pefile  (pip install pefile)
"""

import sys
import argparse
from collections import defaultdict

try:
    import pefile
except ImportError:
    print("ERROR: pefile not installed. Run: pip install pefile", file=sys.stderr)
    sys.exit(1)


# ── Hashing algorithms (must match hash-api.py) ───────────────────────────────

def ror13(name: str) -> int:
    h = 0
    for c in name:
        h = ((h >> 13) | (h << (32 - 13))) & 0xFFFFFFFF
        h = (h + ord(c)) & 0xFFFFFFFF
    return h


def djb2(name: str) -> int:
    h = 5381
    for c in name:
        h = ((h << 5) + h + ord(c)) & 0xFFFFFFFF
    return h


def fnv1a(name: str) -> int:
    FNV_PRIME  = 0x01000193
    FNV_OFFSET = 0x811C9DC5
    h = FNV_OFFSET
    for c in name:
        h ^= ord(c)
        h = (h * FNV_PRIME) & 0xFFFFFFFF
    return h


ALGORITHMS = {"ror13": ror13, "djb2": djb2, "fnv1a": fnv1a}


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Check for API hash collisions")
    parser.add_argument("dll",   help="Path to DLL")
    parser.add_argument("funcs", nargs="+", help="Target function names to check")
    parser.add_argument("--algo", default="ror13",
                        choices=list(ALGORITHMS),
                        help="Hash algorithm (default: ror13)")
    args = parser.parse_args()

    hash_fn = ALGORITHMS[args.algo]

    # Load all exports
    try:
        pe = pefile.PE(args.dll, fast_load=True)
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"]])
    except (pefile.PEFormatError, FileNotFoundError) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    if not hasattr(pe, "DIRECTORY_ENTRY_EXPORT"):
        print("ERROR: DLL has no export directory", file=sys.stderr)
        sys.exit(1)

    all_exports = {}
    for exp in pe.DIRECTORY_ENTRY_EXPORT.symbols:
        if exp.name:
            name = exp.name.decode("ascii", errors="replace")
            all_exports[name] = hash_fn(name)

    # Build reverse map: hash → [names]
    hash_to_names: dict = defaultdict(list)
    for name, h in all_exports.items():
        hash_to_names[h].append(name)

    # Check each target function
    print(f"Algorithm: {args.algo.upper()}  |  DLL: {args.dll}")
    print(f"Checking {len(args.funcs)} target function(s) against {len(all_exports)} exports\n")

    collision_found = False
    for func in args.funcs:
        if func not in all_exports:
            print(f"  {func:<45} NOT FOUND in DLL exports")
            continue

        h = all_exports[func]
        colliders = [n for n in hash_to_names[h] if n != func]

        if colliders:
            collision_found = True
            print(f"  {func:<45} 0x{h:08X}  *** COLLISION with: {', '.join(colliders)}")
        else:
            print(f"  {func:<45} 0x{h:08X}  OK")

    print()
    if collision_found:
        print("FAIL — collisions found. Switch algorithm or add a secondary check in your EAT walker.")
        sys.exit(1)
    else:
        print("PASS — no collisions detected for the target function set.")


if __name__ == "__main__":
    main()
