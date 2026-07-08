#!/usr/bin/env bash
set -euo pipefail

# install-vscode.sh — Set up grimoire for VS Code (MCP server + prompt files)
#
# What it does:
#   1. Checks if MCP is supported in VS Code
#   2. Builds the MCP server (npm ci + tsc) — if supported
#   3. Generates prompt files (build.sh)
#   4. Detects VS Code config directory
#   5. Writes MCP config to mcp.json — if supported (VS Code 1.100+ dedicated file)
#   6. Merges prompt file path into settings.json
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
PROMPT_FILES_ONLY=false
for arg in "$@"; do
    case "${arg}" in
        --apply)   AUTO_APPLY=true ;;
        --dry-run) DRY_RUN=true ;;
        --prompt-files-only) PROMPT_FILES_ONLY=true ;;
        --help|-h)
            echo "Usage: bash install-vscode.sh [options]"
            echo ""
            echo "Options:"
            echo "  --apply             Edit VS Code config files without prompting"
            echo "  --dry-run           Show what would be merged, don't write anything"
            echo "  --prompt-files-only Skip MCP setup, install prompt files only"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown flag: ${arg}"
            echo "Usage: bash install-vscode.sh [--apply|--dry-run|--prompt-files-only]"
            exit 1
            ;;
    esac
done

detect_mcp_support() {
    # Check if VS Code has MCP enabled in User settings
    # Look for mcp.access setting; if it's "none", MCP is disabled
    local settings_path=""
    case "$(uname -s)" in
        Darwin)
            settings_path="${HOME}/Library/Application Support/Code/User/settings.json"
            ;;
        Linux)
            settings_path="${HOME}/.config/Code/User/settings.json"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if [[ -n "${APPDATA:-}" ]]; then
                settings_path="${APPDATA}/Code/User/settings.json"
            fi
            ;;
    esac

    if [[ -z "${settings_path}" || ! -f "${settings_path}" ]]; then
        return 0  # assume supported if we can't check
    fi

    # Check for mcp.access setting; if it's "none", MCP is disabled
    if grep -q '"mcp.access".*"none"' "${settings_path}" 2>/dev/null; then
        return 1  # MCP not supported
    fi

    return 0  # MCP supported
}

