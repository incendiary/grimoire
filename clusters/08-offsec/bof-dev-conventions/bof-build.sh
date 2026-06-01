#!/usr/bin/env bash
# bof-build.sh
# clang-cl wrapper for building Beacon Object Files (BOFs).
# Enforces correct BOF compilation flags: no CRT, no globals init, static runtime.
#
# Usage:
#   ./bof-build.sh <source.c> [output.o]
#   If output not specified, uses <source>.o
#
# Requires: clang-cl on PATH (Visual Studio with LLVM toolset, or standalone LLVM)
#
# Output: COFF object file suitable for loading via CobaltStrike execute-assembly
#         or inline-execute, or Havoc's BOF loader.

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <source.c> [output.o]"
    exit 1
fi

SRC="$1"
OUT="${2:-${SRC%.c}.o}"

if [[ ! -f "$SRC" ]]; then
    echo "ERROR: source file not found: $SRC"
    exit 1
fi

if ! command -v clang-cl &>/dev/null; then
    echo "ERROR: clang-cl not found on PATH"
    echo "Install: Visual Studio with LLVM toolset, or standalone LLVM from llvm.org"
    exit 1
fi

echo "Building BOF: $SRC → $OUT"

clang-cl \
    /c \
    /GS- \
    /MT \
    /Ox \
    /DWIN32_LEAN_AND_MEAN \
    /DNOMINMAX \
    /W3 \
    /WX \
    /Fo"$OUT" \
    "$SRC"

SIZE=$(wc -c < "$OUT")
echo "Done — $OUT ($SIZE bytes)"
echo ""
echo "Verify with: ./bof-validate.sh $OUT"
