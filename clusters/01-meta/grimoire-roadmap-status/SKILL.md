# grimoire-roadmap-status

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** action

## Description
Query current roadmap status from `ROADMAP.md` and return a compact operational view:
open/complete counts, top clusters by outstanding items, and infrastructure roadmap progress.

Invoke when: "what should I work on next?", "show roadmap status", "what is still open?",
or before selecting the next implementation batch.

## Context needed
- Repository root containing `ROADMAP.md`

## What to do

1. Read `ROADMAP.md` from repo root.
2. Report top-line totals: open checklist items and completed checklist items.
3. Report open item counts by cluster section (`### <cluster>`), highest first.
4. Report infrastructure roadmap open items (`## Infrastructure roadmap` section).

```bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROADMAP="${ROOT}/ROADMAP.md"

if [[ ! -f "${ROADMAP}" ]]; then
  echo "ERROR: ROADMAP.md not found at ${ROADMAP}"
  exit 1
fi

echo "=== grimoire roadmap status ==="

open_count=$(grep -E '^- \[ \]' "${ROADMAP}" | wc -l | tr -d ' ')
done_count=$(grep -E '^- \[x\]' "${ROADMAP}" | wc -l | tr -d ' ')

echo "Open checklist items: ${open_count}"
echo "Completed checklist items: ${done_count}"
echo ""

echo "Top clusters by open items:"
awk '
  /^### / {cluster=$0; sub(/^### /,"",cluster); in_cluster=1; next}
  /^## Infrastructure roadmap/ {in_cluster=0}
  in_cluster && /^- \*\*/ {counts[cluster]++}
  END {
    for (c in counts) {
      printf "%d\t%s\n", counts[c], c
    }
  }
' "${ROADMAP}" | sort -nr | head -10 | awk -F'\t' '{printf "- %s: %s open\n", $2, $1}'

echo ""
echo "Infrastructure roadmap (open):"
awk '
  /^## Infrastructure roadmap/ {infra=1; next}
  infra && /^- \[ \]/ {print}
' "${ROADMAP}"
```

## Gotchas
- This skill reads markdown text directly; if roadmap formatting changes substantially,
  adjust the awk patterns.
- Open item counting is based on checkbox format (`- [ ]`, `- [x]`).

## Roadmap
- [ ] Add `--json` output mode for machine-readable consumers
- [ ] Add severity/priority grouping by keyword (`requires real session`, `worked example`)
- [ ] Add optional filtering by cluster name
