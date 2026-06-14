#!/usr/bin/env bash
set -euo pipefail

# uninstall-all.sh — Remove grimoire-managed skills from a target skills directory
#
# Usage:
#   bash uninstall-all.sh            # interactive confirmation
#   bash uninstall-all.sh --apply    # non-interactive removal
#   bash uninstall-all.sh --dry-run  # list skills that would be removed
#   bash uninstall-all.sh --skills-dir /path/to/skills

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${HOME}/.claude/skills"
CLUSTERS_DIR="${SCRIPT_DIR}/clusters"
PRIVATE_CLUSTERS_DIR="${SCRIPT_DIR}/clusters-private/clusters"

AUTO_APPLY=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) AUTO_APPLY=true ;;
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: bash uninstall-all.sh [--apply|--dry-run] [--skills-dir <path>]"
            echo ""
            echo "  default   Prompt before removing installed grimoire skills"
            echo "  --apply   Remove without prompting"
            echo "  --dry-run Show what would be removed"
            echo "  --skills-dir <path>  Target skills directory (default: ~/.claude/skills)"
            exit 0
            ;;
        --skills-dir)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --skills-dir requires a path"
                exit 1
            fi
            SKILLS_DIR="$2"
            shift
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Usage: bash uninstall-all.sh [--apply|--dry-run] [--skills-dir <path>]"
            exit 1
            ;;
    esac
    shift
done

if [[ "${AUTO_APPLY}" == "true" && "${DRY_RUN}" == "true" ]]; then
    echo "ERROR: --apply and --dry-run are mutually exclusive"
    exit 1
fi

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "No skills directory found at: ${SKILLS_DIR}"
    exit 0
fi

declare -a cluster_roots
declare -a managed_skills
declare -a removable

cluster_roots=("${CLUSTERS_DIR}")
if [[ -d "${PRIVATE_CLUSTERS_DIR}" ]]; then
    cluster_roots+=("${PRIVATE_CLUSTERS_DIR}")
fi

for cluster_root in "${cluster_roots[@]}"; do
    for skill_path in "${cluster_root}"/*/*; do
        [[ -d "${skill_path}" ]] || continue
        managed_skills+=("$(basename "${skill_path}")")
    done
done

# Deduplicate while preserving order
unique_skills=()
for s in "${managed_skills[@]}"; do
    seen=false
    for u in "${unique_skills[@]:-}"; do
        if [[ "${u}" == "${s}" ]]; then
            seen=true
            break
        fi
    done
    if [[ "${seen}" == "false" ]]; then
        unique_skills+=("${s}")
    fi
done

for skill in "${unique_skills[@]:-}"; do
    dest="${SKILLS_DIR}/${skill}"
    if [[ -d "${dest}" ]]; then
        removable+=("${skill}")
    fi
done

if [[ ${#removable[@]} -eq 0 ]]; then
    echo "No grimoire-managed skills found in ${SKILLS_DIR}"
    exit 0
fi

echo "Skills managed by grimoire that are currently installed:"
for s in "${removable[@]}"; do
    echo "  - ${s}"
done
echo ""

if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] No changes made."
    exit 0
fi

if [[ "${AUTO_APPLY}" != "true" ]]; then
    printf "Remove these %d skill(s) from %s? [y/N] " "${#removable[@]}" "${SKILLS_DIR}"
    read -r reply
    if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

removed=()
for s in "${removable[@]}"; do
    rm -rf "${SKILLS_DIR:?}/${s}"
    removed+=("${s}")
done

echo ""
echo "Removed (${#removed[@]}):"
for s in "${removed[@]}"; do
    echo "  - ${s}"
done
