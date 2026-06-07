#!/usr/bin/env bash
# pin_readme_version.sh
# Rewrites README install instructions to pin the current release version.
# Replaces references to 'main', 'master', or any older vX.Y.Z tag with the
# current version detected from VERSION file, git tag, or pyproject.toml.
#
# Usage:
#   ./pin_readme_version.sh              # apply changes in-place
#   ./pin_readme_version.sh --dry-run    # show what would change, no edits

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

echo "=== readme-version-pin ==="
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
    echo "  [ERROR] Could not detect version."
    echo "          Provide a VERSION file, a git tag, or version in pyproject.toml."
    exit 1
fi

# Ensure version has a leading 'v'
[[ "$VERSION" != v* ]] && VERSION="v${VERSION}"

echo "  Version  : $VERSION  (from $VERSION_SOURCE)"
$DRY_RUN && echo "  Mode     : DRY RUN — no files will be changed"
echo ""

# ── Find README files ─────────────────────────────────────────────────────
mapfile -t READMES < <(find . -name "README*" -not -path "*/.git/*" | sort)

if [[ ${#READMES[@]} -eq 0 ]]; then
    echo "  [WARN] No README files found."
    exit 0
fi

# ── Patterns to rewrite ────────────────────────────────────────────────────
# Each pattern is a sed expression.
# Order matters — more specific patterns first.
#
# Patterns handled:
#   git clone -b main          → git clone -b v1.2.9
#   git clone -b master        → git clone -b v1.2.9
#   git clone -b v1.0.0        → git clone -b v1.2.9
#   @main                      → @v1.2.9
#   @master                    → @v1.2.9
#   @v1.0.0                    → @v1.2.9
#   checkout main              → checkout v1.2.9
#   checkout master            → checkout v1.2.9

# shellcheck disable=SC2016  # \& is a sed backreference, not a shell expression
ESC_VER=$(printf '%s\n' "$VERSION" | sed 's/[[\.*^$()+?{|]/\\&/g')

CHANGED=0

for readme in "${READMES[@]}"; do
    # Build sed script
    SED_SCRIPT=""
    # @main / @master / @vX.Y.Z
    SED_SCRIPT+="s|@main\b|@${ESC_VER}|g;"
    SED_SCRIPT+="s|@master\b|@${ESC_VER}|g;"
    SED_SCRIPT+="s|@v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\b|@${ESC_VER}|g;"
    # git clone -b main / master / vX.Y.Z
    SED_SCRIPT+="s|\(-b\) main\b|\1 ${ESC_VER}|g;"
    SED_SCRIPT+="s|\(-b\) master\b|\1 ${ESC_VER}|g;"
    SED_SCRIPT+="s|\(-b\) v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\b|\1 ${ESC_VER}|g;"
    # checkout main / master / vX.Y.Z
    SED_SCRIPT+="s|\(checkout\) main\b|\1 ${ESC_VER}|g;"
    SED_SCRIPT+="s|\(checkout\) master\b|\1 ${ESC_VER}|g;"
    SED_SCRIPT+="s|\(checkout\) v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\b|\1 ${ESC_VER}|g;"

    BEFORE=$(cat "$readme")
    AFTER=$(sed "$SED_SCRIPT" "$readme")

    if [[ "$BEFORE" != "$AFTER" ]]; then
        CHANGED=$((CHANGED + 1))
        echo "  [CHANGED] $readme"
        diff <(echo "$BEFORE") <(echo "$AFTER") | grep "^[<>]" | while IFS= read -r line; do
            echo "    $line"
        done
        echo ""
        if ! $DRY_RUN; then
            printf '%s\n' "$AFTER" > "$readme"
        fi
    fi
done

if [[ $CHANGED -eq 0 ]]; then
    echo "  [PASS] All README pins already at $VERSION — nothing to change."
else
    if $DRY_RUN; then
        echo "  $CHANGED README file(s) would be updated (dry run — no changes made)."
        echo "  Run without --dry-run to apply."
    else
        echo "  $CHANGED README file(s) updated."
        echo "  Stage and commit: git add -u && git commit -m \"chore: pin README install refs to $VERSION\""
    fi
fi

echo ""
echo "=== readme-version-pin complete ==="
