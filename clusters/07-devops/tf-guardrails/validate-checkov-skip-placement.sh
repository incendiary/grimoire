#!/usr/bin/env bash
# validate-checkov-skip-placement.sh
# Finds checkov:skip annotations in Terraform files and reports any that
# appear outside a resource or module block, where they would have no effect.
#
# Usage:
#   ./validate-checkov-skip-placement.sh [directory]
#   Default directory: current working directory
#
# A checkov:skip comment is valid only when placed inside a resource{} or
# module{} block. Top-level, dangling, or misplaced skips are silently ignored
# by checkov — this script surfaces them before they cause confusion.

set -euo pipefail

SEARCH_DIR="${1:-.}"

if [[ ! -d "$SEARCH_DIR" ]]; then
    echo "ERROR: directory not found: $SEARCH_DIR"
    exit 1
fi

echo "=== validate-checkov-skip-placement: $SEARCH_DIR ==="
echo ""

MISPLACED=0
VALID=0
TOTAL=0

# Find all .tf files with a checkov:skip annotation
while IFS= read -r tf_file; do
    # Track block depth to determine if we're inside resource/module
    in_block=false
    block_depth=0
    lineno=0

    while IFS= read -r line; do
        lineno=$((lineno + 1))

        # Opening brace: increment depth
        opens=$(echo "$line" | tr -cd '{' | wc -c)
        closes=$(echo "$line" | tr -cd '}' | wc -c)

        # Check if this line opens a resource or module block (depth 0 → 1)
        if [[ "$block_depth" -eq 0 ]]; then
            if echo "$line" | grep -qE '^\s*(resource|module)\s+'; then
                in_block=true
            fi
        fi

        block_depth=$((block_depth + opens - closes))
        if [[ "$block_depth" -le 0 ]]; then
            block_depth=0
            in_block=false
        fi

        # Check for checkov:skip on this line
        if echo "$line" | grep -qiE '#\s*checkov\s*:\s*skip'; then
            TOTAL=$((TOTAL + 1))
            if $in_block; then
                VALID=$((VALID + 1))
            else
                MISPLACED=$((MISPLACED + 1))
                echo "  [WARN] Misplaced skip at ${tf_file}:${lineno}"
                echo "         $line"
                echo ""
            fi
        fi
    done < "$tf_file"
done < <(find "$SEARCH_DIR" -name "*.tf" -not -path "*/.terraform/*" | sort)

# ── Summary ───────────────────────────────────────────────────────────────────
echo "Total checkov:skip annotations : $TOTAL"
echo "  Inside resource/module block : $VALID"
echo "  Misplaced (no effect)        : $MISPLACED"
echo ""

if [[ "$MISPLACED" -gt 0 ]]; then
    echo "FAIL — $MISPLACED misplaced skip(s) found. Move them inside the relevant resource{} block."
    exit 1
else
    echo "PASS — all checkov:skip annotations are inside resource or module blocks."
fi
