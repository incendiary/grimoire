#!/usr/bin/env bash
# skill-dependency-graph.sh — Generate skill reference dependencies from SKILL.md/README.md
#
# Usage:
#   bash scripts/skill-dependency-graph.sh
#   bash scripts/skill-dependency-graph.sh --dot
#
# Output:
#   default: tab-separated edges "source<TAB>target"
#   --dot: Graphviz DOT directed graph

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="text"

if [[ "${1:-}" == "--dot" ]]; then
    MODE="dot"
fi

# Collect all known skill names (public + private if mounted)
declare -a skill_dirs
skill_dirs=("${REPO_ROOT}/clusters")
if [[ -d "${REPO_ROOT}/clusters-private/clusters" ]]; then
    skill_dirs+=("${REPO_ROOT}/clusters-private/clusters")
fi

TMP_SKILLS="$(mktemp)"
TMP_EDGES="$(mktemp)"
trap 'rm -f "${TMP_SKILLS}" "${TMP_EDGES}"' EXIT

for root in "${skill_dirs[@]}"; do
    for skill_path in "${root}"/*/*; do
        [[ -d "${skill_path}" ]] || continue
        basename "${skill_path}" >> "${TMP_SKILLS}"
    done
done

sort -u "${TMP_SKILLS}" -o "${TMP_SKILLS}"

# Build edges by scanning backticked tokens in SKILL/README docs
for root in "${skill_dirs[@]}"; do
    for skill_path in "${root}"/*/*; do
        [[ -d "${skill_path}" ]] || continue
        source_skill="$(basename "${skill_path}")"

        for doc in "${skill_path}/SKILL.md" "${skill_path}/README.md"; do
            [[ -f "${doc}" ]] || continue

            # Extract backticked tokens and keep those that match known skill names
            # shellcheck disable=SC2016
            while IFS= read -r token; do
                [[ -n "${token}" ]] || continue
                if [[ "${token}" != "${source_skill}" ]] && grep -Fxq "${token}" "${TMP_SKILLS}"; then
                    printf "%s\t%s\n" "${source_skill}" "${token}" >> "${TMP_EDGES}"
                fi
            done < <(grep -oE '`[a-z0-9][a-z0-9-]*`' "${doc}" | tr -d '`' || true)
        done
    done
done

if [[ ! -s "${TMP_EDGES}" ]]; then
    echo "No skill dependencies found."
    exit 0
fi

sort -u "${TMP_EDGES}" -o "${TMP_EDGES}"

if [[ "${MODE}" == "dot" ]]; then
    echo "digraph skill_dependencies {"
    echo "  rankdir=LR;"
    echo "  node [shape=box, style=rounded];"
    while IFS=$'\t' read -r src dst; do
        printf '  "%s" -> "%s";\n' "${src}" "${dst}"
    done < "${TMP_EDGES}"
    echo "}"
else
    cat "${TMP_EDGES}"
fi
