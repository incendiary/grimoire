#!/usr/bin/env bash
# check_push_protocol.sh
# Detects SSH vs HTTPS remote protocol, tests connectivity, and suggests
# corrective action if the push will fail.
#
# Usage:
#   ./check_push_protocol.sh [remote-name]
#   Default remote: origin
#
# Requires: git, ssh (for SSH check), gh (for HTTPS token check, optional)

set -euo pipefail

REMOTE="${1:-origin}"

# ── Get remote URL ────────────────────────────────────────────────────────────
if ! git rev-parse --git-dir &>/dev/null; then
    echo "ERROR: not inside a git repository"
    exit 1
fi

REMOTE_URL=$(git remote get-url "$REMOTE" 2>/dev/null || true)
if [[ -z "$REMOTE_URL" ]]; then
    echo "ERROR: remote '$REMOTE' not found"
    git remote -v
    exit 1
fi

echo "=== check_push_protocol: $REMOTE ==="
echo "  URL: $REMOTE_URL"
echo ""

# ── Detect protocol ───────────────────────────────────────────────────────────
if [[ "$REMOTE_URL" == git@* || "$REMOTE_URL" == ssh://* ]]; then
    PROTOCOL="ssh"
elif [[ "$REMOTE_URL" == https://* || "$REMOTE_URL" == http://* ]]; then
    PROTOCOL="https"
else
    PROTOCOL="unknown"
fi

echo "  Protocol detected: $PROTOCOL"
echo ""

# ── Protocol-specific connectivity test ──────────────────────────────────────
case "$PROTOCOL" in

    ssh)
        echo "--- SSH connectivity test ---"
        # Extract host from git@host:owner/repo or ssh://host/...
        if [[ "$REMOTE_URL" == git@* ]]; then
            _tmp="${REMOTE_URL#git@}"; SSH_HOST="${_tmp%%:*}"
        else
            _tmp="${REMOTE_URL#ssh://}"; SSH_HOST="${_tmp%%/*}"
        fi
        echo "  Host: $SSH_HOST"

        # Test SSH — GitHub returns exit code 1 even on success ("Hi user!")
        SSH_OUT=$(ssh -T -o ConnectTimeout=5 -o BatchMode=yes "git@${SSH_HOST}" 2>&1 || true)
        if echo "$SSH_OUT" | grep -qiE 'successfully authenticated|hi '; then
            echo "  [PASS] SSH auth OK: $SSH_OUT"
        elif echo "$SSH_OUT" | grep -qi 'permission denied\|publickey'; then
            echo "  [FAIL] SSH auth failed: $SSH_OUT"
            echo ""
            echo "  Fix options:"
            echo "    1. Start ssh-agent:  eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519"
            echo "    2. Switch to HTTPS:  git remote set-url $REMOTE https://github.com/<owner>/<repo>.git"
            echo "    3. Check your key is added on GitHub: https://github.com/settings/keys"
        else
            echo "  [WARN] Unexpected SSH response: $SSH_OUT"
        fi
        ;;

    https)
        echo "--- HTTPS connectivity test ---"
        if git ls-remote --heads "$REMOTE_URL" &>/dev/null; then
            echo "  [PASS] HTTPS remote is reachable and authenticated"
        else
            echo "  [FAIL] HTTPS remote not reachable"
            echo ""
            echo "  Fix options:"
            echo "    1. Use gh CLI credential helper: gh auth login"
            echo "    2. Switch to SSH:  git remote set-url $REMOTE git@github.com:<owner>/<repo>.git"
            echo "    3. Store a PAT:    git credential approve (see: git help credential)"
        fi
        ;;

    *)
        echo "  [WARN] Unrecognised remote URL format — cannot test connectivity"
        echo "         Expected: git@host:owner/repo  or  https://host/owner/repo"
        ;;
esac

echo ""
echo "=== check_push_protocol complete ==="
