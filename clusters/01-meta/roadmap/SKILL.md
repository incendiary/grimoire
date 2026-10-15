---
name: roadmap
description: "Shows roadmap status and picks the next implementation-ready item from ROADMAP.md or README roadmaps, then frames the execution chain (state, decompose, plan, verify). Use when asked 'what should I work on next', 'show roadmap status', 'what is still open', or 'pick up from the roadmap'. To tick items after a merge use roadmap-sync."
---
# roadmap

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** action

## Description
**Status only:** read the open items in `ROADMAP.md` (or the README roadmap) and summarise them.

Selects the next roadmap work item and frames an execution chain automatically.
Designed for prompts like "what should I work on next?" and "pick up from roadmap".

Invoke when: choosing next task from `ROADMAP.md`; starting a new implementation batch;
recovering after interruption.

## Context needed
- `ROADMAP.md` in repository root
- Optional focus area (cluster name, infra-only, UI-only)

## Execution chain

1. `orient` — assess repository truth state
2. `plan-decompose` — split chosen work into atomic chunks
3. `plan` — clarify spec and success criteria
4. `plan-verify` — verify result quality before close-out

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

echo "=== roadmap ==="

# 1) Prefer infrastructure roadmap open items
infra_choice=$(awk '
  /^## Infrastructure roadmap/ {infra=1; next}
  infra && /^- \[ \]/ {print; exit}
' "${ROADMAP}" || true)

if [[ -n "${infra_choice}" ]]; then
  echo "Selected next item (infrastructure):"
  echo "${infra_choice}"
  echo ""
  echo "Suggested chain: orient -> plan-decompose -> plan -> plan-verify"
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
  echo "Suggested chain: orient -> plan-decompose -> plan -> plan-verify"
  exit 0
fi

echo "No implementation-ready roadmap item found."
```

## Working the whole roadmap

When asked to deliver every outstanding item ("work through this repo's roadmap"):

1. **Start cold:** run `orient` before touching code. Read nested READMEs; the real roadmap
   is often one level down. Check the code before treating an unticked item as outstanding.
2. **Propose the delivery plan** (order, one PR per logical batch) and get agreement first.
3. **Loop per item:** feature branch, PR, CI green, squash merge, then `roadmap-sync` to tick
   it. Do not start the next item until CI is green.
4. **Versions and releases come from release-please** (see `release`): never bump versions
   by hand. In a monorepo, scope each PR to one package where feasible.
5. **Finish with a clean state:** no stale branches, no open PRs, every tag backed by a release.

Stage specific files only (never `git add -A`). If branch protection blocks a merge, ask
the owner; never bypass protection.

## Gotchas
- Do not auto-close roadmap items; closure is a separate explicit step.
- If only "requires real session" items remain, output that explicitly and stop.
- Keep one item per run to preserve atomic PR discipline.
