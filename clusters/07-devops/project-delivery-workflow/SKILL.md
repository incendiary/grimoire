# project-delivery-workflow

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
End-to-end workflow for delivering a GitHub project from cold checkout to final
version bump: read nested READMEs to build the roadmap, work each item as a PR,
keep READMEs and versions in sync, verify CI on every push, and do a major version
bump when all items are done.

Invoke when: handed a GitHub repo to work through, asked to complete outstanding
roadmap items, or starting a structured delivery session on any project.

## Context needed
- Repository name or URL (to clone / `gh repo clone`)
- Branch strategy preference if not stated (default: feature branch per item, PR to main)
- Whether the repo uses semver tags, a VERSION file, or version in a manifest
  (`package.json`, `pyproject.toml`, `*.csproj`, etc.)

## What to do

1. **Start cold: clone and run repo-compass before touching any code.**

   ```bash
   gh repo clone <owner>/<repo>
   cd <repo>
   find . -name "README*" -not -path "*/.git/*" | sort | \
     xargs -I{} sh -c 'echo "=== {} ===" && cat {}'
   ```

   Run `repo-compass` (or follow its checklist manually) to produce the true state
   summary: GitHub state + README roadmap cross-check + discrepancy list. This is
   the single source of truth for what is outstanding before any work begins.

   READMEs are the source of truth for what is outstanding. Do not assume — read
   them all, including nested ones in subdirectories. Build a numbered list of
   outstanding roadmap items from what you find.

2. **Propose the delivery plan before writing a single line of code.**

   Format:
   ```
   Roadmap items found:
   1. [item] — proposed as: single commit / split into N commits
   2. [item] — proposed as: single commit / split into N commits
   ...

   Commit/PR packaging rationale:
   - Items that touch a single concern → one commit, one PR
   - Items that span multiple layers (e.g. model + API + test) → split by layer,
     squashed into one PR
   - Breaking changes → separate PR with version bump commit included

   Proposed version progression:
   - After each item: patch bump (x.y.Z) or minor bump (x.Y.0) as appropriate
   - On final item: major bump (X.0.0)
   ```

   Wait for confirmation or adjustment before starting. This is the one planned
   pause before execution begins.

3. **Work each item as a feature branch → PR → merge loop.**

   Per item:
   ```bash
   git checkout -b <descriptive-branch-name>   # e.g. feat/add-retry-logic
   # implement
   git add <specific files>
   git commit -m "<imperative summary>"
   git push -u origin <branch>
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   - <bullet points of what changed and why>

   ## Test plan
   - [ ] <verification step>
   - [ ] CI passes

   🤖 Generated with Claude Code
   EOF
   )"
   ```

   Then wait for CI before merging. Never merge a red PR.

4. **Check CI status after every push. Do not proceed to the next item until green.**

   ```bash
   gh pr checks <PR-number> --watch
   # or poll:
   gh run list --limit 5
   gh run view <run-id>
   ```

   If CI fails:
   - Read the failure output in full before guessing at a fix
   - Push a fix commit to the same branch (do not open a new PR)
   - Re-check before merging

   Once green:
   ```bash
   gh pr merge <PR-number> --squash --delete-branch
   git checkout main && git pull
   ```

5. **After merging each PR: update the README and bump the version.**

   README update — tick the completed item:
   ```markdown
   - [x] Add retry logic   ← was [ ]
   ```
   Commit directly to main (README + version bump is a single housekeeping commit,
   not a PR):
   ```bash
   # bump version in the appropriate manifest
   git add README.md <version-file>
   git commit -m "chore: mark <item> complete, bump to x.y.z"
   git push origin main
   ```

   Version bump rules:
   | Change type | Bump |
   |-------------|------|
   | Bug fix, docs, chore | patch (x.y.Z+1) |
   | New feature, backwards-compatible | minor (x.Y+1.0) |
   | Breaking change | major (X+1.0.0) |
   | All roadmap items complete | major (X+1.0.0), regardless of item types |

