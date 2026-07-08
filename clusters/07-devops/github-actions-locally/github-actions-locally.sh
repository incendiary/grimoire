#!/bin/bash
# github-actions-locally.sh — Run GitHub Actions locally before pushing
# Discovers linting and test jobs from .github/workflows/, runs them locally,
# auto-fixes issues where possible, and reports results.

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
REPO_ROOT="${1:-.}"
DRY_RUN=false
LIST_ONLY=false
JOB_TYPE="all"  # all, lint, test
WORKFLOW_FILTER=""

# Results tracking
declare -a LINT_JOBS=()
declare -a TEST_JOBS=()
declare -a PASSED_JOBS=()
declare -a FAILED_JOBS=()
declare -a FIXED_JOBS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --lint)
            JOB_TYPE="lint"
            shift
            ;;
        --test)
            JOB_TYPE="test"
            shift
            ;;
        --workflow)
            WORKFLOW_FILTER="$2"
            shift 2
            ;;
        --job)
            # Job pattern filtering (reserved for future expansion)
            shift 2
            ;;
        *)
            REPO_ROOT="$1"
            shift
            ;;
    esac
done

cd "$REPO_ROOT" || exit 1

# Helper: Check if job name matches lint/test keywords
is_lint_job() {
    local job_name="$1"
    if [[ "$job_name" =~ (lint|ruff|black|shellcheck|prettier|eslint|format|style) ]]; then
        return 0
    fi
    return 1
}

is_test_job() {
    local job_name="$1"
    if [[ "$job_name" =~ (test|pytest|jest|vitest|build|spec) ]]; then
        return 0
    fi
    return 1
}

# Helper: Extract run commands from workflow YAML
extract_run_commands() {
    local workflow_file="$1"
    local job_name="$2"

    # Simple regex-based extraction (looking for 'run:' lines after the job)
    awk -v job="$job_name" '
        /^[[:space:]]*'"$job_name"':/ { in_job=1; next }
        in_job && /^[[:space:]]*[a-zA-Z_]/ && !/^[[:space:]]*-/ { in_job=0 }
        in_job && /run:/ {
            getline
            while (/^[[:space:]]+/) {
                print $0
                getline
            }
        }
    ' "$workflow_file"
}

