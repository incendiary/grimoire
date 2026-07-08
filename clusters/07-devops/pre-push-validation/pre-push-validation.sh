#!/bin/bash
# pre-push-validation — fail-closed, workflow-aware validation
# Parses .github/workflows/validate.yml and runs those checks locally
# Works for ANY repo with a validate.yml workflow
# Fail-closed: missing tools, install failures, or ambiguous output = BLOCK

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
FAILED_CHECKS=""

# Setup Python environment
setup_python_env() {
    if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
        source venv/bin/activate >/dev/null 2>&1
        echo -e "${GREEN}✓ Activated venv${NC}"
    elif [ -d ".venv" ] && [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate >/dev/null 2>&1
        echo -e "${GREEN}✓ Activated .venv${NC}"
    fi
}

# Parse validate.yml and extract job run commands
parse_workflow() {
    local workflow_file=".github/workflows/validate.yml"
    local tmpfile="/tmp/validate_checks_$$.txt"

    if [ ! -f "$workflow_file" ]; then
        return 1
    fi

    # Use Python to parse YAML and write to temp file
    python3 << EOF
import yaml
import base64

try:
    with open('$workflow_file') as f:
        workflow = yaml.safe_load(f)

    if 'jobs' not in workflow:
        exit(0)

    with open('$tmpfile', 'w') as out:
        for job_name, job_config in workflow['jobs'].items():
            if not isinstance(job_config, dict) or 'steps' not in job_config:
                continue

            for step in job_config['steps']:
                if not isinstance(step, dict) or 'run' not in step:
                    continue

                name = step.get('name', f'step-{job_name}')
                run_cmd = step['run'].strip()
                # Encode command as base64 to preserve all characters/newlines safely
                encoded = base64.b64encode(run_cmd.encode()).decode()
                out.write(f'{name}|{encoded}\n')

except Exception as e:
    pass
EOF

    cat "$tmpfile" 2>/dev/null || return 1
    rm -f "$tmpfile"
}

# Fail-closed: ensure tool exists, install if needed
ensure_tool() {
    local tool="$1"
    local install_cmd="$2"

    if command -v "$tool" >/dev/null 2>&1; then
        return 0
    fi

    echo -e "${YELLOW}Installing $tool...${NC}"
    if eval "$install_cmd" >/dev/null 2>&1; then
        if command -v "$tool" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $tool installed${NC}"
            return 0
        fi
    fi

    echo -e "${RED}✗ FAILED to install $tool${NC}"
    echo -e "${RED}   Install: $install_cmd${NC}"
    return 1
}

# Map command to tool and install command
get_tool_and_install_cmd() {
    local cmd="$1"

    # Multi-line bash scripts or complex commands
    if echo "$cmd" | grep -qE "^#!|^set -|^\$\(|^[A-Z_]+=|for |if |while "; then
        echo "bash|||which bash >/dev/null || exit 1"
        return 0
    fi

    # Shellcheck
    if echo "$cmd" | grep -q "shellcheck"; then
        echo "shellcheck|||apt-get install -y shellcheck 2>/dev/null || brew install shellcheck 2>/dev/null || exit 1"
        return 0
    fi

    # Python (pytest, black, flake8, ruff, etc)
    if echo "$cmd" | grep -qE "python|pytest|black|flake8|ruff"; then
        echo "python3|||which python3 >/dev/null || exit 1"
        return 0
    fi

    # Node (npm, eslint, prettier)
    if echo "$cmd" | grep -qE "npm|node|eslint|prettier"; then
        echo "npm|||which npm >/dev/null || exit 1"
        return 0
    fi

    # Go
    if echo "$cmd" | grep -qE "go |go\$|gofmt|govet"; then
        echo "go|||which go >/dev/null || exit 1"
        return 0
    fi

    # Rust
    if echo "$cmd" | grep -qE "cargo|rustfmt|clippy"; then
        echo "cargo|||which cargo >/dev/null || exit 1"
        return 0
    fi

    # Bash/shell keywords
    if echo "$cmd" | grep -qE "bash|sh\$"; then
        echo "bash|||which bash >/dev/null || exit 1"
        return 0
    fi

    # Default: assume tool name is first word
    local tool=$(echo "$cmd" | awk '{print $1}')
    echo "$tool|||which $tool >/dev/null || exit 1"
}

# Fail-closed: run check and verify output
run_check() {
    local name="$1"
    local cmd_encoded="$2"

    echo -n "Checking $name... "

    # Decode base64-encoded command
    local cmd
    cmd=$(echo "$cmd_encoded" | base64 -d 2>/dev/null) || {
        echo -e "${RED}✗ FAIL${NC}"
        echo "Failed to decode command"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        FAILED_CHECKS="${FAILED_CHECKS}\n  - $name: command decode failed"
        return 1
    }

    # Get tool and install command
    local tool_info
    tool_info=$(get_tool_and_install_cmd "$cmd")
    local tool=$(echo "$tool_info" | cut -d'|' -f1)
    local install_cmd=$(echo "$tool_info" | cut -d'|' -f3)

    # Fail-closed: ensure tool available
    if ! ensure_tool "$tool" "$install_cmd"; then
        echo -e "${RED}✗ FAIL${NC}"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        FAILED_CHECKS="${FAILED_CHECKS}\n  - $name: tool '$tool' not available"
        return 1
    fi

    # Run the check
    local output
    local exit_code=0
    output=$(eval "$cmd" 2>&1) || exit_code=$?

    # Fail-closed: verify output indicates success
    if [ -z "$output" ] || echo "$output" | grep -qiE "ERROR|FAIL|failed"; then
        echo -e "${RED}✗ FAIL${NC}"
        echo "Output:"
        echo "$output" | head -15
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        FAILED_CHECKS="${FAILED_CHECKS}\n  - $name"
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

    if [ ! -f ".github/workflows/validate.yml" ]; then
        echo -e "${YELLOW}⚠ No .github/workflows/validate.yml found${NC}"
        echo "Skipping validation"
        return 0
    fi

    echo -e "${BLUE}Reading: .github/workflows/validate.yml${NC}"
    echo ""

    setup_python_env
    echo ""

    # Parse workflow and run each check
    local job_count=0
    while IFS='|' read -r name cmd; do
        [ -z "$name" ] && continue
        [ -z "$cmd" ] && continue

        run_check "$name" "$cmd"
        job_count=$((job_count + 1))
    done < <(parse_workflow)

    if [ $job_count -eq 0 ]; then
        echo -e "${YELLOW}⚠ No checks found in workflow${NC}"
        return 0
    fi

    echo ""
    echo -e "${BLUE}=== Results ===${NC}"
    echo "Passed: $CHECKS_PASSED"
    echo "Failed: $CHECKS_FAILED"

    # Fail-closed: if any check failed, abort
    if [ $CHECKS_FAILED -gt 0 ]; then
        echo ""
        echo -e "${RED}VALIDATION FAILED — push blocked${NC}"
        echo -e "${RED}Issues:${NC}"
        echo -e "$FAILED_CHECKS"
        return 1
    fi

    echo -e "${GREEN}✓ All checks passed${NC}"
    echo ""

    # Ask to install hook (only if not already installed)
    if [ ! -f ".git/hooks/pre-push" ]; then
        echo -e "${BLUE}Install pre-push hook?${NC}"
        echo "This will auto-run these checks before every push."
        echo ""
        read -rp "Install hook? (y/n) " -n 1 reply
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
    echo "   Bypass: git push --no-verify"
    echo "   Uninstall: rm .git/hooks/pre-push"
}

main "$@"
exit $?
