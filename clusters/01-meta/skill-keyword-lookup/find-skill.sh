#!/usr/bin/env bash
# find-skill.sh — keyword lookup for grimoire skills
set -euo pipefail

LIMIT=10
INCLUDE_PRIVATE=false

usage() {
    cat <<'EOF'
Usage: bash find-skill.sh [--limit N] [--include-private] <keywords...>

Examples:
  bash find-skill.sh devops standard roadmap readme
  bash find-skill.sh --limit 5 lint black ruff
  bash find-skill.sh --include-private odpc syscall

Scoring:
- Counts keyword hits in SKILL.md and README.md for each skill
- Boosts score if keyword appears in skill directory name
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --limit)
        [[ $# -ge 2 ]] || {
            echo "ERROR: --limit requires a value" >&2
            exit 2
        }
        LIMIT="$2"
        shift 2
        ;;
    --include-private)
        INCLUDE_PRIVATE=true
        shift
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    --*)
        echo "ERROR: Unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    *)
        break
        ;;
    esac
done

if [[ $# -lt 1 ]]; then
    usage >&2
    exit 2
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TERMS=("$@")

search_roots=("$ROOT/clusters")
if [[ "$INCLUDE_PRIVATE" == "true" && -d "$ROOT/clusters-private/clusters" ]]; then
    search_roots+=("$ROOT/clusters-private/clusters")
fi

skill_dirs=()
for base in "${search_roots[@]}"; do
    while IFS= read -r dir; do
        skill_dirs+=("$dir")
    done < <(find "$base" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | sort)
done

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
    echo "No skill directories found." >&2
    exit 1
fi

results=()

for dir in "${skill_dirs[@]}"; do
    skill_name="$(basename "$dir")"
    cluster_name="$(basename "$(dirname "$dir")")"

    skill_file="$dir/SKILL.md"
    readme_file="$dir/README.md"

    score=0
    matched_terms=()

    for term in "${TERMS[@]}"; do
        term_hits=0

        if [[ -f "$skill_file" ]]; then
            hits="$( (grep -i -o -- "$term" "$skill_file" 2>/dev/null || true) | wc -l | tr -d ' ' )"
            term_hits=$((term_hits + hits))
        fi

        if [[ -f "$readme_file" ]]; then
            hits="$( (grep -i -o -- "$term" "$readme_file" 2>/dev/null || true) | wc -l | tr -d ' ' )"
            term_hits=$((term_hits + hits))
        fi

        # Boost if term appears in skill directory name.
        if echo "$skill_name" | grep -qi -- "$term"; then
            term_hits=$((term_hits + 2))
        fi

        if [[ $term_hits -gt 0 ]]; then
            score=$((score + term_hits))
            matched_terms+=("$term")
        fi
    done

    if [[ $score -gt 0 ]]; then
        rel_dir="${dir#"$ROOT"/}"
        results+=("$score|$cluster_name|$skill_name|$rel_dir|$(printf '%s,' "${matched_terms[@]}" | sed 's/,$//')")
    fi
done

if [[ ${#results[@]} -eq 0 ]]; then
    echo "No matching skills found for: ${TERMS[*]}"
    exit 0
fi

echo "=== skill keyword lookup ==="
echo "Query: ${TERMS[*]}"
echo ""

printf '%s\n' "${results[@]}" \
    | sort -t'|' -k1,1nr -k2,2 -k3,3 \
    | head -n "$LIMIT" \
    | awk -F'|' '{
        printf "- [%s] %s/%s\n", $1, $2, $3
        printf "  path: %s\n", $4
        printf "  matched: %s\n", $5
      }'