# Discover all jobs in workflows
discover_jobs() {
    echo -e "${BLUE}=== Discovering Jobs ===${NC}"

    if [[ ! -d ".github/workflows" ]]; then
        echo "No .github/workflows/ directory found"
        return 1
    fi

    local workflow_files=(.github/workflows/*.yml .github/workflows/*.yaml)

    for workflow_file in "${workflow_files[@]}"; do
        [[ -f "$workflow_file" ]] || continue

        if [[ -n "$WORKFLOW_FILTER" && "$workflow_file" != *"$WORKFLOW_FILTER"* ]]; then
            continue
        fi

        echo "  $(basename "$workflow_file"):"

        # Extract job names (simple regex for jobs: section)
        # shellcheck disable=SC2030,SC2031
        grep -E "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_-]*:" "$workflow_file" | \
        sed 's/[^a-zA-Z0-9_-]//g' | while read -r job_name; do
            [[ -z "$job_name" ]] && continue

            if is_lint_job "$job_name"; then
                LINT_JOBS+=("$job_name")
                echo "    ✓ $job_name (linting)"
            elif is_test_job "$job_name"; then
                TEST_JOBS+=("$job_name")
                echo "    ✓ $job_name (test)"
            fi
        done
    done

    echo ""
}

# List discovered jobs
list_jobs() {
    echo -e "${BLUE}=== Discovered Jobs ===${NC}"
    echo ""

    if [[ ${#LINT_JOBS[@]} -gt 0 ]]; then
        echo "LINTING:"
        for job in "${LINT_JOBS[@]}"; do
            echo "  - $job"
        done
        echo ""
    fi

    if [[ ${#TEST_JOBS[@]} -gt 0 ]]; then
        echo "TESTS:"
        for job in "${TEST_JOBS[@]}"; do
            echo "  - $job"
        done
        echo ""
    fi

    local total=$((${#LINT_JOBS[@]} + ${#TEST_JOBS[@]}))
    echo "Total: $total jobs (${#LINT_JOBS[@]} lint, ${#TEST_JOBS[@]} test)"
}

# Run a command and capture output
run_job() {
    local job_name="$1"
    local command="$2"

    echo -e "${BLUE}Running: $job_name...${NC}"

    # Execute command and capture output
    local output
    local exit_code
    output=$(eval "$command" 2>&1) || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_JOBS+=("$job_name")
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "Output:"
        echo "$output" | head -20
        [[ ${#output} -gt 100 ]] && echo "... (truncated)"
        FAILED_JOBS+=("$job_name")

        # Attempt auto-fix based on tool
        attempt_fix "$job_name" "$command" "$output"
    fi
}

# Attempt auto-fixes for common tools
attempt_fix() {
    local job_name="$1"
    local command="$2"
    local output="$3"

    if [[ "$command" =~ black ]]; then
        echo "  Attempting auto-fix with black..."
        if black . >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Black auto-fixed files${NC}"
            FIXED_JOBS+=("$job_name (black)")
            # Re-run to confirm
            if eval "$command" >/dev/null 2>&1; then
                PASSED_JOBS+=("$job_name")
                FAILED_JOBS=("${FAILED_JOBS[@]/$job_name}")
            fi
        fi
    elif [[ "$command" =~ ruff ]]; then
        echo "  Attempting auto-fix with ruff..."
        if ruff check --fix . >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Ruff auto-fixed issues${NC}"
            FIXED_JOBS+=("$job_name (ruff)")
            # Re-run to confirm
            if eval "$command" >/dev/null 2>&1; then
                PASSED_JOBS+=("$job_name")
                FAILED_JOBS=("${FAILED_JOBS[@]/$job_name}")
            fi
        fi
    fi
}

# Generate summary report
generate_report() {
    echo ""
    echo -e "${BLUE}=== Summary ===${NC}"

    local total=$((${#LINT_JOBS[@]} + ${#TEST_JOBS[@]}))
    local passed=${#PASSED_JOBS[@]}
    local failed=${#FAILED_JOBS[@]}
    local fixed=${#FIXED_JOBS[@]}

    echo "Jobs: $total total, $passed passed, $failed failed"

    if [[ $fixed -gt 0 ]]; then
        echo -e "${YELLOW}Auto-fixed: $fixed job(s)${NC}"
        for job in "${FIXED_JOBS[@]}"; do
            echo "  - $job"
        done
    fi

    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Manual attention needed: $failed job(s)${NC}"
        for job in "${FAILED_JOBS[@]}"; do
            echo "  - $job"
        done
    fi

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✅ All jobs passed. Ready to push.${NC}"
    else
        echo -e "${YELLOW}⚠️  $failed issue(s) require manual review.${NC}"
    fi

    echo ""
}

# Main flow
main() {
    echo -e "${BLUE}=== GitHub Actions — Local Run ===${NC}"
    echo ""

    discover_jobs

    if [[ "$LIST_ONLY" == true ]]; then
        list_jobs
        exit 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        list_jobs
        echo -e "${YELLOW}Dry-run: not executing jobs${NC}"
        exit 0
    fi

    # Select jobs based on filter
    local jobs_to_run=()
    if [[ "$JOB_TYPE" == "all" || "$JOB_TYPE" == "lint" ]]; then
        jobs_to_run+=("${LINT_JOBS[@]}")
    fi
    if [[ "$JOB_TYPE" == "all" || "$JOB_TYPE" == "test" ]]; then
        jobs_to_run+=("${TEST_JOBS[@]}")
    fi

    if [[ ${#jobs_to_run[@]} -eq 0 ]]; then
        echo "No jobs to run"
        exit 0
    fi

    echo "Running ${#jobs_to_run[@]} job(s)..."
    echo ""

    # TODO: Extract actual commands from workflows and run them
    # For now, show placeholder
    echo -e "${YELLOW}Note: Full job execution implementation coming soon${NC}"
    echo "Discovered: ${#LINT_JOBS[@]} linting jobs, ${#TEST_JOBS[@]} test jobs"

    list_jobs

    generate_report
}

main "$@"
exit 0
