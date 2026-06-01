#!/usr/bin/env bash
# bof-validate.sh
# Static validation checks for a compiled BOF COFF object.
# Catches common BOF mistakes before loading in CS/Havoc.
#
# Checks:
#   1. Exports 'go' entry point
#   2. No .bss section (static globals with zero-init = CRT dependency)
#   3. No CRT imports (msvcrt, ucrt)
#   4. No libc function calls (malloc, free, printf, etc.)
#   5. File is a COFF object (not a DLL or EXE)
#
# Usage:
#   ./bof-validate.sh <bof.o>
#
# Requires: objdump (binutils) or llvm-objdump on PATH

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <bof.o>"
    exit 1
fi

BOF="$1"
PASS=0
FAIL=0
WARN=0

if [[ ! -f "$BOF" ]]; then
    echo "ERROR: file not found: $BOF"
    exit 1
fi

# Select objdump variant
if command -v llvm-objdump &>/dev/null; then
    OBJDUMP="llvm-objdump"
elif command -v objdump &>/dev/null; then
    OBJDUMP="objdump"
else
    echo "ERROR: objdump or llvm-objdump not found on PATH"
    exit 1
fi

echo "=== bof-validate: $BOF ==="
echo ""

# ── Check 1: COFF file magic ──────────────────────────────────────────────────
MAGIC=$(od -A n -t x1 -N 2 "$BOF" | tr -d ' \n')
# x64 COFF: 0x8664, x86 COFF: 0x014c
if [[ "$MAGIC" == "6486" || "$MAGIC" == "4c01" ]]; then
    echo "  [PASS] COFF object file (magic: 0x${MAGIC})"
    PASS=$((PASS+1))
else
    echo "  [FAIL] Not a COFF object file (magic: 0x${MAGIC} — expected 0x8664 or 0x014c)"
    FAIL=$((FAIL+1))
fi

# ── Check 2: Exports 'go' ─────────────────────────────────────────────────────
if $OBJDUMP -t "$BOF" 2>/dev/null | grep -q '\bgo\b'; then
    echo "  [PASS] Exports 'go' entry point"
    PASS=$((PASS+1))
else
    echo "  [FAIL] No 'go' export found — CS/Havoc BOF loaders require a 'go' function"
    FAIL=$((FAIL+1))
fi

# ── Check 3: No .bss section ─────────────────────────────────────────────────
if $OBJDUMP -h "$BOF" 2>/dev/null | grep -q '\.bss'; then
    echo "  [FAIL] .bss section present — static zero-init globals imply CRT dependency"
    echo "         Remove static globals or initialise them explicitly"
    FAIL=$((FAIL+1))
else
    echo "  [PASS] No .bss section"
    PASS=$((PASS+1))
fi

# ── Check 4: No CRT library imports ──────────────────────────────────────────
CRT_HITS=$($OBJDUMP -t "$BOF" 2>/dev/null | grep -iE 'msvcrt|ucrtbase|vcruntime' || true)
if [[ -n "$CRT_HITS" ]]; then
    echo "  [FAIL] CRT library references found:"
    echo "$CRT_HITS" | sed 's/^/         /'
    FAIL=$((FAIL+1))
else
    echo "  [PASS] No CRT library references"
    PASS=$((PASS+1))
fi

# ── Check 5: No raw libc calls ────────────────────────────────────────────────
LIBC_FUNCS="malloc free calloc realloc printf sprintf fprintf strlen strcpy strcat memcpy memset"
LIBC_HITS=""
for fn in $LIBC_FUNCS; do
    if $OBJDUMP -t "$BOF" 2>/dev/null | grep -qw "__imp_${fn}\|${fn}@"; then
        LIBC_HITS="${LIBC_HITS} ${fn}"
    fi
done
if [[ -n "$LIBC_HITS" ]]; then
    echo "  [WARN] Possible libc calls:${LIBC_HITS}"
    echo "         Use BeaconPrintf / BeaconDataExtract equivalents instead"
    WARN=$((WARN+1))
else
    echo "  [PASS] No raw libc function calls detected"
    PASS=$((PASS+1))
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Result: $PASS passed, $WARN warned, $FAIL failed ==="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
