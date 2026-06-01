# github-history-wipe

> **Status:** promoted
> **Cluster:** 07-devops
> **Source:** PycharmProjects session (pattern detected 16x)

## Description
Fresh `git init` workflow for public repos: clone to `/tmp`, scan for sensitive strings,
capture releases and tags, wipe history, force push, recreate releases.

Invoke when: a repo needs a clean history before publication and history preservation
is not required, or when `git filter-repo` has already been attempted and references remain.

## Context needed
- List of repos to process
- Sensitive string patterns to scan for (corporate names, hostnames, credentials)
- Whether each repo has GitHub releases or tags that need recreating

## What to do

For each repo:

```bash
# 1. Clone to a temp location
cd /tmp && git clone git@github.com:incendiary/<repo>.git <repo>-wipe && cd <repo>-wipe

# 2. Scan for sensitive strings before touching anything
grep -rI --include="*.py" --include="*.cs" --include="*.sh" --include="*.md" \
  -l "<corp-name>\|<internal-hostname>\|<internal-ip>" .

# 3. Capture releases and tags to JSON
gh release list --repo incendiary/<repo> --json tagName,name,body,isDraft,isPrerelease \
  > /tmp/<repo>-releases.json
git tag -l > /tmp/<repo>-tags.txt

# 4. Confirm with user before wiping — show what will be lost

# 5. Wipe history
rm -rf .git
git init
git branch -m main
git add .
git commit -m "Initial commit" \
  --author="incendiary <email>" \
  -c "author.email=<public-email>"

# 6. Force push
git remote add origin git@github.com:incendiary/<repo>.git
git push --force --set-upstream origin main

# 7. Recreate releases from JSON
# (use gh release create for each entry in the JSON)
```

Always confirm with the user after step 4, before step 5. Never wipe without explicit approval.

## Gotchas
- Archived repos must be unarchived before force push, then re-archived afterwards
- `git author email` in commit metadata survives content wipes — override explicitly at commit time
- GitHub releases are not part of git history — they will be lost and must be recreated manually
- If the repo has open PRs or branch protection, the force push will fail — resolve first

## Suggested scripts
- `capture-releases.sh` — dumps all releases and tags to JSON before wipe
- `recreate-releases.sh` — reads JSON and calls `gh release create` for each entry
