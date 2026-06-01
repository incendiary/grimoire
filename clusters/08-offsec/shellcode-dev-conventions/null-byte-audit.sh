#!/usr/bin/env bash
# null-byte-audit.sh
# Scans a shellcode binary for null bytes (0x00) and reports their offsets.
# Null bytes break string-based delivery (strcpy, printf %s, etc.)
#
# Usage:
#   ./null-byte-audit.sh <shellcode.bin>
#
# Exit code: 0 = clean, 1 = null bytes found, 2 = usage error

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <shellcode.bin>"
    exit 2
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "ERROR: file not found: $FILE"
    exit 2
fi

SIZE=$(wc -c < "$FILE")
echo "=== null-byte-audit: $FILE ($SIZE bytes) ==="
echo ""

# Find null byte offsets using od (portable, no external deps)
NULLS=$(od -A d -t x1 "$FILE" | awk '
{
    base = strtonum($1)
    for (i=2; i<=NF; i++) {
        if ($i == "00") {
            printf "%d (0x%04x)\n", base + (i-2), base + (i-2)
        }
    }
}')

if [[ -z "$NULLS" ]]; then
    echo "CLEAN — no null bytes found"
    exit 0
fi

COUNT=$(echo "$NULLS" | wc -l | tr -d ' ')
echo "FAIL — $COUNT null byte(s) found at offset(s):"
echo "$NULLS" | sed 's/^/  /'
echo ""
echo "Fix: use null-free encoding (XOR, arithmetic, or avoid null-producing instructions)"
echo "     e.g. 'mov eax, 0' → 'xor eax, eax'"
echo "          'push 0x00'  → 'push 0x01 ; dec byte [rsp]'"
exit 1
