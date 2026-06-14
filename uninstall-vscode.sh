#!/usr/bin/env bash
set -euo pipefail

# uninstall-vscode.sh — Remove grimoire VS Code integration
#
# What it does:
#   1. Removes grimoire MCP server entry from mcp.json
#   2. Removes grimoire prompts path from settings.json chat.promptFilesLocations
#   3. Optionally deletes generated prompts/ files
#
# Usage:
#   bash uninstall-vscode.sh            # interactive confirmation
#   bash uninstall-vscode.sh --apply    # non-interactive apply
#   bash uninstall-vscode.sh --dry-run  # show what would change

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPTS_DIR="${SCRIPT_DIR}/prompts"

AUTO_APPLY=false
DRY_RUN=false

for arg in "$@"; do
    case "${arg}" in
        --apply) AUTO_APPLY=true ;;
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: bash uninstall-vscode.sh [--apply|--dry-run]"
            echo ""
            echo "  default   Prompt before editing VS Code config files"
            echo "  --apply   Apply without prompting"
            echo "  --dry-run Show what would be removed"
            exit 0
            ;;
        *)
            echo "Unknown flag: ${arg}"
            echo "Usage: bash uninstall-vscode.sh [--apply|--dry-run]"
            exit 1
            ;;
    esac
done

if [[ "${AUTO_APPLY}" == "true" && "${DRY_RUN}" == "true" ]]; then
    echo "ERROR: --apply and --dry-run are mutually exclusive"
    exit 1
fi

detect_vscode_user_dir() {
    local candidate=""
    case "$(uname -s)" in
        Darwin)
            candidate="${HOME}/Library/Application Support/Code/User"
            ;;
        Linux)
            candidate="${HOME}/.config/Code/User"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if [[ -n "${APPDATA:-}" ]]; then
                candidate="${APPDATA}/Code/User"
            fi
            ;;
    esac
    if [[ -n "${candidate}" && -d "${candidate}" ]]; then
        echo "${candidate}"
    fi
}

VSCODE_USER_DIR="$(detect_vscode_user_dir)"
if [[ -z "${VSCODE_USER_DIR}" ]]; then
    echo "Could not locate VS Code user config directory."
    echo "Remove manually from mcp.json and settings.json if needed."
    exit 0
fi

MCP_PATH="${VSCODE_USER_DIR}/mcp.json"
SETTINGS_PATH="${VSCODE_USER_DIR}/settings.json"

echo "=== grimoire VS Code uninstall ==="
echo "User config: ${VSCODE_USER_DIR}"
echo ""

if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] Would remove:"
    [[ -f "${MCP_PATH}" ]] && echo "  - MCP server entry: grimoire (${MCP_PATH})"
    [[ -f "${SETTINGS_PATH}" ]] && echo "  - Prompt path from settings: ${PROMPTS_DIR}"
    if [[ -d "${PROMPTS_DIR}" ]]; then
        echo "  - Generated prompts output: ${PROMPTS_DIR}"
    fi
    exit 0
fi

if [[ "${AUTO_APPLY}" != "true" ]]; then
    printf "Proceed with uninstall from VS Code config? [y/N] "
    read -r response
    if [[ ! "${response}" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Remove grimoire server from mcp.json
if [[ -f "${MCP_PATH}" ]]; then
  # shellcheck disable=SC2016
    node -e '
const fs = require("fs");
const p = process.argv[1];
let data = {};
try {
  const raw = fs.readFileSync(p, "utf8");
  const cleaned = raw.replace(/^\uFEFF/, "").replace(/,(\s*[}\]])/g, "$1");
  data = JSON.parse(cleaned);
} catch {
  data = {};
}
if (data.servers && data.servers.grimoire) {
  delete data.servers.grimoire;
  if (Object.keys(data.servers).length === 0) delete data.servers;
  fs.writeFileSync(p, JSON.stringify(data, null, "\t") + "\n");
  console.log("Removed grimoire MCP server from mcp.json");
} else {
  console.log("No grimoire MCP server entry found in mcp.json");
}
' "${MCP_PATH}"
else
    echo "No mcp.json found; skipping MCP removal."
fi

# Remove prompts path from settings.json
if [[ -f "${SETTINGS_PATH}" ]]; then
  # shellcheck disable=SC2016
    node -e '
const fs = require("fs");
const p = process.argv[1];
const promptsPath = process.argv[2];
let data = {};
try {
  const raw = fs.readFileSync(p, "utf8");
  const cleaned = raw.replace(/^\uFEFF/, "").replace(/,(\s*[}\]])/g, "$1");
  data = JSON.parse(cleaned);
} catch {
  data = {};
}

const key = "chat.promptFilesLocations";
if (Array.isArray(data[key])) {
  const before = data[key].length;
  data[key] = data[key].filter(e => !(e && typeof e.path === "string" && e.path === promptsPath));
  const after = data[key].length;
  if (after === 0) {
    delete data[key];
  }
  if (before !== after) {
    fs.writeFileSync(p, JSON.stringify(data, null, 4) + "\n");
    console.log("Removed grimoire prompts path from settings.json");
  } else {
    console.log("No grimoire prompts path found in settings.json");
  }
} else {
  console.log("No chat.promptFilesLocations array found in settings.json");
}
' "${SETTINGS_PATH}" "${PROMPTS_DIR}"
else
    echo "No settings.json found; skipping prompt path removal."
fi

# Delete generated prompts output
if [[ -d "${PROMPTS_DIR}" ]]; then
    rm -rf "${PROMPTS_DIR:?}"/*
    echo "Deleted generated prompt files in: ${PROMPTS_DIR}"
else
    echo "No prompts directory found; skipping prompt cleanup."
fi

echo ""
echo "Uninstall complete."
