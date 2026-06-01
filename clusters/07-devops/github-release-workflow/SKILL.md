# github-release-workflow

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Execute the full issue → branch → PR → CI wait → merge → tag → GitHub release flow
in sequence, with correct commit message formatting and SSH/HTTPS fallback awareness.

Invoke when: releasing a new version of a repo. Trigger phrases: "cut a release",
"release this version", "create the GitHub release for v[X]".

## Context needed
- Default branch name (usually `main`)
- Version to release (semver: vX.Y.Z)
- Location of version string in the project (`__version__`, `pyproject.toml`, `package.json`)
- Whether there is a CHANGELOG or release notes to generate

## What to do

1. **Open an issue for the release (optional but keeps history clean):**
   ```bash
   gh issue create --title "Release vX.Y.Z" --body "Release checklist for vX.Y.Z"
   ```

2. **Create a release branch, bump the version, commit:**
   ```bash
   git checkout -b release/vX.Y.Z
   # Edit version file (pyproject.toml, __version__.py, etc.)
   git add <version-file>
   git commit -m "Bump version to vX.Y.Z"
   ```

3. **Push, open a PR, and wait for CI:**
   ```bash
   git push -u origin release/vX.Y.Z
   gh pr create --title "Release vX.Y.Z" --body "Bumps version to vX.Y.Z"
   gh pr checks --watch   # wait for CI to pass
   ```

4. **Merge the PR:**
   ```bash
   gh pr merge --squash --delete-branch
   git checkout main && git pull
   ```

5. **Tag and create the GitHub release:**
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   gh release create vX.Y.Z --title "vX.Y.Z" --notes "$(cat CHANGELOG.md | head -50)"
   ```

6. **Verify the release page** on GitHub and confirm the tag points to the correct commit.

## Gotchas
- SSH push can fail if the key agent is not loaded. Check with `ssh -T git@github.com`
  before pushing the tag. If it fails, switch remote to HTTPS: `gh config set git_protocol https`.
- `gh pr checks --watch` blocks until CI completes. Do not merge before it returns success.
- Squash merge rewrites the commit — the tag must be applied to `main` after the merge
  pull, not to the release branch head.
- If the repo uses protected branches, the PR must pass status checks before merge.
  Never use `--admin` to bypass branch protection.

## Suggested scripts
- `release.sh` — parameterised script that runs the full flow from version bump to
  GitHub release creation
