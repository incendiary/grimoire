#!/usr/bin/env bash
# roadmap-collect.sh — Collects open roadmap items from all skill READMEs
# Outputs a markdown summary grouped by cluster.
#
# Usage: bash scripts/roadmap-collect.sh [--json]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON_MODE=false

if [[ "${1:-}" == "--json" ]]; then
    JSON_MODE=true
fi

collect_items() {
    local cluster_dir="$1"
    local cluster_name
    cluster_name="$(basename "$cluster_dir")"

    for readme in "$cluster_dir"/*/README.md; do
        [ -f "$readme" ] || continue
        local skill_name
        skill_name="$(basename "$(dirname "$readme")")"

        # Extract open items (unchecked checkboxes) from ## Roadmap section
        local in_roadmap=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]Roadmap ]]; then
                in_roadmap=true
                continue
            fi
            if [[ "$in_roadmap" == true && "$line" =~ ^## ]]; then
                break
            fi
            if [[ "$in_roadmap" == true && "$line" =~ ^-[[:space:]]\[[[:space:]]\] ]]; then
                local item="${line#*] }"
                if [[ "$JSON_MODE" == true ]]; then
                    printf '{"cluster":"%s","skill":"%s","item":"%s"}\n' \
                        "$cluster_name" "$skill_name" "$item"
                else
                    printf "  - **%s**: %s\n" "$skill_name" "$item"
                fi
            fi
        done < "$readme"
    done
}

if [[ "$JSON_MODE" == true ]]; then
    echo "["
    first=true
    for cluster_dir in "$REPO_ROOT"/clusters/*/; do
        [ -d "$cluster_dir" ] || continue
        while IFS= read -r json_line; do
            [ -z "$json_line" ] && continue
            if [[ "$first" == true ]]; then
                echo "  $json_line"
                first=false
            else
                echo "  ,$json_line"
            fi
        done < <(collect_items "$cluster_dir")
    done
    echo "]"
else
    total_open=0
    total_done=0

    for cluster_dir in "$REPO_ROOT"/clusters/*/; do
        [ -d "$cluster_dir" ] || continue
        cluster_name="$(basename "$cluster_dir")"
        items="$(collect_items "$cluster_dir")"
        if [ -n "$items" ]; then
            echo "### $cluster_name"
            echo ""
            echo "$items"
            echo ""
            count=$(echo "$items" | wc -l)
            total_open=$((total_open + count))
        fi
    done

    # Count completed items too
    total_done=$(grep -rch "\- \[x\]" "$REPO_ROOT"/clusters/*/*/README.md 2>/dev/null | paste -sd+ - | bc)

    echo "---"
    echo ""
    echo "**Summary:** $total_open open items | $total_done completed items"
fi
