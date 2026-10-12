#!/usr/bin/env bash
# check_readme_version.sh
# Asserts that all README version pins match the current release version.
# Exits 0 if all pins are correct. Exits 1 and prints mismatches if not.
#
# Designed to run as:
#   - a pre-commit hook (blocks commit on mismatch)
#   - a CI step (fails the build on mismatch)
#   - a standalone check after running pin_readme_version.sh
#
# Usage:
#   ./check_readme_version.sh

set -euo pipefail

echo "=== check-readme-version ==="
echo ""

# ── Detect current version ────────────────────────────────────────────────
VERSION=""
VERSION_SOURCE=""

if [[ -f "VERSION" ]]; then
    VERSION=$(tr -d '[:space:]' < VERSION)
    VERSION_SOURCE="VERSION file"
elif git rev-parse --git-dir &>/dev/null; then
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null || true)
    if [[ -n "$VERSION" ]]; then
        VERSION_SOURCE="git tag"
    fi
fi

if [[ -z "$VERSION" && -f "pyproject.toml" ]]; then
    VERSION=$(python3 -c "
import re
try:
    m = re.search(r'^version\s*=\s*[\"\'](.*?)[\"\']', open('pyproject.toml').read(), re.MULTILINE)
    print(('v' + m.group(1)) if m else '')
except Exception:
    pass
" 2>/dev/null || true)
    if [[ -n "$VERSION" ]]; then
        VERSION_SOURCE="pyproject.toml"
    fi
fi

if [[ -z "$VERSION" ]]; then
    echo "  [ERROR] Could not detect version — cannot check README pins."
    exit 1
fi

[[ "$VERSION" != v* ]] && VERSION="v${VERSION}"
echo "  Expected version : $VERSION  (from $VERSION_SOURCE)"
echo ""

# ── Find README files ─────────────────────────────────────────────────────
mapfile -t READMES < <(find . -name "README*" -not -path "*/.git/*" | sort)

FAILED=false

for readme in "${READMES[@]}"; do
    # Look for stale pins: @main, @master, @vX.Y.Z where X.Y.Z != current
    STALE_LINES=""

    while IFS= read -r line; do
        # Check for @main or @master
        if echo "$line" | grep -qE '@(main|master)\b'; then
            STALE_LINES+="  $line"$'\n'
            continue
        fi
        # Check for @vX.Y.Z that doesn't match current version
        if echo "$line" | grep -qE '@v[0-9]+\.[0-9]+\.[0-9]+'; then
            if ! echo "$line" | grep -qF "@${VERSION}"; then
                STALE_LINES+="  $line"$'\n'
            fi
        fi
        # Check for 'clone -b main/master' or 'checkout main/master'
        if echo "$line" | grep -qE '(-b|checkout) (main|master)\b'; then
            STALE_LINES+="  $line"$'\n'
            continue
        fi
        # Check for 'clone -b vX.Y.Z' or 'checkout vX.Y.Z' that doesn't match
        if echo "$line" | grep -qE '(-b|checkout) v[0-9]+\.[0-9]+\.[0-9]+'; then
            if ! echo "$line" | grep -qF "${VERSION}"; then
                STALE_LINES+="  $line"$'\n'
            fi
        fi
    done < "$readme"

    if [[ -n "$STALE_LINES" ]]; then
        echo "  [FAIL] $readme — stale version pin(s):"
        while IFS= read -r stale_line; do
            [[ -n "$stale_line" ]] && echo "         $stale_line"
        done <<< "$STALE_LINES"
        echo ""
        FAILED=true
    fi
done

if $FAILED; then
    echo "  Fix: run pin_readme_version.sh to update all pins to $VERSION"
    echo ""
    echo "=== check-readme-version FAILED ==="
    exit 1
else
    echo "  [PASS] All README version pins are at $VERSION"
    echo ""
    echo "=== check-readme-version PASSED ==="
fi
