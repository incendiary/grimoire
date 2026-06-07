#!/usr/bin/env bash
# check-lockfile-integrity.sh
# Audits package-lock.json for supply chain integrity hygiene:
#   - Lockfile presence and lockfile version (v1 uses sha1; v2/v3 use sha512)
#   - Packages missing integrity fields (cannot be verified by npm ci)
#   - npm version compatibility with integrity enforcement
#
# Usage:
#   ./check-lockfile-integrity.sh                    # audit current directory
#   ./check-lockfile-integrity.sh /path/to/project   # audit a specific project
#   ./check-lockfile-integrity.sh --strict           # exit 1 on warnings as well as failures

set -euo pipefail

# ── Arguments ────────────────────────────────────────────────────────────────
PROJECT_DIR="."
STRICT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict) STRICT=true; shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *)  PROJECT_DIR="$1"; shift ;;
    esac
done

LOCKFILE="$PROJECT_DIR/package-lock.json"

PASS=0
WARN=0
FAIL=0

echo "=== npm-lockfile-integrity ==="
echo "  Project : $(realpath "$PROJECT_DIR")"
echo ""

# ── Helpers ──────────────────────────────────────────────────────────────────
pass() { echo "  [PASS] $1"; (( PASS++ )) || true; }
warn() { echo "  [WARN] $1"; (( WARN++ )) || true; }
fail() { echo "  [FAIL] $1"; (( FAIL++ )) || true; }
info() { echo "  [INFO] $1"; }

# ── 1. Lockfile presence ──────────────────────────────────────────────────────
echo "--- Lockfile ---"
echo ""

if [[ ! -f "$LOCKFILE" ]]; then
    fail "package-lock.json not found in $PROJECT_DIR"
    echo ""
    echo "  Remediation:"
    echo "    Run: npm install  (generates package-lock.json)"
    echo "    Then commit it: git add package-lock.json && git commit -m 'chore: add lockfile'"
    echo "    Switch all CI pipelines from 'npm install' to 'npm ci' after committing."
    echo ""
    echo "=== npm-lockfile-integrity — FAILED ==="
    exit 1
fi

pass "package-lock.json found"

# ── 2. Lockfile version (sha1 vs sha512) ─────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    warn "python3 not found — skipping lockfile version and integrity checks"
else
    LOCKFILE_VERSION=$(python3 -c "
import json, sys
try:
    data = json.load(open('$LOCKFILE'))
    print(data.get('lockfileVersion', 'unknown'))
except Exception as e:
    print('error')
" 2>/dev/null)

    case "$LOCKFILE_VERSION" in
        1)
            fail "Lockfile version 1 detected — uses sha1 hashes (insufficient for supply chain integrity)"
            echo "         Remediation: upgrade npm to ≥ 7, then:"
            echo "           rm -rf node_modules package-lock.json"
            echo "           npm install  (regenerates with sha512 hashes)"
            echo "           git diff package-lock.json  (review before committing)"
            ;;
        2|3)
            pass "Lockfile version $LOCKFILE_VERSION (sha512 integrity hashes)"
            ;;
        error)
            fail "Could not parse package-lock.json — file may be malformed"
            ;;
        unknown)
            warn "lockfileVersion field missing — treating as v1 (sha1)"
            ;;
        *)
            warn "Unexpected lockfileVersion: $LOCKFILE_VERSION"
            ;;
    esac

    echo ""

    # ── 3. Integrity field coverage ───────────────────────────────────────────
    echo "--- Integrity field coverage ---"
    echo ""

    INTEGRITY_REPORT=$(python3 - "$LOCKFILE" <<'PYEOF'
import json, sys

lockfile_path = sys.argv[1]
data = json.load(open(lockfile_path))

missing = []
total = 0

def check_packages(packages, prefix=""):
    for name, info in packages.items():
        if not isinstance(info, dict):
            continue
        total_ref[0] += 1
        if "integrity" not in info:
            missing.append(name)
        # Recurse into nested dependencies (lockfile v1 format)
        if "dependencies" in info:
            check_packages(info["dependencies"])

total_ref = [0]

# lockfile v2/v3: top-level "packages" key
if "packages" in data:
    pkgs = data["packages"]
    for name, info in pkgs.items():
        if not isinstance(info, dict):
            continue
        # Skip the root package entry (empty name key)
        if name == "":
            continue
        total_ref[0] += 1
        if "integrity" not in info:
            missing.append(name)
# lockfile v1: top-level "dependencies" key
elif "dependencies" in data:
    check_packages(data["dependencies"])

total = total_ref[0]
print(f"TOTAL={total}")
print(f"MISSING={len(missing)}")
for m in missing[:20]:  # cap output at 20
    print(f"PKG={m}")
if len(missing) > 20:
    print(f"TRUNCATED={len(missing) - 20}")
PYEOF
)

    TOTAL=$(echo "$INTEGRITY_REPORT" | grep "^TOTAL=" | cut -d= -f2)
    MISSING_COUNT=$(echo "$INTEGRITY_REPORT" | grep "^MISSING=" | cut -d= -f2)
    TRUNCATED=$(echo "$INTEGRITY_REPORT" | grep "^TRUNCATED=" | cut -d= -f2 || echo "0")

    info "Total packages in lockfile: $TOTAL"

    if [[ "$MISSING_COUNT" -eq 0 ]]; then
        pass "All $TOTAL packages have integrity fields"
    else
        fail "$MISSING_COUNT of $TOTAL packages are missing integrity fields"
        echo ""
        echo "  Packages without integrity hashes:"
        while IFS= read -r line; do
            if [[ "$line" == PKG=* ]]; then
                echo "    ${line#PKG=}"
            fi
        done <<< "$INTEGRITY_REPORT"
        if [[ "$TRUNCATED" -gt 0 ]]; then
            echo "    ... and $TRUNCATED more"
        fi
        echo ""
        echo "  Remediation:"
        echo "    rm -rf node_modules package-lock.json"
        echo "    npm install  (regenerates all integrity hashes)"
        echo "    git diff package-lock.json  (review before committing)"
    fi
