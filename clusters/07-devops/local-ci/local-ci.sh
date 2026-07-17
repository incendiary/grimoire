#!/bin/bash
# local-ci.sh — Run your GitHub Actions workflows locally, before you push.
#
# Discovers .github/workflows/*.yml with a real YAML parser, extracts each
# job's `run:` steps, executes them in file order (stopping a job at its
# first failed step, as CI does), and reports only what actually ran.
#
# Core safety rule (writing): only *writes* (auto-fixes with black/ruff) when
# it has *verified* its tool version matches what CI pins in the workflow.
# Otherwise it reads and reports only — using a mismatched tool version and
# then auto-fixing with it can corrupt correct files (CI's Black and yours can
# format differently across versions). `--sync` builds CI's exact pinned
# toolchain in an ephemeral venv (inside .git/, never your own venv).
#
# Hooks (never clobber): can install itself into a git hook slot —
#   --install-hook pre-commit  → fast lint subset, informational (never blocks)
#   --install-hook pre-push    → full run, fail-closed (--gate; blocks a red push)
# A pre-existing hook in the slot (e.g. the pre-commit framework / gitleaks) is
# preserved as a sidecar and still runs first — installs COMPLEMENT, never
# overwrite. A normal run auto-installs the pre-push gate if no local-ci hook
# exists yet.
#
# Exit code: 0 by default (a normal run never breaks your shell). With --gate,
# non-zero on a genuine check failure, so the pre-push hook blocks the push.

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
SYNC_REQUESTED=false  # --sync: build CI's pinned toolchain before running
SYNC_ACTIVE=false     # set true once that ephemeral env is actually built
GATE=false            # --gate: exit non-zero on real failures (for a blocking hook)
HARD_FAILURES=0       # count of genuine check failures (excludes local toolchain gaps)

# Results tracking
declare -a PASSED_JOBS=()
declare -a FAILED_JOBS=()
declare -a FIXED_JOBS=()
declare -a SKIPPED_JOBS=()
declare -a SKIPPED_AFTER_FAILURE=()
declare -a FAILED_JOB_KEYS=()  # bash 3.2 (macOS default) has no associative
                               # arrays; linear-search this instead — job
                               # counts are small enough that it's fine.
declare -a PIN_TOOLS=()        # CI-pinned tool names, parsed from workflows'
declare -a PIN_VERS=()         # own `pip install X==Y` / requirements files.
RAN_ANY=false

