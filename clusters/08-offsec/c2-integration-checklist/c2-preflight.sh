#!/usr/bin/env bash
# c2-preflight.sh
# Pre-flight checks before deploying a C2 implant to an engagement.
#
# Checks performed:
#   1. c2lint on a malleable C2 profile (if provided and c2lint is on PATH)
#   2. SSL certificate expiry for the listener domain
#   3. Printed summary of OPSEC checklist items requiring manual sign-off
#
# Usage:
#   ./c2-preflight.sh --domain c2.example.com
#   ./c2-preflight.sh --domain c2.example.com --profile ./http-profile.profile
#   ./c2-preflight.sh --domain c2.example.com --profile ./http.profile --port 443 --warn-days 30
#
# Options:
#   --domain      Listener domain (required)
#   --profile     Path to malleable C2 profile (optional; skipped if omitted)
#   --port        HTTPS port for cert check (default: 443)
#   --warn-days   Warn if cert expires within N days (default: 14)
#   --no-cert     Skip SSL certificate check
#   --no-lint     Skip c2lint even if a profile is provided
#   --no-opsec    Skip the manual OPSEC summary

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
DOMAIN=""
PROFILE=""
PORT=443
WARN_DAYS=14
CHECK_CERT=true
RUN_LINT=true
PRINT_OPSEC=true
PASS=0
FAIL=0

# ── Parse arguments ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)    DOMAIN="$2";    shift 2 ;;
        --profile)   PROFILE="$2";   shift 2 ;;
        --port)      PORT="$2";      shift 2 ;;
        --warn-days) WARN_DAYS="$2"; shift 2 ;;
        --no-cert)   CHECK_CERT=false; shift ;;
        --no-lint)   RUN_LINT=false;   shift ;;
        --no-opsec)  PRINT_OPSEC=false; shift ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$DOMAIN" ]]; then
    echo "Error: --domain is required." >&2
    echo "Usage: $0 --domain <listener-domain> [--profile <profile.profile>]" >&2
    exit 1
fi

echo "=== c2-preflight ==="
echo "  Domain  : $DOMAIN"
[[ -n "$PROFILE" ]] && echo "  Profile : $PROFILE"
echo "  Port    : $PORT"
echo ""

# ── Helper ──────────────────────────────────────────────────────────────────
pass() { echo "  [PASS] $1"; (( PASS++ )) || true; }
fail() { echo "  [FAIL] $1"; (( FAIL++ )) || true; }
warn() { echo "  [WARN] $1"; }
info() { echo "  [INFO] $1"; }

# ── 1. c2lint ────────────────────────────────────────────────────────────────
echo "--- c2lint ---"
echo ""

if [[ -z "$PROFILE" ]]; then
    info "No --profile provided; skipping c2lint."
elif ! $RUN_LINT; then
    info "--no-lint set; skipping c2lint."
elif [[ ! -f "$PROFILE" ]]; then
    fail "Profile not found: $PROFILE"
elif ! command -v c2lint &>/dev/null; then
    warn "c2lint not found on PATH."
    warn "Add your Cobalt Strike install directory to PATH and re-run."
    warn "  Expected: \$CS_DIR/c2lint $PROFILE"
else
    echo "  Running: c2lint $PROFILE"
    if c2lint "$PROFILE"; then
        pass "c2lint: profile syntax OK"
    else
        fail "c2lint: profile has errors — fix before deployment"
    fi
fi

echo ""

# ── 2. SSL certificate expiry ────────────────────────────────────────────────
echo "--- SSL certificate expiry ---"
echo ""

if ! $CHECK_CERT; then
    info "--no-cert set; skipping certificate check."
elif ! command -v openssl &>/dev/null; then
    warn "openssl not found; skipping certificate check."
