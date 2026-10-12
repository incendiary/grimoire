#!/bin/sh
# check-version-sync.sh — Verifies VERSION file, git tag, and GitHub release agree.
# Usage: bash check-version-sync.sh [repo-root]
# Exit: 0 = all in sync, 1 = drift detected
set -e

REPO_ROOT="${1:-.}"
cd "$REPO_ROOT"

# --- Read VERSION file ---
if [ ! -f VERSION ]; then
  echo "✗ No VERSION file found at repo root"
  exit 1
fi
FILE_VERSION=$(tr -d '[:space:]' < VERSION)

# --- Read latest git tag ---
TAG_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//') || TAG_VERSION=""
if [ -z "$TAG_VERSION" ]; then
  echo "✗ No git tags found"
  TAG_VERSION="(none)"
fi

# --- Read GitHub release (requires gh CLI) ---
if command -v gh >/dev/null 2>&1; then
  RELEASE_VERSION=$(gh release view --json tagName --jq '.tagName' 2>/dev/null | sed 's/^v//') || RELEASE_VERSION=""
  if [ -z "$RELEASE_VERSION" ]; then
    RELEASE_VERSION="(none)"
  fi
else
  RELEASE_VERSION="(gh CLI not available)"
fi

# --- Compare ---
echo "VERSION file:    $FILE_VERSION"
echo "Latest git tag:  ${TAG_VERSION}"
echo "GitHub release:  ${RELEASE_VERSION}"
echo ""

if [ "$FILE_VERSION" = "$TAG_VERSION" ] && { [ "$RELEASE_VERSION" = "$FILE_VERSION" ] || [ "$RELEASE_VERSION" = "(gh CLI not available)" ]; }; then
  echo "✓ All in sync."
  exit 0
else
  echo "✗ DRIFT DETECTED"
  if [ "$FILE_VERSION" != "$TAG_VERSION" ]; then
    echo "  VERSION ($FILE_VERSION) != tag ($TAG_VERSION)"
  fi
  if [ "$RELEASE_VERSION" != "$FILE_VERSION" ] && [ "$RELEASE_VERSION" != "(gh CLI not available)" ]; then
    echo "  VERSION ($FILE_VERSION) != release ($RELEASE_VERSION)"
  fi
  exit 1
fi
