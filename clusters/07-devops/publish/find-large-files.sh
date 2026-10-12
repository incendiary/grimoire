#!/usr/bin/env bash
# find-large-files.sh
# Reports files in the working tree by size tier.
#
# Tiers:
#   HARD BLOCK  — > 100 MB  (GitHub hard limit)
#   SOFT FLAG   — 10–100 MB (warn; requires explicit approval)
#   BINARY      — compiled objects, media, archives (any size)
#
# Usage: bash find-large-files.sh [directory]
#   directory  (optional) path to search; defaults to current directory

set -euo pipefail

ROOT="${1:-.}"

HARD_BYTES=104857600   # 100 MB
SOFT_BYTES=10485760    # 10 MB

BINARY_EXT="exe|dll|so|dylib|o|a|lib|pdb|obj|class|jar|war|ear|pyc|pyo|whl"
MEDIA_EXT="mp4|mkv|avi|mov|wmv|flv|swf|mpg|mpeg|webm|gif|png|jpg|jpeg|bmp|tiff|ico|pdf|psd|ai|sketch"
ARCHIVE_EXT="tar|gz|bz2|xz|zip|7z|rar|iso|img|dmg|pkg|deb|rpm"

hard_count=0
soft_count=0
binary_count=0

echo "=== File size audit: $ROOT ==="
echo ""

echo "--- HARD BLOCK (> 100 MB) ---"
while IFS= read -r -d '' file; do
  size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
  if [ "$size" -gt "$HARD_BYTES" ]; then
    size_mb=$(( size / 1048576 ))
    echo "  BLOCK  ${size_mb} MB  $file"
    hard_count=$(( hard_count + 1 ))
  fi
done < <(find "$ROOT" -not -path "*/.git/*" -type f -print0)

[ "$hard_count" -eq 0 ] && echo "  (none)"

echo ""
echo "--- SOFT FLAG (10–100 MB) ---"
while IFS= read -r -d '' file; do
  size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
  if [ "$size" -gt "$SOFT_BYTES" ] && [ "$size" -le "$HARD_BYTES" ]; then
    size_mb=$(( size / 1048576 ))
    echo "  FLAG   ${size_mb} MB  $file"
    soft_count=$(( soft_count + 1 ))
  fi
done < <(find "$ROOT" -not -path "*/.git/*" -type f -print0)

[ "$soft_count" -eq 0 ] && echo "  (none)"

echo ""
echo "--- BINARY / MEDIA / ARCHIVE ---"
while IFS= read -r -d '' file; do
  ext="${file##*.}"
  ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  if echo "$ext_lower" | grep -qE "^($BINARY_EXT|$MEDIA_EXT|$ARCHIVE_EXT)$"; then
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    size_kb=$(( size / 1024 ))
    echo "  BIN    ${size_kb} KB  $file"
    binary_count=$(( binary_count + 1 ))
  fi
done < <(find "$ROOT" -not -path "*/.git/*" -type f -print0)

[ "$binary_count" -eq 0 ] && echo "  (none)"

echo ""
echo "=== Summary ==="
echo "  Hard blocks  : $hard_count"
echo "  Soft flags   : $soft_count"
echo "  Binaries     : $binary_count"

if [ "$hard_count" -gt 0 ]; then
  echo ""
  echo "ACTION REQUIRED: $hard_count file(s) exceed the 100 MB GitHub hard limit."
  echo "Remove them, move to Git LFS, or add to .gitignore before pushing."
  exit 1
fi

if [ "$soft_count" -gt 0 ] || [ "$binary_count" -gt 0 ]; then
  echo ""
  echo "REVIEW: Confirm the flagged files are intentional before making the repo public."
fi

exit 0