resolve_node_bin() {
    # Return absolute path to the first node binary that is version >=22.
    # Search order: PATH node → Homebrew → nvm (descending) → Volta
    local candidates=()

    if command -v node >/dev/null 2>&1; then
        candidates+=("$(command -v node)")
    fi
    candidates+=("/opt/homebrew/bin/node" "/usr/local/bin/node")

    if [[ -d "${HOME}/.nvm/versions/node" ]]; then
        # shellcheck disable=SC2012
        while IFS= read -r d; do
            candidates+=("${d}bin/node")
        done < <(ls -1d "${HOME}/.nvm/versions/node"/v*/ 2>/dev/null | sort -rV)
    fi
    candidates+=("${HOME}/.volta/bin/node")

    local candidate
    for candidate in "${candidates[@]}"; do
        [[ -x "${candidate}" ]] || continue
        local ver
        ver=$("${candidate}" --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [[ -n "${ver}" && "${ver}" -ge 22 ]]; then
            echo "${candidate}"
            return 0
        fi
    done
    return 1
}

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

# --- Pre-flight: Check MCP support ---
if [[ "${PROMPT_FILES_ONLY}" != "true" ]]; then
    if ! detect_mcp_support; then
        echo "⚠ WARNING: MCP is disabled in your VS Code settings (mcp.access = 'none')"
        echo ""
        echo "This usually means your organization restricts MCP. The MCP server won't start,"
        echo "and attempting to register it can break VS Code tool execution."
        echo ""
        echo "Two installation paths:"
        echo ""
        echo "  1. RECOMMENDED: Install prompt files only (no MCP)"
        echo "     • Skills available as #skill-name in Copilot Chat"
        echo "     • No MCP server, no org policy conflicts"
        echo "     • Run: bash install-vscode.sh --prompt-files-only"
        echo ""
        echo "  2. Continue with full setup (including MCP registration)"
        echo "     • Requires MCP to be enabled"
        echo "     • MCP will fail to start and may break tools"
        echo "     • Run: bash install-vscode.sh --prompt-files-only=false"
        echo ""

        if [[ "${AUTO_APPLY}" == "true" ]]; then
            echo "ERROR: --apply flag used but MCP is disabled. Use --prompt-files-only instead."
            exit 1
        fi

        printf "Continue with prompt files only? [Y/n] "
        read -r response
        if [[ ! "${response}" =~ ^[Nn]$ ]]; then
            PROMPT_FILES_ONLY=true
            echo ""
            echo "Proceeding with prompt files only."
            echo ""
        fi
    fi
fi

# --- Step 1: Build MCP server (if not prompt-files-only) ---
if [[ "${PROMPT_FILES_ONLY}" != "true" ]]; then
    echo "[1/5] Building MCP server..."
    if ! NODE_BIN="$(resolve_node_bin)"; then
        echo "ERROR: Node.js 22+ not found. Install options:"
        echo "  Homebrew:  brew install node"
        echo "  nvm:       nvm install 22 && nvm use 22"
        echo "  Volta:     volta install node@22"
        exit 1
    fi
    NPM_BIN="$(dirname "${NODE_BIN}")/npm"
    echo "  Node: ${NODE_BIN} ($("${NODE_BIN}" --version))"

    cd "${MCP_SERVER_DIR}"
    # Prepend node's own bin directory so npm uses the resolved node, not the PATH default
    PATH="$(dirname "${NODE_BIN}"):${PATH}" "${NPM_BIN}" ci --silent
    PATH="$(dirname "${NODE_BIN}"):${PATH}" "${NPM_BIN}" run build --silent
    echo "  ✓ MCP server built"
else
    echo "[1/3] Setup (prompt files only)"
    NODE_BIN="node"  # fallback for prompt file generation
fi


# --- Step 2/1: Generate prompt files ---
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

# --- Step 4: Write MCP config to mcp.json (skip if prompt-files-only) ---
if [[ "${PROMPT_FILES_ONLY}" != "true" ]]; then
    echo "[4/5] Configuring MCP server (mcp.json)..."
    echo ""

    MCP_CONFIG=$("${NODE_BIN}" -e "
const config = {
    servers: {
        grimoire: {
            command: process.argv[1],
            args: [process.argv[2]],
            type: 'stdio'
        }
    }
};
console.log(JSON.stringify(config, null, '\t'));
" "${NODE_BIN}" "${MCP_SERVER_DIR}/dist/server.js")

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
                "${NODE_BIN}" -e "
const fs = require('fs');
const mcpPath = process.argv[1];
const serverJsPath = process.argv[2];
const nodeBin = process.argv[3];

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
    command: nodeBin,
    args: [serverJsPath],
    type: 'stdio'
};
if (!existing.inputs) existing.inputs = [];

fs.writeFileSync(mcpPath, JSON.stringify(existing, null, '\t') + '\n');
console.log('  ✓ mcp.json updated — grimoire MCP server registered');
" "${MCP_PATH}" "${MCP_SERVER_DIR}/dist/server.js" "${NODE_BIN}"
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
else
    echo "[3/3] Skipping MCP configuration (prompt files only)"
    echo ""
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
// VS Code accepts two formats: array (1.100+ recommended) or legacy object
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
if [[ "${PROMPT_FILES_ONLY}" == "true" ]]; then
    echo "Installation mode: Prompt files only (no MCP)"
    echo ""
    echo "Usage:"
    echo "  • Type #skill-name in Copilot Chat to reference grimoire skills"
    echo "  • Skills are available across all VS Code sessions"
    echo "  • No MCP server — fully compliant with org policies"
else
    echo "Installation mode: Full setup (MCP + Prompt files)"
    echo ""
    echo "Usage:"
    echo "  • Prompt files: type #skill-name in Copilot Chat"
    echo "  • MCP tools:    available automatically when grimoire server is connected"
fi
echo ""
echo "After pulling updates, re-run:"
echo "  bash ${SCRIPT_DIR}/install-vscode.sh"

