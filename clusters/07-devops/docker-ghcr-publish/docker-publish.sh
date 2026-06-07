#!/usr/bin/env bash
# docker-publish.sh
# Builds, tags, and pushes Docker images to GHCR pinned to the current
# release version. Handles an optional GPU variant. Optionally updates
# the README ## Docker section with versioned pull+run commands.
#
# Usage:
#   ./docker-publish.sh                    # build + test + push
#   ./docker-publish.sh --dry-run          # show what would happen; build nothing
#   ./docker-publish.sh --update-readme    # also rewrite README ## Docker section
#   ./docker-publish.sh --no-gpu           # skip GPU build
#   ./docker-publish.sh --skip-test        # push without running docker-test.sh

set -euo pipefail

# ── Parse flags ───────────────────────────────────────────────────────────
IMAGE=""
DOCKERFILE="Dockerfile"
GPU_DOCKERFILE=""
UPDATE_README=false
DRY_RUN=false
NO_GPU=false
SKIP_TEST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)          IMAGE="$2";          shift 2 ;;
        --dockerfile)     DOCKERFILE="$2";     shift 2 ;;
        --gpu-dockerfile) GPU_DOCKERFILE="$2"; shift 2 ;;
        --update-readme)  UPDATE_README=true;  shift ;;
        --dry-run)        DRY_RUN=true;        shift ;;
        --no-gpu)         NO_GPU=true;         shift ;;
        --skip-test)      SKIP_TEST=true;      shift ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

echo "=== docker-ghcr-publish ==="
echo ""

# ── Detect version ─────────────────────────────────────────────────────────
VERSION=""
if [[ -f "VERSION" ]]; then
    VERSION=$(tr -d '[:space:]' < VERSION)
    [[ "$VERSION" != v* ]] && VERSION="v${VERSION}"
