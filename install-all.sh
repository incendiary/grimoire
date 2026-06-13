#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTERS_DIR="${SCRIPT_DIR}/clusters"
PRIVATE_CLUSTERS_DIR="${SCRIPT_DIR}/clusters-private/clusters"

mkdir -p "${SKILLS_DIR}"

installed=()
skipped=()

# Collect all cluster paths (public + private submodule if present)
CLUSTER_PATHS=("${CLUSTERS_DIR}")
if [[ -d "${PRIVATE_CLUSTERS_DIR}" ]]; then
    CLUSTER_PATHS+=("${PRIVATE_CLUSTERS_DIR}")
fi

for cluster_root in "${CLUSTER_PATHS[@]}"; do
for skill_path in "${cluster_root}"/*/*; do
    [[ -d "${skill_path}" ]] || continue
    skill_name="$(basename "${skill_path}")"
    dest="${SKILLS_DIR}/${skill_name}"

    if [[ -d "${dest}" ]]; then
        skipped+=("${skill_name}")
    else
        cp -r "${skill_path}" "${dest}"
        installed+=("${skill_name}")
    fi
done

done  # end cluster_root loop

# Wire the Stop hook for session-skill-extractor if it was just installed
if [[ " ${installed[*]:-} " == *" session-skill-extractor "* ]]; then
    if [[ -f "${SKILLS_DIR}/session-skill-extractor/install.sh" ]]; then
        echo "Running session-skill-extractor/install.sh..."
        bash "${SKILLS_DIR}/session-skill-extractor/install.sh"
    fi
fi

echo ""
echo "=== install-all summary ==="
if [[ ${#installed[@]} -gt 0 ]]; then
    echo "Installed (${#installed[@]}):"
    for s in "${installed[@]}"; do echo "  + ${s}"; done
else
    echo "Installed: none"
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "Skipped — already present (${#skipped[@]}):"
    for s in "${skipped[@]}"; do echo "  ~ ${s}"; done
else
    echo "Skipped: none"
fi