job_has_failed() {
    local key="$1" k
    # Guard against expanding an empty array under `set -u` — bash 3.2
    # (macOS's stock /bin/bash) treats "${arr[@]}" on a never-populated
    # array as an unbound-variable error, unlike bash 4+.
    [[ ${#FAILED_JOB_KEYS[@]} -eq 0 ]] && return 1
    for k in "${FAILED_JOB_KEYS[@]}"; do
        [[ "$k" == "$key" ]] && return 0
    done
    return 1
}

# --- Tool version parity with CI -------------------------------------------
# The core safety rule: this tool may only *write* (auto-fix) when it has
# *verified* its tool version matches what CI pins. Otherwise it reads and
# reports only. Everything below implements that check.

# Version CI pins for a tool (parsed from the workflows), or "" if unpinned.
pin_for_tool() {
    local tool="$1" i
    [[ ${#PIN_TOOLS[@]} -eq 0 ]] && { echo ""; return; }
    for i in "${!PIN_TOOLS[@]}"; do
        [[ "${PIN_TOOLS[$i]}" == "$tool" ]] && { echo "${PIN_VERS[$i]}"; return; }
    done
    echo ""
}

# Locally-resolved version of a tool (in the currently active env), or "".
local_tool_version() {
    local tool="$1" out
    command -v "$tool" >/dev/null 2>&1 || { echo ""; return; }
    out=$("$tool" --version 2>&1) || true
    echo "$out" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

# Auto-fix is permitted only when the tool version is verified against CI's
# pin — either because we synced CI's exact toolchain, or because the local
# version already equals the pin. Unpinned-in-CI or not-installed => no.
tool_can_autofix() {
    local tool="$1" pin lv
    [[ "$SYNC_ACTIVE" == true ]] && return 0
    pin=$(pin_for_tool "$tool"); [[ -z "$pin" ]] && return 1
    lv=$(local_tool_version "$tool"); [[ -z "$lv" ]] && return 1
    [[ "$lv" == "$pin" ]]
}

# Does any runnable step actually invoke this tool? (So we only report on
# tools the run will exercise.)
runnable_mentions() {
    local tool="$1" e b c
    [[ ${#RUNNABLE[@]} -eq 0 ]] && return 1
    for e in "${RUNNABLE[@]}"; do
        b="${e##*|}"
        c=$(echo "$b" | base64 -d 2>/dev/null)
        [[ "$c" == *"$tool"* ]] && return 0
    done
    return 1
}

# Print one line of parity status for a fixable tool that the run will use.
print_tool_status() {
    local tool="$1" pin lv
    runnable_mentions "$tool" || return 0
    pin=$(pin_for_tool "$tool")
    lv=$(local_tool_version "$tool")
    if [[ "$SYNC_ACTIVE" == true && -n "$pin" ]]; then
        echo -e "  ${GREEN}✓ $tool $pin${NC} — CI-matched (synced); auto-fix enabled"
    elif [[ -z "$lv" ]]; then
        echo -e "  ${YELLOW}• $tool not installed locally${NC} — its step will report a toolchain issue"
    elif [[ -z "$pin" ]]; then
        echo -e "  ${YELLOW}⚠ $tool $lv local; CI does not pin it${NC} — parity unverifiable, auto-fix disabled (report-only)"
    elif [[ "$lv" == "$pin" ]]; then
        echo -e "  ${GREEN}✓ $tool $lv${NC} matches CI pin — auto-fix enabled"
    else
        echo -e "  ${RED}⚠ $tool local $lv ≠ CI pin $pin${NC} — results may differ; auto-fix disabled (report-only). Re-run with ${BLUE}--sync${NC} to match CI."
    fi
}

# Print the toolchain-vs-CI section, if the run uses any fixable tool.
print_toolchain_section() {
    runnable_mentions black || runnable_mentions ruff || return 0
    echo -e "${BLUE}=== Toolchain vs CI ===${NC}"
    print_tool_status black
    print_tool_status ruff
    echo ""
}

# --sync: build an ephemeral, CI-matched venv from the workflows' own pins.
# Lives inside .git/ so it is never tracked, never in the work tree, and
# never mutates the developer's own venv or global tools. Falls back to
# report-only (returns non-zero) on any problem, never aborts the run.
build_sync_env() {
    if [[ ${#PIN_TOOLS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}--sync: no pinned versions found in any workflow — nothing to build; staying report-only.${NC}"
        echo ""
        return 1
    fi
    local git_dir venv_dir specs=() i
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
        echo -e "${YELLOW}--sync: not inside a git repo — staying report-only.${NC}"; echo ""; return 1; }
    venv_dir="$git_dir/gal-venv"

    echo -e "${BLUE}=== --sync: building CI-matched environment ===${NC}"
    echo "  location: $venv_dir (ephemeral, outside the work tree)"
    if [[ ! -d "$venv_dir" ]]; then
        if ! python3 -m venv "$venv_dir" >/dev/null 2>&1; then
            echo -e "  ${RED}✗ could not create venv — staying report-only.${NC}"; echo ""; return 1
        fi
    fi
    # shellcheck disable=SC1091
    source "$venv_dir/bin/activate" 2>/dev/null || {
        echo -e "  ${RED}✗ could not activate venv — staying report-only.${NC}"; echo ""; return 1; }

    for i in "${!PIN_TOOLS[@]}"; do specs+=("${PIN_TOOLS[$i]}==${PIN_VERS[$i]}"); done
    echo "  pip install ${specs[*]}"
    if pip install --quiet --upgrade "${specs[@]}" >/dev/null 2>&1; then
        SYNC_ACTIVE=true
        echo -e "  ${GREEN}✓ CI-matched environment ready${NC} ($(command -v python3))"
        echo ""
        return 0
    fi
    echo -e "  ${RED}✗ pip install failed — staying report-only with existing tools.${NC}"
    echo ""
    return 1
}

INSTALL_HOOK_ONLY=false
INSTALL_HOOK_SLOT="pre-push"   # default slot for --install-hook / auto-install

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --list) LIST_ONLY=true; shift ;;
        --lint) JOB_TYPE="lint"; shift ;;
        --test) JOB_TYPE="test"; shift ;;
        --workflow) WORKFLOW_FILTER="$2"; shift 2 ;;
        --sync) SYNC_REQUESTED=true; shift ;;
        --gate) GATE=true; shift ;;
        --install-hook)
            INSTALL_HOOK_ONLY=true
            # Optional slot argument: --install-hook pre-commit|pre-push
            case "${2:-}" in
                pre-commit|pre-push) INSTALL_HOOK_SLOT="$2"; shift 2 ;;
                *) shift ;;
            esac
            ;;
        *) REPO_ROOT="$1"; shift ;;
    esac
done

cd "$REPO_ROOT" || exit 1

# Absolute path to this script, so the installed hook works from any repo layout.
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

HOOK_MARKER="# managed-by: local-ci"

# True if our hook is already installed in either slot.
have_our_hook() {
    grep -q "$HOOK_MARKER" .git/hooks/pre-commit 2>/dev/null && return 0
    grep -q "$HOOK_MARKER" .git/hooks/pre-push   2>/dev/null && return 0
    return 1
}

# Write our wrapper into a slot, *complementing* whatever is already there —
# never clobbering it. A pre-existing foreign hook (e.g. the pre-commit
# framework / gitleaks) is preserved as a sidecar and still runs first; our
# wrapper chains it. Our own hook is simply regenerated (idempotent).
install_to_slot() {
    local slot="$1" invocation="$2"
    local hook=".git/hooks/$slot"
    local sidecar=".git/hooks/${slot}.local-ci-prev"
    mkdir -p ".git/hooks"

    if [[ -e "$hook" ]] && ! grep -q "$HOOK_MARKER" "$hook" 2>/dev/null; then
        # Foreign hook present — preserve it, never destroy it.
        if [[ -e "$sidecar" ]]; then
            echo -e "  ${YELLOW}note: a foreign $slot hook reappeared; keeping it as ${slot}.local-ci-prev (prior sidecar overwritten).${NC}"
        fi
        mv "$hook" "$sidecar"
        chmod +x "$sidecar" 2>/dev/null || true
        echo -e "  ${BLUE}chained existing $slot hook${NC} → ${slot}.local-ci-prev (still runs first)"
    fi

    # The wrapper always runs the sidecar first (if present) and honours its
    # exit code, so a chained gitleaks/framework hook keeps its blocking power.
    cat > "$hook" <<HOOK
#!/bin/bash
$HOOK_MARKER — do not remove this line; it marks the hook as ours.
# Runs any pre-existing hook first (preserved as ${slot}.local-ci-prev),
# then local-ci. Regenerate: bash "$SCRIPT_PATH" --install-hook $slot
_lci_dir="\$(cd "\$(dirname "\$0")" && pwd)"
_lci_prev="\$_lci_dir/${slot}.local-ci-prev"
if [ -x "\$_lci_prev" ]; then
  "\$_lci_prev" "\$@" || exit \$?
fi
cd "\$(git rev-parse --show-toplevel)" || exit 0
$invocation
HOOK
    chmod +x "$hook"
}

# Install our hook into a slot with slot-appropriate behaviour:
#   pre-commit → fast lint subset, informational (never blocks)
#   pre-push   → full run, fail-closed (--gate: blocks a red push)
install_hook() {
    local slot="${1:-pre-push}"
    case "$slot" in
        pre-commit)
            install_to_slot pre-commit \
"bash \"$SCRIPT_PATH\" --lint || true
exit 0"
            echo -e "${GREEN}✓ pre-commit hook installed${NC} (fast lint, informational — never blocks)"
            ;;
        pre-push)
            install_to_slot pre-push \
"exec bash \"$SCRIPT_PATH\" --gate"
            echo -e "${GREEN}✓ pre-push hook installed${NC} (full CI, fail-closed — blocks a red push; bypass once with 'git push --no-verify')"
            ;;
        *)
            echo -e "${RED}unknown hook slot: $slot${NC} (use pre-commit or pre-push)"
            return 1
            ;;
    esac
    echo "   Uninstall: rm .git/hooks/$slot   (if it chained a prior hook, mv .git/hooks/${slot}.local-ci-prev back)"
}

