#!/usr/bin/env bash
# bootstrap-security.sh
# Deploys .gitleaks.toml and .github/workflows/secret-scan.yml to one or more repos.
# Handles the unarchive/re-archive dance for archived repos automatically.
#
# Usage:
#   ./bootstrap-security.sh <owner/repo> [<owner/repo> ...]
#
# Requires: gh CLI authenticated, git
#
# The script looks for the template files adjacent to itself:
#   gitleaks-config-template.toml   -> deployed as .gitleaks.toml
#   secret-scan.yml                 -> deployed as .github/workflows/secret-scan.yml
#
# If those files are not present, it will generate sensible defaults.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOML_TEMPLATE="${SCRIPT_DIR}/gitleaks-config-template.toml"

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <owner/repo> [<owner/repo> ...]"
    exit 1
fi

REPOS=("$@")
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Bootstrap security infrastructure"
echo "Repos: ${REPOS[*]}"
echo "Work dir: $WORK_DIR"
echo ""

for REPO in "${REPOS[@]}"; do
    echo "=== $REPO ==="

    # Check if archived
    IS_ARCHIVED=$(gh repo view "$REPO" --json isArchived --jq '.isArchived' 2>/dev/null || echo "false")

    if [[ "$IS_ARCHIVED" == "true" ]]; then
        echo "  Repo is archived — unarchiving ..."
        gh repo unarchive "$REPO" --yes
    fi

    # Clone
    REPO_NAME=$(basename "$REPO")
    CLONE_DIR="${WORK_DIR}/${REPO_NAME}"
    git clone "git@github.com:${REPO}.git" "$CLONE_DIR"
    cd "$CLONE_DIR"

    # Deploy .gitleaks.toml
    if [[ -f "$TOML_TEMPLATE" ]]; then
        cp "$TOML_TEMPLATE" .gitleaks.toml
    else
        cat > .gitleaks.toml <<'TOML'
title = "gitleaks config"

[extend]
useDefault = true

[[rules]]
id = "corporate-refs"
description = "Internal corporate or client references — customise regex before committing"
regex = '''(?i)(<CORP_NAME>|<DOMAIN_SUFFIX>|<ENGAGEMENT_HOSTNAME>)'''
tags = ["corporate", "sensitive"]

[allowlist]
paths = [
  '''.gitleaks\.toml''',
  '''\.git/''',
]
TOML
        echo "  WARNING: no gitleaks-config-template.toml found — deployed placeholder. Customise before pushing."
    fi

    # Deploy secret-scan.yml
    mkdir -p .github/workflows
    cat > .github/workflows/secret-scan.yml <<'YAML'
name: Secret scan
on: [push, pull_request]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
YAML

    # Check if there is anything new to commit
    if git diff --cached --quiet && git diff --quiet; then
        # Check untracked
        if [[ -z "$(git status --porcelain)" ]]; then
            echo "  No changes needed — files already present"
            cd "$WORK_DIR"
            if [[ "$IS_ARCHIVED" == "true" ]]; then
                echo "  Re-archiving ..."
                gh repo archive "$REPO" --yes
            fi
            continue
        fi
    fi

    git add .gitleaks.toml .github/workflows/secret-scan.yml
    git commit -m "chore: add secret scanning infrastructure"
    git push
    echo "  Deployed and pushed."

    cd "$WORK_DIR"

    # Re-archive if it was archived
    if [[ "$IS_ARCHIVED" == "true" ]]; then
        echo "  Re-archiving ..."
        gh repo archive "$REPO" --yes
    fi

    echo "  Done."
    echo ""
done

echo "Bootstrap complete."
