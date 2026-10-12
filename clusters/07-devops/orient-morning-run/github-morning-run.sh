#!/usr/bin/env bash
set -euo pipefail

# github-morning-run.sh — GitHub repository maintenance routine
# Audits open PRs, auto-merges simple dependabot updates, checks CI status
#
# Usage:
#   bash github-morning-run.sh                # interactive scope selection
#   bash github-morning-run.sh --current      # current repo only
#   bash github-morning-run.sh --all          # all incendiary-authored repos
#   bash github-morning-run.sh --repo owner/repo  # specific repo

set_scope() {
    local arg="${1:-}"

    if [[ -z "${arg}" ]]; then
        echo "=== GitHub Morning Run — Select Scope ==="
        echo ""
        echo "Which repos to check?"
        echo "  1) Current repo only"
        echo "  2) All incendiary-authored repos"
        echo "  3) Specific repo URL"
        echo ""
        printf "Select [1-3]: "
        read -r choice
        case "${choice}" in
            1) SCOPE="current" ;;
            2) SCOPE="all" ;;
            3)
                printf "Repo (owner/repo): "
                read -r REPO
                SCOPE="specific"
                ;;
            *)
                echo "Invalid choice."
                exit 1
                ;;
        esac
    else
        case "${arg}" in
            --current) SCOPE="current" ;;
            --all) SCOPE="all" ;;
            --repo)
                SCOPE="specific"
                REPO="${2:-}"
                if [[ -z "${REPO}" ]]; then
                    echo "ERROR: --repo requires an argument (owner/repo)"
                    exit 1
                fi
                ;;
            *)
                echo "Unknown flag: ${arg}"
                echo "Usage: bash github-morning-run.sh [--current|--all|--repo owner/repo]"
                exit 1
                ;;
        esac
    fi
}

get_repos() {
    case "${SCOPE}" in
        current)
            # Get current repo from git
            if ! git rev-parse --git-dir > /dev/null 2>&1; then
                echo "ERROR: Not in a git repository"
                exit 1
            fi
            local origin
            origin=$(git config --get remote.origin.url 2>/dev/null || echo "")
            if [[ -z "${origin}" ]]; then
                echo "ERROR: No origin remote found"
                exit 1
            fi
            # Extract owner/repo from URL (handle both SSH and HTTPS)
            # ssh://git@github.com/owner/repo.git or https://github.com/owner/repo.git
            local repo_name
            repo_name="${origin##*/}"
            repo_name="${repo_name%.git}"
            local owner
            owner=$(echo "${origin}" | sed -n 's/.*github\.com[:/]\([^/]*\).*/\1/p')
            [[ -z "${owner}" ]] && owner="unknown"
            echo "${owner}/${repo_name}"
            ;;
        all)
            # List repos from incendiary (requires gh auth)
            gh repo list incendiary --json nameWithOwner -q '.[].nameWithOwner'
            ;;
        specific)
            echo "${REPO}"
            ;;
    esac
}

check_rate_limit() {
    local remaining
    remaining=$(gh api rate-limit --jq '.rate.remaining' 2>/dev/null || echo "unknown")
    # Only check if remaining is a number (not error JSON)
    if [[ "${remaining}" =~ ^[0-9]+$ ]] && [[ "${remaining}" -lt 100 ]]; then
        echo "⚠️  GitHub API rate limit low (${remaining} remaining). Pausing..."
        sleep 10
    fi
}

process_repo() {
    local repo="$1"
    local auto_merged=0
    local flagged=0
    local total_prs=0

    echo ""
    echo "=== REPO: ${repo} ==="

    # Check if repo is accessible
    if ! gh repo view "${repo}" --json name > /dev/null 2>&1; then
        echo "  ✗ Not accessible (private, archived, or does not exist)"
        return
    fi

    # Count open PRs
    local open_prs
    open_prs=$(gh pr list -R "${repo}" -s open --json number,author,title,state,statusCheckRollup -q '.[].number' | wc -l)
    total_prs="${open_prs}"

    echo "  Open PRs: ${total_prs}"

    if [[ "${total_prs}" -eq 0 ]]; then
        echo "  No action needed."
        return
    fi

    # Process each open PR (fetch all at once, not individually)
    while IFS=$'\t' read -r pr_num author title; do
        check_rate_limit

        # Skip empty lines
        [[ -z "${pr_num}" ]] && continue

        # Handle dependabot PRs (author may be "dependabot", "app/dependabot", or "dependabot[bot]")
        if [[ "${author}" == *"dependabot"* ]]; then
            echo -n "  [#${pr_num}] ${title:0:50}... "

            # Try to merge; gh will report if it fails (conflicts, CI, etc)
            if gh pr merge -R "${repo}" "${pr_num}" --squash --delete-branch --auto 2>/dev/null; then
                echo "✓ (merged)"
                ((auto_merged++))
            else
                # Merge failed; likely due to conflict, CI, or protection
                echo "⚠️  (needs review)"
                ((flagged++))
            fi
        else
            echo "  [#${pr_num}] ${title:0:50}... (review needed)"
        fi
    done < <(gh pr list -R "${repo}" -s open --json number,author,title -q '.[] | [.number, .author.login, .title] | @tsv')

    # Check recent CI runs
    echo ""
    echo "  Recent CI runs (last 3):"
    gh run list -R "${repo}" --limit 3 --json databaseId,conclusion \
        -q '.[] | select(.databaseId != null) | "\(.databaseId)\t\(.conclusion // "in_progress")"' 2>/dev/null | \
    while IFS=$'\t' read -r run_id status; do
        local icon="✓"
        [[ "${status}" == "failure" ]] && icon="✗"
        [[ "${status}" == "in_progress" ]] && icon="⏳"
        echo "    ${icon} Run #${run_id}: ${status}"
    done

    echo "  Summary: ${auto_merged} auto-merged, ${flagged} flagged for review"
}

main() {
    local arg="${1:-}"
    local arg2="${2:-}"

    set_scope "${arg}" "${arg2}"

    echo ""
    echo "Scope: ${SCOPE}"

    local repos
    repos=$(get_repos)

    local total_repos=0

    while IFS= read -r repo; do
        [[ -z "${repo}" ]] && continue
        ((total_repos++))
        process_repo "${repo}"
    done <<< "${repos}"

    echo ""
    echo "=== MORNING RUN COMPLETE ==="
    echo "Repos checked: ${total_repos}"
}

main "$@"
