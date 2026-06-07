#!/usr/bin/env bash
# check-provenance.sh
# Verifies npm package provenance attestations (Sigstore-backed build transparency).
#
# Checks performed:
#   1. npm version supports provenance verification (≥ 9.5.0)
#   2. node_modules is present (npm ci must have been run first)
#   3. npm audit signatures — batch signature verification for all installed packages
#   4. Per-package provenance detail check for --critical packages
#
# Usage:
#   ./check-provenance.sh                              # signatures only
#   ./check-provenance.sh --critical express,axios     # + provenance detail for named packages
#   ./check-provenance.sh --strict                     # exit 1 on missing sigs, not just invalid
#   ./check-provenance.sh /path/to/project             # specify project directory

set -euo pipefail

# ── Arguments ────────────────────────────────────────────────────────────────
PROJECT_DIR="."
CRITICAL_PKGS=""
STRICT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --critical)  CRITICAL_PKGS="$2"; shift 2 ;;
        --strict)    STRICT=true; shift ;;
        -*)          echo "Unknown option: $1" >&2; exit 1 ;;
        *)           PROJECT_DIR="$1"; shift ;;
    esac
done

PASS=0
WARN=0
FAIL=0

echo "=== npm-provenance-attestation ==="
echo "  Project : $(realpath "$PROJECT_DIR")"
echo ""

# ── Helpers ──────────────────────────────────────────────────────────────────
pass() { echo "  [PASS] $1"; (( PASS++ )) || true; }
warn() { echo "  [WARN] $1"; (( WARN++ )) || true; }
fail() { echo "  [FAIL] $1"; (( FAIL++ )) || true; }
info() { echo "  [INFO] $1"; }

# ── 1. npm version check ──────────────────────────────────────────────────────
echo "--- npm version ---"
echo ""

if ! command -v npm &>/dev/null; then
    fail "npm not found on PATH"
    echo ""
    echo "=== npm-provenance-attestation — FAILED ==="
    exit 1
fi

NPM_VERSION=$(npm --version 2>/dev/null)
info "npm version: $NPM_VERSION"

# Parse major.minor
NPM_MAJOR=$(echo "$NPM_VERSION" | cut -d. -f1)
NPM_MINOR=$(echo "$NPM_VERSION" | cut -d. -f2)

# Provenance requires ≥ 9.5.0
if [[ "$NPM_MAJOR" -lt 9 ]] || { [[ "$NPM_MAJOR" -eq 9 ]] && [[ "$NPM_MINOR" -lt 5 ]]; }; then
    fail "npm $NPM_VERSION is below 9.5.0 — provenance verification is unavailable"
    echo ""
    echo "  Remediation:"
    echo "    npm install -g npm@latest"
    echo "    Minimum for provenance: npm 9.5.0 (released 2023-04)"
    echo "    Fallback: use npm-lockfile-integrity skill (sha512 hashes remain valid)"
    echo ""
    echo "=== npm-provenance-attestation — FAILED ==="
    exit 1
fi

pass "npm $NPM_VERSION supports provenance verification"
echo ""

# ── 2. node_modules presence ──────────────────────────────────────────────────
echo "--- node_modules ---"
echo ""

if [[ ! -d "$PROJECT_DIR/node_modules" ]]; then
    fail "node_modules not found — run 'npm ci' before checking provenance"
    echo ""
    echo "  npm audit signatures requires installed packages to be present."
    echo ""
    echo "=== npm-provenance-attestation — FAILED ==="
    exit 1
fi

pass "node_modules present"
echo ""

# ── 3. npm audit signatures ───────────────────────────────────────────────────
echo "--- npm audit signatures ---"
echo ""

info "Running: npm audit signatures (this may take a moment...)"
echo ""

# Capture output; npm audit signatures exits 0 even with findings
AUDIT_OUTPUT=$(cd "$PROJECT_DIR" && npm audit signatures 2>&1 || true)

# Parse the output categories
# npm audit signatures output format (as of npm 9.x):
#   audited N packages
#   N packages have verified registry signatures
#   N packages have missing registry signatures  (warn)
#   N packages have invalid registry signatures  (fail)

VERIFIED=0
MISSING=0
INVALID=0

while IFS= read -r line; do
    if echo "$line" | grep -q "verified registry signatures"; then
        VERIFIED=$(echo "$line" | grep -o '[0-9]*' | head -1)
    elif echo "$line" | grep -q "missing registry signatures"; then
        MISSING=$(echo "$line" | grep -o '[0-9]*' | head -1)
    elif echo "$line" | grep -q "invalid registry signatures"; then
        INVALID=$(echo "$line" | grep -o '[0-9]*' | head -1)
    fi
done <<< "$AUDIT_OUTPUT"

info "Verified:  $VERIFIED"
info "Missing:   $MISSING"
info "Invalid:   $INVALID"
echo ""

if [[ "$INVALID" -gt 0 ]]; then
    fail "$INVALID package(s) have invalid registry signatures — treat as potentially compromised"
    echo ""
    # Print the raw output so the specific packages are visible
    echo "  npm audit signatures output:"
    while IFS= read -r line; do
        echo "    $line"
    done <<< "$AUDIT_OUTPUT"
    echo ""
