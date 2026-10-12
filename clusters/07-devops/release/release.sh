#!/usr/bin/env bash
# release.sh
# Parameterised release helper: bumps VERSION, commits, tags, pushes, and
# creates a GitHub release using the latest CHANGELOG entry as the body.
#
# Usage:
#   ./release.sh <major|minor|patch>          # auto-bump VERSION file
#   ./release.sh --version <X.Y.Z>            # explicit version
#
# Options:
#   --dry-run    Print what would happen without making any changes
#   --no-push    Commit and tag locally but do not push or create release
#
# Requires: git, gh (authenticated), VERSION file in repo root
# Optional: CHANGELOG.md  (first section used as release body if present)

set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
BUMP_TYPE=""
EXPLICIT_VERSION=""
DRY_RUN=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        major|minor|patch) BUMP_TYPE="$1"; shift ;;
        --version)         EXPLICIT_VERSION="$2"; shift 2 ;;
        --dry-run)         DRY_RUN=true; shift ;;
        --no-push)         NO_PUSH=true; shift ;;
        *) echo "Usage: $0 <major|minor|patch> [--dry-run] [--no-push]" >&2
           echo "   or: $0 --version <X.Y.Z>   [--dry-run] [--no-push]" >&2
           exit 1 ;;
    esac
done

if [[ -z "$BUMP_TYPE" && -z "$EXPLICIT_VERSION" ]]; then
    echo "Usage: $0 <major|minor|patch> [--dry-run] [--no-push]" >&2
    echo "   or: $0 --version <X.Y.Z>   [--dry-run] [--no-push]" >&2
    exit 1
fi

# ── Read current VERSION ──────────────────────────────────────────────────────
VERSION_FILE="VERSION"
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "ERROR: $VERSION_FILE not found in $(pwd)"
    exit 1
fi
CURRENT=$(tr -d '[:space:]' < "$VERSION_FILE")

# Parse semver
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# ── Compute new version ───────────────────────────────────────────────────────
if [[ -n "$EXPLICIT_VERSION" ]]; then
    NEW_VERSION="$EXPLICIT_VERSION"
else
    case "$BUMP_TYPE" in
        major) MAJOR=$((MAJOR + 1)); MINOR=0;          PATCH=0 ;;
        minor)                       MINOR=$((MINOR + 1)); PATCH=0 ;;
        patch)                                         PATCH=$((PATCH + 1)) ;;
    esac
    NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

TAG="v${NEW_VERSION}"

echo "=== release.sh ==="
echo "  Current version : $CURRENT"
echo "  New version     : $NEW_VERSION  (tag: $TAG)"
if $DRY_RUN; then echo "  Mode            : DRY RUN — no changes will be made"; fi
echo ""

# ── Dry-run exit ─────────────────────────────────────────────────────────────
if $DRY_RUN; then
    echo "Would:"
    echo "  1. Write '$NEW_VERSION' to $VERSION_FILE"
    echo "  2. git commit -am \"chore: bump version to $NEW_VERSION\""
    echo "  3. git tag $TAG"
    if ! $NO_PUSH; then
        echo "  4. git push origin main --tags"
        echo "  5. gh release create $TAG ..."
    fi
    exit 0
fi

# ── Bump VERSION file ─────────────────────────────────────────────────────────
printf '%s\n' "$NEW_VERSION" > "$VERSION_FILE"
echo "  [1/5] VERSION updated to $NEW_VERSION"

# ── Commit ────────────────────────────────────────────────────────────────────
git add "$VERSION_FILE"
git commit -m "chore: bump version to ${NEW_VERSION}"
echo "  [2/5] Committed VERSION bump"

# ── Tag ───────────────────────────────────────────────────────────────────────
git tag "$TAG"
echo "  [3/5] Tagged $TAG"

if $NO_PUSH; then
    echo ""
    echo "  --no-push set — stopping before push/release."
    echo "  To finish: git push origin main --tags && gh release create $TAG"
    exit 0
fi

# ── Push ──────────────────────────────────────────────────────────────────────
git push origin main --tags
echo "  [4/5] Pushed main + tag $TAG"

# ── Build release notes ───────────────────────────────────────────────────────
RELEASE_NOTES=""
if [[ -f "CHANGELOG.md" ]]; then
    # Extract first H2 section (## vX.Y.Z or ## [vX.Y.Z]) from CHANGELOG
    RELEASE_NOTES=$(awk '/^## /{if(found) exit; found=1; next} found{print}' CHANGELOG.md | head -30)
fi
if [[ -z "$RELEASE_NOTES" ]]; then
    RELEASE_NOTES="Release ${TAG}"
fi

# ── Create GitHub release ─────────────────────────────────────────────────────
gh release create "$TAG" \
    --title "$TAG" \
    --notes "$RELEASE_NOTES"
echo "  [5/5] GitHub release created: $TAG"

echo ""
echo "=== Release $TAG complete ==="
