#!/usr/bin/env bash
# check-ci-ready.sh
# Runs ruff and black locally to confirm the project is CI-ready before pushing.
# Mirrors the lint job in ci.yml exactly.
#
# Usage:
#   ./check-ci-ready.sh [path]
#   If no path given, checks the current directory.
#
# Requires: ruff, black (pip install ruff black)

set -euo pipefail

TARGET="${1:-.}"
PASS=0
FAIL=0

echo "=== CI readiness check: $TARGET ==="
echo ""

# ruff
echo "--- ruff ---"
if ruff check "$TARGET"; then
    echo "  ruff: PASS"
    PASS=$((PASS + 1))
else
    echo "  ruff: FAIL  (run: ruff check --fix $TARGET)"
    FAIL=$((FAIL + 1))
fi
echo ""

# black
echo "--- black ---"
if black --check "$TARGET"; then
    echo "  black: PASS"
    PASS=$((PASS + 1))
else
    echo "  black: FAIL  (run: black $TARGET)"
    FAIL=$((FAIL + 1))
fi
echo ""

echo "=== Result: $PASS passed, $FAIL failed ==="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
