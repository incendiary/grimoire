#!/usr/bin/env bash
# branch-surface-resolve.sh
# Audits all local + remote branches, categorises each, and optionally resolves.
#
# Usage:
#   bash branch-surface-resolve.sh              # report only
#   bash branch-surface-resolve.sh --resolve    # report + push + create PRs for READY/LOCAL-ONLY
#   bash branch-surface-resolve.sh --prune-stale # also delete stale branches after confirmation
set -euo pipefail

RESOLVE=false
PRUNE_STALE=false

for arg in "$@"; do
    case "${arg}" in
        --resolve)     RESOLVE=true ;;
        --prune-stale) PRUNE_STALE=true ;;
        --help|-h)
            echo "Usage: bash branch-surface-resolve.sh [--resolve] [--prune-stale]"
            echo ""
            echo "  --resolve      Push and create PRs for READY and LOCAL-ONLY branches"
            echo "  --prune-stale  Delete stale branches (interactive confirmation per branch)"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown flag: ${arg}"
            exit 1
            ;;
    esac
done

# ─── Helpers ────────────────────────────────────────────────────────────────

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${ROOT}"

# Determine main branch name
MAIN_BRANCH="main"
if ! git rev-parse --verify main >/dev/null 2>&1; then
    if git rev-parse --verify master >/dev/null 2>&1; then
        MAIN_BRANCH="master"
    else
        echo "ERROR: Could not find 'main' or 'master' branch."
        exit 1
    fi
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI not found. Install from https://cli.github.com"
    exit 1
fi

git fetch --all --prune --quiet 2>/dev/null || true

# ─── Collect branches ───────────────────────────────────────────────────────

# All local branches except main/master
readarray -t LOCAL_BRANCHES < <(
    git branch --format='%(refname:short)' | grep -v "^${MAIN_BRANCH}$" | sort
)

# All remote branches except HEAD/main/master
readarray -t REMOTE_BRANCHES < <(
    git branch -r --format='%(refname:short)' \
    | sed 's|^origin/||' \
    | grep -v "^HEAD$" \
    | grep -v "^${MAIN_BRANCH}$" \
    | sort
)

# Union: all unique branch names
declare -A SEEN
ALL_BRANCHES=()
for b in "${LOCAL_BRANCHES[@]}" "${REMOTE_BRANCHES[@]}"; do
    if [[ -z "${SEEN[${b}]+x}" ]]; then
        ALL_BRANCHES+=("${b}")
        SEEN["${b}"]=1
    fi
done

