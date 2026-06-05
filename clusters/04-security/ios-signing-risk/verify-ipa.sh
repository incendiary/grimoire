#!/usr/bin/env bash
# verify-ipa.sh
# Hash and code-signature verification for an IPA file.
# Runs SHA-256 hash, unpacks the IPA, verifies the code signature, and
# checks entitlements for the main app bundle.
#
# Prerequisites (macOS): codesign (Xcode CLT), unzip
#
# Usage:
#   ./verify-ipa.sh <path/to/app.ipa>
#   ./verify-ipa.sh <path/to/app.ipa> --expected-hash <sha256>

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path/to/app.ipa> [--expected-hash <sha256>]"
    exit 1
fi

IPA_PATH="$1"
EXPECTED_HASH=""

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --expected-hash) EXPECTED_HASH="${2:-}"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ ! -f "$IPA_PATH" ]]; then
    echo "[ERROR] File not found: $IPA_PATH"
    exit 1
fi

echo "=== verify-ipa ==="
echo "  IPA: $IPA_PATH"
echo ""

# ── SHA-256 hash ───────────────────────────────────────────────────────────
echo "--- Hash ---"
ACTUAL_HASH=$(shasum -a 256 "$IPA_PATH" | awk '{print $1}')
echo "  SHA-256: $ACTUAL_HASH"

if [[ -n "$EXPECTED_HASH" ]]; then
    if [[ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]]; then
        echo "  [PASS] Hash matches expected"
    else
        echo "  [FAIL] Hash mismatch"
        echo "         Expected: $EXPECTED_HASH"
        echo "         Actual  : $ACTUAL_HASH"
    fi
fi
echo ""

# ── Unpack ─────────────────────────────────────────────────────────────────
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "--- Unpacking ---"
unzip -q "$IPA_PATH" -d "$WORK_DIR"

APP_BUNDLE=$(find "$WORK_DIR/Payload" -maxdepth 1 -name "*.app" -type d 2>/dev/null | head -1)
if [[ -z "$APP_BUNDLE" ]]; then
    echo "  [ERROR] No .app bundle found in Payload/"
    exit 1
fi

APP_NAME=$(basename "$APP_BUNDLE")
echo "  App bundle: $APP_NAME"
echo ""

# ── Code signature verification ────────────────────────────────────────────
echo "--- Code Signature ---"
if ! command -v codesign &>/dev/null; then
    echo "  [SKIP] codesign not available (requires macOS + Xcode CLT)"
else
    codesign -dv --verbose=4 "$APP_BUNDLE" 2>&1 | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""

    echo "--- Signature Validity ---"
    if codesign --verify --deep --strict "$APP_BUNDLE" 2>/dev/null; then
        echo "  [PASS] Signature is valid"
    else
        echo "  [FAIL] Signature verification failed"
        codesign --verify --deep --strict "$APP_BUNDLE" 2>&1 | while IFS= read -r line; do
            echo "         $line"
        done
    fi
    echo ""

    # ── Entitlements ──────────────────────────────────────────────────────────
    echo "--- Entitlements ---"
    codesign -d --entitlements - "$APP_BUNDLE" 2>/dev/null | while IFS= read -r line; do
        echo "  $line"
    done
fi

echo ""
echo "=== verify-ipa complete ==="
