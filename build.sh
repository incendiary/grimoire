#!/usr/bin/env bash
set -euo pipefail

# build.sh — Generate VS Code prompt files from SKILL.md source
#
# Reads clusters/*/*/SKILL.md files that have a Type: field and generates
# .prompt.md files in the prompts/ directory.
#
# Usage:
#   bash build.sh              # generate all prompt files
#   bash build.sh --clean      # remove prompts/ and regenerate

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPTS_DIR="${SCRIPT_DIR}/prompts"
CLUSTERS_DIR="${SCRIPT_DIR}/clusters"
PRIVATE_CLUSTERS_DIR="${SCRIPT_DIR}/clusters-private/clusters"

# --- Clean mode ---
if [[ "${1:-}" == "--clean" ]]; then
    rm -rf "${PROMPTS_DIR}"
    echo "Cleaned ${PROMPTS_DIR}"
fi

mkdir -p "${PROMPTS_DIR}"

generated=0
skipped=0

# Collect SKILL.md from public clusters and private submodule (if present)
SKILL_PATHS=("${CLUSTERS_DIR}"/*/SKILL.md "${CLUSTERS_DIR}"/*/*/SKILL.md)
if [[ -d "${PRIVATE_CLUSTERS_DIR}" ]]; then
    SKILL_PATHS+=("${PRIVATE_CLUSTERS_DIR}"/*/SKILL.md "${PRIVATE_CLUSTERS_DIR}"/*/*/SKILL.md)
fi

for skill_md in "${SKILL_PATHS[@]}"; do
    [[ -f "${skill_md}" ]] || continue

    # Only process skills with a Type: field
    if ! grep -q '> \*\*Type:\*\*' "${skill_md}" 2>/dev/null; then
        skipped=$((skipped + 1))
        continue
    fi

    # Extract metadata
    skill_dir="$(dirname "${skill_md}")"
    skill_name="$(basename "${skill_dir}")"

    # Extract description (first paragraph after ## Description)
    description=$(sed -n '/^## Description/,/^##/{/^## Description/d;/^##/d;p;}' "${skill_md}" | head -5 | sed '/^$/d' | tr '\n' ' ' | sed 's/  */ /g;s/^ //;s/ $//')

    # Extract the main content (everything from ## Description onward, excluding header)
    content=$(sed -n '/^## Description/,$p' "${skill_md}")

    # Escape quotes in description for YAML front matter
    safe_description="${description:0:200}"
    safe_description="${safe_description//\"/\\\"}"

    # Generate .prompt.md
    output_file="${PROMPTS_DIR}/${skill_name}.prompt.md"

    {
        echo "---"
        echo "mode: agent"
        echo "description: \"${safe_description}\""
        echo "---"
        echo ""
        echo "# ${skill_name}"
        echo ""
        echo "${content}"
    } > "${output_file}"

    generated=$((generated + 1))
done

echo ""
echo "=== build.sh summary ==="
echo "Generated: ${generated} prompt files in ${PROMPTS_DIR}/"
echo "Skipped:   ${skipped} (no Type: field)"
echo ""
if [[ ${generated} -gt 0 ]]; then
    echo "Prompt files ready. Point VS Code to:"
    echo "  \"chat.promptFilesLocations\": [{\"path\": \"${PROMPTS_DIR}\"}]"
fi
