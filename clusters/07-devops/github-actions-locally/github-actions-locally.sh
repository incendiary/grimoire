#!/bin/bash
# github-actions-locally.sh — Run GitHub Actions workflow jobs locally.
# Discovers .github/workflows/*.yml with a real YAML parser, extracts each
# job's `run:` steps, executes them, and reports only what actually ran.
# Auto-fixes failures where a known fixer exists (black, ruff), re-running to
# confirm. Exits 0 regardless of pass/fail — the report is the signal, not
# the exit code (unlike pre-push-validation, this does not block anything).

set -u

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
REPO_ROOT="."
DRY_RUN=false
LIST_ONLY=false
JOB_TYPE="all"  # all, lint, test
WORKFLOW_FILTER=""

# Results tracking
declare -a PASSED_JOBS=()
declare -a FAILED_JOBS=()
declare -a FIXED_JOBS=()
declare -a SKIPPED_JOBS=()
RAN_ANY=false
VENV_ACTIVE=false

INSTALL_HOOK_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --list) LIST_ONLY=true; shift ;;
        --lint) JOB_TYPE="lint"; shift ;;
        --test) JOB_TYPE="test"; shift ;;
        --workflow) WORKFLOW_FILTER="$2"; shift 2 ;;
        --install-hook) INSTALL_HOOK_ONLY=true; shift ;;
        *) REPO_ROOT="$1"; shift ;;
    esac
done

cd "$REPO_ROOT" || exit 1

