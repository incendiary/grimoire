# shellcheck shell=bash
# Shared installer helpers, sourced (not executed) by the install and uninstall scripts.

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

# Sets NODE_BIN and builds mcp-server; needs MCP_SERVER_DIR. $1 is the step label.
build_mcp_server() {
    echo "${1} Building MCP server..."
    if ! NODE_BIN="$(resolve_node_bin)"; then
        echo "ERROR: Node.js 22+ not found. Install options:"
        echo "  Homebrew:  brew install node"
        echo "  nvm:       nvm install 22 && nvm use 22"
        echo "  Volta:     volta install node@22"
        exit 1
    fi
    NPM_BIN="$(dirname "${NODE_BIN}")/npm"
    echo "  Node: ${NODE_BIN} ($("${NODE_BIN}" --version))"

    cd "${MCP_SERVER_DIR}" || exit
    # Prepend node's own bin directory so npm uses the resolved node, not the PATH default
    PATH="$(dirname "${NODE_BIN}"):${PATH}" "${NPM_BIN}" ci --silent
    PATH="$(dirname "${NODE_BIN}"):${PATH}" "${NPM_BIN}" run build --silent
    echo "  ✓ MCP server built"
}
