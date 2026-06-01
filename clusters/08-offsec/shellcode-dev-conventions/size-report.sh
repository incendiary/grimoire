#!/usr/bin/env bash
# size-report.sh
# Reports shellcode binary size with threshold warnings.
# Useful for checking against common loader constraints.
#
# Usage:
#   ./size-report.sh <shellcode.bin> [warn_kb] [hard_kb]
#   Defaults: warn=4KB, hard=8KB
#
# Thresholds:
#   <  warn_kb  : PASS (green)
#   >= warn_kb  : WARN — may exceed some loader limits
#   >= hard_kb  : FAIL — likely too large for most inline loaders
#
# Exit code: 0 = pass, 1 = warn, 2 = fail/error

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <shellcode.bin> [warn_kb] [hard_kb]"
    exit 2
fi

FILE="$1"
WARN_KB="${2:-4}"
HARD_KB="${3:-8}"

if [[ ! -f "$FILE" ]]; then
    echo "ERROR: file not found: $FILE"
    exit 2
fi

BYTES=$(wc -c < "$FILE")
KB=$(echo "scale=2; $BYTES / 1024" | bc)
WARN_BYTES=$((WARN_KB * 1024))
HARD_BYTES=$((HARD_KB * 1024))

echo "=== size-report: $FILE ==="
echo ""
echo "  Size:      $BYTES bytes (${KB} KB)"
echo "  Warn at:   ${WARN_KB} KB ($WARN_BYTES bytes)"
echo "  Hard cap:  ${HARD_KB} KB ($HARD_BYTES bytes)"
echo ""

if [[ "$BYTES" -ge "$HARD_BYTES" ]]; then
    echo "FAIL — shellcode exceeds hard cap (${HARD_KB}KB)"
    echo "     Reduce: remove debug stubs, compress strings, use hash-based API resolution"
    exit 2
elif [[ "$BYTES" -ge "$WARN_BYTES" ]]; then
    echo "WARN — shellcode exceeds soft warning (${WARN_KB}KB)"
    echo "     Consider: trim if targeting constrained loaders (BOF inline, stack buffers)"
    exit 1
else
    echo "PASS — size is within limits"
    exit 0
fi
