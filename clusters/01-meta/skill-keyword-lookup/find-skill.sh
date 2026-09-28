#!/usr/bin/env bash
# find-skill.sh — keyword lookup for grimoire skills
set -euo pipefail

LIMIT=10
INCLUDE_PRIVATE=false
JSON_OUTPUT=false

usage() {
    cat <<'EOF'
Usage: bash find-skill.sh [--limit N] [--include-private] [--json] <keywords...>

Examples:
  bash find-skill.sh devops standard roadmap readme
  bash find-skill.sh --limit 5 lint black ruff
  bash find-skill.sh --include-private odpc syscall
  bash find-skill.sh --json devops roadmap

Scoring:
- Counts keyword hits in SKILL.md and README.md for each skill (a keyword's known
  synonyms, e.g. "standards" -> "practices", are searched too)
- Boosts score if keyword appears in skill directory name
EOF
}

# Known synonym pairs for grimoire terminology, so a search for one term also
# matches skills that only use the other. Bash 3.2 (macOS default) has no
# associative arrays, hence the case statement instead of a lookup table.
synonyms_for() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    standards) printf 'practices' ;;
    practices) printf 'standards' ;;
    ci) printf 'pipeline|workflow' ;;
    pipeline) printf 'ci|workflow' ;;
    workflow) printf 'ci|pipeline' ;;
    lint) printf 'ruff|black|shellcheck' ;;
    format | formatting) printf 'black|ruff' ;;
    release) printf 'version|tag|changelog' ;;
    *) printf '' ;;
    esac
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
    --json)
        JSON_OUTPUT=true
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
if [[ "$INCLUDE_PRIVATE" == "true" ]]; then
    for _priv_root in "$ROOT"/clusters-*/clusters; do
        [[ -d "$_priv_root" ]] && search_roots+=("$_priv_root")
    done
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

        synonyms="$(synonyms_for "$term")"
        if [[ -n "$synonyms" ]]; then
            search_pattern="${term}|${synonyms}"
        else
            search_pattern="$term"
        fi

        if [[ -f "$skill_file" ]]; then
            hits="$( (grep -i -o -E -- "$search_pattern" "$skill_file" 2>/dev/null || true) | wc -l | tr -d ' ' )"
            term_hits=$((term_hits + hits))
        fi

        if [[ -f "$readme_file" ]]; then
            hits="$( (grep -i -o -E -- "$search_pattern" "$readme_file" 2>/dev/null || true) | wc -l | tr -d ' ' )"
            term_hits=$((term_hits + hits))
        fi

        # Boost if term (or a synonym) appears in skill directory name.
        if echo "$skill_name" | grep -qi -E -- "$search_pattern"; then
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

if [[ "$JSON_OUTPUT" == "true" ]]; then
    command -v jq >/dev/null 2>&1 || {
        echo "ERROR: --json requires jq" >&2
        exit 2
    }
fi

if [[ ${#results[@]} -eq 0 ]]; then
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        jq -n --arg query "${TERMS[*]}" '{query: $query, results: []}'
    else
        echo "No matching skills found for: ${TERMS[*]}"
    fi
    exit 0
fi

sorted_results="$(printf '%s\n' "${results[@]}" | sort -t'|' -k1,1nr -k2,2 -k3,3 | head -n "$LIMIT")"

if [[ "$JSON_OUTPUT" == "true" ]]; then
    json_items=()
    while IFS='|' read -r score cluster skill path matched; do
        IFS=',' read -ra matched_arr <<<"$matched"
        item="$(jq -n \
            --argjson score "$score" \
            --arg cluster "$cluster" \
            --arg skill "$skill" \
            --arg path "$path" \
            --args '{score: $score, cluster: $cluster, skill: $skill, path: $path, matched: $ARGS.positional}' \
            "${matched_arr[@]}")"
        json_items+=("$item")
    done <<<"$sorted_results"

    printf '%s\n' "${json_items[@]}" \
        | jq -n --arg query "${TERMS[*]}" '{query: $query, results: [inputs]}'
    exit 0
fi

echo "=== skill keyword lookup ==="
echo "Query: ${TERMS[*]}"
echo ""

printf '%s\n' "$sorted_results" \
    | awk -F'|' '{
        printf "- [%s] %s/%s\n", $1, $2, $3
        printf "  path: %s\n", $4
        printf "  matched: %s\n", $5
      }'
