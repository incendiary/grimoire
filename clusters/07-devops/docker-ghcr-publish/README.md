# docker-ghcr-publish

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-07

Builds and pushes Docker images to GitHub Container Registry (GHCR) pinned to the
current release version. Handles CPU and GPU variants, verifies each image starts
correctly, and updates README deployment instructions with versioned pull commands.

---

## What this skill does

- Detects the current version from `VERSION` file, git tag, or `pyproject.toml`
- Infers the GHCR image URI from the git remote
- Builds and tags CPU image (`vX.Y.Z` + `latest`)
- Auto-detects GPU Dockerfile and builds GPU variant (`vX.Y.Z-gpu` + `latest-gpu`)
- Runs `docker-test.sh` to verify each variant starts before pushing
- Tests `docker-compose` if a compose file is present
- Pushes all verified tags to `ghcr.io`
- Rewrites the `## Docker` section in `README.md` with versioned pull + run commands

---

## When to use it

- After cutting a release and wanting to ship a container image alongside it
- When adding Docker support to a project for the first time
- Whenever README Docker pull instructions reference an outdated version

---

## Installation

```bash
cp -r ~/Claude/skills/grimoire/clusters/07-devops/docker-ghcr-publish ~/.claude/skills/
```

---

## Quick start

```bash
export GITHUB_TOKEN=$(gh auth token)   # needs write:packages scope

# 1. Verify detection
bash docker-publish.sh --dry-run

# 2. Build, test, push, update README
bash docker-publish.sh --update-readme

# 3. Commit README
git add README.md && git commit -m "docs: update Docker instructions to vX.Y.Z"
```

---

## Scripts

| Script | Purpose |
|--------|---------|
| `docker-publish.sh` | Build + tag + push CPU/GPU images; `--update-readme` flag |
| `docker-test.sh` | Verify CPU/GPU containers start; test docker-compose services |

---

## Roadmap

- [x] SKILL.md written: workflow, flags, GPU handling, gotchas
- [x] README.md written
- [x] Write `docker-publish.sh` — build, tag, push; `--update-readme`; `--dry-run`
- [x] Write `docker-test.sh` — CPU/GPU smoke test; compose service health check
- [x] Ship: copy to `~/.claude/skills/docker-ghcr-publish/`
- [ ] Add `--platform linux/amd64,linux/arm64` multi-arch build support
- [ ] Add GitHub Actions workflow snippet for automated GHCR publish on tag push
- [ ] Test on pdf2john-docker and bgp_rogue