6. **On the final item: major version bump + release.**

   ```bash
   # After the last PR is merged and README fully updated:
   git tag vX.0.0
   git push origin vX.0.0
   gh release create vX.0.0 --title "vX.0.0" --notes "$(cat <<'EOF'
   ## What's in this release
   - <summary of all items delivered>

   ## Breaking changes
   - <if any>
   EOF
   )"
   ```

   Verify the release appears correctly on GitHub:
   ```bash
   gh release view vX.0.0
   ```

## Monorepo variant

When the repo is a monorepo (multiple packages or clusters under one root):

- Iterate per package/subdirectory: scope each PR to a single package where feasible.
  A PR that touches `packages/foo/` and `packages/bar/` for unrelated reasons is hard to review.
- Version files may be per-package (`packages/foo/VERSION`) rather than at the root.
  Bump the relevant per-package version after each PR, not the root version.
- README roadmap items may appear at multiple levels: root `README.md` AND
  `packages/foo/README.md`. Tick both when an item is delivered.
- Branch names should include the package: `feat/foo/add-retry-logic` rather than
  just `feat/add-retry-logic`.
- The final major version bump and release should wait until *all* package roadmaps
  are complete. If packages have independent release cadences, do per-package releases
  and a root release at the end.

## Required reviewers

If the repo has required reviewers or branch protection rules, `gh pr merge` will fail
with a "merge blocked" error even after CI is green. Handle it:

1. **Check protection rules before starting:**
   ```bash
   gh api repos/OWNER/REPO/branches/main/protection --jq '.required_pull_request_reviews'
   ```

2. **Mark the PR as ready for review (if it was a draft):**
   ```bash
   gh pr ready <PR-number>
   ```

3. **Request review explicitly:**
   ```bash
   gh pr review <PR-number> --request-reviewers <github-username>
   ```

4. **Wait for approval before attempting merge.** Do not attempt `gh pr merge` until
   the review is approved — it will error and leave the PR in a confusing state.

5. **After approval, merge normally:**
   ```bash
   gh pr merge <PR-number> --squash --delete-branch
   ```

If you are the sole maintainer and required-reviewer rules prevent self-merge:
- Either disable the rule temporarily (Settings → Branches → edit protection rule)
- Or use the GitHub web UI to bypass if you have admin rights

## Post-delivery checklist

Run this after the final PR is merged and the major version release is created:

```bash
# 1. No stale feature branches remain
git branch -r --merged main | grep -v 'main\|HEAD'
# → should be empty

# 2. No open PRs or draft PRs
gh pr list --state open
# → should be empty

# 3. All tags backed by releases (no loose tags)
git tag --sort=-creatordate | head -10
gh release list --limit 10
# → every tag should appear in release list

# 4. Final release marked Latest
gh release view --json tagName,isLatest,publishedAt
# → isLatest: true

# 5. README roadmap fully ticked
grep -- "- \[ \]" README.md
# → should return nothing (all items complete or explicitly deferred)

# 6. CI green on main
gh run list --limit 3
# → all runs: completed / success

# 7. Install script works cleanly
bash install-all.sh
# → should print "Installed" or "Skipped" for every skill, no errors
```

If any check fails, fix it before declaring the delivery complete.

## Gotchas
- Always read nested READMEs. A top-level README often says "see subdirectory X"
  and the real roadmap is buried one level down.
- Do not `git add .` or `git add -A` — stage specific files. Stray `.env`, build
  artefacts, or test fixtures have been committed this way before.
- SSH push failures are common after a session gap. Check `git remote -v` and
  switch to HTTPS if needed (`git-push-protocol-handler` skill).
- Do not bump the version mid-PR. The version bump commit goes on main after merge,
  not on the feature branch.
- `gh pr merge --squash` rewrites history — the branch commits are squashed into
  one on main. Make sure the squash commit message is the PR title, not a generated
  hash. Edit it if the default is unclear.
- Roadmap items marked `[ ]` in a README may already be implemented if the README
  wasn't kept up to date. Check the code before treating an item as outstanding.

## Suggested scripts
- None — this skill orchestrates `gh` CLI commands directly
