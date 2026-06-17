#!/usr/bin/env bash
# lint-gate.sh — Fast Python lint/format gate for Black + Ruff projects.
set -euo pipefail

MODE="check"
TARGET="."
STAGED_ONLY=false

usage() {
    cat <<'EOF'
Usage: bash lint-gate.sh [--check|--fix] [--target PATH] [--staged]

Modes:
  --check    Run validation only (default): ruff check + black --check
  --fix      Apply safe fixes: ruff check --fix + black, then re-check

Options:
  --target PATH  Directory or file to check (default: .)
  --staged       Check only files staged in git (overrides --target)

Exit codes:
  0 = gate passed
  1 = gate failed (issues remain)
  2 = usage/dependency error
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --check)
        MODE="check"
        shift
        ;;
    --fix)
        MODE="fix"
        shift
        ;;
    --staged)
        STAGED_ONLY=true
        shift
        ;;
    --target)
        [[ $# -ge 2 ]] || {
            echo "ERROR: --target requires a value" >&2
            exit 2
        }
        TARGET="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "ERROR: Unknown argument: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
done

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: Missing dependency: $1" >&2
        exit 2
    fi
}

require_cmd ruff
require_cmd black

# Resolve staged-only mode
if [[ "$STAGED_ONLY" == "true" ]]; then
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "ERROR: --staged requires a git repository" >&2
        exit 2
    fi
    mapfile -t STAGED_PY < <(git diff --cached --name-only -- '*.py' 2>/dev/null)
    if [[ ${#STAGED_PY[@]} -eq 0 ]]; then
        echo "[lint-gate] no staged Python files — nothing to check"
        exit 0
    fi
    echo "[lint-gate] staged=${#STAGED_PY[*]} file(s) mode=$MODE"
else
    if [[ ! -e "$TARGET" ]]; then
        echo "ERROR: Target not found: $TARGET" >&2
        exit 2
    fi
    echo "[lint-gate] target=$TARGET mode=$MODE"
fi

run_checks() {
    local ok=0
    local targets=()

    if [[ "$STAGED_ONLY" == "true" ]]; then
        targets=("${STAGED_PY[@]}")
    else
        targets=("$TARGET")
    fi

    if ! ruff check "${targets[@]}"; then
        ok=1
    fi

    if ! black --check "${targets[@]}"; then
        ok=1
    fi

    return "$ok"
}

print_guidance() {
    cat <<'EOF'

Lint guidance:
- F401/F841: remove unused imports/variables or prefix intentional unused vars with _
- E722: replace bare 'except:' with an explicit exception type
- B904: inside except, use 'raise ... from exc' when re-raising context
- Long lines/wrapping: prefer parentheses + trailing comma (Black-friendly)
- Avoid broad '# noqa' and file-wide disables; keep suppressions narrow and justified
EOF
}

if [[ "$MODE" == "fix" ]]; then
    echo "[lint-gate] applying safe fixes"
    if [[ "$STAGED_ONLY" == "true" ]]; then
        ruff check --fix "${STAGED_PY[@]}" || true
        black "${STAGED_PY[@]}" || true
    else
        ruff check --fix "$TARGET" || true
        black "$TARGET" || true
    fi
fi

if run_checks; then
    echo "[lint-gate] PASS"
    exit 0
fi

print_guidance
echo "[lint-gate] FAIL" >&2
exit 1
