#!/usr/bin/env bash
set -euo pipefail

# install-vscode.sh — Set up grimoire for VS Code (MCP server + prompt files)
#
# What it does:
#   1. Builds the MCP server (npm ci + tsc)
#   2. Generates prompt files (build.sh)
#   3. Prints the VS Code settings to add

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_SERVER_DIR="${SCRIPT_DIR}/mcp-server"

echo "=== grimoire VS Code setup ==="
echo ""

# --- Step 1: Build MCP server ---
echo "[1/3] Building MCP server..."
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
echo "[2/3] Generating prompt files..."
cd "${SCRIPT_DIR}"
bash build.sh --clean
echo "  ✓ Prompt files generated"

# --- Step 3: Print configuration ---
echo ""
echo "[3/3] Add to your VS Code settings.json:"
echo ""
echo "  In: ~/Library/Application Support/Code/User/settings.json"
echo ""
echo '  "chat.promptFilesLocations": ['
echo "    {\"path\": \"${SCRIPT_DIR}/prompts\"}"
echo '  ],'
echo ''
echo '  "mcp": {'
echo '    "servers": {'
echo '      "grimoire": {'
echo '        "command": "node",'
echo "        \"args\": [\"${MCP_SERVER_DIR}/dist/server.js\"]"
echo '      }'
echo '    }'
echo '  }'
echo ""
echo "=== Setup complete ==="
echo ""
echo "Usage:"
echo "  Prompt files: reference with #skill-name in Copilot Chat"
echo "  MCP tools:    available automatically when grimoire server is connected"
echo ""
echo "After pulling updates, re-run:"
echo "  bash ${SCRIPT_DIR}/install-vscode.sh"