elif [[ "$MISSING" -gt 0 ]]; then
    warn "$MISSING package(s) have missing registry signatures"
    echo "         Missing signatures are expected for packages published before ~2023."
    echo "         Flag if any are newly-published or recently updated under new maintainership."
    if $STRICT; then
        echo "         --strict mode: treating missing signatures as failure"
    fi
else
    pass "All $VERIFIED package(s) have verified registry signatures"
fi

echo ""

# ── 4. Critical package provenance detail ─────────────────────────────────────
if [[ -n "$CRITICAL_PKGS" ]]; then
    echo "--- Provenance detail for critical packages ---"
    echo ""

    # Split comma-separated list into array
    IFS=',' read -ra PKG_LIST <<< "$CRITICAL_PKGS"

    for pkg in "${PKG_LIST[@]}"; do
        # Strip whitespace
        pkg="${pkg// /}"
        [[ -z "$pkg" ]] && continue

        echo "  Package: $pkg"

        # Get installed version from node_modules
        PKG_JSON="$PROJECT_DIR/node_modules/$pkg/package.json"
        if [[ ! -f "$PKG_JSON" ]]; then
            warn "  $pkg not found in node_modules — skipping"
            echo ""
            continue
        fi

        PKG_VERSION=$(python3 -c "import json; print(json.load(open('$PKG_JSON'))['version'])" 2>/dev/null || echo "unknown")
        echo "  Version : $PKG_VERSION"

        if [[ "$PKG_VERSION" == "unknown" ]]; then
            warn "  Could not read version from $PKG_JSON"
            echo ""
            continue
        fi

        # Fetch attestations from the registry
        ATTESTATION_JSON=$(npm view "${pkg}@${PKG_VERSION}" dist.attestations --json 2>/dev/null || echo "null")

        if [[ "$ATTESTATION_JSON" == "null" ]] || [[ -z "$ATTESTATION_JSON" ]]; then
            warn "  No provenance attestation found"
            echo "         Expected for packages published before npm 9.5.0 (2023-04)."
            echo "         Flag as yellow if this package was recently published or recently"
            echo "         changed maintainers."
        else
            # Parse attestation fields with python3
            PROVENANCE_INFO=$(python3 - "$ATTESTATION_JSON" <<'PYEOF'
import json, sys

raw = sys.argv[1]
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("PARSE_ERROR")
    sys.exit(0)

# Attestations may be a list or a dict
if isinstance(data, list):
    attestations = data
elif isinstance(data, dict) and "attestations" in data:
    attestations = data["attestations"]
else:
    attestations = [data]

for att in attestations:
    predicate_type = att.get("predicateType", "unknown")
    bundle = att.get("bundle", {})
    predicate = att.get("predicate", {})

    # SLSA provenance fields
    build_meta = predicate.get("buildDefinition", {}) or {}
    ext = build_meta.get("externalParameters", {}) or {}
    source_repo = ext.get("workflow", {}).get("repository", "") or \
                  predicate.get("buildMetadata", {}).get("invocationId", "") or ""

    # npm-publish-provenance style
    if not source_repo:
        source_repo = predicate.get("sourceRepositoryURI", "")

    build_trigger = predicate.get("buildTrigger", "") or \
                    ext.get("workflow", {}).get("ref", "")

    run_uri = predicate.get("runInvocationURI", "") or \
              predicate.get("buildMetadata", {}).get("invocationId", "")

    print(f"TYPE={predicate_type}")
    print(f"SOURCE={source_repo}")
    print(f"TRIGGER={build_trigger}")
    print(f"RUN={run_uri}")
PYEOF
)
            if [[ "$PROVENANCE_INFO" == "PARSE_ERROR" ]]; then
                warn "  Could not parse attestation JSON"
            else
                SOURCE=$(echo "$PROVENANCE_INFO" | grep "^SOURCE=" | cut -d= -f2-)
                TRIGGER=$(echo "$PROVENANCE_INFO" | grep "^TRIGGER=" | cut -d= -f2-)
                RUN=$(echo "$PROVENANCE_INFO" | grep "^RUN=" | cut -d= -f2-)
                TYPE=$(echo "$PROVENANCE_INFO" | grep "^TYPE=" | cut -d= -f2-)

                echo "  Attestation type : $TYPE"
                echo "  Source repo      : ${SOURCE:-<not found>}"
                echo "  Build trigger    : ${TRIGGER:-<not found>}"
                echo "  Run URI          : ${RUN:-<not found>}"
                echo ""
                echo "  Verify manually:"
                echo "    □ sourceRepositoryURI matches the expected GitHub/GitLab repo"
                echo "    □ buildTrigger is a CI event (push/workflow_dispatch), not 'manual'"
                echo "    □ runInvocationURI points to a real CI run in that repository"

                if [[ -n "$SOURCE" ]]; then
                    pass "  $pkg: provenance attestation found and parsed"
                else
                    warn "  $pkg: attestation found but source repository not readable"
                fi
            fi
        fi

        echo ""
    done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo "--- Summary ---"
echo ""
echo "  Passed:   $PASS"
echo "  Warnings: $WARN"
echo "  Failed:   $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo "=== npm-provenance-attestation — FAILED ($FAIL check(s)) ==="
    exit 1
elif $STRICT && [[ "$WARN" -gt 0 ]]; then
    echo "=== npm-provenance-attestation — FAILED in --strict mode ($WARN warning(s)) ==="
    exit 1
else
    echo "=== npm-provenance-attestation complete ==="
fi
