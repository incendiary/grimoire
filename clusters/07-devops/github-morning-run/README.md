# github-morning-run

Routine GitHub repository maintenance. Audits open PRs, auto-merges simple dependabot updates when CI passes, checks action status, and flags complex issues for review.

## Quick start

Run the script with interactive scope selection:

```bash
bash github-morning-run.sh
```

Or specify scope directly:

```bash
# Current repo only
bash github-morning-run.sh --current

# All incendiary-authored repos
bash github-morning-run.sh --all

# Specific repo
bash github-morning-run.sh --repo owner/repo
```

## What it does

1. **Audit open PRs**
   - List open PRs per repo
   - Show review status (approved, needs review, failing CI)
   - Identify dependabot PRs for processing

2. **Auto-merge safe dependabot PRs**
   - ✅ CI passes
   - ✅ No merge conflicts
   - ✅ Single dependency (not a batch)
   - ✅ Not in a critical repo

   → Merges with `--squash --delete-branch`

3. **Flag complex issues**
   - CI failing
   - Merge conflicts
   - Multi-dependency updates
   - Critical infrastructure repos
   
   → Displays for manual review

4. **Check CI run status**
   - Last 3 GitHub Actions runs per repo
   - Status: ✓ passed, ✗ failed, ⏳ in-progress

5. **Rate limit awareness**
   - Checks remaining API quota
   - Pauses if <100 requests remaining

## Examples

### Simple morning check on current repo
```bash
bash github-morning-run.sh --current
```

Output:
```
=== REPO: incendiary/grimoire ===
  Open PRs: 3
  [#42] chore: bump deps... ✓ (auto-merging)
  [#41] fix: shell bug... (review needed)
  [#40] docs: readme update... (review needed)

  Recent CI runs (last 3):
    ✓ Run #12345: success
    ✓ Run #12344: success
    ✗ Run #12343: failure

  Summary: 1 auto-merged, 0 flagged for review
```

### Full portfolio audit
```bash
bash github-morning-run.sh --all
```

Iterates through all authored repos, applies same logic.

### Scheduled via cron
```bash
# Daily at 8 AM
0 8 * * * cd /path/to/grimoire && bash clusters/07-devops/github-morning-run/github-morning-run.sh --all >> /tmp/github-morning.log 2>&1
```

## Gotchas

- **Rate limits**: API quota ~5000/hr. Checking many repos can hit limits; script pauses if <100 remaining.
- **Branch protection**: Repos with required reviewers will block auto-merge; these are flagged.
- **Archived repos**: Skipped automatically (no PRs possible).
- **Private repos**: Requires `gh auth` to be configured with proper token.
- **Dependabot stale**: PRs open >30 days without update are flagged as abandoned.

## Skill context

- **Cluster**: 07-devops
- **Type**: action
- **Trigger**: "check my repos", "morning run", "GitHub status"
- **Routing**: for issues requiring deeper work, route to `github-release-workflow` or `project-delivery-workflow`
