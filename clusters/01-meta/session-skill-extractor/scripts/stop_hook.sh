#!/usr/bin/env bash
# stop_hook.sh
#
# Claude Code Stop hook for session-skill-extractor.
# Fires after each of Claude's turns. Only runs full extraction when the
# session appears to be genuinely ending (user types a closing phrase).
#
# Claude Code passes hook context as JSON via stdin:
# {
#   "session_id": "...",
#   "stop_reason": "end_turn | max_tokens | stop_sequence",
#   "transcript_path": "..." (may not always be present)
# }
#
# Install in ~/.claude/settings.json:
# {
#   "hooks": {
#     "Stop": [{
#       "matcher": "",
#       "hooks": [{
#         "type": "command",
#         "command": "bash ~/.claude/skills/session-skill-extractor/scripts/stop_hook.sh"
#       }]
#     }]
#   }
# }

set -euo pipefail

SKILL_DIR="${HOME}/.claude/skills/session-skill-extractor"
CONFIG_FILE="${SKILL_DIR}/config.json"
EXTRACT_SCRIPT="${SKILL_DIR}/scripts/extract_patterns.py"
STUB_SCRIPT="${SKILL_DIR}/scripts/generate_stubs.py"
LOG_FILE="${HOME}/.claude/skills/session-skill-extractor/extraction.log"

# Read stdin (hook context JSON)
HOOK_INPUT=$(cat)

# Parse stop reason - only run on genuine session end, not every turn
STOP_REASON=$(echo "$HOOK_INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('stop_reason',''))" 2>/dev/null || echo "")

# Only proceed on end_turn. Skip on max_tokens (session is still running).
# Note: Claude Code may not always send stop_reason - we run anyway if we can't determine it.
if [[ "$STOP_REASON" == "max_tokens" ]]; then
    exit 0
fi

# Check transcript path from hook context
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null || echo "")

# Determine which project we're in via CLAUDE_PROJECT_DIR env var (set by Claude Code)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"

# Run extraction
{
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') Stop hook fired ==="
    echo "stop_reason: ${STOP_REASON}"
    echo "project_dir: ${PROJECT_DIR}"

    if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
        # Preferred: use the transcript path Claude Code gave us
        python3 "$EXTRACT_SCRIPT" \
            --session-file "$TRANSCRIPT_PATH" \
            --config "$CONFIG_FILE" \
            2>>"$LOG_FILE" | \
        python3 "$STUB_SCRIPT" \
            2>>"$LOG_FILE"
    elif [[ -n "$PROJECT_DIR" ]]; then
        # Fallback: find latest JSONL in the project dir
        python3 "$EXTRACT_SCRIPT" \
            --project-dir "${HOME}/.claude/projects/$(basename "$PROJECT_DIR")" \
            --config "$CONFIG_FILE" \
            2>>"$LOG_FILE" | \
        python3 "$STUB_SCRIPT" \
            2>>"$LOG_FILE"
    else
        # Last resort: find latest session across all projects
        python3 "$EXTRACT_SCRIPT" \
            --config "$CONFIG_FILE" \
            2>>"$LOG_FILE" | \
        python3 "$STUB_SCRIPT" \
            2>>"$LOG_FILE"
    fi

    echo "=== Extraction complete ==="
} >> "$LOG_FILE" 2>&1

# Exit cleanly - never block Claude Code
exit 0