fi

echo ""

# ── 4. npm version check ──────────────────────────────────────────────────────
echo "--- npm version ---"
echo ""

if ! command -v npm &>/dev/null; then
    warn "npm not found on PATH — cannot verify npm version"
else
    NPM_VERSION=$(npm --version 2>/dev/null || echo "0.0.0")
    NPM_MAJOR=$(echo "$NPM_VERSION" | cut -d. -f1)
    NPM_MINOR=$(echo "$NPM_VERSION" | cut -d. -f2)

    info "npm version: $NPM_VERSION"

    # npm ci with integrity enforcement: requires ≥ 5.7.0
    if [[ "$NPM_MAJOR" -lt 5 ]] || { [[ "$NPM_MAJOR" -eq 5 ]] && [[ "$NPM_MINOR" -lt 7 ]]; }; then
        fail "npm $NPM_VERSION is below 5.7 — npm ci does not enforce integrity hashes"
        echo "         Upgrade npm: npm install -g npm@latest"
    elif [[ "$NPM_MAJOR" -lt 7 ]]; then
        warn "npm $NPM_VERSION generates lockfile v1 (sha1 hashes) — upgrade to npm ≥ 7 for sha512"
        echo "         Upgrade npm: npm install -g npm@latest"
    else
        pass "npm $NPM_VERSION — generates lockfile v2/v3 with sha512 hashes"
    fi
fi

echo ""

# ── 5. CI usage check (best-effort) ──────────────────────────────────────────
echo "--- CI pipeline check (best-effort) ---"
echo ""

CI_FILES=()
mapfile -t CI_FILES < <(find "$PROJECT_DIR" \
    -name "*.yml" -o -name "*.yaml" \
    | grep -E "(\.github/workflows|\.gitlab-ci|\.circleci)" \
    | head -20 || true)

if [[ ${#CI_FILES[@]} -eq 0 ]]; then
    info "No CI workflow files found — skipping"
else
    NPM_INSTALL_FILES=()
    for f in "${CI_FILES[@]}"; do
        if grep -q "npm install" "$f" 2>/dev/null; then
            NPM_INSTALL_FILES+=("$f")
        fi
    done

    if [[ ${#NPM_INSTALL_FILES[@]} -eq 0 ]]; then
        pass "No CI files use 'npm install' (${#CI_FILES[@]} file(s) checked)"
    else
        fail "${#NPM_INSTALL_FILES[@]} CI file(s) use 'npm install' instead of 'npm ci':"
        for f in "${NPM_INSTALL_FILES[@]}"; do
            echo "    $f"
        done
        echo ""
        echo "  Remediation: replace 'npm install' with 'npm ci' in each file listed above"
    fi
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "--- Summary ---"
echo ""
echo "  Passed:   $PASS"
echo "  Warnings: $WARN"
echo "  Failed:   $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo "=== npm-lockfile-integrity — FAILED ($FAIL check(s)) ==="
    exit 1
elif $STRICT && [[ "$WARN" -gt 0 ]]; then
    echo "=== npm-lockfile-integrity — FAILED in --strict mode ($WARN warning(s)) ==="
    exit 1
else
    echo "=== npm-lockfile-integrity complete ==="
fi
