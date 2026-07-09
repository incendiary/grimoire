#!/bin/bash
# pre-push-validation — fail-closed, workflow-aware validation
# Discovers .github/workflows/*.yml, extracts each job's `run:` steps, and runs
# them locally before a push. Steps that can only run in CI (GitHub Actions
# contexts, secrets, release creation, OS package installs) are skipped
# explicitly — never silently. Works for ANY repo. Fail-closed: any non-zero
# exit (including a missing tool) blocks the push.

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

# Absolute path to this script, so the installed git hook can call it from any repo.
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_SKIPPED=0
FAILED_CHECKS=""

# Setup Python environment (activate a venv if the repo has one)
setup_python_env() {
    if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
        # shellcheck disable=SC1091
        source venv/bin/activate >/dev/null 2>&1
        echo -e "${GREEN}✓ Activated venv${NC}"
    elif [ -d ".venv" ] && [ -f ".venv/bin/activate" ]; then
        # shellcheck disable=SC1091
        source .venv/bin/activate >/dev/null 2>&1
        echo -e "${GREEN}✓ Activated .venv${NC}"
    fi
}

# Discover all workflow files and extract their run steps.
# Emits one line per step:  STATUS|B64NAME|B64CMD|B64REASON
#   STATUS = RUN  (runnable locally)  |  SKIP (CI-only)
# Fields are base64-encoded so newlines/pipes in commands survive intact.
parse_workflows() {
    python3 - "$1" <<'PYEOF'
import base64
import glob
import os
import re
import shlex
import sys

try:
    import yaml
except ImportError:
    sys.exit(3)  # signal: PyYAML missing

tmpfile = sys.argv[1]

def workdir(doc, job, step):
    # Effective working-directory: step > job defaults > workflow defaults.
    for scope in (step, job, doc):
        if isinstance(scope, dict):
            wd = scope.get('working-directory')
            if not wd:
                run = (scope.get('defaults') or {}).get('run') or {}
                wd = run.get('working-directory')
            if wd:
                return str(wd)
    return None

# Patterns that mean a step cannot meaningfully run outside CI.
CI_ONLY = [
    (re.compile(r'\$\{\{'),               'uses a GitHub Actions ${{ }} context'),
    (re.compile(r'\bsecrets\.'),          'references secrets.'),
    (re.compile(r'\bgh\s+release\b'),     'creates/edits a GitHub release'),
    (re.compile(r'GITHUB_OUTPUT|GITHUB_ENV|GITHUB_STEP_SUMMARY'),
                                          'writes a CI-only GITHUB_* file'),
    (re.compile(r'\bsudo\b|\bapt-get\b|\bapt\s+install\b|\byum\s+install\b|\bapk\s+add\b'),
                                          'OS package/setup step — provisioned locally instead'),
]

def classify(cmd):
    for pat, reason in CI_ONLY:
        if pat.search(cmd):
            return 'SKIP', reason
    return 'RUN', ''

def b64(s):
    return base64.b64encode(s.encode()).decode()

files = sorted(set(glob.glob('.github/workflows/*.yml') +
                   glob.glob('.github/workflows/*.yaml')))

with open(tmpfile, 'w') as out:
    for wf in files:
        try:
            with open(wf) as f:
                doc = yaml.safe_load(f)
        except Exception:
            continue
        if not isinstance(doc, dict) or 'jobs' not in doc:
            continue
        wf_name = os.path.basename(wf)
        for job_name, job in doc['jobs'].items():
            if not isinstance(job, dict) or 'steps' not in job:
                continue
            for step in job['steps']:
                if not isinstance(step, dict) or 'run' not in step:
                    continue  # `uses:` actions have no run: — naturally excluded
                label = step.get('name') or job_name
                display = f'{wf_name} › {label}'
                cmd = str(step['run']).strip()
                status, reason = classify(cmd)
                wd = workdir(doc, job, step)
                if wd and wd != '.':
                    cmd = f'cd {shlex.quote(wd)} || exit 1\n{cmd}'
                out.write(f'{status}|{b64(display)}|{b64(cmd)}|{b64(reason)}\n')
PYEOF
}

