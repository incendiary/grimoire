#!/usr/bin/env bash
set -euo pipefail

# install-all.sh — Install grimoire skills for Claude Code
#
# Usage:
#   bash install-all.sh            # install new skills, skip existing
#   bash install-all.sh --update   # backup + overwrite existing skills
#   bash install-all.sh --force    # overwrite existing skills (no backup)

UPDATE_MODE=false
FORCE_MODE=false

for arg in "$@"; do
    case "${arg}" in
        --update) UPDATE_MODE=true ;;
        --force) FORCE_MODE=true ;;
        --help|-h)
            echo "Usage: bash install-all.sh [--update|--force]"
            echo ""
            echo "  default   Install new skills only; skip existing"
            echo "  --update  Backup and overwrite existing skills (keeps last 5 backups per skill)"
            echo "  --force   Overwrite existing skills without backup"
            exit 0
            ;;
        *)
            echo "Unknown flag: ${arg}"
            echo "Usage: bash install-all.sh [--update|--force]"
            exit 1
            ;;
    esac
done

if [[ "${UPDATE_MODE}" == "true" && "${FORCE_MODE}" == "true" ]]; then
    echo "ERROR: --update and --force are mutually exclusive"
    exit 1
fi

SKILLS_DIR="${HOME}/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTERS_DIR="${SCRIPT_DIR}/clusters"
PRIVATE_CLUSTERS_DIR="${SCRIPT_DIR}/clusters-private/clusters"
BACKUP_ROOT="${SKILLS_DIR}/.backups"

mkdir -p "${SKILLS_DIR}"

if [[ "${UPDATE_MODE}" == "true" ]]; then
    mkdir -p "${BACKUP_ROOT}"
fi

installed=()
skipped=()
updated=()
forced=()

backup_skill_dir() {
    local skill_name="$1"
    local src_dir="$2"
    local skill_backup_root="${BACKUP_ROOT}/${skill_name}"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup_dir="${skill_backup_root}/${timestamp}"

    mkdir -p "${skill_backup_root}"
    mv "${src_dir}" "${backup_dir}"

    # Prune to latest 5 backups
    local count
    count=$(find "${skill_backup_root}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    if [[ "${count}" -gt 5 ]]; then
        find "${skill_backup_root}" -mindepth 1 -maxdepth 1 -type d -print0 \
            | xargs -0 ls -1dt \
            | tail -n +6 \
            | while IFS= read -r old; do
                rm -rf "${old}"
            done
    fi
}

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
        if [[ "${UPDATE_MODE}" == "true" ]]; then
            backup_skill_dir "${skill_name}" "${dest}"
            cp -r "${skill_path}" "${dest}"
            updated+=("${skill_name}")
        elif [[ "${FORCE_MODE}" == "true" ]]; then
            rm -rf "${dest}"
            cp -r "${skill_path}" "${dest}"
            forced+=("${skill_name}")
        else
            skipped+=("${skill_name}")
        fi
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

if [[ ${#updated[@]} -gt 0 ]]; then
    echo "Updated with backup (${#updated[@]}):"
    for s in "${updated[@]}"; do echo "  * ${s}"; done
else
    echo "Updated with backup: none"
fi

if [[ ${#forced[@]} -gt 0 ]]; then
    echo "Overwritten (force, no backup) (${#forced[@]}):"
    for s in "${forced[@]}"; do echo "  ! ${s}"; done
else
    echo "Overwritten (force): none"
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "Skipped — already present (${#skipped[@]}):"
    for s in "${skipped[@]}"; do echo "  ~ ${s}"; done
else
    echo "Skipped: none"
fi