# Absolute path to this script, so the installed hook works from any repo layout.
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Installs a pre-commit hook (never pre-push — pre-push-validation already
# owns that slot, and a single hook file can't serve two independent
# installers). Safe to auto-install without asking: this tool always exits 0,
# so the hook can never block a commit, only surface information.
install_hook() {
    local hook_file=".git/hooks/pre-commit"
    mkdir -p "$(dirname "$hook_file")"
    cat > "$hook_file" <<HOOK
#!/bin/bash
# Installed by github-actions-locally. Informational only — never blocks
# (the underlying script always exits 0).
cd "\$(git rev-parse --show-toplevel)" || exit 0
bash "$SCRIPT_PATH"
exit 0
HOOK
    chmod +x "$hook_file"
    echo -e "${GREEN}✓ pre-commit hook installed${NC} → $hook_file"
    echo "   Informational only — never blocks a commit."
    echo "   Uninstall: rm $hook_file"
}

# Offer or auto-install the hook, once, if nothing is already there.
# Interactive (TTY): ask. Non-interactive (e.g. invoked by an agent, or as
# a hook itself): install without asking, since it's always non-blocking —
# unlike pre-push-validation's blocking hook, there's no downside to silently
# adding this one, only to silently skipping it and staying uncovered.
maybe_install_hook() {
    [[ -f ".git/hooks/pre-commit" ]] && return 0
    if [[ -t 0 ]]; then
        echo -e "${BLUE}Install pre-commit hook to run this automatically (informational, never blocks)?${NC}"
        read -rp "Install? (y/n) " -n 1 reply
        echo ""
        [[ "$reply" =~ ^[Yy]$ ]] && install_hook
    else
        echo -e "${YELLOW}No pre-commit hook found — installing one automatically (non-interactive; this tool never blocks, so it's safe to add without asking).${NC}"
        install_hook
    fi
}

# Activate the target repo's own venv/.venv if present — never rely on
# whatever's on the caller's global PATH. A tool resolved from a different
# environment than CI's pinned install can silently diverge in behavior
# (e.g. Black's formatting rules changed between major versions) and, worse,
# auto-fix will then "correct" files to a style CI doesn't actually want.
setup_python_env() {
    if [[ -f "venv/bin/activate" ]]; then
        # shellcheck disable=SC1091
        source venv/bin/activate >/dev/null 2>&1
        VENV_ACTIVE=true
        echo -e "${GREEN}✓ Activated venv${NC} ($(command -v python3))"
    elif [[ -f ".venv/bin/activate" ]]; then
        # shellcheck disable=SC1091
        source .venv/bin/activate >/dev/null 2>&1
        VENV_ACTIVE=true
        echo -e "${GREEN}✓ Activated .venv${NC} ($(command -v python3))"
    else
        echo -e "${YELLOW}⚠ No venv/.venv found — using PATH tools as-is.${NC}"
        echo -e "${YELLOW}  Auto-fix (black/ruff) will be skipped: their version may not match CI's pinned one.${NC}"
    fi
}

# Helper: classify a job by name (heuristic — used only for --lint/--test
# filtering and report grouping, never to decide whether something ran).
classify_job() {
    local job_name="$1"
    if [[ "$job_name" =~ (lint|ruff|black|shellcheck|prettier|eslint|format|style) ]]; then
        echo "lint"
    elif [[ "$job_name" =~ (test|pytest|jest|vitest|build|spec) ]]; then
        echo "test"
    else
        echo "other"
    fi
}

# Real YAML parser: discover every job's `run:` steps under every
# .github/workflows/*.yml, honoring working-directory (step > job
# defaults.run > workflow defaults.run), exactly as pre-push-validation.sh
# does. Emits one line per step to $1:
#   STATUS|B64(WORKFLOW)|B64(JOB)|B64(STEPNAME)|B64(CMD)|B64(REASON)
# STATUS = RUN | SKIP (CI-only: ${{ }} contexts, secrets., gh release,
# GITHUB_* files, or OS package installs — never run locally).
discover_jobs() {
    local tmpfile="$1"
    local wf_filter="$2"
    python3 - "$tmpfile" "$wf_filter" <<'PYEOF'
import base64, glob, os, re, shlex, sys

try:
    import yaml
except ImportError:
    sys.exit(3)

tmpfile, wf_filter = sys.argv[1], sys.argv[2]

CI_ONLY = [
    (re.compile(r'\$\{\{'),               'uses a GitHub Actions ${{ }} context'),
    (re.compile(r'\bsecrets\.'),          'references secrets.'),
    (re.compile(r'\bgh\s+release\b'),     'creates/edits a GitHub release'),
    (re.compile(r'GITHUB_OUTPUT|GITHUB_ENV|GITHUB_STEP_SUMMARY'),
                                          'writes a CI-only GITHUB_* file'),
    (re.compile(r'\bsudo\b|\bapt-get\b|\bapt\s+install\b|\byum\s+install\b|\bapk\s+add\b'),
                                          'OS package/setup step'),
]

def classify(cmd):
    for pat, reason in CI_ONLY:
        if pat.search(cmd):
            return 'SKIP', reason
    return 'RUN', ''

def workdir(doc, job, step):
    for scope in (step, job, doc):
        if isinstance(scope, dict):
            wd = scope.get('working-directory')
            if not wd:
                run = (scope.get('defaults') or {}).get('run') or {}
                wd = run.get('working-directory')
            if wd:
                return str(wd)
    return None

def b64(s):
    return base64.b64encode(s.encode()).decode()

files = sorted(set(glob.glob('.github/workflows/*.yml') +
                   glob.glob('.github/workflows/*.yaml')))
if wf_filter:
    files = [f for f in files if wf_filter in f]

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
                    continue
                step_name = step.get('name') or job_name
                cmd = str(step['run']).strip()
                status, reason = classify(cmd)
                wd = workdir(doc, job, step)
                if wd and wd != '.':
                    cmd = f'cd {shlex.quote(wd)} || exit 1\n{cmd}'
                out.write(f'{status}|{b64(wf_name)}|{b64(job_name)}|{b64(step_name)}|{b64(cmd)}|{b64(reason)}\n')
PYEOF
}

# Attempt auto-fixes for common tools, then re-run to confirm. Refuses to run
# unless a project venv was activated — auto-fixing with whatever black/ruff
# happens to be on the caller's global PATH can silently apply a different
# formatting style than the one CI's pinned version wants, corrupting files
# that were actually correct. Reporting the failure and stopping is safer
# than "fixing" it with the wrong tool.
attempt_fix() {
    local job_name="$1"
    local command="$2"

    if [[ "$VENV_ACTIVE" != true ]]; then
        echo -e "  ${YELLOW}Skipping auto-fix: no project venv active, won't risk the wrong tool version.${NC}"
        return 1
    fi

    if [[ "$command" =~ black ]]; then
        echo "  Attempting auto-fix with black ($(command -v black))..."
        if black . >/dev/null 2>&1 && eval "$command" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Black auto-fixed files${NC}"
            FIXED_JOBS+=("$job_name (black)")
            PASSED_JOBS+=("$job_name")
            return 0
        fi
    elif [[ "$command" =~ ruff ]]; then
        echo "  Attempting auto-fix with ruff ($(command -v ruff))..."
        if ruff check --fix . >/dev/null 2>&1 && eval "$command" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Ruff auto-fixed issues${NC}"
            FIXED_JOBS+=("$job_name (ruff)")
            PASSED_JOBS+=("$job_name")
            return 0
        fi
    fi
    return 1
}

# Run one step and record the outcome. Trusts the exit code — no output
# heuristics.
run_job() {
    local job_name="$1"
    local command="$2"

    echo -e "${BLUE}Running: $job_name...${NC}"
    RAN_ANY=true

    local output exit_code=0
    output=$(eval "$command" 2>&1) || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_JOBS+=("$job_name")
        return 0
    fi

    # Distinguish a broken local toolchain (missing shim, command not found)
    # from an actual lint/test failure — the fix is different (install the
    # tool), and it shouldn't be reported or auto-fixed as if code is wrong.
    if [[ $exit_code -eq 127 ]] || echo "$output" | grep -qiE "command not found|No such file or directory.*pyenv|pyenv: .*No such file"; then
        echo -e "${RED}✗ TOOLCHAIN ISSUE${NC} (not a code failure — a required tool is missing or misconfigured)"
        echo "$output" | head -10
        FAILED_JOBS+=("$job_name (toolchain)")
        return 1
    fi

    echo -e "${RED}✗ FAIL${NC} (exit $exit_code)"
    echo "$output" | head -20
    FAILED_JOBS+=("$job_name")

    if attempt_fix "$job_name" "$command"; then
        # attempt_fix already recorded success; undo the failure record.
        FAILED_JOBS=("${FAILED_JOBS[@]/$job_name}")
    fi
}

generate_report() {
    echo ""
    echo -e "${BLUE}=== Summary ===${NC}"

    if [[ "$RAN_ANY" != true ]]; then
        echo -e "${YELLOW}0 steps executed — nothing runnable was discovered.${NC}"
        echo ""
        return
    fi

    local passed=${#PASSED_JOBS[@]}
    local failed=${#FAILED_JOBS[@]}
    local fixed=${#FIXED_JOBS[@]}
    local skipped=${#SKIPPED_JOBS[@]}

    echo "Ran: $((passed + failed)) executed, $passed passed, $failed failed, $skipped skipped (CI-only)"

    if [[ $fixed -gt 0 ]]; then
        echo -e "${YELLOW}Auto-fixed: $fixed job(s)${NC}"
        for job in "${FIXED_JOBS[@]}"; do echo "  - $job"; done
    fi

    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Manual attention needed: $failed job(s)${NC}"
        for job in "${FAILED_JOBS[@]}"; do
            [[ -z "$job" ]] && continue
            echo "  - $job"
        done
    fi

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✅ All executed steps passed.${NC} ($skipped CI-only step(s) skipped — verify those in CI)"
    else
        echo -e "${YELLOW}⚠️  $failed issue(s) require manual review.${NC}"
    fi
    echo ""
}

main() {
    if [[ "$INSTALL_HOOK_ONLY" == true ]]; then
        install_hook
        return 0
    fi

    echo -e "${BLUE}=== GitHub Actions — Local Run ===${NC}"
    echo ""

    shopt -s nullglob
    local wf_files=(.github/workflows/*.yml .github/workflows/*.yaml)
    shopt -u nullglob
    if [[ ${#wf_files[@]} -eq 0 ]]; then
        echo "No .github/workflows/ files found"
        exit 0
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}✗ python3 not found — cannot parse workflows${NC}"
        exit 1
    fi

    setup_python_env
    echo ""

    TMPFILE=$(mktemp "${TMPDIR:-/tmp}/gal_jobs.XXXXXX")
    trap 'rm -f "$TMPFILE"' EXIT

    discover_jobs "$TMPFILE" "$WORKFLOW_FILTER"
    local parse_rc=$?
    if [[ $parse_rc -eq 3 ]]; then
        echo -e "${RED}✗ PyYAML not installed — cannot parse workflows${NC}"
        echo "   Install: pip install pyyaml"
        exit 1
    fi

    if [[ ! -s "$TMPFILE" ]]; then
        echo "No run: steps found in any workflow"
        exit 0
    fi

    # Build a printable job list, applying --lint/--test filtering by job name.
    declare -a DISPLAY_LINES=()
    declare -a RUNNABLE=()  # index-parallel: "status|job|step|cmd"
    while IFS='|' read -r status b64wf b64job b64step b64cmd b64reason; do
        [[ -z "$status" ]] && continue
        local job step wf class
        job=$(echo "$b64job" | base64 -d)
        step=$(echo "$b64step" | base64 -d)
        wf=$(echo "$b64wf" | base64 -d)
        class=$(classify_job "$job")

        if [[ "$JOB_TYPE" != "all" && "$JOB_TYPE" != "$class" ]]; then
            continue
        fi

        if [[ "$status" == "SKIP" ]]; then
            local reason
            reason=$(echo "$b64reason" | base64 -d)
            DISPLAY_LINES+=("SKIP|$wf › $job › $step|$reason")
            SKIPPED_JOBS+=("$wf › $job › $step")
            continue
        fi

        DISPLAY_LINES+=("RUN|$wf › $job › $step|")
        RUNNABLE+=("$wf › $job › $step|$b64cmd")
    done < "$TMPFILE"

    echo -e "${BLUE}=== Discovered ===${NC}"
    for line in "${DISPLAY_LINES[@]}"; do
        IFS='|' read -r st name reason <<< "$line"
        if [[ "$st" == "SKIP" ]]; then
            echo -e "  ${YELLOW}skip${NC}  $name  ($reason)"
        else
            echo -e "  ${GREEN}run${NC}   $name"
        fi
    done
    echo ""
    echo "Runnable: ${#RUNNABLE[@]}   Skipped (CI-only): ${#SKIPPED_JOBS[@]}"
    echo ""

    if [[ "$LIST_ONLY" == true || "$DRY_RUN" == true ]]; then
        [[ "$DRY_RUN" == true ]] && echo -e "${YELLOW}Dry-run: not executing${NC}"
        exit 0
    fi

    if [[ ${#RUNNABLE[@]} -eq 0 ]]; then
        generate_report
        maybe_install_hook
        exit 0
    fi

    for entry in "${RUNNABLE[@]}"; do
        local name b64cmd cmd
        name="${entry%%|*}"
        b64cmd="${entry#*|}"
        cmd=$(echo "$b64cmd" | base64 -d)
        run_job "$name" "$cmd"
    done

    generate_report
    maybe_install_hook
}

main "$@"
exit 0