if [[ ${#ALL_BRANCHES[@]} -eq 0 ]]; then
    echo "No branches found other than ${MAIN_BRANCH}. Repository is clean."
    exit 0
fi

# ─── Categorise ─────────────────────────────────────────────────────────────

declare -a READY=()
declare -a LOCAL_ONLY=()
declare -a HAS_PR=()
declare -a CONFLICT=()
declare -a STALE=()

echo "=== branch-surface-resolve ==="
echo "Base branch: ${MAIN_BRANCH}"
echo "Found ${#ALL_BRANCHES[@]} branch(es) to analyse"
echo ""

for branch in "${ALL_BRANCHES[@]}"; do
    # Does this branch exist locally?
    local_exists=false
    if git rev-parse --verify "${branch}" >/dev/null 2>&1; then
        local_exists=true
    fi

    # Does it exist on remote?
    remote_exists=false
    if git rev-parse --verify "origin/${branch}" >/dev/null 2>&1; then
        remote_exists=true
    fi

    # Commits ahead of main
    if [[ "${local_exists}" == "true" ]]; then
        ref="${branch}"
    else
        ref="origin/${branch}"
    fi
    ahead=$(git rev-list --count "${MAIN_BRANCH}..${ref}" 2>/dev/null || echo "0")

    if [[ "${ahead}" -eq 0 ]]; then
        STALE+=("${branch}")
        printf "  [STALE]      %s — 0 commits ahead of %s\n" "${branch}" "${MAIN_BRANCH}"
        continue
    fi

    # Check for open PR
    pr_url=""
    if [[ "${remote_exists}" == "true" ]]; then
        pr_json=$(NO_COLOR=1 GH_PAGER='' gh pr list \
            --head "${branch}" --state open \
            --json number,url,title,statusCheckRollup \
            --limit 1 2>/dev/null || echo "[]")
        if [[ "${pr_json}" != "[]" && "${pr_json}" != "" ]]; then
            pr_url=$(echo "${pr_json}" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
            HAS_PR+=("${branch}|${pr_url}|${ahead}")
            printf "  [HAS-PR]     %s — %d commit(s) — %s\n" "${branch}" "${ahead}" "${pr_url}"
            continue
        fi
    fi

    # Dry-run merge to detect conflicts
    if [[ "${local_exists}" == "true" ]]; then
        conflict_check=$(
            git merge --no-commit --no-ff "${branch}" 2>&1 || true
        )
        git merge --abort 2>/dev/null || true

        if echo "${conflict_check}" | grep -qi "conflict"; then
            CONFLICT+=("${branch}|${ahead}")
            printf "  [CONFLICT]   %s — %d commit(s) — MERGE CONFLICT DETECTED\n" "${branch}" "${ahead}"
            continue
        fi
    fi

    if [[ "${remote_exists}" == "false" ]]; then
        LOCAL_ONLY+=("${branch}|${ahead}")
        printf "  [LOCAL-ONLY] %s — %d commit(s) — not pushed\n" "${branch}" "${ahead}"
    else
        READY+=("${branch}|${ahead}")
        printf "  [READY]      %s — %d commit(s)\n" "${branch}" "${ahead}"
    fi
done

echo ""
echo "─── Summary ────────────────────────────────────────────────────────"
printf "  READY:        %d\n" "${#READY[@]}"
printf "  LOCAL-ONLY:   %d\n" "${#LOCAL_ONLY[@]}"
printf "  HAS-PR:       %d\n" "${#HAS_PR[@]}"
printf "  CONFLICT:     %d\n" "${#CONFLICT[@]}"
printf "  STALE:        %d\n" "${#STALE[@]}"
echo ""

# ─── Surface conflicts ───────────────────────────────────────────────────────

if [[ ${#CONFLICT[@]} -gt 0 ]]; then
    echo "─── CONFLICT branches (manual resolution required) ─────────────────"
    for entry in "${CONFLICT[@]}"; do
        branch="${entry%%|*}"
        ahead="${entry##*|}"
        echo ""
        echo "  Branch: ${branch} (${ahead} commit(s))"
        echo "  Commits:"
        git log --oneline "${MAIN_BRANCH}..${branch}" | sed 's/^/    /'
        echo "  Files changed:"
        git diff --stat "${MAIN_BRANCH}...${branch}" | tail -1 | sed 's/^/    /'
        echo ""
        echo "  Suggested resolution options:"
        echo "    a) Cherry-pick individual commits onto a clean branch"
        echo "    b) Rebase interactively to isolate useful changes"
        echo "    c) Create new branch from main with specific files only"
    done
    echo ""
fi

# ─── Resolve READY and LOCAL-ONLY ───────────────────────────────────────────

if [[ "${RESOLVE}" == "true" ]]; then
    if [[ ${#LOCAL_ONLY[@]} -gt 0 ]]; then
        echo "─── Pushing LOCAL-ONLY branches ────────────────────────────────────"
        for entry in "${LOCAL_ONLY[@]}"; do
            branch="${entry%%|*}"
            echo "  Pushing ${branch}..."
            git push -u origin "${branch}"
            READY+=("${entry}")
        done
        echo ""
    fi

    if [[ ${#READY[@]} -gt 0 ]]; then
        echo "─── Creating PRs for READY branches ────────────────────────────────"
        for entry in "${READY[@]}"; do
            branch="${entry%%|*}"
            ahead="${entry##*|}"

            echo ""
            echo "  Branch: ${branch} (${ahead} commit(s))"

            # Build PR title from last commit subject
            pr_title=$(git log --format="%s" "${MAIN_BRANCH}..${branch}" | head -1)

            # Build PR body from all commit subjects
            pr_body=$(git log --format="- %s" "${MAIN_BRANCH}..${branch}")

            NO_COLOR=1 GH_PAGER='' gh pr create \
                --base "${MAIN_BRANCH}" \
                --head "${branch}" \
                --title "${pr_title}" \
                --body "${pr_body}" \
                2>&1 || echo "  WARNING: PR creation failed for ${branch} (may already exist)"
        done
        echo ""
    fi
else
    if [[ ${#READY[@]} -gt 0 || ${#LOCAL_ONLY[@]} -gt 0 ]]; then
        echo "─── Next steps for READY / LOCAL-ONLY ──────────────────────────────"
        echo "  Re-run with --resolve to push and create PRs automatically."
        echo ""
    fi
fi

# ─── Stale prune ─────────────────────────────────────────────────────────────

if [[ "${PRUNE_STALE}" == "true" && ${#STALE[@]} -gt 0 ]]; then
    echo "─── Pruning STALE branches ─────────────────────────────────────────"
    for branch in "${STALE[@]}"; do
        printf "  Delete %s? [y/N] " "${branch}"
        read -r answer
        if [[ "${answer}" =~ ^[Yy]$ ]]; then
            git branch -d "${branch}" 2>/dev/null && echo "  Deleted local: ${branch}" || true
            git push origin --delete "${branch}" 2>/dev/null && echo "  Deleted remote: ${branch}" || true
        fi
    done
    echo ""
fi

echo "─── Done ───────────────────────────────────────────────────────────"
if [[ ${#CONFLICT[@]} -gt 0 ]]; then
    echo "  ACTION REQUIRED: ${#CONFLICT[@]} branch(es) with conflicts need manual resolution."
fi
if [[ "${RESOLVE}" == "false" && $((${#READY[@]} + ${#LOCAL_ONLY[@]})) -gt 0 ]]; then
    echo "  Run with --resolve to auto-push and PR the READY/LOCAL-ONLY branches."
fi
