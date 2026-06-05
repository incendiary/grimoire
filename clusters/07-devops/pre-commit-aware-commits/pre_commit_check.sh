#!/usr/bin/env bash
# pre_commit_check.sh
# Detects whether pre-commit is installed and configured for this repo,
# then optionally runs all hooks against staged or all files.
#
# Usage:
#   ./pre_commit_check.sh              # detect + report status only
#   ./pre_commit_check.sh --run        # detect + run hooks on staged files
#   ./pre_commit_check.sh --run-all    # detect + run hooks on all files

set -euo pipefail

RUN_MODE="none"
for arg in "$@"; do
    case "$arg" in
        --run)     RUN_MODE="staged" ;;
        --run-all) RUN_MODE="all"    ;;
    esac
done

echo "=== pre-commit-aware-commits ==="
echo ""

# ── Check pre-commit binary ───────────────────────────────────────────────
if ! command -v pre-commit &>/dev/null; then
    echo "  [MISS] pre-commit not installed"
    echo "         Install: pip install pre-commit  (or: brew install pre-commit)"
    echo ""
    echo "=== pre-commit check complete ==="
    exit 1
fi

PRE_COMMIT_VERSION=$(pre-commit --version 2>/dev/null | head -1)
echo "  [PASS] pre-commit found: $PRE_COMMIT_VERSION"

# ── Check .pre-commit-config.yaml ─────────────────────────────────────────
if [[ ! -f ".pre-commit-config.yaml" ]]; then
    echo "  [MISS] .pre-commit-config.yaml not found in $(pwd)"
    echo "         Run: pre-commit sample-config > .pre-commit-config.yaml"
    echo "         Then customise and run: pre-commit install"
    echo ""
    echo "=== pre-commit check complete ==="
    exit 1
fi

echo "  [PASS] .pre-commit-config.yaml present"

# ── Check hooks are installed (.git/hooks/pre-commit) ─────────────────────
if git rev-parse --git-dir &>/dev/null; then
    GIT_DIR=$(git rev-parse --git-dir)
    HOOK_FILE="$GIT_DIR/hooks/pre-commit"
    if [[ -f "$HOOK_FILE" ]] && grep -q "pre-commit" "$HOOK_FILE" 2>/dev/null; then
        echo "  [PASS] pre-commit hook installed in $GIT_DIR/hooks/"
    else
        echo "  [WARN] pre-commit hook not installed — run: pre-commit install"
    fi
else
    echo "  [WARN] Not inside a git repo — skipping hook check"
fi

echo ""

# ── Optionally run hooks ───────────────────────────────────────────────────
if [[ "$RUN_MODE" == "staged" ]]; then
    echo "--- Running hooks on staged files ---"
    echo ""
    pre-commit run
elif [[ "$RUN_MODE" == "all" ]]; then
    echo "--- Running hooks on all files ---"
    echo ""
    pre-commit run --all-files
fi

echo ""
echo "=== pre-commit check complete ==="
