#!/usr/bin/env bash
# verify-cwd.sh
# Confirms the active working directory and optionally checks it against
# a list of known project roots. Use at session start or before bulk
# file operations — particularly on projects with both local and
# iCloud-synced paths.
#
# Usage:
#   ./verify-cwd.sh                                  # print cwd + ls
#   ./verify-cwd.sh /path/root1 ~/iCloud/root2 ...  # check against known roots
#
# Exit codes:
#   0  — matched a known root (or no roots given)
#   1  — cwd did not match any supplied known root

set -euo pipefail

CWD=$(pwd)

echo "=== cwd-verify ==="
echo "  CWD: $CWD"
echo ""
echo "--- Contents ---"
ls -la
echo ""

if [[ $# -eq 0 ]]; then
    echo "(No known roots provided — re-run: verify-cwd.sh /root1 /root2 ...)"
    exit 0
fi

echo "--- Known root check ---"
MATCHED=false
for root in "$@"; do
    # Expand leading ~ manually (avoids quoting issues with paths containing spaces)
    expanded="${root/#\~/$HOME}"
    if [[ "$CWD" == "$expanded" || "$CWD" == "$expanded/"* ]]; then
        echo "  [MATCH] $root"
        MATCHED=true
    else
        echo "  [    ] $root"
    fi
done

echo ""
if $MATCHED; then
    echo "=== Active root confirmed ==="
else
    echo "=== WARNING: CWD does not match any known root ==="
    echo "    Expected one of:"
    for root in "$@"; do echo "      $root"; done
    exit 1
fi