elif git rev-parse --git-dir &>/dev/null; then
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null || true)
fi
if [[ -z "$VERSION" && -f "pyproject.toml" ]]; then
    VERSION=$(python3 -c "
import re
try:
    m = re.search(r'^version\s*=\s*[\"\'](.*?)[\"\']', open('pyproject.toml').read(), re.MULTILINE)
    v = m.group(1) if m else ''
    print(('v' + v) if v and not v.startswith('v') else v)
except Exception:
    pass
" 2>/dev/null || true)
fi
if [[ -z "$VERSION" ]]; then
    echo "[ERROR] Cannot detect version. Provide a VERSION file, git tag, or pyproject.toml."
    exit 1
fi
echo "  Version  : $VERSION"

# ── Detect image name ──────────────────────────────────────────────────────
if [[ -z "$IMAGE" ]]; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ "$REMOTE_URL" == git@github.com:* ]]; then
        REPO_PATH="${REMOTE_URL#git@github.com:}"
        REPO_PATH="${REPO_PATH%.git}"
    elif [[ "$REMOTE_URL" == https://github.com/* ]]; then
        REPO_PATH="${REMOTE_URL#https://github.com/}"
        REPO_PATH="${REPO_PATH%.git}"
    else
        echo "[ERROR] Cannot infer image name from remote: $REMOTE_URL"
        echo "        Pass --image ghcr.io/owner/repo"
        exit 1
    fi
    IMAGE="ghcr.io/${REPO_PATH,,}"  # lowercase required by GHCR
fi
echo "  Image    : $IMAGE"

# ── Check CPU Dockerfile ───────────────────────────────────────────────────
if [[ ! -f "$DOCKERFILE" ]]; then
    echo "[ERROR] CPU Dockerfile not found: $DOCKERFILE"
    echo "        Pass --dockerfile <path>"
    exit 1
fi
echo "  CPU      : $DOCKERFILE → ${IMAGE}:${VERSION} + ${IMAGE}:latest"

# ── Auto-detect GPU Dockerfile ─────────────────────────────────────────────
if ! $NO_GPU && [[ -z "$GPU_DOCKERFILE" ]]; then
    for candidate in Dockerfile.gpu Dockerfile.cuda docker/Dockerfile.gpu docker/Dockerfile.cuda; do
        if [[ -f "$candidate" ]]; then
            GPU_DOCKERFILE="$candidate"
            break
        fi
    done
fi
HAS_GPU=false
if ! $NO_GPU && [[ -n "$GPU_DOCKERFILE" ]]; then
    HAS_GPU=true
    echo "  GPU      : $GPU_DOCKERFILE → ${IMAGE}:${VERSION}-gpu + ${IMAGE}:latest-gpu"
else
    echo "  GPU      : none detected"
fi

# ── Auto-detect compose file ───────────────────────────────────────────────
COMPOSE_FILE=""
for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    if [[ -f "$candidate" ]]; then
        COMPOSE_FILE="$candidate"
        break
    fi
done
if [[ -n "$COMPOSE_FILE" ]]; then
    echo "  Compose  : $COMPOSE_FILE"
fi

echo ""

if $DRY_RUN; then
    echo "  [DRY RUN] No builds or pushes will be performed."
    echo "            Re-run without --dry-run to execute."
    echo ""
    echo "=== docker-ghcr-publish dry run complete ==="
    exit 0
fi

# ── Auth check ─────────────────────────────────────────────────────────────
TOKEN="${GITHUB_TOKEN:-${CR_PAT:-}}"
if [[ -z "$TOKEN" ]]; then
    echo "[ERROR] GITHUB_TOKEN or CR_PAT not set."
    echo "        export GITHUB_TOKEN=\$(gh auth token)"
    echo "        (token needs write:packages scope)"
    exit 1
fi

OWNER="${IMAGE#ghcr.io/}"
OWNER="${OWNER%%/*}"
echo "$TOKEN" | docker login ghcr.io -u "$OWNER" --password-stdin
echo ""

# ── Build CPU image ────────────────────────────────────────────────────────
echo "--- Building CPU image ---"
docker build -f "$DOCKERFILE" -t "${IMAGE}:${VERSION}" -t "${IMAGE}:latest" .
echo ""

# ── Test CPU image ─────────────────────────────────────────────────────────
if ! $SKIP_TEST; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "--- Testing CPU image ---"
    bash "${SCRIPT_DIR}/docker-test.sh" --image "$IMAGE" --version "$VERSION" --no-gpu
    echo ""
fi

# ── Build GPU image ────────────────────────────────────────────────────────
if $HAS_GPU; then
    echo "--- Building GPU image ---"
    docker build -f "$GPU_DOCKERFILE" \
        -t "${IMAGE}:${VERSION}-gpu" \
        -t "${IMAGE}:latest-gpu" .
    echo ""

    if ! $SKIP_TEST; then
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        echo "--- Testing GPU image ---"
        bash "${SCRIPT_DIR}/docker-test.sh" --image "$IMAGE" --version "$VERSION" --gpu-only
        echo ""
    fi
fi

# ── Compose test ───────────────────────────────────────────────────────────
if ! $SKIP_TEST && [[ -n "$COMPOSE_FILE" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "--- Testing docker-compose ---"
    bash "${SCRIPT_DIR}/docker-test.sh" \
        --image "$IMAGE" --version "$VERSION" \
        --no-gpu --compose-only --compose-file "$COMPOSE_FILE"
    echo ""
fi

# ── Push all tags ──────────────────────────────────────────────────────────
echo "--- Pushing ---"
docker push "${IMAGE}:${VERSION}"
docker push "${IMAGE}:latest"
if $HAS_GPU; then
    docker push "${IMAGE}:${VERSION}-gpu"
    docker push "${IMAGE}:latest-gpu"
fi
echo ""

# ── Update README ──────────────────────────────────────────────────────────
if $UPDATE_README; then
    echo "--- Updating README.md ---"
    README="README.md"
    if [[ ! -f "$README" ]]; then
        echo "  [WARN] README.md not found — skipping"
    else
        # Build the new Docker section
        GPU_SECTION=""
        if $HAS_GPU; then
            GPU_SECTION=$(cat <<GPUSEC

### GPU (CUDA)

\`\`\`bash
docker pull ${IMAGE}:${VERSION}-gpu
docker run --rm --gpus all ${IMAGE}:${VERSION}-gpu
\`\`\`
GPUSEC
)
        fi

        COMPOSE_SECTION=""
        if [[ -n "$COMPOSE_FILE" ]]; then
            COMPOSE_SECTION=$(cat <<COMPOSESEC

### docker-compose

\`\`\`bash
docker compose up
\`\`\`
COMPOSESEC
)
        fi

        NEW_SECTION=$(cat <<SECTION
## Docker

Pull and run the latest release:

### CPU

\`\`\`bash
docker pull ${IMAGE}:${VERSION}
docker run --rm ${IMAGE}:${VERSION}
\`\`\`
${GPU_SECTION}${COMPOSE_SECTION}
SECTION
)

        # Replace existing ## Docker section, or append if absent
        if grep -q "^## Docker" "$README"; then
            python3 - "$README" "$NEW_SECTION" <<'PYEOF'
import sys, re
path = sys.argv[1]
new_section = sys.argv[2]
content = open(path).read()
# Replace from ## Docker up to the next ## heading (or end of file)
updated = re.sub(
    r'^## Docker\b.*?(?=^## |\Z)',
    new_section + '\n',
    content,
    flags=re.MULTILINE | re.DOTALL
)
open(path, 'w').write(updated)
PYEOF
            echo "  [DONE] Updated existing ## Docker section"
        else
            printf '\n%s\n' "$NEW_SECTION" >> "$README"
            echo "  [DONE] Appended ## Docker section"
        fi
    fi
fi

echo ""
echo "=== docker-ghcr-publish complete ==="
echo "  Pushed: ${IMAGE}:${VERSION}"
$HAS_GPU && echo "  Pushed: ${IMAGE}:${VERSION}-gpu"
echo ""
echo "  Next: git add README.md && git commit -m \"docs: update Docker instructions to ${VERSION}\""
