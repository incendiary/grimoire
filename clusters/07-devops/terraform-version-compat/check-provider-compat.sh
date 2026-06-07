#!/usr/bin/env bash
# check-provider-compat.sh
# Extracts required_providers blocks from all Terraform files in the current
# directory tree, collects version constraints per provider, and reports
# any conflicts between modules.
#
# Usage:
#   ./check-provider-compat.sh               # scan current directory
#   ./check-provider-compat.sh /path/to/repo # scan a specific path

set -euo pipefail

SCAN_ROOT="${1:-.}"

echo "=== terraform-provider-compat ==="
echo "  Root: $(realpath "$SCAN_ROOT")"
echo ""

# ── Find all .tf files ────────────────────────────────────────────────────
mapfile -t TF_FILES < <(find "$SCAN_ROOT" -name "*.tf" -not -path "*/.git/*" -not -path "*/.terraform/*" | sort)

if [[ ${#TF_FILES[@]} -eq 0 ]]; then
    echo "  [WARN] No .tf files found under $SCAN_ROOT"
    exit 0
fi

echo "  Found ${#TF_FILES[@]} .tf file(s)"
echo ""

# ── Extract required_providers constraints ────────────────────────────────
# Parse blocks of the form:
#   required_providers {
#     aws = { source = "..." version = ">= 5.0" }
#   }
# We use python3 for multi-line regex matching since bash is too limited here.

EXTRACT_PY=$(cat <<'PYEOF'
import sys
import re
import json

results = {}  # provider -> list of (constraint, file)

for filepath in sys.argv[1:]:
    try:
        content = open(filepath).read()
    except OSError:
        continue

    # Find required_providers blocks
    blocks = re.findall(r'required_providers\s*\{([^}]+)\}', content, re.DOTALL)
    for block in blocks:
        # Find individual provider entries: name = { ... version = "..." ... }
        entries = re.finditer(
            r'(\w+)\s*=\s*\{[^}]*?(?:version\s*=\s*"([^"]+)")[^}]*\}',
            block, re.DOTALL
        )
        for m in entries:
            provider = m.group(1)
            constraint = m.group(2)
            if provider not in results:
                results[provider] = []
            results[provider].append({"constraint": constraint, "file": filepath})

print(json.dumps(results, indent=2))
PYEOF
)

PROVIDER_JSON=$(python3 -c "$EXTRACT_PY" "${TF_FILES[@]}")

if [[ "$(echo "$PROVIDER_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d))")" -eq 0 ]]; then
    echo "  [INFO] No required_providers version constraints found."
    echo "         Modules without pinned versions will resolve to latest on init."
    exit 0
fi

# ── Report per provider ────────────────────────────────────────────────────
echo "--- Provider constraints ---"
echo ""

CONFLICT=false

python3 - "$PROVIDER_JSON" <<'PYEOF'
import sys
import json

data = json.loads(sys.argv[1])

for provider, entries in sorted(data.items()):
    print(f"  Provider: {provider}")
    constraints = set(e["constraint"] for e in entries)
    for entry in entries:
        print(f"    {entry['constraint']:<30}  {entry['file']}")

    if len(constraints) > 1:
        print(f"    *** CONFLICT: multiple constraints — verify compatibility ***")
    print("")
PYEOF

# ── Detect obvious conflicts (same provider, incompatible pinned versions) ──
CONFLICTS=$(python3 - "$PROVIDER_JSON" <<'PYEOF'
import sys
import json
import re

data = json.loads(sys.argv[1])
conflicts = []

for provider, entries in data.items():
    constraints = [e["constraint"] for e in entries]
    if len(set(constraints)) > 1:
        conflicts.append({"provider": provider, "constraints": list(set(constraints))})

print(json.dumps(conflicts))
PYEOF
)

CONFLICT_COUNT=$(echo "$CONFLICTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")

if [[ "$CONFLICT_COUNT" -gt 0 ]]; then
    echo "--- Conflicts detected ---"
    echo ""
    echo "$CONFLICTS" | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    print(f\"  {c['provider']}: {' vs '.join(c['constraints'])}\")
"
    echo ""
    echo "  Next steps:"
    echo "    1. Find a version satisfying all constraints simultaneously"
    echo "    2. Update the older module or pin constraints to the compatible range"
    echo "    3. Run: terraform providers lock -platform=linux_amd64 -platform=darwin_amd64"
    echo ""
    echo "=== terraform-provider-compat — CONFLICTS FOUND ==="
    exit 1
else
    echo "  [PASS] No constraint conflicts detected."
    echo ""
    echo "=== terraform-provider-compat complete ==="
fi
