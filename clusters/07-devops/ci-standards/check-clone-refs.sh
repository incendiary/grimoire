#!/bin/sh
# check-clone-refs.sh — Finds unpinned @main/@master refs in docs and workflows.
# Usage: bash check-clone-refs.sh [repo-root]
# Exit: 0 = clean, 1 = violations found
set -e

REPO_ROOT="${1:-.}"
cd "$REPO_ROOT"

COUNT=0

# Patterns that indicate unpinned references
PATTERNS='@main\|@master\|@latest'

# Files/dirs to scan
SCAN_TARGETS=""
for target in README.md docs .github/workflows INSTALL.md CONTRIBUTING.md; do
  if [ -e "$target" ]; then
    SCAN_TARGETS="$SCAN_TARGETS $target"
  fi
done

if [ -z "$SCAN_TARGETS" ]; then
  echo "✓ No documentation files found to scan."
  exit 0
fi

echo "Scanning:$SCAN_TARGETS"
echo ""

# Grep for violations (ignore binary files, skip this script itself)
# shellcheck disable=SC2086
RESULTS=$(grep -rn "$PATTERNS" $SCAN_TARGETS 2>/dev/null | grep -v 'check-clone-refs.sh' || true)

if [ -n "$RESULTS" ]; then
  # Filter out false positives:
  # - Lines that are comments explaining the rule (contain "don't use" or "never use")
  # - Lines inside code blocks that demonstrate bad practice (context-dependent, skip for now)
  FILTERED=""
  while IFS= read -r line; do
    # Skip lines that are clearly documenting the anti-pattern
    case "$line" in
      *"don't use"*|*"Do not use"*|*"Never use"*|*"avoid"*|*"instead of"*)
        continue
        ;;
      *)
        FILTERED="${FILTERED}${line}
"
        COUNT=$((COUNT + 1))
        ;;
    esac
  done <<EOF
$RESULTS
EOF

  if [ $COUNT -gt 0 ]; then
    echo "✗ Unpinned references found:"
    echo ""
    echo "$FILTERED"
    echo "$COUNT violation(s). Pin to specific versions (@vX.Y.Z or @sha)."
    exit 1
  fi
fi

echo "✓ All references are pinned. No @main/@master/@latest found."
exit 0
