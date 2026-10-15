---
name: release
description: "Cuts a release with release-please: merges the standing release PR once CI is green (which creates the tag and GitHub release), or sets release-please up in a repo that has none. Use when asked to 'cut a release', 'release this version', 'ship what is queued', or 'set up releases'. For README version pins use release-readme-pin; for container images use release-docker-ghcr."
---
# release

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional

## Pathway

| Step | Skill | When |
|---|---|---|
| 1 | `release` | Cutting a release |
| 2 | `release-readme-pin` | README install lines need the new tag |
| 3 | `release-docker-ghcr` | The repo ships a container image |
| 4 | `roadmap-sync` | Tick roadmap items the release closed |

## Description
Releases come from release-please. It reads Conventional Commit prefixes on `main`
(`feat:` minor, `fix:` patch, `feat!:` or a `BREAKING CHANGE:` footer major) and keeps a
standing "chore(release): vX.Y.Z" PR open. Merging that PR bumps the version, creates the
tag, and publishes the GitHub release in one step. Never bump versions or create tags by hand.

## What to do

### The repo already uses release-please
(`.github/workflows/release-please.yml` exists)

1. Find the release PR:
   ```bash
   gh pr list --search "chore(release) in:title" --state open
   ```
   No PR means nothing releasable has landed since the last release (only `docs:`,
   `chore:`, `ci:` commits do not trigger one).
2. Check its version is what the owner expects. A `feat!:` anywhere since the last release
   makes it a major version.
3. Wait for CI to be green, then squash-merge it. If branch protection blocks the merge,
   ask the owner; never bypass protection.
4. Confirm the tag and release exist: `gh release list --limit 1`.
5. Continue down the pathway (README pin, Docker image, roadmap sync) as needed.

### The repo has no release-please yet

1. Add `.github/workflows/release-please.yml`:
   ```yaml
   name: release-please
   on:
     push:
       branches: [main]
   permissions:
     contents: write
     pull-requests: write
   jobs:
     release-please:
       runs-on: ubuntu-latest
       steps:
         - uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5
           with:
             token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
             config-file: release-please-config.json
             manifest-file: .release-please-manifest.json
   ```
2. Add `release-please-config.json` with the right `release-type` (`simple` with a
   `version-file: VERSION`, or `python`, `node`, and so on) and
   `.release-please-manifest.json` holding the current version (`{".": "1.4.0"}`).
3. Ask the owner to create a fine-grained PAT as the `RELEASE_PLEASE_TOKEN` repo secret.
   The default `GITHUB_TOKEN` cannot trigger CI on the release PR, so required checks
   would never report.
4. From then on, commits must use Conventional Commit prefixes.

## Gotchas
- Pick exactly one release path per repo. If an old `release-on-tag.yml` or manual
  `gh release create` habit exists, remove it when adopting release-please, or the same tag
  gets two release attempts.
- If `CHANGELOG.md` is hand-written, set `skip-changelog: true` so release-please only owns
  the version, tag, and release.
- A version-sync CI check (VERSION equals latest tag) will be red on the release PR itself.
  Do not make it a required check.
- To create releases for old tags that never got one, use `scripts/release-backfill.sh`
  in the grimoire repo.
