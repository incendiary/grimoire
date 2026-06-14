#!/usr/bin/env bash
# roadmap-close.sh — Marks a roadmap item as done in a skill's README.md
#
# Usage:
#   bash scripts/roadmap-close.sh <skill-name> <item-index>
#   bash scripts/roadmap-close.sh <skill-name> --grep "<pattern>"
#
# Examples:
#   bash scripts/roadmap-close.sh devops-practices 1        # closes first open item
#   bash scripts/roadmap-close.sh devops-practices --grep "CI workflow"
#
# The item-index is 1-based, counting only open (unchecked) items in the
# ## Roadmap section of that skill's README.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
    echo "Usage: $0 <skill-name> <item-index | --grep pattern>"
    echo ""
    echo "  skill-name    Name of the skill directory (e.g. devops-practices)"
    echo "  item-index    1-based index of the open item to close"
    echo "  --grep pat    Close the first open item matching the pattern"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

SKILL_NAME="$1"
shift

# Find the skill README (check both README.md and SKILL.md)
README_PATH=""
for cluster_dir in "$REPO_ROOT"/clusters/*/; do
    for candidate_file in README.md SKILL.md; do
        candidate="${cluster_dir}${SKILL_NAME}/${candidate_file}"
        if [[ -f "$candidate" ]]; then
            # Check if this file has a ## Roadmap section with open items
            if grep -q '^\- \[ \]' "$candidate" 2>/dev/null; then
                README_PATH="$candidate"
                break 2
            fi
            # Fall back to README.md even without items (for error reporting)
            if [[ -z "$README_PATH" && "$candidate_file" == "README.md" ]]; then
                README_PATH="$candidate"
            fi
        fi
    done
done

# Also check private clusters
if [[ -z "$README_PATH" || ! -f "$README_PATH" ]] && [[ -d "$REPO_ROOT/clusters-private/clusters" ]]; then
    for cluster_dir in "$REPO_ROOT"/clusters-private/clusters/*/; do
        for candidate_file in README.md SKILL.md; do
            candidate="${cluster_dir}${SKILL_NAME}/${candidate_file}"
            if [[ -f "$candidate" ]]; then
                if grep -q '^\- \[ \]' "$candidate" 2>/dev/null; then
                    README_PATH="$candidate"
                    break 2
                fi
                if [[ -z "$README_PATH" && "$candidate_file" == "README.md" ]]; then
                    README_PATH="$candidate"
                fi
            fi
        done
    done
fi

if [[ -z "$README_PATH" ]]; then
    echo "ERROR: Skill '$SKILL_NAME' not found in any cluster."
    exit 1
fi

# Determine mode: index or grep
MODE="index"
TARGET_INDEX=0
GREP_PATTERN=""

if [[ "$1" == "--grep" ]]; then
    MODE="grep"
    if [[ $# -lt 2 ]]; then
        echo "ERROR: --grep requires a pattern argument"
        exit 1
    fi
    GREP_PATTERN="$2"
else
    TARGET_INDEX="$1"
    if ! [[ "$TARGET_INDEX" =~ ^[0-9]+$ ]] || [[ "$TARGET_INDEX" -lt 1 ]]; then
        echo "ERROR: Item index must be a positive integer, got: $TARGET_INDEX"
        exit 1
    fi
fi

# Find and close the item
ITEM_COUNT=0
CLOSED=false
TEMP_FILE=$(mktemp)
IN_ROADMAP=false

while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]Roadmap ]]; then
        IN_ROADMAP=true
        echo "$line" >> "$TEMP_FILE"
        continue
    fi

    if [[ "$IN_ROADMAP" == true && "$line" =~ ^## ]]; then
        IN_ROADMAP=false
    fi

    if [[ "$IN_ROADMAP" == true && "$line" =~ ^-[[:space:]]\[[[:space:]]\] && "$CLOSED" == false ]]; then
        ITEM_COUNT=$((ITEM_COUNT + 1))

        SHOULD_CLOSE=false
        if [[ "$MODE" == "index" && "$ITEM_COUNT" -eq "$TARGET_INDEX" ]]; then
            SHOULD_CLOSE=true
        elif [[ "$MODE" == "grep" && "$line" == *"$GREP_PATTERN"* ]]; then
            SHOULD_CLOSE=true
        fi

        if [[ "$SHOULD_CLOSE" == true ]]; then
            # Replace "- [ ]" with "- [x]"
            closed_line="${line/\- \[ \]/- [x]}"
            echo "$closed_line" >> "$TEMP_FILE"
            CLOSED=true
            echo "✓ Closed: ${line#*] }"
            continue
        fi
    fi

    echo "$line" >> "$TEMP_FILE"
done < "$README_PATH"

if [[ "$CLOSED" == true ]]; then
    mv "$TEMP_FILE" "$README_PATH"
    echo "  in: $README_PATH"
else
    rm -f "$TEMP_FILE"
    if [[ "$MODE" == "index" ]]; then
        echo "ERROR: Skill '$SKILL_NAME' has $ITEM_COUNT open items; index $TARGET_INDEX out of range."
    else
        echo "ERROR: No open item matching '$GREP_PATTERN' in skill '$SKILL_NAME'."
    fi
    exit 1
fi
