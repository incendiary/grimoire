#!/usr/bin/env bash
# run-log.sh
# Appends a dated, structured iteration entry to edr-test-log.md.
# Used with the edr-test-loop skill to maintain a hypothesis-driven test log.
#
# Usage (interactive):
#   ./run-log.sh
#
# Usage (non-interactive):
#   ./run-log.sh --iter 3 --edr "CrowdStrike Falcon" \
#                --hypothesis "ETW patch suppresses telemetry" \
#                --change "Added EtwEventWrite NOP patch" \
#                --result evaded
#
# Log file: ./edr-test-log.md  (created with header if absent)

set -euo pipefail

LOG="edr-test-log.md"

# ── Parse args (optional — falls back to interactive prompts) ─────────────────
ITER=""
EDR=""
HYPOTHESIS=""
CHANGE=""
RESULT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --iter)       ITER="$2";       shift 2 ;;
        --edr)        EDR="$2";        shift 2 ;;
        --hypothesis) HYPOTHESIS="$2"; shift 2 ;;
        --change)     CHANGE="$2";     shift 2 ;;
        --result)     RESULT="$2";     shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# ── Interactive prompts for missing fields ────────────────────────────────────
if [[ -z "$ITER" ]];       then read -rp "Iteration number: "                   ITER;       fi
if [[ -z "$EDR" ]];        then read -rp "EDR product/version: "                EDR;        fi
if [[ -z "$HYPOTHESIS" ]]; then read -rp "Hypothesis: "                         HYPOTHESIS; fi
if [[ -z "$CHANGE" ]];     then read -rp "Change made: "                        CHANGE;     fi
if [[ -z "$RESULT" ]];     then read -rp "Result (detected/evaded/partial): "   RESULT;     fi

# ── Create log file with header if absent ────────────────────────────────────
if [[ ! -f "$LOG" ]]; then
    printf '# EDR Test Log\n\n| # | Date | EDR | Hypothesis | Change | Result |\n|---|------|-----|------------|--------|--------|\n' > "$LOG"
    echo "Created $LOG"
fi

# ── Append entry ──────────────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
printf "| %s | %s | %s | %s | %s | %s |\n" \
    "$ITER" "$TIMESTAMP" "$EDR" "$HYPOTHESIS" "$CHANGE" "$RESULT" >> "$LOG"

echo "Logged iteration $ITER → $LOG"
