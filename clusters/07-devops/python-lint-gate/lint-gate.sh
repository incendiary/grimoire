#!/usr/bin/env bash
# lint-gate.sh — Fast Python lint/format gate for Black + Ruff projects.
set -euo pipefail

MODE="check"
TARGET="."

usage() {
    cat <<'EOF'
Usage: bash lint-gate.sh [--check|--fix] [--target PATH]

Modes:
  --check    Run validation only (default): ruff check + black --check
  --fix      Apply safe fixes: ruff check --fix + black, then re-check

Options:
  --target PATH  Directory or file to check (default: .)

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

if [[ ! -e "$TARGET" ]]; then
    echo "ERROR: Target not found: $TARGET" >&2
    exit 2
fi

echo "[lint-gate] target=$TARGET mode=$MODE"

run_checks() {
    local ok=0

    if ! ruff check "$TARGET"; then
        ok=1
    fi

    if ! black --check "$TARGET"; then
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
    ruff check --fix "$TARGET" || true
    black "$TARGET" || true
fi

if run_checks; then
    echo "[lint-gate] PASS"
    exit 0
fi

print_guidance
echo "[lint-gate] FAIL" >&2
exit 1
