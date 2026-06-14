# roadmap-driver

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** action

## Description
Selects the next roadmap work item and frames an execution chain automatically.
Designed for prompts like "what should I work on next?" and "pick up from roadmap".

Invoke when: choosing next task from `ROADMAP.md`; starting a new implementation batch;
recovering after interruption.

## Context needed
- `ROADMAP.md` in repository root
- Optional focus area (cluster name, infra-only, UI-only)

## Execution chain

1. `repo-compass` — assess repository truth state
2. `task-decomposer` — split chosen work into atomic chunks
3. `karpathy-framework` — clarify spec and success criteria
4. `karpathy-verify` — verify result quality before close-out

## What to do

1. Parse open checklist items from `ROADMAP.md`.
2. Prioritize in this order:
   - infrastructure roadmap items that are implementation-ready
   - non-"requires real session" cluster items
   - worked examples
3. Pick one next item and produce:
   - chosen item
   - why it was selected
   - atomic implementation steps
   - verification steps
   - roadmap update step

```bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROADMAP="${ROOT}/ROADMAP.md"

if [[ ! -f "${ROADMAP}" ]]; then
  echo "ERROR: ROADMAP.md not found at ${ROADMAP}"
  exit 1
fi

echo "=== roadmap-driver ==="

# 1) Prefer infrastructure roadmap open items
infra_choice=$(awk '
  /^## Infrastructure roadmap/ {infra=1; next}
  infra && /^- \[ \]/ {print; exit}
' "${ROADMAP}" || true)

if [[ -n "${infra_choice}" ]]; then
  echo "Selected next item (infrastructure):"
  echo "${infra_choice}"
  echo ""
  echo "Suggested chain: repo-compass -> task-decomposer -> karpathy-framework -> karpathy-verify"
  exit 0
fi

# 2) Otherwise pick first open cluster item that is not marked requires real session
cluster_choice=$(awk '
  /^### / {cluster=$0; sub(/^### /, "", cluster)}
  /^- \*\*/ {
    line=$0
    l=tolower(line)
    if (l !~ /requires real session/ && l !~ /requires real usage/) {
      print cluster " :: " line
      exit
    }
  }
' "${ROADMAP}" || true)

if [[ -n "${cluster_choice}" ]]; then
  echo "Selected next item (cluster):"
  echo "${cluster_choice}"
  echo ""
  echo "Suggested chain: repo-compass -> task-decomposer -> karpathy-framework -> karpathy-verify"
  exit 0
fi

echo "No implementation-ready roadmap item found."
```

## Gotchas
- Do not auto-close roadmap items; closure is a separate explicit step.
- If only "requires real session" items remain, output that explicitly and stop.
- Keep one item per run to preserve atomic PR discipline.

## Roadmap
- [ ] Add `--cluster` filter for targeted routing
- [ ] Add `--json` output for MCP consumers
- [ ] Add confidence scoring for candidate items
