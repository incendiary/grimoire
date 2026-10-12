#!/usr/bin/env bash
# capture-releases.sh
# Exports all GitHub releases for a repo to releases-backup.json before a history wipe.
#
# Usage:
#   ./capture-releases.sh [owner/repo]
#   If no argument supplied, uses the remote origin of the current repo.
#
# Output:
#   releases-backup.json in the current directory
#
# Requires: gh CLI authenticated

set -euo pipefail

REPO="${1:-}"

if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)
fi

if [[ -z "$REPO" ]]; then
    echo "ERROR: Could not determine repo. Pass owner/repo as argument or run from inside a git repo."
    exit 1
fi

echo "Capturing releases for $REPO ..."

# Get all releases (up to 100)
gh release list --repo "$REPO" --limit 100 --json tagName,name,body,isDraft,isPrerelease,publishedAt \
    > releases-backup.json

COUNT=$(jq length releases-backup.json)
echo "Captured $COUNT release(s) to releases-backup.json"

if [[ "$COUNT" -eq 0 ]]; then
    echo "No releases found — nothing to preserve."
    exit 0
fi

echo ""
echo "Release tags captured:"
jq -r '.[] | "  " + .tagName + " — " + .name' releases-backup.json
