#!/usr/bin/env bash
# static-audit.sh
# Pre-flight static analysis for a shellcode or PE binary.
# Runs entropy analysis, suspicious strings extraction, and optional YARA scan.
# Use before deploying a payload to flag obvious detection surface.
#
# Usage:
#   ./static-audit.sh <binary> [--yara <rules.yar>]
#
# Requires: strings (binutils), python3 (entropy), yara (optional)

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <binary> [--yara <rules.yar>]"
    exit 1
fi

BINARY="$1"
YARA_RULES=""

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --yara) YARA_RULES="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

if [[ ! -f "$BINARY" ]]; then
    echo "ERROR: file not found: $BINARY"
    exit 1
fi

echo "=== static-audit: $BINARY ==="
echo ""

# ── Entropy ───────────────────────────────────────────────────────────────────
if command -v python3 &>/dev/null; then
    ENTROPY=$(python3 - "$BINARY" <<'PYEOF'
import sys, math, collections
data = open(sys.argv[1], "rb").read()
if not data:
    print("0.00")
else:
    counts = collections.Counter(data)
    total = len(data)
    ent = -sum((c / total) * math.log2(c / total) for c in counts.values())
    print(f"{ent:.2f}")
PYEOF
)
    # Compare as integer (entropy * 10) to avoid float ops in bash
    ENTROPY_INT=$(python3 -c "print(int(float('${ENTROPY}') * 10))")
    if [[ "$ENTROPY_INT" -ge 72 ]]; then
        echo "  [INFO] Entropy: ${ENTROPY} / 8.00  (high — packed or encrypted payload)"
    elif [[ "$ENTROPY_INT" -ge 60 ]]; then
        echo "  [INFO] Entropy: ${ENTROPY} / 8.00  (moderate)"
    else
        echo "  [WARN] Entropy: ${ENTROPY} / 8.00  (low — plaintext; strings likely detectable)"
    fi
else
    echo "  [SKIP] Entropy check — python3 not found"
fi

echo ""

# ── Strings extraction ────────────────────────────────────────────────────────
if ! command -v strings &>/dev/null; then
    echo "  [SKIP] strings — not found on PATH"
else
    echo "--- Suspicious strings ---"

    # Win32/NT API references (allocation, injection, loader primitives)
    API_HITS=$(strings "$BINARY" | grep -iE \
        'VirtualAlloc|VirtualProtect|CreateThread|WriteProcessMemory|OpenProcess|CreateRemoteThread|LoadLibrary|GetProcAddress|NtAllocate|NtWrite|NtProtect|NtCreateThread' \
        || true)
    if [[ -n "$API_HITS" ]]; then
        echo "  [WARN] Win32/NT API references:"
        while IFS= read -r line; do echo "         $line"; done <<< "$API_HITS"
    else
        echo "  [PASS] No obvious Win32/NT API strings"
    fi

    # CRT / MSVC artefacts
    CRT_HITS=$(strings "$BINARY" | grep -iE 'msvcrt|ucrtbase|vcruntime|printf|malloc|_start' || true)
    if [[ -n "$CRT_HITS" ]]; then
        echo "  [WARN] CRT/MSVC artefacts:"
        while IFS= read -r line; do echo "         $line"; done <<< "$CRT_HITS"
    else
        echo "  [PASS] No CRT/MSVC artefact strings"
    fi

    # PDB path / PE stub banner
    PE_HINTS=$(strings "$BINARY" | grep -iE '\.pdb$|\.pdb |This program cannot|!This program' || true)
    if [[ -n "$PE_HINTS" ]]; then
        echo "  [WARN] PDB / PE banner artefacts:"
        while IFS= read -r line; do echo "         $line"; done <<< "$PE_HINTS"
    else
        echo "  [PASS] No PDB / PE banner strings"
    fi

    echo ""
    echo "--- All printable strings (min 6 chars, first 50) ---"
    strings -n 6 "$BINARY" | head -50
    TOTAL=$(strings -n 6 "$BINARY" | wc -l | tr -d ' ')
    if [[ "$TOTAL" -gt 50 ]]; then
        echo "  ... ($TOTAL total — output truncated at 50)"
    fi
fi

echo ""

# ── Optional YARA scan ────────────────────────────────────────────────────────
if [[ -n "$YARA_RULES" ]]; then
    if ! command -v yara &>/dev/null; then
        echo "  [SKIP] YARA — not found on PATH"
    elif [[ ! -f "$YARA_RULES" ]]; then
        echo "  [ERROR] YARA rules file not found: $YARA_RULES"
    else
        echo "--- YARA scan: $YARA_RULES ---"
        YARA_OUT=$(yara "$YARA_RULES" "$BINARY" 2>&1 || true)
        if [[ -z "$YARA_OUT" ]]; then
            echo "  [PASS] No YARA matches"
        else
            echo "  [WARN] YARA matches:"
            while IFS= read -r line; do echo "         $line"; done <<< "$YARA_OUT"
        fi
        echo ""
    fi
fi

echo "=== static-audit complete ==="
