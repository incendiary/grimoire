#!/usr/bin/env bash
# list-authored.sh
# Fetches the incendiary repo list from GitHub and classifies each repo as:
#   ✅ authored  — in the canonical authored list
#   ⚠️  fork     — GitHub marks it as a fork
#   ❓ unlisted  — not a fork but not in the authored list (may need CLAUDE.md update)
#
# Usage: bash list-authored.sh [--json]
#   --json   Output machine-readable JSON instead of coloured text

set -euo pipefail

OWNER="incendiary"

# Canonical authored repos (keep in sync with CLAUDE.md)
AUTHORED=(
  StartingPoint
  Phosphor
  Slice-N-Dice
  htb-canvas
  IncendiaryService
  DNSResolver
  CLion-nova-bof-template
  WindowsServiceTemplate
  csharp-shellcode-runner
  QueuserAPC
  EarlyWorm
  pdf2john-docker
  bgp_rogue
  Implant-Practice
  agency-agents
  ScallOps
  az-nsg
  burps
)

# Explicit exclude list (forks / reference copies kept locally)
EXCLUDE=(
  Ghostwriter
  OSCE3-Notes
  RTOVMSetup
  AWAE-PREP
  pybgpstream
  plaintextoffenders
  clone-cert
  my-arsenal-of-aws-security-tools
  Azurite
  kerberoast
  reveal.js
  hashcat
)

# Build lookup sets
declare -A authored_set
for r in "${AUTHORED[@]}"; do authored_set["$r"]=1; done

declare -A exclude_set
for r in "${EXCLUDE[@]}"; do exclude_set["$r"]=1; done

# Fetch all repos (public + private if authenticated)
repos=$(gh repo list "$OWNER" --limit 200 --json name,isFork --jq '.[]')

json_mode=0
[[ "${1:-}" == "--json" ]] && json_mode=1

if [[ $json_mode -eq 1 ]]; then
  echo "["
fi

first=1
while IFS= read -r repo_json; do
  name=$(echo "$repo_json" | jq -r '.name')
  is_fork=$(echo "$repo_json" | jq -r '.isFork')

  if [[ $json_mode -eq 1 ]]; then
    [[ $first -eq 0 ]] && echo ","
    first=0
    if [[ -n "${authored_set[$name]+_}" ]]; then
      category="authored"
    elif [[ "$is_fork" == "true" || -n "${exclude_set[$name]+_}" ]]; then
      category="fork"
    else
      category="unlisted"
    fi
    printf '  {"name": "%s", "isFork": %s, "category": "%s"}' "$name" "$is_fork" "$category"
  else
    if [[ -n "${authored_set[$name]+_}" ]]; then
      echo "✅  $name"
    elif [[ "$is_fork" == "true" || -n "${exclude_set[$name]+_}" ]]; then
      echo "⚠️   $name  (fork/excluded — skip)"
    else
      echo "❓  $name  (unlisted — confirm before including)"
    fi
  fi
done <<< "$repos"

if [[ $json_mode -eq 1 ]]; then
  echo ""
  echo "]"
fi
