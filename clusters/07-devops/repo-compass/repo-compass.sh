#!/usr/bin/env bash
# repo-compass.sh
# Runs all GitHub platform state commands for the current repository and
# prints a structured summary. Feeds the repo-compass skill workflow.
#
# Usage:
#   ./repo-compass.sh [--repo <owner/repo>]
#
# If --repo is omitted, uses the remote of the current git working tree.
# Requires: git, gh (GitHub CLI, authenticated)

set -euo pipefail

# ── Resolve repo ──────────────────────────────────────────────────────────────
REPO_FLAG=""
if [[ $# -ge 2 && "$1" == "--repo" ]]; then
    REPO_FLAG="--repo $2"
fi

# Determine display name
if [[ -n "$REPO_FLAG" ]]; then
    REPO_NAME="${2}"
else
    REPO_NAME=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "(unknown)")
fi

echo "=== repo-compass: ${REPO_NAME} ==="
echo ""

# ── Open PRs ─────────────────────────────────────────────────────────────────
echo "--- Open PRs ---"
# shellcheck disable=SC2086
PR_OUT=$(gh pr list --state open ${REPO_FLAG} 2>&1 || true)
if [[ -z "$PR_OUT" ]]; then
    echo "  None"
else
    while IFS= read -r line; do echo "  $line"; done <<< "$PR_OUT"
fi
echo ""

# ── Open issues ──────────────────────────────────────────────────────────────
echo "--- Open issues ---"
# shellcheck disable=SC2086
ISSUE_OUT=$(gh issue list --state open ${REPO_FLAG} 2>&1 || true)
if [[ -z "$ISSUE_OUT" ]]; then
    echo "  None"
else
    while IFS= read -r line; do echo "  $line"; done <<< "$ISSUE_OUT"
fi
echo ""

# ── Recent CI runs ────────────────────────────────────────────────────────────
echo "--- CI runs (last 5) ---"
# shellcheck disable=SC2086
RUN_OUT=$(gh run list --limit 5 ${REPO_FLAG} 2>&1 || true)
if [[ -z "$RUN_OUT" ]]; then
    echo "  No runs found"
else
    while IFS= read -r line; do echo "  $line"; done <<< "$RUN_OUT"
fi
echo ""

# ── Releases ─────────────────────────────────────────────────────────────────
echo "--- Releases (last 5) ---"
# shellcheck disable=SC2086
REL_OUT=$(gh release list --limit 5 ${REPO_FLAG} 2>&1 || true)
if [[ -z "$REL_OUT" ]]; then
    echo "  No releases"
else
    while IFS= read -r line; do echo "  $line"; done <<< "$REL_OUT"
fi
echo ""

# ── Tags (git) ────────────────────────────────────────────────────────────────
echo "--- Git tags (newest 10) ---"
TAG_OUT=$(git tag --sort=-creatordate 2>/dev/null | head -10 || true)
if [[ -z "$TAG_OUT" ]]; then
    echo "  No tags"
else
    while IFS= read -r line; do echo "  $line"; done <<< "$TAG_OUT"
fi
echo ""

# ── Stale merged branches ────────────────────────────────────────────────────
echo "--- Stale remote branches (merged into main) ---"
STALE_OUT=$(git branch -r --merged main 2>/dev/null | grep -v 'origin/main\|HEAD' | sed 's/^ *//' || true)
if [[ -z "$STALE_OUT" ]]; then
    echo "  None"
else
    while IFS= read -r line; do echo "  $line"; done <<< "$STALE_OUT"
fi
echo ""

# ── README roadmap items ─────────────────────────────────────────────────────
echo "--- Unchecked README roadmap items ---"
UNCHECKED=$(grep -rn '^\- \[ \]' --include='README*' . 2>/dev/null | grep -v '.git' || true)
if [[ -z "$UNCHECKED" ]]; then
    echo "  None — roadmap is fully checked"
else
    COUNT=$(echo "$UNCHECKED" | wc -l | tr -d ' ')
    echo "  ${COUNT} unchecked item(s):"
    while IFS= read -r line; do echo "  $line"; done <<< "$UNCHECKED"
fi
echo ""

echo "=== repo-compass complete ==="
