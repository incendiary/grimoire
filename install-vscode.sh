#!/usr/bin/env bash
set -euo pipefail

# install-vscode.sh — Set up grimoire for VS Code (MCP server + prompt files)
#
# What it does:
#   1. Builds the MCP server (npm ci + tsc)
#   2. Generates prompt files (build.sh)
#   3. Detects VS Code config directory
#   4. Writes MCP config to mcp.json (VS Code 1.100+ dedicated file)
#   5. Merges prompt file path into settings.json
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
            echo "  --apply    Edit VS Code config files without prompting"
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

# --- Timestamped backup helper ---
# Creates a dated backup and prunes to keep only the last 5.
backup_file() {
    local target="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup="${target}.grimoire-${timestamp}.bak"
    cp "${target}" "${backup}"
    echo "  Backup: ${backup}"

    # Prune old backups — keep only the 5 most recent
    local count
    # shellcheck disable=SC2012
    count=$(ls -1 "${target}".grimoire-*.bak 2>/dev/null | wc -l | tr -d ' ')
    if [[ "${count}" -gt 5 ]]; then
        # shellcheck disable=SC2012
        ls -1t "${target}".grimoire-*.bak | tail -n +6 | while IFS= read -r old; do
            rm -f "${old}"
        done
    fi
}

echo "=== grimoire VS Code setup ==="
echo ""

# --- Step 1: Build MCP server ---
echo "[1/5] Building MCP server..."
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
echo "[2/5] Generating prompt files..."
cd "${SCRIPT_DIR}"
bash build.sh --clean
echo "  ✓ Prompt files generated"

# --- Step 3: Detect VS Code config directory ---
echo "[3/5] Detecting VS Code config..."

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
SETTINGS_PATH=""
MCP_PATH=""

if [[ -n "${VSCODE_USER_DIR}" ]]; then
    SETTINGS_PATH="${VSCODE_USER_DIR}/settings.json"
    MCP_PATH="${VSCODE_USER_DIR}/mcp.json"
fi

# --- Step 4: Write MCP config to mcp.json ---
echo "[4/5] Configuring MCP server (mcp.json)..."
echo ""

MCP_CONFIG=$(node -e "
const config = {
    servers: {
        grimoire: {
            command: 'node',
            args: [process.argv[1]],
            type: 'stdio'
        }
    }
};
console.log(JSON.stringify(config, null, '\t'));
" "${MCP_SERVER_DIR}/dist/server.js")

if [[ -z "${VSCODE_USER_DIR}" ]]; then
    echo "  ⚠ Could not locate VS Code config directory."
    echo ""
    echo "  Create mcp.json manually in your VS Code User directory:"
    echo ""
    echo "${MCP_CONFIG}"
    echo ""
    echo "  Common locations:"
    echo "    macOS:   ~/Library/Application Support/Code/User/mcp.json"
    echo "    Linux:   ~/.config/Code/User/mcp.json"
    echo "    Windows: %APPDATA%\\Code\\User\\mcp.json"
    echo ""
else
    echo "  Target: ${MCP_PATH}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo ""
        echo "  [dry-run] Would write to mcp.json:"
        echo ""
        echo "${MCP_CONFIG}"
        echo ""
    else
        write_mcp_config() {
            node -e "
const fs = require('fs');
const mcpPath = process.argv[1];
const serverJsPath = process.argv[2];

let existing = {};
try {
    if (fs.existsSync(mcpPath)) {
        const raw = fs.readFileSync(mcpPath, 'utf8');
        const cleaned = raw.replace(/^\uFEFF/, '').replace(/,(\s*[}\]])/g, '\$1');
        existing = JSON.parse(cleaned);
    }
} catch (e) {
    existing = {};
}

if (!existing.servers) existing.servers = {};
existing.servers.grimoire = {
    command: 'node',
    args: [serverJsPath],
    type: 'stdio'
};
if (!existing.inputs) existing.inputs = [];

fs.writeFileSync(mcpPath, JSON.stringify(existing, null, '\t') + '\n');
console.log('  ✓ mcp.json updated — grimoire MCP server registered');
" "${MCP_PATH}" "${MCP_SERVER_DIR}/dist/server.js"
        }

        if [[ "${AUTO_APPLY}" == "true" ]]; then
            write_mcp_config
        else
            echo ""
            echo "  Will register grimoire server in: ${MCP_PATH}"
            echo "    command: node"
            echo "    args:    ${MCP_SERVER_DIR}/dist/server.js"
            echo ""
            printf "  Apply? [y/N] "
            read -r response
            if [[ "${response}" =~ ^[Yy]$ ]]; then
                write_mcp_config
            else
                echo "  Skipped. Create mcp.json manually:"
                echo ""
                echo "${MCP_CONFIG}"
                echo ""
            fi
        fi
    fi