# On a normal run with no local-ci hook anywhere, auto-install the pre-push
# gate — the correct slot for "run CI before pushing", usually free (frameworks
# live in pre-commit), and it *chains* rather than clobbers anything present.
# Interactive: ask. Non-interactive: install (chaining keeps it safe).
maybe_install_hook() {
    have_our_hook && return 0
    if [[ -t 0 ]]; then
        echo -e "${BLUE}Install the pre-push CI gate (full run, fail-closed; chains any existing hook)?${NC}"
        read -rp "Install? (y/n) " -n 1 reply
        echo ""
        [[ "$reply" =~ ^[Yy]$ ]] && install_hook pre-push
        echo -e "${YELLOW}Tip: also 'local-ci.sh --install-hook pre-commit' for a fast per-commit lint.${NC}"
    else
        echo -e "${YELLOW}No local-ci hook found — installing the pre-push CI gate (chains any existing hook, never clobbers).${NC}"
        install_hook pre-push
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
        echo -e "${GREEN}✓ Activated venv${NC} ($(command -v python3))"
    elif [[ -f ".venv/bin/activate" ]]; then
        # shellcheck disable=SC1091
        source .venv/bin/activate >/dev/null 2>&1
        echo -e "${GREEN}✓ Activated .venv${NC} ($(command -v python3))"
    else
        echo -e "${YELLOW}⚠ No venv/.venv found — using PATH tools as-is.${NC}"
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

# Parse CI's pinned tool versions — the authoritative versions we must match
# before we're allowed to auto-fix. Sources: inline `pip install X==Y` in a
# run step, and requirements files it references via `-r <file>`.
PIN_RE = re.compile(r'([A-Za-z0-9_.\-]+)==([0-9][A-Za-z0-9_.\-]*)')

def extract_pins(cmd, wd, pins):
    if 'install' not in cmd:
        return
    if 'pip' not in cmd and 'uv' not in cmd:
        return
    for m in PIN_RE.finditer(cmd):
        pins.setdefault(m.group(1).lower(), m.group(2))
    for m in re.finditer(r'-r\s+(\S+)', cmd):
        rel = m.group(1)
        for cand in ([os.path.join(wd, rel)] if wd else []) + [rel]:
            try:
                with open(cand) as rf:
                    for line in rf:
                        line = line.split('#', 1)[0].strip()
                        rm = PIN_RE.match(line)
                        if rm:
                            pins.setdefault(rm.group(1).lower(), rm.group(2))
                break
            except OSError:
                continue

files = sorted(set(glob.glob('.github/workflows/*.yml') +
                   glob.glob('.github/workflows/*.yaml')))
if wf_filter:
    files = [f for f in files if wf_filter in f]

pins = {}
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
            run_step_idx = 0
            for step in job['steps']:
                if not isinstance(step, dict) or 'run' not in step:
                    continue
                run_step_idx += 1
                # Unnamed steps fall back to the job name, which collides
                # when a job has multiple unnamed run: steps (e.g. npm ci /
                # npx tsc / npm run lint all named "build") — number them so
                # a failure can be pinned to the actual step that failed.
                step_name = step.get('name') or f'{job_name} (step {run_step_idx})'
                raw_cmd = str(step['run']).strip()
                wd = workdir(doc, job, step)
                extract_pins(raw_cmd, wd, pins)
                status, reason = classify(raw_cmd)
                cmd = raw_cmd
                if wd and wd != '.':
                    cmd = f'cd {shlex.quote(wd)} || exit 1\n{cmd}'
                out.write(f'{status}|{b64(wf_name)}|{b64(job_name)}|{b64(step_name)}|{b64(cmd)}|{b64(reason)}\n')
    for name, ver in pins.items():
        out.write(f'PIN|{b64(name)}|{b64(ver)}\n')
PYEOF
}

