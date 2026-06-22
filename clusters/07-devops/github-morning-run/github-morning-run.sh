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
            # Extract owner/repo from URL
            origin="${origin##*/}"
            origin="${origin%.git}"
            local owner
            owner=$(git config --get remote.origin.url | grep -oP '(?<=github.com[:/])[^/]+' || echo "unknown")
            echo "${owner}/${origin}"
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
    if [[ "${remaining}" != "unknown" ]] && [[ "${remaining}" -lt 100 ]]; then
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

    # Process each open PR
    while IFS= read -r pr_num; do
        check_rate_limit

        # Get PR details
        local pr_data
        pr_data=$(gh pr view -R "${repo}" "${pr_num}" --json \
            number,title,author,isDraft,state,statusCheckRollup,hasConflicts \
            -q '.' 2>/dev/null || echo '{}')

        local author
        author=$(echo "${pr_data}" | jq -r '.author.login // "unknown"' 2>/dev/null || echo "unknown")
        local title
        title=$(echo "${pr_data}" | jq -r '.title // ""' 2>/dev/null || echo "")
        local has_conflicts
        has_conflicts=$(echo "${pr_data}" | jq -r '.hasConflicts // false' 2>/dev/null || echo "false")
        local ci_status
        ci_status=$(echo "${pr_data}" | jq -r '.statusCheckRollup[0].state // "unknown"' 2>/dev/null || echo "unknown")

        # Skip drafts
        if echo "${pr_data}" | jq -e '.isDraft' > /dev/null 2>&1; then
            echo "  [#${pr_num}] ${title:0:50}... (draft, skipped)"
            continue
        fi

        # Handle dependabot PRs
        if [[ "${author}" == "dependabot" ]] || [[ "${author}" == "dependabot[bot]" ]]; then
            echo -n "  [#${pr_num}] ${title:0:50}... "

            if [[ "${has_conflicts}" == "true" ]]; then
                echo "⚠️  (conflict — review needed)"
                ((flagged++))
            elif [[ "${ci_status}" != "SUCCESS" ]]; then
                echo "✗ (CI failed — investigate)"
                ((flagged++))
            else
                # Auto-merge simple dependabot PR
                echo "✓ (auto-merging)"
                if gh pr merge -R "${repo}" "${pr_num}" --squash --delete-branch --auto 2>/dev/null; then
                    ((auto_merged++))
                else
                    echo "    → Merge queued or requires approval"
                fi
            fi
        else
            echo "  [#${pr_num}] ${title:0:50}... (review needed)"
        fi
    done < <(gh pr list -R "${repo}" -s open --json number -q '.[].number')

    # Check recent CI runs
    echo ""
    echo "  Recent CI runs (last 3):"
    local run_count=0
    while IFS= read -r run_id status; do
        if [[ ${run_count} -ge 3 ]]; then break; fi
        local icon="✓"
        [[ "${status}" == "failure" ]] && icon="✗"
        [[ "${status}" == "in_progress" ]] && icon="⏳"
        echo "    ${icon} Run #${run_id}: ${status}"
        ((run_count++))
    done < <(gh run list -R "${repo}" --json databaseId,conclusion --jq '.[] | [.databaseId, .conclusion // "in_progress"]' -q 2>/dev/null | tr '\t' ' ' || echo "")

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
    local total_auto_merged=0
    local total_flagged=0

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
