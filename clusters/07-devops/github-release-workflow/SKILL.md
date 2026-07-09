# github-release-workflow

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

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

5. **Tag and push. Check first whether `.github/workflows/release-on-tag.yml` exists —
   if it does, the tag push *is* the release step; do not also run `gh release create`
   manually, or you will collide with the workflow (whichever runs second gets
   `HTTP 422: Release.tag_name already exists`).**
   ```bash
   test -f .github/workflows/release-on-tag.yml && echo "workflow will create the release"

   git tag vX.Y.Z
   git push origin vX.Y.Z

   # Only if release-on-tag.yml does NOT exist in this repo:
   # gh release create vX.Y.Z --title "vX.Y.Z" --notes "$(cat CHANGELOG.md | head -50)"
   ```

6. **Verify the release page** on GitHub and confirm the tag points to the correct commit.
   If `release-on-tag.yml` ran, check it succeeded: `gh run list --workflow release-on-tag.yml --limit 1`.

## Gotchas
- SSH push can fail if the key agent is not loaded. Check with `ssh -T git@github.com`
  before pushing the tag. If it fails, switch remote to HTTPS: `gh config set git_protocol https`.
- `gh pr checks --watch` blocks until CI completes. Do not merge before it returns success.
- Squash merge rewrites the commit — the tag must be applied to `main` after the merge
  pull, not to the release branch head.
- If the repo uses protected branches, the PR must pass status checks before merge.
  Never use `--admin` to bypass branch protection.
- **Never run both the manual `gh release create` step and `release-on-tag.yml` on the
  same tag.** Pick exactly one release-creation path per repo. If both exist, use the
  idempotent workflow template below (it checks for an existing release first) so a
  stray manual run doesn't turn every release into a guaranteed-red Actions run.

## Suggested scripts
- `release.sh` — parameterised script that runs the full flow from version bump to
  GitHub release creation
- `release-backfill.sh` — one-off reconciliation: creates GitHub Releases for any
  tags that are missing them (supports `--mark-prerelease-before`)

## CI enforcement: release-on-tag workflow

Add this workflow to any repo to guarantee every `v*` tag gets a GitHub Release.
Prevents tag↔release drift regardless of who pushes the tag. **Idempotent by
design** — it checks for an existing release before creating one, so it is safe
even if someone also runs `gh release create` manually for the same tag (step 5
above still says: don't do both on purpose, but this stops it being a guaranteed
failure if it happens anyway).

```yaml
# .github/workflows/release-on-tag.yml
name: Release on tag
on:
  push:
    tags: ["v*"]
permissions:
  contents: write
jobs:
  create-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - name: Extract version from tag
        id: version
        run: |
          TAG="${GITHUB_REF#refs/tags/}"
          echo "tag=$TAG" >> "$GITHUB_OUTPUT"
          echo "version=${TAG#v}" >> "$GITHUB_OUTPUT"
      - name: Check for existing release
        id: existing
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          TAG="${{ steps.version.outputs.tag }}"
          if gh release view "$TAG" >/dev/null 2>&1; then
            echo "exists=true" >> "$GITHUB_OUTPUT"
            echo "Release $TAG already exists — skipping creation (idempotent)"
          else
            echo "exists=false" >> "$GITHUB_OUTPUT"
          fi
      - name: Extract release notes from CHANGELOG
        id: notes
        if: steps.existing.outputs.exists == 'false'
        run: |
          VERSION="${{ steps.version.outputs.version }}"
          NOTES=""
          if [ -f "CHANGELOG.md" ]; then
            NOTES=$(awk -v ver="$VERSION" '
              /^## / { if (found) exit; if (index($0,"["ver"]")) { found=1; next } }
              found { print }
            ' CHANGELOG.md | head -50)
          fi
          if [ -z "$NOTES" ]; then
            echo "use_generate_notes=true" >> "$GITHUB_OUTPUT"
          else
            echo "use_generate_notes=false" >> "$GITHUB_OUTPUT"
            printf '%s\n' "$NOTES" > /tmp/release-notes.md
          fi
      - name: Create release
        if: steps.existing.outputs.exists == 'false'
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          TAG="${{ steps.version.outputs.tag }}"
          if [ "${{ steps.notes.outputs.use_generate_notes }}" = "true" ]; then
            gh release create "$TAG" --title "$TAG" --generate-notes
          else
            gh release create "$TAG" --title "$TAG" --notes-file /tmp/release-notes.md
          fi
```

### Variant: direct tag on main (no release branch)

For projects that tag directly on `main` without a release branch PR:

```bash
# Bump version, commit, tag, push, and let CI create the release
echo "1.7.0" > VERSION
git add VERSION && git commit -m "chore: bump version to 1.7.0"
git tag v1.7.0
git push origin main --tags
# release-on-tag.yml will create the GitHub Release automatically
```

### Reconciliation: detecting drift

Add to your validation CI (warning only, not a hard failure):

```yaml
- name: Version-tag drift check
  run: |
    VERSION=$(tr -d '[:space:]' < VERSION)
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
    if [ "$LATEST_TAG" != "v${VERSION}" ]; then
      echo "::warning::VERSION ($VERSION) ≠ latest tag ($LATEST_TAG)"
    fi
```
