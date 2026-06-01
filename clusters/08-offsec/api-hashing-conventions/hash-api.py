#!/usr/bin/env python3
"""
hash-api.py
Prints hash values for all exports in a Windows DLL using common
offensive hashing algorithms (ROR13, DJB2, FNV-1a).

Usage:
    python hash-api.py <path-to-dll> [--algo ror13|djb2|fnv1a|all] [--filter NAME]

Examples:
    python hash-api.py C:\\Windows\\System32\\kernel32.dll --algo ror13
    python hash-api.py ntdll.dll --algo all --filter VirtualAlloc

Requires: pefile  (pip install pefile)
"""

import sys
import argparse

try:
    import pefile
except ImportError:
    print("ERROR: pefile not installed. Run: pip install pefile", file=sys.stderr)
    sys.exit(1)


# ── Hashing algorithms ────────────────────────────────────────────────────────

def ror13(name: str) -> int:
    """ROR13 hash — common in Metasploit/Cobalt Strike shellcode."""
    h = 0
    for c in name:
        h = ((h >> 13) | (h << (32 - 13))) & 0xFFFFFFFF
        h = (h + ord(c)) & 0xFFFFFFFF
    return h


def djb2(name: str) -> int:
    """DJB2 hash — lightweight, low collision rate."""
    h = 5381
    for c in name:
        h = ((h << 5) + h + ord(c)) & 0xFFFFFFFF
    return h


def fnv1a(name: str) -> int:
    """FNV-1a 32-bit hash."""
    FNV_PRIME  = 0x01000193
    FNV_OFFSET = 0x811C9DC5
    h = FNV_OFFSET
    for c in name:
        h ^= ord(c)
        h = (h * FNV_PRIME) & 0xFFFFFFFF
    return h


ALGORITHMS = {
    "ror13": ror13,
    "djb2":  djb2,
    "fnv1a": fnv1a,
}

# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Hash DLL exports for API hashing")
    parser.add_argument("dll", help="Path to DLL (Windows PE)")
    parser.add_argument("--algo", default="ror13",
                        choices=list(ALGORITHMS) + ["all"],
                        help="Hash algorithm (default: ror13)")
    parser.add_argument("--filter", default=None, metavar="NAME",
                        help="Only show exports matching this substring (case-insensitive)")
    args = parser.parse_args()

    try:
        pe = pefile.PE(args.dll, fast_load=True)
        pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXPORT"]])
    except pefile.PEFormatError as e:
        print(f"ERROR: not a valid PE: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"ERROR: file not found: {args.dll}", file=sys.stderr)
        sys.exit(1)

    if not hasattr(pe, "DIRECTORY_ENTRY_EXPORT"):
        print("ERROR: DLL has no export directory", file=sys.stderr)
        sys.exit(1)

    algos = list(ALGORITHMS.items()) if args.algo == "all" else [(args.algo, ALGORITHMS[args.algo])]

    # Header
    header = f"{'Export':<50}"
    for name, _ in algos:
        header += f"  {name.upper():>12}"
    print(header)
    print("-" * len(header))

    exports = pe.DIRECTORY_ENTRY_EXPORT.symbols
    for exp in sorted(exports, key=lambda e: e.name or b""):
        if exp.name is None:
            continue
        func_name = exp.name.decode("ascii", errors="replace")

        if args.filter and args.filter.lower() not in func_name.lower():
            continue

        row = f"{func_name:<50}"
        for _, fn in algos:
            row += f"  0x{fn(func_name):08X}"
        print(row)


if __name__ == "__main__":
    main()
