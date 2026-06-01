#!/usr/bin/env bash
# install.sh
# Installs session-skill-extractor into ~/.claude/skills/ and
# wires the Stop hook into ~/.claude/settings.json.
#
# Usage:
#   bash install.sh           # full install
#   bash install.sh --dry-run # preview only

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SKILL_NAME="session-skill-extractor"
SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DEST="${HOME}/.claude/skills/${SKILL_NAME}"
SETTINGS_FILE="${HOME}/.claude/settings.json"
PROPOSED_DIR="${HOME}/.claude/proposed-skills"

log()  { echo "[install] $*"; }
run()  { if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi; }

# ---- 1. Verify claude CLI is available ---------------------------------
if ! command -v claude &>/dev/null; then
    log "ERROR: claude CLI not found in PATH."
    log "Install Claude Code first: https://code.claude.com/docs/en/quickstart"
    exit 1
fi
log "claude CLI found at: $(which claude)"

# ---- 2. Verify python3 is available ------------------------------------
if ! command -v python3 &>/dev/null; then
    log "ERROR: python3 not found in PATH."
    exit 1
fi
log "python3 found at: $(which python3)"

# ---- 3. Copy skill files -----------------------------------------------
log "Installing skill to ${SKILL_DEST}..."
run mkdir -p "${SKILL_DEST}/scripts"
run mkdir -p "${SKILL_DEST}/templates"
run mkdir -p "${PROPOSED_DIR}"

run cp "${SKILL_SRC}/SKILL.md"                          "${SKILL_DEST}/SKILL.md"
run cp "${SKILL_SRC}/config.json"                       "${SKILL_DEST}/config.json"
run cp "${SKILL_SRC}/scripts/extract_patterns.py"       "${SKILL_DEST}/scripts/extract_patterns.py"
run cp "${SKILL_SRC}/scripts/generate_stubs.py"         "${SKILL_DEST}/scripts/generate_stubs.py"
run cp "${SKILL_SRC}/scripts/stop_hook.sh"              "${SKILL_DEST}/scripts/stop_hook.sh"

run chmod +x "${SKILL_DEST}/scripts/stop_hook.sh"
run chmod +x "${SKILL_DEST}/scripts/extract_patterns.py"
run chmod +x "${SKILL_DEST}/scripts/generate_stubs.py"

# ---- 4. Wire Stop hook into ~/.claude/settings.json --------------------
HOOK_ENTRY=$(cat <<'JSON'
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "bash ~/.claude/skills/session-skill-extractor/scripts/stop_hook.sh"
    }
  ]
}
JSON
)

if ! command -v jq &>/dev/null; then
    log ""
    log "WARNING: jq not found. Add the following to ${SETTINGS_FILE} manually under hooks.Stop:"
    echo "$HOOK_ENTRY"
    log ""
    log "Install jq to automate this step: brew install jq"
else
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        log "Creating ${SETTINGS_FILE}..."
        run bash -c "echo '{\"hooks\":{\"Stop\":[]}}' > \"${SETTINGS_FILE}\""
    fi

    EXISTING=$(jq \
        '.hooks.Stop // [] | map(select(.hooks[]?.command // "" | contains("session-skill-extractor"))) | length' \
        "$SETTINGS_FILE" 2>/dev/null || echo 0)

    if [[ "$EXISTING" -gt 0 ]]; then
        log "Stop hook already registered in ${SETTINGS_FILE}. Skipping."
    else
        log "Adding Stop hook to ${SETTINGS_FILE}..."
        run bash -c "jq --argjson hook '$HOOK_ENTRY' \
            '.hooks.Stop = (.hooks.Stop // []) + [\$hook]' \
            \"${SETTINGS_FILE}\" > /tmp/.claude_settings_tmp && \
            mv /tmp/.claude_settings_tmp \"${SETTINGS_FILE}\""
        log "Stop hook registered."
    fi
fi

# ---- Done --------------------------------------------------------------
log ""
log "Installation complete."
log ""
log "Manual run against most recent session:"
log "  python3 ${SKILL_DEST}/scripts/extract_patterns.py | \\"
log "  python3 ${SKILL_DEST}/scripts/generate_stubs.py"
log ""
log "Manual run against a specific project:"
log "  python3 ${SKILL_DEST}/scripts/extract_patterns.py \\"
log "    --project-dir ~/.claude/projects/<hash> | \\"
log "  python3 ${SKILL_DEST}/scripts/generate_stubs.py"
log ""
log "Proposed stubs will appear in: ${PROPOSED_DIR}"
log "Promote: cp -r ${PROPOSED_DIR}/<name> ~/.claude/skills/<name>"
