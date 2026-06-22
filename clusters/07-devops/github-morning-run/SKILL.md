# github-morning-run

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Routine GitHub maintenance for one or more repositories. Audits open PRs, identifies
and auto-merges simple dependabot updates when CI passes, checks action run status,
and flags complex issues for discussion. Designed for daily or weekly repo hygiene.

Invoke when: "check my GitHub repos", "morning run", "GitHub status", "any routine repo maintenance".

## Context needed
- Repository scope (current repo, all authored repos, or specific repo URL)
- GitHub CLI access (must have `gh` configured and authenticated)

## What to do

### Scope Selection
When invoked, confirm the scope:

```
Which repos to check?
1. Current repo only (${PWD##*/})
2. All incendiary-authored repos
3. Specific repo URL
→ Select [1-3]:
```

Choose scope based on your need:
- **1: Current repo** — quick check on the repo you're in
- **2: All authored repos** — full portfolio audit
- **3: Specific URL** — one-off check on a target repo

---

### Workflow per repo

For each target repo:

#### 1. Audit open PRs
- Count open PRs, review status, CI status
- Identify PRs awaiting review, failing CI, or ready to merge
- Display summary table:
  ```
  REPO: owner/repo
  Open PRs: 5
    Ready to merge (passing CI, approved): 2
    Awaiting review: 1
    Failing CI: 2
  ```

#### 2. Handle dependabot PRs
For each dependabot PR:

- **Simple merge** (auto-proceed if all true):
  - CI passes ✓
  - No conflicts with main ✓
  - Single dependency (not a batch update) ✓
  - Dependency is not marked critical/do-not-auto-merge ✓
  
  Action: Merge with `gh pr merge <N> --squash --delete-branch`

- **Complex case** (flag for discussion):
  - CI failing
  - Has merge conflicts
  - Batch/multi-dependency update
  - Critical infrastructure (terraform, CI workflows, auth)
  
  Action: Output PR details; human reviews and decides

#### 3. Check CI run status
- List last 5 CI runs (completed or in-progress)
- Show status: ✓ passed, ✗ failed, ⏳ in-progress
- If failures, show brief reason (timeout, test failure, etc.)
- If older than 24h with unresolved failures, flag for triage

#### 4. Summary and handoff
After all repos processed, display:
```
=== MORNING RUN SUMMARY ===
Repos checked: 5
PRs processed: 12
  Auto-merged: 3
  Flagged for review: 2
  No action needed: 7
CI runs: 15
  Passed: 12
  Failed: 2 (details below)
  In-progress: 1

⚠️  Issues requiring attention:
  - repo1#42: Test timeout (rerun or investigate)
  - repo2#7: Merge conflict (resolve and push)
```

---

## Gotchas

- **GitHub rate limits** — checking many repos/runs can hit API limits. Script checks
  remaining quota and pauses if <100 requests left.
- **Dependabot stale PRs** — if a dependabot PR has been open >30 days without
  interaction, flag it as abandoned (may need manual close).
- **Critical repos** — never auto-merge PRs to repos marked critical without extra
  review (e.g., auth, deployment, compliance repos).
- **Branch protection rules** — if a repo has required reviewers or status checks,
  auto-merge will fail; flag for manual review instead.

---

## Output
- Concise, actionable summary
- Links to PRs and runs (clickable if in GitHub CLI output)
- Clear indication of what was auto-merged vs. flagged
- Timestamps on older issues

---

## Roadmap

- [ ] Add `--auto-merge-all` flag to skip prompts and merge all safe dependabots
- [ ] Add `--report-only` mode (no merges, just audit)
- [ ] Persist "acknowledged failures" to skip re-reporting old known issues
- [ ] Integration with Slack/email notifications for critical issues
- [ ] Add dependency update grouping (e.g., "merge all ESLint family updates together")
