#!/usr/bin/env bash
# check-manifest.sh
# Parses an OTA plist manifest (URL or local file) and verifies bundle ID,
# version, and that the IPA URL resolves. Reports any field mismatches.
#
# Prerequisites: curl, python3 (for plist parsing on macOS)
#
# Usage:
#   ./check-manifest.sh <manifest-url-or-path>
#   ./check-manifest.sh <manifest-url-or-path> --bundle-id com.example.app
#   ./check-manifest.sh <manifest-url-or-path> --bundle-id com.example.app --version 2.1.0

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <manifest-url-or-path> [--bundle-id <id>] [--version <ver>]"
    exit 1
fi

MANIFEST_INPUT="$1"
EXPECTED_BUNDLE_ID=""
EXPECTED_VERSION=""

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bundle-id) EXPECTED_BUNDLE_ID="${2:-}"; shift 2 ;;
        --version)   EXPECTED_VERSION="${2:-}";   shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

echo "=== check-manifest ==="
echo "  Source: $MANIFEST_INPUT"
echo ""

# ── Fetch or use local ────────────────────────────────────────────────────
MANIFEST_FILE=""
CLEANUP=false

if [[ "$MANIFEST_INPUT" == http* ]]; then
    echo "--- Fetching manifest ---"
    MANIFEST_FILE=$(mktemp /tmp/ota-manifest-XXXXXX.plist)
    CLEANUP=true
    HTTP_CODE=$(curl -sSL -w "%{http_code}" -o "$MANIFEST_FILE" "$MANIFEST_INPUT")
    if [[ "$HTTP_CODE" != "200" ]]; then
        echo "  [FAIL] HTTP $HTTP_CODE — manifest URL did not resolve"
        rm -f "$MANIFEST_FILE"
        exit 1
    fi
    echo "  [PASS] Manifest fetched (HTTP 200)"
else
    if [[ ! -f "$MANIFEST_INPUT" ]]; then
        echo "  [ERROR] File not found: $MANIFEST_INPUT"
        exit 1
    fi
    MANIFEST_FILE="$MANIFEST_INPUT"
fi

cleanup() { $CLEANUP && rm -f "$MANIFEST_FILE" 2>/dev/null || true; }
trap cleanup EXIT

echo ""

# ── Parse plist ───────────────────────────────────────────────────────────
echo "--- Manifest Fields ---"
BUNDLE_ID=$(python3 - "$MANIFEST_FILE" <<'PYEOF'
import sys, plistlib
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
items = p.get('items', [{}])[0]
meta = {m['key']: m['value'] for m in items.get('metadata', [])}
print(meta.get('bundle-identifier', ''))
PYEOF
)

BUNDLE_VERSION=$(python3 - "$MANIFEST_FILE" <<'PYEOF'
import sys, plistlib
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
items = p.get('items', [{}])[0]
meta = {m['key']: m['value'] for m in items.get('metadata', [])}
print(meta.get('bundle-version', ''))
PYEOF
)

IPA_URL=$(python3 - "$MANIFEST_FILE" <<'PYEOF'
import sys, plistlib
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
items = p.get('items', [{}])[0]
for asset in items.get('assets', []):
    if asset.get('kind') == 'software-package':
        print(asset.get('url', ''))
        break
PYEOF
)

DISPLAY_NAME=$(python3 - "$MANIFEST_FILE" <<'PYEOF'
import sys, plistlib
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
items = p.get('items', [{}])[0]
meta = {m['key']: m['value'] for m in items.get('metadata', [])}
print(meta.get('title', ''))
PYEOF
)

echo "  bundle-identifier : $BUNDLE_ID"
echo "  bundle-version    : $BUNDLE_VERSION"
echo "  title             : $DISPLAY_NAME"
echo "  ipa-url           : $IPA_URL"
echo ""

# ── Validate expected values ──────────────────────────────────────────────
echo "--- Validation ---"
FAILED=false

if [[ -n "$EXPECTED_BUNDLE_ID" ]]; then
    if [[ "$BUNDLE_ID" == "$EXPECTED_BUNDLE_ID" ]]; then
        echo "  [PASS] bundle-identifier matches expected ($EXPECTED_BUNDLE_ID)"
    else
        echo "  [FAIL] bundle-identifier mismatch"
        echo "         Expected: $EXPECTED_BUNDLE_ID"
        echo "         Actual  : $BUNDLE_ID"
        FAILED=true
    fi
fi

if [[ -n "$EXPECTED_VERSION" ]]; then
    if [[ "$BUNDLE_VERSION" == "$EXPECTED_VERSION" ]]; then
        echo "  [PASS] bundle-version matches expected ($EXPECTED_VERSION)"
    else
        echo "  [FAIL] bundle-version mismatch"
        echo "         Expected: $EXPECTED_VERSION"
        echo "         Actual  : $BUNDLE_VERSION"
        FAILED=true
    fi
fi

# ── IPA URL reachability ──────────────────────────────────────────────────
if [[ -n "$IPA_URL" ]]; then
    IPA_CODE=$(curl -sSL --head -o /dev/null -w "%{http_code}" "$IPA_URL" 2>/dev/null || echo "ERR")
    if [[ "$IPA_CODE" == "200" || "$IPA_CODE" == "206" ]]; then
        echo "  [PASS] IPA URL reachable (HTTP $IPA_CODE)"
    else
        echo "  [WARN] IPA URL returned HTTP $IPA_CODE — may not be accessible"
    fi
else
    echo "  [WARN] No IPA URL found in manifest assets"
fi

echo ""
if $FAILED; then
    echo "=== check-manifest complete — VALIDATION FAILURES DETECTED ==="
    exit 1
else
    echo "=== check-manifest complete ==="
fi
