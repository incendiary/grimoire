#!/usr/bin/env bash
set -euo pipefail

# install-jetbrains.sh — Set up grimoire MCP server for JetBrains clients
#
# What it does:
#   1. Builds the MCP server (npm ci + tsc)
#   2. Detects a JetBrains MCP config path (or uses --mcp-path)
#   3. Merges grimoire server entry into mcp.json
#
# Usage:
#   bash install-jetbrains.sh
#   bash install-jetbrains.sh --apply
#   bash install-jetbrains.sh --dry-run
#   bash install-jetbrains.sh --mcp-path "/absolute/path/to/mcp.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_SERVER_DIR="${SCRIPT_DIR}/mcp-server"

AUTO_APPLY=false
DRY_RUN=false
MCP_PATH_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply)
            AUTO_APPLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --mcp-path)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --mcp-path requires a value"
                exit 1
            fi
            MCP_PATH_OVERRIDE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: bash install-jetbrains.sh [--apply] [--dry-run] [--mcp-path <path>]"
            echo ""
            echo "  --apply            Edit configuration without interactive prompt"
            echo "  --dry-run          Print target config and exit without writing"
            echo "  --mcp-path <path>  Explicit path to JetBrains MCP config file"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Usage: bash install-jetbrains.sh [--apply] [--dry-run] [--mcp-path <path>]"
            exit 1
            ;;
    esac
done

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

backup_file() {
    local target="$1"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local backup="${target}.grimoire-${timestamp}.bak"
    cp "${target}" "${backup}"
    echo "  Backup: ${backup}"

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

detect_default_mcp_path() {
    local -a candidates=()
    case "$(uname -s)" in
        Darwin)
            candidates+=(
                "${HOME}/.junie/mcp.json"
                "${HOME}/Library/Application Support/JetBrains/Junie/mcp.json"
                "${HOME}/Library/Application Support/JetBrains/AI Assistant/mcp.json"
            )
            ;;
        Linux)
            candidates+=(
                "${HOME}/.junie/mcp.json"
                "${HOME}/.config/JetBrains/Junie/mcp.json"
                "${HOME}/.config/JetBrains/AI Assistant/mcp.json"
            )
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if [[ -n "${APPDATA:-}" ]]; then
                candidates+=(
                    "${APPDATA}/JetBrains/Junie/mcp.json"
                    "${APPDATA}/JetBrains/AI Assistant/mcp.json"
                )
            fi
            ;;
    esac

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -f "${candidate}" ]]; then
            echo "${candidate}"
            return 0
        fi
    done

    if [[ ${#candidates[@]} -gt 0 ]]; then
        echo "${candidates[0]}"
    fi
}

echo "=== grimoire JetBrains MCP setup ==="
echo ""

echo "[1/3] Building MCP server..."
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

echo "[2/3] Resolving JetBrains MCP config path..."
MCP_PATH="${MCP_PATH_OVERRIDE:-$(detect_default_mcp_path)}"

if [[ -z "${MCP_PATH}" ]]; then
    echo "ERROR: Could not determine MCP path automatically."
    echo "Use: bash install-jetbrains.sh --mcp-path /absolute/path/to/mcp.json"
    exit 1
fi

echo "  Target: ${MCP_PATH}"

echo "[3/3] Configuring MCP server entry..."

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
console.log(JSON.stringify(config, null, 2));
" "${NODE_BIN}" "${MCP_SERVER_DIR}/dist/server.js")

if [[ "${DRY_RUN}" == "true" ]]; then
    echo ""
    echo "[dry-run] Would merge into ${MCP_PATH}:"
    echo ""
    echo "${MCP_CONFIG}"
    echo ""
    exit 0
fi

mkdir -p "$(dirname "${MCP_PATH}")"

merge_mcp_config() {
    local mcp_path="$1"
    local server_js_path="$2"
    local node_bin="$3"

    "${NODE_BIN}" -e "
const fs = require('fs');
const mcpPath = process.argv[1];
const serverJsPath = process.argv[2];
const nodeBin = process.argv[3];

let existing = {};
try {
  if (fs.existsSync(mcpPath)) {
    const raw = fs.readFileSync(mcpPath, 'utf8');
    const cleaned = raw.replace(/^\uFEFF/, '').replace(/,(\s*[}\]])/g, '$1');
    existing = JSON.parse(cleaned);
  }
} catch (e) {
  console.error('  WARNING: Failed to parse existing mcp.json; replacing with fresh config');
  existing = {};
}

if (!existing.servers) existing.servers = {};
existing.servers.grimoire = {
  command: nodeBin,
  args: [serverJsPath],
  type: 'stdio'
};
if (!existing.inputs) existing.inputs = [];

fs.writeFileSync(mcpPath, JSON.stringify(existing, null, 2) + '\n');
console.log('  ✓ mcp.json updated — grimoire MCP server registered');
" "${mcp_path}" "${server_js_path}" "${node_bin}"
}

if [[ "${AUTO_APPLY}" == "true" ]]; then
    if [[ -f "${MCP_PATH}" ]]; then
        backup_file "${MCP_PATH}"
    fi
    merge_mcp_config "${MCP_PATH}" "${MCP_SERVER_DIR}/dist/server.js" "${NODE_BIN}"
else
    echo ""
    echo "  Will register grimoire server in ${MCP_PATH}:"
    echo "    command: ${NODE_BIN}"
    echo "    args:    ${MCP_SERVER_DIR}/dist/server.js"
    echo ""
    printf "  Apply? [y/N] "
    read -r response
    if [[ "${response}" =~ ^[Yy]$ ]]; then
        if [[ -f "${MCP_PATH}" ]]; then
            backup_file "${MCP_PATH}"
        fi
        merge_mcp_config "${MCP_PATH}" "${MCP_SERVER_DIR}/dist/server.js" "${NODE_BIN}"
    else
        echo "  Skipped."
        echo ""
        echo "  Manual config snippet:"
        echo "${MCP_CONFIG}"
        echo ""
    fi
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "If your JetBrains client does not auto-detect this file, re-run with:"
echo "  bash install-jetbrains.sh --mcp-path /absolute/path/to/mcp.json"
