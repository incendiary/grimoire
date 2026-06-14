#!/usr/bin/env bash
# release-backfill.sh — Create GitHub Releases for tags that are missing them.
#
# Usage:
#   bash scripts/release-backfill.sh              # dry-run (default)
#   bash scripts/release-backfill.sh --apply      # actually create releases
#   bash scripts/release-backfill.sh --apply --mark-prerelease-before v1.6.0
#
# Requires: git, gh (authenticated), bash 4+ (for arrays) or zsh
# Works on any repo — run from the repo root.

set -euo pipefail

APPLY=false
PRERELEASE_BEFORE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) APPLY=true; shift ;;
        --mark-prerelease-before) PRERELEASE_BEFORE="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--apply] [--mark-prerelease-before vX.Y.Z]"
            echo ""
            echo "Options:"
            echo "  --apply                      Actually create releases (default: dry-run)"
            echo "  --mark-prerelease-before TAG Mark releases older than TAG as prerelease"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ── Collect tags and existing releases ────────────────────────────────────────
echo "=== Release Backfill ==="
echo ""

ALL_TAGS=()
while IFS= read -r tag; do
    ALL_TAGS[${#ALL_TAGS[@]}]="$tag"
done <<< "$(git tag --sort=v:refname | grep '^v')"

RELEASED=()
while IFS= read -r rel; do
    [[ -n "$rel" ]] && RELEASED[${#RELEASED[@]}]="$rel"
done <<< "$(gh release list --limit 200 --json tagName --jq '.[].tagName' 2>/dev/null)"

echo "  Git tags found:       ${#ALL_TAGS[@]}"
echo "  GitHub Releases found: ${#RELEASED[@]}"
echo ""

# ── Find tags without releases ────────────────────────────────────────────────
MISSING=()
for tag in "${ALL_TAGS[@]}"; do
    found=false
    for rel in "${RELEASED[@]}"; do
        if [[ "$tag" == "$rel" ]]; then
            found=true
            break
        fi
    done
    if ! $found; then
        MISSING[${#MISSING[@]}]="$tag"
    fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "  ✓ All tags have matching GitHub Releases. Nothing to do."
    exit 0
fi

echo "  Tags missing a GitHub Release (${#MISSING[@]}):"
for tag in "${MISSING[@]}"; do
    echo "    - $tag"
done
echo ""

# ── Helper: version comparison ────────────────────────────────────────────────
version_lt() {
    # Returns 0 (true) if $1 < $2 in semver
    local v1="${1#v}" v2="${2#v}"
    if [[ "$v1" == "$v2" ]]; then return 1; fi
    local IFS='.'
    # shellcheck disable=SC2086
    set -- $v1
    local a1="${1:-0}" a2="${2:-0}" a3="${3:-0}"
    # shellcheck disable=SC2086
    set -- $v2
    local b1="${1:-0}" b2="${2:-0}" b3="${3:-0}"
    IFS=' '
    if (( a1 < b1 )); then return 0; fi
    if (( a1 > b1 )); then return 1; fi
    if (( a2 < b2 )); then return 0; fi
    if (( a2 > b2 )); then return 1; fi
    if (( a3 < b3 )); then return 0; fi
    return 1
}

# ── Extract release notes from CHANGELOG ──────────────────────────────────────
extract_notes() {
    local version="${1#v}"
    if [[ ! -f "CHANGELOG.md" ]]; then
        echo "Release $1"
        return
    fi

    local notes
    notes=$(awk -v ver="$version" '
        /^## / {
            if (found) exit
            if (index($0, "[" ver "]") || index($0, "[v" ver "]")) {
                found=1
                next
            }
        }
        found { print }
    ' CHANGELOG.md | head -50)

    if [[ -z "$notes" ]]; then
        echo "Release $1"
    else
        echo "$notes"
    fi
}

# ── Create missing releases ───────────────────────────────────────────────────
if ! $APPLY; then
    echo "  DRY RUN — pass --apply to create releases."
    echo ""
    for tag in "${MISSING[@]}"; do
        prerelease_flag=""
        if [[ -n "$PRERELEASE_BEFORE" ]] && version_lt "$tag" "$PRERELEASE_BEFORE"; then
            prerelease_flag=" [prerelease]"
        fi
        echo "  Would create: $tag$prerelease_flag"
    done
    exit 0
fi

echo "  Creating releases..."
echo ""

for tag in "${MISSING[@]}"; do
    NOTES=$(extract_notes "$tag")
    PRERELEASE_FLAG=""

    if [[ -n "$PRERELEASE_BEFORE" ]] && version_lt "$tag" "$PRERELEASE_BEFORE"; then
        PRERELEASE_FLAG="--prerelease"
    fi

    printf '%s\n' "$NOTES" > /tmp/backfill-notes.md

    if [[ -n "$PRERELEASE_FLAG" ]]; then
        gh release create "$tag" \
            --title "$tag" \
            --notes-file /tmp/backfill-notes.md \
            --prerelease \
            2>&1
    else
        gh release create "$tag" \
            --title "$tag" \
            --notes-file /tmp/backfill-notes.md \
            2>&1
    fi

    status=$?
    if [[ $status -eq 0 ]]; then
        echo "  ✓ Created release: $tag ${PRERELEASE_FLAG}"
    else
        echo "  ✗ FAILED: $tag (exit $status)"
    fi
done

echo ""
echo "=== Backfill complete ==="
