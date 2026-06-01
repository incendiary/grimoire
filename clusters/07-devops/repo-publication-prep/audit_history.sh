#!/usr/bin/env bash
# audit_history.sh
# Scans the full git history of a repo for common secret patterns and
# recommends a sanitisation approach.
#
# Requires: git, gitleaks (optional — falls back to grep patterns if absent)
#
# Usage: bash audit_history.sh [repo_path]
#   repo_path  (optional) path to git repo; defaults to current directory

set -euo pipefail

REPO="${1:-.}"

cd "$REPO"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: $REPO is not a git repository."
  exit 1
fi

commit_count=$(git rev-list --count HEAD 2>/dev/null || echo 0)
branch_count=$(git branch -a | wc -l | tr -d ' ')
first_commit=$(git log --reverse --format="%ar" | head -1)

echo "=== Git history audit: $REPO ==="
echo ""
echo "  Commits : $commit_count"
echo "  Branches: $branch_count"
echo "  Oldest  : $first_commit"
echo ""

# --- gitleaks scan (preferred) ---
if command -v gitleaks > /dev/null 2>&1; then
  echo "--- gitleaks scan (full history) ---"
  if gitleaks detect --source . --log-opts="--all" --no-banner 2>/dev/null; then
    echo "  CLEAN: gitleaks found no secrets in history."
  else
    echo ""
    echo "  SECRETS FOUND — see gitleaks output above."
  fi
else
  echo "--- gitleaks not found; falling back to grep patterns ---"
  echo "    Install gitleaks for a more thorough scan."
  echo ""

  # Common secret patterns (not exhaustive)
  patterns=(
    "AKIA[0-9A-Z]{16}"
    "ghp_[A-Za-z0-9]{36}"
    "glpat-[A-Za-z0-9\\-]{20}"
    "-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----"
    "password\s*=\s*['\"][^'\"]{6,}"
    "secret\s*=\s*['\"][^'\"]{6,}"
    "api[_-]?key\s*[:=]\s*['\"][^'\"]{8,}"
  )

  hit_count=0
  for pattern in "${patterns[@]}"; do
    count=$(git log --all -p | grep -cE "$pattern" 2>/dev/null || true)
    if [ "$count" -gt 0 ]; then
      echo "  HIT: $count match(es) for pattern: $pattern"
      hit_count=$(( hit_count + 1 ))
    fi
  done

  if [ "$hit_count" -eq 0 ]; then
    echo "  No obvious secret patterns found (grep-only scan — install gitleaks for full coverage)."
  fi
fi

echo ""
echo "=== Recommendation ==="
echo ""

if [ "$commit_count" -le 5 ]; then
  echo "  HISTORY VALUE: Low ($commit_count commits)"
  echo "  → Consider a fresh init (github-history-wipe) to produce a clean public history."
elif [ "$commit_count" -ge 50 ]; then
  echo "  HISTORY VALUE: High ($commit_count commits — meaningful progression)"
  echo "  → Prefer git filter-repo for targeted secret removal if any found."
else
  echo "  HISTORY VALUE: Moderate ($commit_count commits)"
  echo "  → Ask the user whether history is worth preserving before choosing an approach."
fi

echo ""
echo "  Next step: review gitleaks output above, then choose:"
echo "    Secrets + history worth keeping → git filter-repo (targeted)"
echo "    Secrets + history is noise      → fresh init (github-history-wipe skill)"
echo "    No secrets                      → proceed; review .gitignore only"
