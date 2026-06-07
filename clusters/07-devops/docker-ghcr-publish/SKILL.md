# docker-ghcr-publish

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Builds, tags, and pushes Docker images to GitHub Container Registry (GHCR) pinned to
the current release version. Handles an optional GPU variant automatically. Updates the
README with versioned deployment instructions. Includes a post-build test script that
verifies each image variant actually starts and responds correctly.

Invoke when: cutting a release and need to ship a container image, asked to "publish
to GHCR", "build and push the Docker image", or "add Docker deployment instructions".

## Context needed
- Whether the repo has a `Dockerfile` in the root (CPU) and/or a GPU variant
  (`Dockerfile.gpu`, `Dockerfile.cuda`, `docker/Dockerfile.gpu`)
- Whether there is a `docker-compose.yml` or `compose.yml` for multi-service testing
- The current release version (detected automatically from `VERSION` file or git tag)
- `GITHUB_TOKEN` set in the environment

## One-time setup

### Enable GHCR writes
By default GitHub tokens from `gh auth token` have `read:packages` scope only.
To push images, you need `write:packages`:

```bash
# Option A — use gh CLI token (if it has write:packages)
export GITHUB_TOKEN=$(gh auth token)

# Option B — create a PAT with write:packages and repo scopes
# Settings → Developer settings → Personal access tokens → Fine-grained
# Permissions: Contents (read), Packages (write)
export GITHUB_TOKEN=ghp_...
```

### Login to GHCR
```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io -u <github-username> --password-stdin
```
`docker-publish.sh` does this automatically if `GITHUB_TOKEN` is set.

### Make package public (optional, first push only)
After the first push: GitHub → your package → Package settings → Change visibility → Public.

## Workflow

### Step 1 — Dry run to verify detection

```bash
bash docker-publish.sh --dry-run
```

Prints: detected version, inferred image name, CPU Dockerfile path, GPU Dockerfile path
(if found), compose file (if found). Makes no changes.

### Step 2 — Build, test, push

```bash
bash docker-publish.sh --update-readme
```

What this does:
1. Logs in to `ghcr.io` using `GITHUB_TOKEN`
2. Builds CPU image: `ghcr.io/<owner>/<repo>:vX.Y.Z` and `:latest`
3. Runs `docker-test.sh` for the CPU image (exits 1 if container fails)
4. If GPU Dockerfile found: builds `:vX.Y.Z-gpu` and `:latest-gpu`; runs GPU test
5. If compose file found: runs compose test (up → ps → assert healthy → down)
6. Pushes all verified tags to GHCR
7. Updates the `## Docker` section in `README.md` with versioned pull+run commands

### Step 3 — Commit the README update

```bash
git add README.md
git commit -m "docs: update Docker deployment instructions to vX.Y.Z"
```

## What the README Docker section looks like after update

```markdown
## Docker

Pull and run the latest release:

### CPU

```bash
docker pull ghcr.io/owner/repo:v1.2.11
docker run --rm ghcr.io/owner/repo:v1.2.11
```

### GPU (CUDA)

```bash
docker pull ghcr.io/owner/repo:v1.2.11-gpu
docker run --rm --gpus all ghcr.io/owner/repo:v1.2.11-gpu
```

### docker-compose

```bash
docker compose up
```
```

## Post-build testing (`docker-test.sh`)

Run standalone at any point to verify images are healthy:

```bash
bash docker-test.sh                          # test current version images
bash docker-test.sh --cmd "python -c 'import app'"   # custom smoke command
bash docker-test.sh --no-gpu                 # skip GPU test
bash docker-test.sh --compose-file path/to/compose.yml
```

**CPU test:** `docker run --rm <image>:vX.Y.Z` — exits 0 = pass.

**GPU test:**
1. `docker run --rm --gpus all <image>:vX.Y.Z-gpu nvidia-smi` — confirms GPU visible
2. `docker run --rm --gpus all <image>:vX.Y.Z-gpu <smoke-command>` — confirms app starts

If the host has no NVIDIA runtime, the GPU test is skipped with a `[SKIP]` notice.

**Compose test:**
1. `docker compose -f <file> up -d --wait` (waits for healthchecks if defined)
2. `docker compose -f <file> ps` — asserts all services are `running` or `healthy`
3. `docker compose -f <file> down`

## Flags reference

### docker-publish.sh
| Flag | Default | Description |
|------|---------|-------------|
| `--image <uri>` | inferred from git remote | Override GHCR image URI |
| `--dockerfile <path>` | `Dockerfile` | Override CPU Dockerfile |
| `--gpu-dockerfile <path>` | auto-detected | Override GPU Dockerfile |
| `--no-gpu` | off | Skip GPU build even if Dockerfile.gpu found |
| `--update-readme` | off | Rewrite `## Docker` section in README.md |
| `--skip-test` | off | Push without running docker-test.sh |
| `--dry-run` | off | Print what would happen; build nothing |

### docker-test.sh
| Flag | Default | Description |
|------|---------|-------------|
| `--image <uri>` | inferred | Override image URI |
| `--cmd <command>` | container default | Custom smoke command |
| `--no-gpu` | off | Skip GPU test |
| `--compose-file <path>` | auto-detected | Override compose file path |
| `--timeout <seconds>` | 30 | Max seconds to wait for container start |

## Gotchas

- **`GITHUB_TOKEN` must have `write:packages` scope.** `gh auth token` may only have
  `read:packages` by default. Create a PAT if pushes fail with 403.
- **GPU tests require nvidia-container-toolkit on the host.** If not installed,
  `docker run --gpus all` will fail. `docker-test.sh` detects this and skips the GPU
  test with `[SKIP]` rather than failing.
- **First push makes the package private by default.** You must manually set it to
  public in GitHub package settings after the first push if public access is needed.
- **`--update-readme` rewrites the entire `## Docker` section.** If you have custom
  content in that section, move it above or below — the script replaces everything
  between `## Docker` and the next `##` heading.
- **Always run `--dry-run` first** when using on a new repo to confirm the image name
  and Dockerfile paths are detected correctly before building.

## Related skills

- `github-release-workflow` — run this skill after tagging the release
- `readme-version-pin` — pins git clone / pip install refs; Docker pull refs are handled separately by this skill
- `pre-commit-aware-commits` — commit the README update cleanly after running `--update-readme`
