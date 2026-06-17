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

### Claude Code

```bash
cp -r clusters/07-devops/docker-ghcr-publish ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#docker-ghcr-publish
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


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

## Multi-arch builds

Use Docker Buildx to produce a single manifest that runs on both AMD64 and ARM64
(e.g. Apple Silicon Macs, AWS Graviton):

```bash
# One-time: create a buildx builder with multi-platform support
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# Build and push multi-arch image directly (no local load)
export VERSION=$(cat VERSION)
export IMAGE=ghcr.io/<owner>/<repo>

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "${IMAGE}:v${VERSION}" \
  --tag "${IMAGE}:latest" \
  --push \
  .

# Verify the manifest list
docker buildx imagetools inspect "${IMAGE}:v${VERSION}"
```

**Notes:**
- `--push` is required for multi-arch (multi-arch images cannot be loaded into the local
  daemon with `--load`; they are pushed directly to the registry)
- The manifest list is a single image URI that Docker resolves to the correct arch at pull time
- Cross-compilation (e.g. building ARM64 on AMD64) requires QEMU emulation:
  `docker run --privileged --rm tonistiigi/binfmt --install all`

## CI integration — automated GHCR publish on tag push

Add `.github/workflows/ghcr-publish-on-tag.yml`:

```yaml
name: Publish to GHCR
on:
  push:
    tags: ["v*"]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract version from tag
        id: version
        run: echo "tag=${GITHUB_REF#refs/tags/}" >> "$GITHUB_OUTPUT"

      - name: Build and push (multi-arch)
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.version.outputs.tag }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**For GPU variants**, add a second job with `Dockerfile.gpu` and tags suffixed `-gpu`.

---

## Roadmap

- [x] SKILL.md written: workflow, flags, GPU handling, gotchas
- [x] README.md written
- [x] Write `docker-publish.sh` — build, tag, push; `--update-readme`; `--dry-run`
- [x] Write `docker-test.sh` — CPU/GPU smoke test; compose service health check
- [x] Ship: copy to `~/.claude/skills/docker-ghcr-publish/`
- [x] Add `--platform linux/amd64,linux/arm64` multi-arch build support
- [x] Add GitHub Actions workflow snippet for automated GHCR publish on tag push
- [ ] Test on pdf2john-docker and bgp_rogue