# Fail-closed: run a check and trust its exit code — exactly as CI does.
# A missing tool surfaces as command-not-found (non-zero exit) and blocks the
# push with its output shown; no guessing which tool a command "needs".
run_check() {
    local name="$1"
    local cmd="$2"

    echo -n "Checking $name... "

    local output exit_code=0
    output=$(eval "$cmd" 2>&1) || exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        echo -e "${RED}✗ FAIL${NC} (exit $exit_code)"
        echo "$output" | head -20
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        FAILED_CHECKS="${FAILED_CHECKS}\n  - $name (exit $exit_code)"
        return 1
    fi

    echo -e "${GREEN}✓ PASS${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
}

install_hook() {
    local hook_file=".git/hooks/pre-push"
    mkdir -p "$(dirname "$hook_file")"

    cat > "$hook_file" <<HOOK
#!/bin/bash
# Installed by pre-push-validation. Runs local CI checks before every push.
set -e
cd "\$(git rev-parse --show-toplevel)"
bash "$SCRIPT_PATH"
HOOK

    chmod +x "$hook_file"
    echo -e "${GREEN}✓ Pre-push hook installed${NC} → $hook_file"
    echo "   Bypass once: git push --no-verify"
    echo "   Uninstall:   rm .git/hooks/pre-push"
}

main() {
    # Non-interactive hook install (for scripted setup): install and exit.
    if [ "${1:-}" = "--install-hook" ]; then
        install_hook
        return 0
    fi

    echo -e "${BLUE}=== Pre-Push Validation ===${NC}"
    echo ""

    shopt -s nullglob
    local wf_files=(.github/workflows/*.yml .github/workflows/*.yaml)
    shopt -u nullglob
    if [ ${#wf_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠ No .github/workflows/*.yml found — nothing to validate${NC}"
        return 0
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}✗ python3 not found — cannot parse workflows${NC}"
        echo "   Install python3 (and PyYAML) to run pre-push validation."
        return 1
    fi

    setup_python_env
    echo ""

    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/ppv_checks.XXXXXX")
    # shellcheck disable=SC2064
    trap "rm -f '$tmpfile'" RETURN

    parse_workflows "$tmpfile"
    local parse_rc=$?
    if [ "$parse_rc" -eq 3 ]; then
        echo -e "${RED}✗ PyYAML not installed — cannot parse workflows${NC}"
        echo "   Install: pip install pyyaml   (or activate a venv that has it)"
        return 1
    fi

    local step_count=0
    local status b64name b64cmd b64reason name cmd reason
    while IFS='|' read -r status b64name b64cmd b64reason; do
        [ -z "$status" ] && continue
        name=$(echo "$b64name" | base64 -d 2>/dev/null)
        step_count=$((step_count + 1))

        if [ "$status" = "SKIP" ]; then
            reason=$(echo "$b64reason" | base64 -d 2>/dev/null)
            echo -e "${YELLOW}Skipped — CI-only:${NC} $name ($reason)"
            CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1))
            continue
        fi

        cmd=$(echo "$b64cmd" | base64 -d 2>/dev/null)
        run_check "$name" "$cmd"
    done < "$tmpfile"

    if [ "$step_count" -eq 0 ]; then
        echo -e "${YELLOW}⚠ No run steps found in any workflow${NC}"
        return 0
    fi

    echo ""
    echo -e "${BLUE}=== Results ===${NC}"
    echo "Passed:  $CHECKS_PASSED"
    echo "Failed:  $CHECKS_FAILED"
    echo "Skipped: $CHECKS_SKIPPED (CI-only)"

    if [ "$CHECKS_FAILED" -gt 0 ]; then
        echo ""
        echo -e "${RED}VALIDATION FAILED — push blocked${NC}"
        echo -e "${RED}Issues:${NC}"
        echo -e "$FAILED_CHECKS"
        return 1
    fi

    echo -e "${GREEN}✓ All runnable checks passed${NC}"
    echo ""

    # Offer the hook only in an interactive terminal. When invoked *as* the git
    # hook there is no TTY — never prompt, never install silently.
    if [ ! -f ".git/hooks/pre-push" ]; then
        if [ -t 0 ]; then
            read -rp "Install pre-push hook to run this automatically? (y/n) " -n 1 reply
            echo ""
            [[ "$reply" =~ ^[Yy]$ ]] && install_hook
        fi
    else
        echo -e "${GREEN}✓ Pre-push hook already installed${NC}"
    fi
    return 0
}

main "$@"
exit $?
