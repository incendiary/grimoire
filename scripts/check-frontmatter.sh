#!/usr/bin/env bash
# check-frontmatter.sh: verifies each SKILL.md starts with valid YAML frontmatter
# (name matches directory, quoted one-line description of 50 to 1024 chars containing "Use when").
# Usage: bash scripts/check-frontmatter.sh [-v] [SKILL.md ...]   (no paths = clusters/*/*/SKILL.md)
# Exit: 0 = all pass, 1 = one or more failed
set -euo pipefail

VERBOSE=0
if [ "${1:-}" = "-v" ]; then
  VERBOSE=1
  shift
fi

if [ $# -eq 0 ]; then
  cd "$(dirname "$0")/.."
  set -- clusters/*/*/SKILL.md
fi

REASON=""

check_one() {
  local path="$1" name close fm names name_val descs desc_line desc len
  name="$(basename "$(dirname "$path")")"

  if [ ! -f "$path" ]; then
    REASON="file not found"
    return 1
  fi
  if [ "$(head -n 1 "$path")" != "---" ]; then
    REASON="line 1 is not ---"
    return 1
  fi
  close="$(awk 'NR>=3 && NR<=6 && /^---$/ {print NR; exit}' "$path")"
  if [ -z "$close" ]; then
    REASON="no closing --- on lines 3 to 6"
    return 1
  fi

  fm="$(sed -n "2,$((close - 1))p" "$path")"

  names="$(sed -n 's/^name: //p' <<< "$fm")"
  name_val="${names%%$'\n'*}"
  if [ "$name_val" != "$name" ]; then
    REASON="name '$name_val' does not match directory '$name'"
    return 1
  fi

  descs="$(grep '^description: "' <<< "$fm" || true)"
  desc_line="${descs%%$'\n'*}"
  if [ -z "$desc_line" ]; then
    REASON="no description line starting with: description: \""
    return 1
  fi
  case "$desc_line" in
    *'"') ;;
    *)
      REASON="description line does not end with a quote"
      return 1
      ;;
  esac

  desc="${desc_line#'description: "'}"
  desc="${desc%'"'}"
  len="${#desc}"
  if [ "$len" -lt 50 ] || [ "$len" -gt 1024 ]; then
    REASON="description is $len characters, need 50 to 1024"
    return 1
  fi
  case "$desc" in
    *"Use when"*) ;;
    *)
      REASON="description does not contain 'Use when'"
      return 1
      ;;
  esac
  return 0
}

total=0
passed=0
for path in "$@"; do
  total=$((total + 1))
  if check_one "$path"; then
    passed=$((passed + 1))
    if [ "$VERBOSE" -eq 1 ]; then
      echo "OK $path"
    fi
  else
    echo "FAIL $path: $REASON"
  fi
done

echo "$passed/$total skills have valid frontmatter"
if [ "$passed" -ne "$total" ]; then
  exit 1
fi
exit 0