fi

# --- Step 5: Merge prompt file path into settings.json ---
echo "[5/5] Configuring prompt files (settings.json)..."
echo ""

PROMPT_CONFIG=$(node -e "
const config = {
    'chat.promptFilesLocations': [
        { path: process.argv[1] }
    ]
};
console.log(JSON.stringify(config, null, 4));
" "${SCRIPT_DIR}/prompts")

if [[ -z "${VSCODE_USER_DIR}" || ! -f "${SETTINGS_PATH}" ]]; then
    echo "  ⚠ Could not locate VS Code settings.json."
    echo ""
    echo "  Add the following to your settings.json:"
    echo ""
    echo "${PROMPT_CONFIG}"
    echo ""
else
    echo "  Target: ${SETTINGS_PATH}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo ""
        echo "  [dry-run] Would merge into settings.json:"
        echo ""
        echo "${PROMPT_CONFIG}"
        echo ""
        echo "  No changes written."
    else
        merge_settings() {
            node -e "
const fs = require('fs');
const settingsPath = process.argv[1];
const promptsPath = process.argv[2];

let existing = {};
try {
    const raw = fs.readFileSync(settingsPath, 'utf8');
    const cleaned = raw.replace(/^\uFEFF/, '').replace(/,(\s*[}\]])/g, '\$1');
    existing = JSON.parse(cleaned);
} catch (e) {
    console.error('  WARNING: Could not parse settings.json — creating backup');
    fs.copyFileSync(settingsPath, settingsPath + '.bak');
    existing = {};
}

// Remove legacy mcp key if present (migrated to mcp.json in VS Code 1.100+)
if (existing.mcp) {
    delete existing.mcp;
    console.log('  ℹ Removed legacy \"mcp\" key from settings.json (migrated to mcp.json)');
}

// Deep merge: chat.promptFilesLocations
// VS Code accepts two formats:
//   Array: [{"path": "/abs/path"}]  (1.100+ recommended)
//   Object: {"/path": true}         (legacy)
// Detect existing format and extend in-kind.
const rawLocations = existing['chat.promptFilesLocations'];
if (Array.isArray(rawLocations)) {
    const alreadyHasPrompts = rawLocations.some(
        entry => (typeof entry === 'string' ? entry : entry.path) === promptsPath
    );
    if (!alreadyHasPrompts) {
        rawLocations.push({ path: promptsPath });
    }
    existing['chat.promptFilesLocations'] = rawLocations;
} else if (rawLocations !== null && typeof rawLocations === 'object') {
    // Object format — add key if not already present
    if (!(promptsPath in rawLocations)) {
        rawLocations[promptsPath] = true;
    }
    existing['chat.promptFilesLocations'] = rawLocations;
} else {
    existing['chat.promptFilesLocations'] = [{ path: promptsPath }];
}

fs.writeFileSync(settingsPath, JSON.stringify(existing, null, 4) + '\n');
console.log('  ✓ settings.json updated — prompt file path registered');
" "${SETTINGS_PATH}" "${SCRIPT_DIR}/prompts"
        }

        if [[ "${AUTO_APPLY}" == "true" ]]; then
            backup_file "${SETTINGS_PATH}"
            merge_settings
        else
            echo ""
            echo "  Will add to settings.json:"
            echo "    • chat.promptFilesLocations → ${SCRIPT_DIR}/prompts"
            echo ""
            if grep -q '"mcp"' "${SETTINGS_PATH}" 2>/dev/null; then
                echo "  Will also remove legacy \"mcp\" key (migrated to mcp.json)"
                echo ""
            fi
            printf "  Apply? [y/N] "
            read -r response
            if [[ "${response}" =~ ^[Yy]$ ]]; then
                backup_file "${SETTINGS_PATH}"
                merge_settings
            else
                echo "  Skipped. Add manually:"
                echo ""
                echo "${PROMPT_CONFIG}"
                echo ""
            fi
        fi
    fi
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Usage:"
echo "  Prompt files: type #skill-name in Copilot Chat"
echo "  MCP tools:    available automatically when grimoire server is connected"
echo ""
echo "After pulling updates, re-run:"
echo "  bash ${SCRIPT_DIR}/install-vscode.sh"