# Attempt auto-fixes for common tools, then re-run to confirm. The safety
# gate is tool_can_autofix(): we only ever write to source files with a tool
# whose version is *verified* against CI's pin (either synced, or the local
# version already equals the pin). Auto-fixing with an unverified version can
# silently apply a formatting style CI doesn't want and corrupt correct files.
attempt_fix() {
    local job_name="$1" command="$2" tool=""
    [[ "$command" == *black* ]] && tool="black"
    [[ "$command" == *ruff*  ]] && tool="ruff"
    [[ -z "$tool" ]] && return 1   # nothing we know how to fix

    if ! tool_can_autofix "$tool"; then
        echo -e "  ${YELLOW}Auto-fix skipped ($tool): version not verified against CI's pin — report-only.${NC}"
        echo -e "  ${YELLOW}  Re-run with --sync to build CI's pinned toolchain and enable fixes.${NC}"
        return 1
    fi

    if [[ "$tool" == "black" ]]; then
        echo "  Attempting auto-fix with black ($(command -v black), CI-matched)..."
        if black . >/dev/null 2>&1 && eval "$command" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Black auto-fixed files${NC}"
            FIXED_JOBS+=("$job_name (black)")
            PASSED_JOBS+=("$job_name")
            return 0
        fi
    else
        echo "  Attempting auto-fix with ruff ($(command -v ruff), CI-matched)..."
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

    # Try auto-fix first; only record a hard failure if it doesn't resolve.
    # (The old code added to FAILED_JOBS up front then blanked the slot on a
    # successful fix, leaving an empty element that inflated the failed count.)
    if attempt_fix "$job_name" "$command"; then
        return 0
    fi

    FAILED_JOBS+=("$job_name")
    HARD_FAILURES=$((HARD_FAILURES + 1))  # a genuine check failure — gates a push
    # bash quirk: `if cond; then body; fi` with a false condition and no else
    # returns 0, not the condition's exit status — so this needs an explicit
    # failure return, or callers checking run_job's exit code (the stop-on-
    # first-failure logic in main()) would see a false "success".
    return 1
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
    local skipped_after_failure=${#SKIPPED_AFTER_FAILURE[@]}

    echo "Ran: $((passed + failed)) executed, $passed passed, $failed failed, $skipped skipped (CI-only), $skipped_after_failure skipped (job already failed)"

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

    if [[ $skipped_after_failure -gt 0 ]]; then
        echo -e "${YELLOW}Not run — job already failed at an earlier step: $skipped_after_failure step(s)${NC}"
        for job in "${SKIPPED_AFTER_FAILURE[@]}"; do echo "  - $job"; done
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
        install_hook "$INSTALL_HOOK_SLOT"
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
    declare -a RUNNABLE=()  # index-parallel: "job_key|display_name|b64cmd"
    while IFS='|' read -r status b64wf b64job b64step b64cmd b64reason; do
        [[ -z "$status" ]] && continue

        # PIN lines carry CI's pinned tool versions: PIN|b64(tool)|b64(version).
        if [[ "$status" == "PIN" ]]; then
            PIN_TOOLS+=("$(echo "$b64wf" | base64 -d)")
            PIN_VERS+=("$(echo "$b64job" | base64 -d)")
            continue
        fi

        local job step wf class job_key
        job=$(echo "$b64job" | base64 -d)
        step=$(echo "$b64step" | base64 -d)
        wf=$(echo "$b64wf" | base64 -d)
        class=$(classify_job "$job")
        job_key="${wf}::${job}"

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
        RUNNABLE+=("${job_key}|${wf} › ${job} › ${step}|${b64cmd}")
    done < "$TMPFILE"

    echo -e "${BLUE}=== Discovered ===${NC}"
    if [[ ${#DISPLAY_LINES[@]} -gt 0 ]]; then
        for line in "${DISPLAY_LINES[@]}"; do
            IFS='|' read -r st name reason <<< "$line"
            if [[ "$st" == "SKIP" ]]; then
                echo -e "  ${YELLOW}skip${NC}  $name  ($reason)"
            else
                echo -e "  ${GREEN}run${NC}   $name"
            fi
        done
    fi
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

    # If asked, build CI's pinned toolchain first (upgrades mismatched tools
    # to "faithful" so auto-fix becomes safe). Falls back to report-only on
    # any failure. Then show, per fixable tool, whether we match CI.
    if [[ "$SYNC_REQUESTED" == true ]]; then
        build_sync_env || true
    fi
    print_toolchain_section

    for entry in "${RUNNABLE[@]}"; do
        local job_key rest name b64cmd cmd
        job_key="${entry%%|*}"
        rest="${entry#*|}"
        name="${rest%%|*}"
        b64cmd="${rest#*|}"

        # Real CI stops a job at its first failed step — later steps never
        # run, so a stale local node_modules/venv/etc. can't make them look
        # like they passed. Mirror that instead of running every step
        # unconditionally regardless of an earlier failure in the same job.
        if job_has_failed "$job_key"; then
            echo -e "${YELLOW}Skipping: $name${NC} (earlier step in this job already failed)"
            SKIPPED_AFTER_FAILURE+=("$name")
            continue
        fi

        cmd=$(echo "$b64cmd" | base64 -d)
        if ! run_job "$name" "$cmd"; then
            FAILED_JOB_KEYS+=("$job_key")
        fi
    done

    generate_report
    # Don't offer to install a hook when we ARE running as one (--gate).
    [[ "$GATE" == true ]] || maybe_install_hook
}

main "$@"

# Default: always exit 0 — a normal/informational run never breaks your shell.
# With --gate (used by the fail-closed pre-push hook), exit non-zero on a
# genuine check failure so the push is blocked. Local toolchain gaps (a tool
# CI has that you don't) are NOT counted as hard failures — they shouldn't
# block a push CI would pass; they're reported for you to install the tool.
if [[ "$GATE" == true && "$HARD_FAILURES" -gt 0 ]]; then
    exit 1
fi
exit 0
