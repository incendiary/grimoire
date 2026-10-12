#!/usr/bin/env bash
# recreate-releases.sh
# Recreates GitHub releases from releases-backup.json after a history wipe.
# Skips any release whose tag already exists on the remote.
#
# Usage:
#   ./recreate-releases.sh [owner/repo]
#   If no argument supplied, uses the remote origin of the current repo.
#
# Prerequisites:
#   - releases-backup.json exists in the current directory (created by capture-releases.sh)
#   - The new repo is already pushed and the new tags exist locally (git push --tags)
#
# Requires: gh CLI authenticated, jq

set -euo pipefail

REPO="${1:-}"

if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)
fi

if [[ -z "$REPO" ]]; then
    echo "ERROR: Could not determine repo. Pass owner/repo as argument or run from inside a git repo."
    exit 1
fi

if [[ ! -f releases-backup.json ]]; then
    echo "ERROR: releases-backup.json not found. Run capture-releases.sh first."
    exit 1
fi

COUNT=$(jq length releases-backup.json)
echo "Recreating $COUNT release(s) on $REPO ..."
echo ""

CREATED=0
SKIPPED=0

while IFS= read -r release; do
    TAG=$(echo "$release" | jq -r '.tagName')
    NAME=$(echo "$release" | jq -r '.name')
    BODY=$(echo "$release" | jq -r '.body // ""')
    IS_DRAFT=$(echo "$release" | jq -r '.isDraft')
    IS_PRE=$(echo "$release" | jq -r '.isPrerelease')

    # Check if release already exists
    if gh release view "$TAG" --repo "$REPO" &>/dev/null; then
        echo "  SKIP $TAG — release already exists"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    ARGS=(--repo "$REPO" --title "$NAME" --notes "$BODY")
    [[ "$IS_DRAFT" == "true" ]] && ARGS+=(--draft)
    [[ "$IS_PRE" == "true" ]] && ARGS+=(--prerelease)

    gh release create "$TAG" "${ARGS[@]}"
    echo "  CREATED $TAG — $NAME"
    CREATED=$((CREATED + 1))

done < <(jq -c '.[]' releases-backup.json)

echo ""
echo "Done — created: $CREATED, skipped: $SKIPPED"
