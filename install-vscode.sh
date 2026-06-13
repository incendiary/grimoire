#!/usr/bin/env bash
set -euo pipefail

# install-vscode.sh — Set up grimoire for VS Code (MCP server + prompt files)
#
# What it does:
#   1. Builds the MCP server (npm ci + tsc)
#   2. Generates prompt files (build.sh)
#   3. Detects VS Code settings.json on disk
#   4. Merges grimoire config into settings (with confirmation or --apply)
#
# Usage:
#   bash install-vscode.sh            # interactive — prompts before editing settings
#   bash install-vscode.sh --apply    # non-interactive — auto-edits without prompting
#   bash install-vscode.sh --dry-run  # show what would be added, don't write

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_SERVER_DIR="${SCRIPT_DIR}/mcp-server"

# --- Parse flags ---
AUTO_APPLY=false
DRY_RUN=false
for arg in "$@"; do
    case "${arg}" in
        --apply)   AUTO_APPLY=true ;;
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "Usage: bash install-vscode.sh [--apply|--dry-run]"
            echo ""
            echo "  --apply    Edit VS Code settings.json without prompting"
            echo "  --dry-run  Show what would be merged, don't write anything"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown flag: ${arg}"
            echo "Usage: bash install-vscode.sh [--apply|--dry-run]"
            exit 1
            ;;
    esac
done

echo "=== grimoire VS Code setup ==="
echo ""

# --- Step 1: Build MCP server ---
echo "[1/4] Building MCP server..."
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found. Install Node 22+ first."
    exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
if [[ "${NODE_VERSION}" -lt 22 ]]; then
    echo "WARNING: Node ${NODE_VERSION} detected. Node 22+ recommended."
fi

cd "${MCP_SERVER_DIR}"
npm ci --silent
npm run build --silent
echo "  ✓ MCP server built"

# --- Step 2: Generate prompt files ---
echo "[2/4] Generating prompt files..."
cd "${SCRIPT_DIR}"
bash build.sh --clean
echo "  ✓ Prompt files generated"

# --- Step 3: Detect VS Code settings.json ---
echo "[3/4] Detecting VS Code settings..."

detect_settings_path() {
    local candidate=""
    case "$(uname -s)" in
        Darwin)
            candidate="${HOME}/Library/Application Support/Code/User/settings.json"
            ;;
        Linux)
            candidate="${HOME}/.config/Code/User/settings.json"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if [[ -n "${APPDATA:-}" ]]; then
                candidate="${APPDATA}/Code/User/settings.json"
            fi
            ;;
    esac
    if [[ -n "${candidate}" && -f "${candidate}" ]]; then
        echo "${candidate}"
    fi
}

SETTINGS_PATH="$(detect_settings_path)"

# --- Step 4: Merge settings ---
echo "[4/4] Configuring VS Code settings..."
echo ""

# The JSON snippet we want to ensure exists in settings.json
GRIMOIRE_CONFIG=$(node -e "
const config = {
    'chat.promptFilesLocations': [
        { path: process.argv[1] }
    ],
    'mcp': {
        servers: {
            grimoire: {
                command: 'node',
                args: [process.argv[2]]
            }
        }
    }
};
console.log(JSON.stringify(config, null, 4));
" "${SCRIPT_DIR}/prompts" "${MCP_SERVER_DIR}/dist/server.js")

if [[ -z "${SETTINGS_PATH}" ]]; then
    # Cannot find settings.json — fall back to manual instructions
    echo "  ⚠ Could not locate VS Code settings.json on disk."
    echo ""
    echo "  Add the following to your settings.json manually:"
    echo ""
    echo "${GRIMOIRE_CONFIG}"
    echo ""
    echo "  Common locations:"
    echo "    macOS:   ~/Library/Application Support/Code/User/settings.json"
    echo "    Linux:   ~/.config/Code/User/settings.json"
    echo "    Windows: %APPDATA%\\Code\\User\\settings.json"
    echo ""
else
    echo "  Found: ${SETTINGS_PATH}"
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "  [dry-run] Would merge the following into settings.json:"
        echo ""
        echo "${GRIMOIRE_CONFIG}"
        echo ""
        echo "  No changes written."
    else
        # Deep-merge using Node.js (already a prerequisite)
        merge_settings() {
            node -e "
const fs = require('fs');
const settingsPath = process.argv[1];
const promptsPath = process.argv[2];
const serverJsPath = process.argv[3];

// Read existing settings
let existing = {};
try {
    const raw = fs.readFileSync(settingsPath, 'utf8');
    // Strip trailing commas (common in VS Code settings) and BOM
    const cleaned = raw.replace(/^\uFEFF/, '').replace(/,(\s*[}\]])/g, '\$1');
    existing = JSON.parse(cleaned);
} catch (e) {
    console.error('  WARNING: Could not parse existing settings.json — creating backup');
    fs.copyFileSync(settingsPath, settingsPath + '.bak');
    existing = {};
}

// Deep merge: chat.promptFilesLocations (append if path not already present)
const promptLocations = existing['chat.promptFilesLocations'] || [];
const alreadyHasPrompts = promptLocations.some(
    entry => (typeof entry === 'string' ? entry : entry.path) === promptsPath
);
if (!alreadyHasPrompts) {
    promptLocations.push({ path: promptsPath });
}
existing['chat.promptFilesLocations'] = promptLocations;

// Deep merge: mcp.servers.grimoire (overwrite server entry)
if (!existing.mcp) existing.mcp = {};
if (!existing.mcp.servers) existing.mcp.servers = {};
existing.mcp.servers.grimoire = {
    command: 'node',
    args: [serverJsPath]
};

// Write back with 4-space indent (VS Code default)
fs.writeFileSync(settingsPath, JSON.stringify(existing, null, 4) + '\n');
console.log('  ✓ Settings merged successfully');
" "${SETTINGS_PATH}" "${SCRIPT_DIR}/prompts" "${MCP_SERVER_DIR}/dist/server.js"
        }

        if [[ "${AUTO_APPLY}" == "true" ]]; then
            cp "${SETTINGS_PATH}" "${SETTINGS_PATH}.grimoire-bak"
            echo "  Backup: ${SETTINGS_PATH}.grimoire-bak"
            merge_settings
        else
            # Interactive — show preview and ask
            echo "  Will merge into: ${SETTINGS_PATH}"
            echo ""
            echo "  Keys to add/update:"
            echo "    • chat.promptFilesLocations → ${SCRIPT_DIR}/prompts"
            echo "    • mcp.servers.grimoire      → ${MCP_SERVER_DIR}/dist/server.js"
            echo ""
            printf "  Apply these settings? [y/N] "
            read -r response
            if [[ "${response}" =~ ^[Yy]$ ]]; then
                cp "${SETTINGS_PATH}" "${SETTINGS_PATH}.grimoire-bak"
                echo "  Backup: ${SETTINGS_PATH}.grimoire-bak"
                merge_settings
            else
                echo "  Skipped. Add manually:"
                echo ""
                echo "${GRIMOIRE_CONFIG}"
                echo ""
            fi
        fi
    fi
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Usage:"
echo "  Prompt files: reference with #skill-name in Copilot Chat"
echo "  MCP tools:    available automatically when grimoire server is connected"
echo ""
echo "After pulling updates, re-run:"
echo "  bash ${SCRIPT_DIR}/install-vscode.sh"
