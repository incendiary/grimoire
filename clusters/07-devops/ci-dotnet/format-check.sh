#!/usr/bin/env bash
# format-check.sh
# Runs dotnet format --verify-no-changes locally and reports which files would change.
# Mirrors the format-check step in the CI workflow.
#
# Usage:
#   ./format-check.sh [solution-or-project-path]
#   If no path given, searches for a .sln or .csproj in the current directory.
#
# Requires: .NET SDK (dotnet CLI)

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    # Auto-detect: prefer .sln, fall back to .csproj
    SLN=$(find . -maxdepth 2 -name "*.sln" | head -1)
    CSPROJ=$(find . -maxdepth 2 -name "*.csproj" | head -1)

    if [[ -n "$SLN" ]]; then
        TARGET="$SLN"
    elif [[ -n "$CSPROJ" ]]; then
        TARGET="$CSPROJ"
    else
        echo "ERROR: No .sln or .csproj found. Pass a path explicitly."
        exit 1
    fi
fi

echo "=== dotnet format check: $TARGET ==="
echo ""

# Run in check mode — exits non-zero if any file would change
if dotnet format "$TARGET" --verify-no-changes --verbosity diagnostic 2>&1; then
    echo ""
    echo "format-check: PASS — no changes needed"
else
    echo ""
    echo "format-check: FAIL — run: dotnet format $TARGET"
    echo "Then review the diff before re-staging."
    exit 1
fi
