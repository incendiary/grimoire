#!/bin/bash
# pre-push-validation — fail-closed local validation
# Mirrors GitHub Actions checks from .github/workflows/validate.yml
# Installs missing tools in venv, runs checks, verifies output
# Asks to install pre-push hook after successful validation

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fail-closed tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
FAILED_CHECKS=""

# Ensure venv exists or use current Python
setup_python_env() {
    if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        echo -e "${GREEN}✓ Activated venv${NC}"
    elif [ -d ".venv" ] && [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        echo -e "${GREEN}✓ Activated .venv${NC}"
    else
        echo -e "${YELLOW}⚠ No venv found, using system Python${NC}"
    fi
}

# Fail-closed: tool must exist or we install it, else FAIL
ensure_tool() {
    local tool="$1"
    local install_cmd="$2"

    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi

    echo -e "${YELLOW}Installing $tool...${NC}"
    if eval "$install_cmd"; then
        echo -e "${GREEN}✓ $tool installed${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED to install $tool${NC}"
        echo -e "${RED}   Install command: $install_cmd${NC}"
        return 1
    fi
}

# Run a check and verify output
run_check() {
    local check_name="$1"
    local tool="$2"
    local install_cmd="$3"
    local run_cmd="$4"

    echo -n "Checking $check_name... "

    # Fail-closed: tool must be available
    if ! ensure_tool "$tool" "$install_cmd"; then
        echo -e "${RED}✗ FAIL${NC}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        FAILED_CHECKS="${FAILED_CHECKS}\n  - $check_name: tool '$tool' not available"
        return 1
    fi

    # Run the check
    local output
    local exit_code
    output=$(eval "$run_cmd" 2>&1) || exit_code=$?

    # Fail-closed: verify output indicates success
    if [ -z "$output" ] || echo "$output" | grep -q "ERROR\|error\|failed\|FAIL"; then
        echo -e "${RED}✗ FAIL${NC}"
        echo "Output:"
        echo "$output" | head -20
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        FAILED_CHECKS="${FAILED_CHECKS}\n  - $check_name"
        return 1
    fi

    echo -e "${GREEN}✓ PASS${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
}

# Main validation flow
main() {
    echo -e "${BLUE}=== Pre-Push Validation ===${NC}"
    echo ""

    # Check if validate.yml exists
    if [ ! -f ".github/workflows/validate.yml" ]; then
        echo -e "${YELLOW}⚠ No .github/workflows/validate.yml found${NC}"
        echo "Skipping validation"
        return 0
    fi

    echo -e "${BLUE}Validating against: .github/workflows/validate.yml${NC}"
    echo ""

    setup_python_env
    echo ""

    # Shellcheck
    run_check \
        "shellcheck" \
        "shellcheck" \
        "apt-get install -y shellcheck || brew install shellcheck || exit 1" \
        "find . -name '*.sh' -not -path './.git/*' -not -path './clusters-private/*' -exec shellcheck {} +"

    # Skill structure
    run_check \
        "skill-structure" \
        "bash" \
        "which bash" \
        "bash -c 'set -e; for dir in clusters/*/*/; do [ ! -f \"\${dir}SKILL.md\" ] && { echo \"ERROR: missing SKILL.md in \${dir}\"; exit 1; }; [ ! -f \"\${dir}README.md\" ] && { echo \"ERROR: missing README.md in \${dir}\"; exit 1; }; done; echo \"All skill directories valid\"'"

    # Registry sync
    run_check \
        "registry-sync" \
        "python3" \
        "which python3" \
        "python3 -c 'import json; import subprocess; registry=json.load(open(\"mcp-server/registry.json\")); skills=[t[\"skill\"] for t in registry[\"tools\"]]; print(\"Checking\", len(skills), \"registry entries\"); [exit(1) if not open(s).read().__contains__(\"Type:\") else None for s in skills]; print(\"Registry valid\")'"

    # README quality
    run_check \
        "readme-quality" \
        "bash" \
        "which bash" \
        "bash -c 'set -e; for readme in clusters/*/*/README.md; do [ ! -f \"\$readme\" ] && continue; grep -q \"## Installation\" \"\$readme\" || { echo \"ERROR: missing ## Installation in \$readme\"; exit 1; }; done; echo \"All READMEs valid\"'"

    # No stale paths
    run_check \
        "stale-paths" \
        "bash" \
        "which bash" \
        "bash -c 'set -e; for readme in clusters/*/*/README.md; do [ ! -f \"\$readme\" ] && continue; grep -qE \"/path/to|loadout/\" \"\$readme\" && { echo \"ERROR: stale path in \$readme\"; exit 1; }; done; echo \"No stale paths\"'"

    echo ""
    echo -e "${BLUE}=== Results ===${NC}"
    echo "Passed: $CHECKS_PASSED"
    echo "Failed: $CHECKS_FAILED"

    # Fail-closed: if any check failed, abort
    if [ $CHECKS_FAILED -gt 0 ]; then
        echo ""
        echo -e "${RED}VALIDATION FAILED${NC}"
        echo -e "${RED}Issues:${NC}"
        echo -e "$FAILED_CHECKS"
        return 1
    fi

    echo -e "${GREEN}All checks passed${NC}"
    echo ""

    # Ask to install hook (only if not already installed)
    if [ ! -f ".git/hooks/pre-push" ]; then
        echo -e "${BLUE}Install pre-push hook?${NC}"
        echo "This will auto-run these checks before every push."
        echo ""
        read -rp "Install pre-push hook? (y/n) " -n 1 reply
        echo ""

        if [[ "$reply" =~ ^[Yy]$ ]]; then
            install_hook
        fi
    else
        echo -e "${GREEN}✓ Pre-push hook already installed${NC}"
    fi
}

install_hook() {
    local hook_file=".git/hooks/pre-push"
    mkdir -p "$(dirname "$hook_file")"

    cat > "$hook_file" << 'HOOK'
#!/bin/bash
set -e
cd "$(git rev-parse --show-toplevel)"
bash clusters/07-devops/pre-push-validation/pre-push-validation.sh
HOOK

    chmod +x "$hook_file"
    echo -e "${GREEN}✓ Pre-push hook installed${NC}"
    echo "   Bypass with: git push --no-verify"
    echo "   Uninstall: rm .git/hooks/pre-push"
}

main "$@"
exit $?
