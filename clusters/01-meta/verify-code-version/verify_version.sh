#!/usr/bin/env bash
# verify_version.sh
# Checks the declared code version against git HEAD after a pull or branch
# switch. Also detects and optionally clears stale .pyc bytecode caches.
#
# Version detection order:
#   1. VERSION file in project root
#   2. Python package __version__ (if package name provided)
#   3. version = "..." in pyproject.toml
#
# Usage:
#   ./verify_version.sh                     # detect version, report .pyc cache
#   ./verify_version.sh mypackage           # also check package.__version__
#   ./verify_version.sh --clear-pyc        # detect + clear .pyc caches
#   ./verify_version.sh mypackage --clear-pyc

set -euo pipefail

CLEAR_PYC=false
PACKAGE=""

for arg in "$@"; do
    case "$arg" in
        --clear-pyc) CLEAR_PYC=true ;;
        *)           PACKAGE="$arg" ;;
    esac
done

echo "=== verify-code-version ==="
echo ""

# ── Git state ─────────────────────────────────────────────────────────────
if git rev-parse --git-dir &>/dev/null; then
    GIT_HEAD=$(git rev-parse --short HEAD)
    GIT_BRANCH=$(git branch --show-current)
    echo "  Git HEAD : $GIT_HEAD  ($GIT_BRANCH)"
else
    echo "  [WARN] Not inside a git repository"
fi
echo ""

# ── Detect code version ───────────────────────────────────────────────────
CODE_VERSION=""
VERSION_SOURCE=""

# 1. VERSION file
if [[ -f "VERSION" ]]; then
    CODE_VERSION=$(tr -d '[:space:]' < VERSION)
    VERSION_SOURCE="VERSION file"

# 2. Python package __version__
elif [[ -n "$PACKAGE" ]]; then
    CODE_VERSION=$(python3 -c "import ${PACKAGE}; print(${PACKAGE}.__version__)" 2>/dev/null || true)
    if [[ -n "$CODE_VERSION" ]]; then
        VERSION_SOURCE="${PACKAGE}.__version__"
    fi
fi

# 3. pyproject.toml fallback
if [[ -z "$CODE_VERSION" && -f "pyproject.toml" ]]; then
    CODE_VERSION=$(python3 -c "
import re
try:
    m = re.search(r'^version\s*=\s*[\"\'](.*?)[\"\']', open('pyproject.toml').read(), re.MULTILINE)
    print(m.group(1) if m else '')
except Exception:
    pass
" 2>/dev/null || true)
    if [[ -n "$CODE_VERSION" ]]; then
        VERSION_SOURCE="pyproject.toml"
    fi
fi

if [[ -n "$CODE_VERSION" ]]; then
    echo "  Code version : $CODE_VERSION  (from $VERSION_SOURCE)"
else
    echo "  [WARN] Could not detect code version"
    echo "         Pass a package name: $0 <package>"
fi

echo ""

# ── .pyc cache ────────────────────────────────────────────────────────────
PYC_COUNT=$(find . -name "*.pyc" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
CACHE_COUNT=$(find . -name "__pycache__" -not -path "*/.git/*" -type d 2>/dev/null | wc -l | tr -d ' ')

if $CLEAR_PYC; then
    if [[ "$PYC_COUNT" -gt 0 || "$CACHE_COUNT" -gt 0 ]]; then
        find . -name "*.pyc" -not -path "*/.git/*" -delete 2>/dev/null || true
        find . -name "__pycache__" -not -path "*/.git/*" -type d -exec rm -rf {} + 2>/dev/null || true
        echo "  [DONE] Cleared $PYC_COUNT .pyc file(s) + $CACHE_COUNT __pycache__ dir(s)"
    else
        echo "  [PASS] No .pyc cache present"
    fi
else
    if [[ "$PYC_COUNT" -gt 0 ]]; then
        echo "  [INFO] $PYC_COUNT .pyc file(s) / $CACHE_COUNT __pycache__ dir(s) present"
        echo "         Run with --clear-pyc to remove stale bytecode after a pull"
    else
        echo "  [PASS] No stale .pyc cache"
    fi
fi

echo ""
echo "=== verify-code-version complete ==="