else
    echo "  Checking: $DOMAIN:$PORT"
    CERT_INFO=$(echo | openssl s_client -connect "${DOMAIN}:${PORT}" \
        -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -enddate -subject 2>/dev/null || true)

    if [[ -z "$CERT_INFO" ]]; then
        fail "Could not retrieve certificate from $DOMAIN:$PORT"
        warn "  Is the listener running? Is the domain resolving?"
    else
        EXPIRY_LINE=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)
        SUBJECT_LINE=$(echo "$CERT_INFO" | grep "subject" | sed 's/subject=//')

        echo "  Subject : $SUBJECT_LINE"
        echo "  Expires : $EXPIRY_LINE"

        # Calculate days remaining
        EXPIRY_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY_LINE" "+%s" 2>/dev/null \
            || date -d "$EXPIRY_LINE" "+%s" 2>/dev/null || echo "0")
        NOW_EPOCH=$(date "+%s")
        DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

        if [[ "$EXPIRY_EPOCH" -eq 0 ]]; then
            warn "Could not parse certificate expiry date."
        elif [[ "$DAYS_LEFT" -le 0 ]]; then
            fail "Certificate EXPIRED ($DAYS_LEFT days ago)"
        elif [[ "$DAYS_LEFT" -le "$WARN_DAYS" ]]; then
            warn "Certificate expires in $DAYS_LEFT day(s) — renew before engagement end"
        else
            pass "Certificate valid for $DAYS_LEFT day(s)"
        fi

        # Flag self-signed cert (subject == issuer)
        ISSUER_LINE=$(echo | openssl s_client -connect "${DOMAIN}:${PORT}" \
            -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//' || true)
        if [[ "$SUBJECT_LINE" == "$ISSUER_LINE" ]]; then
            fail "Self-signed certificate detected — replace with a CA-signed cert before engagement"
        else
            pass "Certificate is CA-signed (not self-signed)"
        fi
    fi
fi

echo ""

# ── 3. OPSEC checklist summary ───────────────────────────────────────────────
if $PRINT_OPSEC; then
    echo "--- OPSEC checklist (manual sign-off required) ---"
    echo ""
    echo "  Framework integration:"
    echo "    □ beacon.h / Havoc API headers match the server version"
    echo "    □ COFF compiled for correct architecture (x64 for 64-bit Beacons)"
    echo "    □ inline-execute tested in a lab Beacon — clean output, no crash"
    echo "    □ fork-and-run: spawnto set to a legitimate signed binary"
    echo ""
    echo "  Sleep mask / in-memory obfuscation:"
    echo "    □ Sleep mask encrypts Beacon heap and .text during sleep"
    echo "    □ Memory permissions cycle: RWX → RW (sleep) → RX (wakeup)"
    echo "    □ Jitter ≥ 25% set (predictable intervals are a detection signal)"
    echo "    □ Memory scan against sleeping Beacon PID returns clean"
    echo ""
    echo "  Malleable profile / listener:"
    echo "    □ User-Agent is a versioned browser string (not default curl/7.x)"
    echo "    □ URI paths use realistic CDN or analytics-style paths"
    echo "    □ Host header points to a categorised domain, not a raw IP"
    echo "    □ Staging disabled for stageless payloads (host_stage = false)"
    echo "    □ Domain fronting CDN still supports your configuration"
    echo ""
    echo "  Kill date and working hours:"
    echo "    □ Kill date set to engagement end date"
    echo "    □ Working hours set if time-constrained engagement"
    echo "    □ Kill date verified in payload generation UI (not just config)"
    echo ""
    echo "  Lab validation:"
    echo "    □ Full lab run completed against a VM matching target OS/EDR"
    echo "    □ All planned post-ex tasks executed in lab first"
    echo "    □ Implant self-terminates at kill date (verified by advancing VM clock)"
    echo "    □ No residual artifacts after termination (prefetch, event logs)"
    echo "    □ Lab validation run documented before engagement start"
    echo ""
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo "--- Summary ---"
echo ""
echo "  Automated checks:  $PASS passed, $FAIL failed"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo "=== c2-preflight — FAILED ($FAIL automated check(s)) ==="
    exit 1
else
    echo "=== c2-preflight complete — review manual checklist above before deployment ==="
fi
