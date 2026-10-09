#!/bin/sh
# check-roadmap-sync.sh — Verifies ROADMAP.md's generated block matches the
# per-skill README `## Roadmap` sections (the source of truth), collected via
# scripts/roadmap-collect.sh.
# Usage: bash check-roadmap-sync.sh [repo-root] [--check|--fix]
# Exit: 0 = in sync (or fixed), 1 = drift detected (--check only)

set -e

REPO_ROOT="${1:-.}"
MODE="--check"
for arg in "$@"; do
  case "$arg" in
    --fix|--check) MODE="$arg" ;;
  esac
done

cd "$REPO_ROOT"
REPO_ROOT="$(pwd)"

ROADMAP_FILE="ROADMAP.md"
START_MARKER='<!-- ROADMAP-COLLECT:START (auto-generated — do not hand-edit; run check-roadmap-sync.sh --fix) -->'
END_MARKER='<!-- ROADMAP-COLLECT:END -->'

if [ ! -f "$ROADMAP_FILE" ]; then
  echo "✗ No ROADMAP.md found at repo root — nothing to check."
  exit 1
fi

if ! grep -qF "$START_MARKER" "$ROADMAP_FILE" || ! grep -qF "$END_MARKER" "$ROADMAP_FILE"; then
  echo "✗ ROADMAP.md is missing the ROADMAP-COLLECT:START/END markers."
  echo "  Expected markers around the 'Open items by cluster' section — see"
  echo "  clusters/07-devops/ci-standards/check-roadmap-sync.sh header."
  exit 1
fi

GENERATED="$(mktemp)"
UPDATED="$(mktemp)"
trap 'rm -f "$GENERATED" "$UPDATED"' EXIT

bash "$REPO_ROOT/scripts/roadmap-collect.sh" > "$GENERATED"

SUMMARY_LINE=$(grep '^\*\*Summary:\*\*' "$GENERATED" | tail -1) || true
OPEN_COUNT=$(printf '%s\n' "$SUMMARY_LINE" | sed -E 's/^\*\*Summary:\*\* ([0-9]+) open items \| ([0-9]+) completed items$/\1/')
DONE_COUNT=$(printf '%s\n' "$SUMMARY_LINE" | sed -E 's/^\*\*Summary:\*\* ([0-9]+) open items \| ([0-9]+) completed items$/\2/')

case "$OPEN_COUNT" in
  ''|*[!0-9]*)
    echo "✗ Could not parse a Summary line out of scripts/roadmap-collect.sh output."
    exit 1
    ;;
esac
case "$DONE_COUNT" in
  ''|*[!0-9]*)
    echo "✗ Could not parse a Summary line out of scripts/roadmap-collect.sh output."
    exit 1
    ;;
esac

TODAY="$(date -u +%Y-%m-%d)"
# --check must not compare against today's date, or every PR fails the day after the last regeneration.
if [ "$MODE" = "--check" ]; then
  TODAY="$(sed -n 's/^\*\*Last updated:\*\* //p' "$ROADMAP_FILE" | head -1)"
fi

# Build the full replacement file: header stats updated, generated block
# spliced in between the markers, everything else untouched.

awk -v start="$START_MARKER" -v end="$END_MARKER" -v genfile="$GENERATED" \
    -v open_count="$OPEN_COUNT" -v done_count="$DONE_COUNT" -v today="$TODAY" '
  BEGIN { in_block = 0 }
  $0 == start {
    print $0
    while ((getline line < genfile) > 0) print line
    print end
    in_block = 1
    next
  }
  $0 == end { in_block = 0; next }
  in_block { next }
  /^\*\*Last updated:\*\*/ { print "**Last updated:** " today; next }
  /^\*\*Open items:\*\*/ { print "**Open items:** " open_count " | **Completed:** " done_count; next }
  { print }
' "$ROADMAP_FILE" > "$UPDATED"

if [ "$MODE" = "--fix" ]; then
  cp "$UPDATED" "$ROADMAP_FILE"
  echo "✓ ROADMAP.md regenerated ($OPEN_COUNT open, $DONE_COUNT completed)."
  exit 0
fi

if diff -q "$ROADMAP_FILE" "$UPDATED" >/dev/null 2>&1; then
  echo "✓ ROADMAP.md is in sync ($OPEN_COUNT open, $DONE_COUNT completed)."
  exit 0
else
  echo "✗ DRIFT DETECTED — ROADMAP.md does not match the per-skill README sources."
  echo ""
  diff -u "$ROADMAP_FILE" "$UPDATED" || true
  echo ""
  echo "Run: bash clusters/07-devops/ci-standards/check-roadmap-sync.sh . --fix"
  exit 1
fi
