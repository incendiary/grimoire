#!/usr/bin/env bash
# docker-test.sh
# Verifies Docker images start and respond correctly after a build or pull.
# Tests CPU image, GPU image (if available), and docker-compose services.
# Exits 0 if all enabled tests pass; exits 1 on any failure.
#
# Usage:
#   ./docker-test.sh                             # auto-detect everything
#   ./docker-test.sh --image ghcr.io/owner/repo --version v1.2.11
#   ./docker-test.sh --cmd "python app.py --version"
#   ./docker-test.sh --no-gpu
#   ./docker-test.sh --compose-file path/to/compose.yml
#   ./docker-test.sh --gpu-only                  # test GPU image only
#   ./docker-test.sh --compose-only              # test compose only

set -euo pipefail

# ── Parse flags ───────────────────────────────────────────────────────────
IMAGE=""
VERSION=""
SMOKE_CMD=""
NO_GPU=false
GPU_ONLY=false
COMPOSE_ONLY=false
COMPOSE_FILE=""
TIMEOUT=30

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)        IMAGE="$2";       shift 2 ;;
        --version)      VERSION="$2";     shift 2 ;;
        --cmd)          SMOKE_CMD="$2";   shift 2 ;;
        --no-gpu)       NO_GPU=true;      shift ;;
        --gpu-only)     GPU_ONLY=true;    shift ;;
        --compose-only) COMPOSE_ONLY=true; shift ;;
        --compose-file) COMPOSE_FILE="$2"; shift 2 ;;
        --timeout)      TIMEOUT="$2";     shift 2 ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

echo "=== docker-test ==="
echo ""

# ── Detect version ─────────────────────────────────────────────────────────
if [[ -z "$VERSION" ]]; then
    if [[ -f "VERSION" ]]; then
        VERSION=$(tr -d '[:space:]' < VERSION)
        [[ "$VERSION" != v* ]] && VERSION="v${VERSION}"
    elif git rev-parse --git-dir &>/dev/null; then
        VERSION=$(git describe --tags --abbrev=0 2>/dev/null || true)
    fi
fi
if [[ -z "$VERSION" ]]; then
    echo "[ERROR] Cannot detect version. Pass --version vX.Y.Z"
    exit 1
fi

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
        echo "[ERROR] Cannot infer image name. Pass --image ghcr.io/owner/repo"
        exit 1
    fi
    IMAGE="ghcr.io/${REPO_PATH,,}"
fi

echo "  Image   : $IMAGE"
echo "  Version : $VERSION"
echo ""

FAILED=false

# ── Helper: run container with timeout ────────────────────────────────────
run_container() {
    local tag="$1"
    local extra_flags="${2:-}"
    local cmd="${3:-}"

    local run_args="--rm --timeout ${TIMEOUT}"

    # docker run doesn't have a --timeout; use `timeout` command wrapper
    if [[ -n "$cmd" ]]; then
        if timeout "$TIMEOUT" docker run --rm $extra_flags "$tag" $cmd; then
            return 0
        else
            return 1
        fi
    else
        if timeout "$TIMEOUT" docker run --rm $extra_flags "$tag"; then
            return 0
        else
            local code=$?
            # Exit code 0 from the container is pass; non-zero is fail
            # But the container may legitimately exit 0 with no output (e.g. --version)
            return $code
        fi
    fi
}

# ── CPU test ───────────────────────────────────────────────────────────────
if ! $GPU_ONLY && ! $COMPOSE_ONLY; then
    echo "--- CPU test ---"
    CPU_TAG="${IMAGE}:${VERSION}"
    echo "  Tag: $CPU_TAG"

    # Check image exists locally or can be pulled
    if ! docker image inspect "$CPU_TAG" &>/dev/null; then
        echo "  [INFO] Image not found locally — pulling"
        docker pull "$CPU_TAG"
    fi

    if run_container "$CPU_TAG" "" "$SMOKE_CMD"; then
        echo "  [PASS] CPU container started and exited 0"
    else
        echo "  [FAIL] CPU container failed or timed out"
        FAILED=true
    fi
    echo ""
fi

# ── GPU test ───────────────────────────────────────────────────────────────
if ! $NO_GPU && ! $COMPOSE_ONLY; then
    GPU_TAG="${IMAGE}:${VERSION}-gpu"

    # Check if GPU runtime is available on this host
    if ! docker info 2>/dev/null | grep -q "nvidia"; then
        if ! $GPU_ONLY; then
            echo "--- GPU test ---"
            echo "  [SKIP] nvidia-container-toolkit not detected on host"
            echo ""
        else
            echo "--- GPU test ---"
            echo "  [SKIP] nvidia-container-toolkit not detected — install nvidia-container-toolkit to enable GPU tests"
            echo ""
        fi
    else
        echo "--- GPU test ---"
        echo "  Tag: $GPU_TAG"

        # Check image exists
        if ! docker image inspect "$GPU_TAG" &>/dev/null; then
            if docker pull "$GPU_TAG" 2>/dev/null; then
                echo "  [INFO] Pulled $GPU_TAG"
            else
                echo "  [SKIP] GPU image not found: $GPU_TAG (not built yet)"
                echo ""
            fi
        fi

        if docker image inspect "$GPU_TAG" &>/dev/null; then
            # Step 1: nvidia-smi check
            if timeout "$TIMEOUT" docker run --rm --gpus all "$GPU_TAG" nvidia-smi &>/dev/null; then
                echo "  [PASS] nvidia-smi: GPU visible inside container"
            else
                echo "  [WARN] nvidia-smi not available in container — skipping GPU visibility check"
            fi

            # Step 2: smoke test
            if run_container "$GPU_TAG" "--gpus all" "$SMOKE_CMD"; then
                echo "  [PASS] GPU container started and exited 0"
            else
                echo "  [FAIL] GPU container failed or timed out"
                FAILED=true
            fi
        fi
        echo ""
    fi
fi

# ── docker-compose test ────────────────────────────────────────────────────
if ! $GPU_ONLY; then
    # Auto-detect compose file if not passed
    if [[ -z "$COMPOSE_FILE" ]]; then
        for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
            if [[ -f "$candidate" ]]; then
                COMPOSE_FILE="$candidate"
                break
            fi
        done
    fi

    if [[ -n "$COMPOSE_FILE" ]]; then
        echo "--- docker-compose test ---"
        echo "  File: $COMPOSE_FILE"

        # Check if --wait is supported (compose v2.1+)
        WAIT_FLAG=""
        if docker compose up --help 2>&1 | grep -q -- "--wait"; then
            WAIT_FLAG="--wait"
        fi

        # Bring up services
        if docker compose -f "$COMPOSE_FILE" up -d $WAIT_FLAG; then
            # Give services a moment if --wait not supported
            [[ -z "$WAIT_FLAG" ]] && sleep 5

            # Check service states
            COMPOSE_STATUS=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null || \
                             docker compose -f "$COMPOSE_FILE" ps)

            SERVICE_FAIL=false
            while IFS= read -r svc_line; do
                if echo "$svc_line" | grep -qiE "(exit|error|stop|dead)"; then
                    echo "  [FAIL] Service issue: $svc_line"
                    SERVICE_FAIL=true
                elif echo "$svc_line" | grep -qiE "(running|healthy|started)"; then
                    SVC_NAME=$(echo "$svc_line" | awk '{print $1}')
                    echo "  [PASS] $SVC_NAME: running/healthy"
                fi
            done <<< "$COMPOSE_STATUS"

            if $SERVICE_FAIL; then
                FAILED=true
            fi

            # Tear down
            docker compose -f "$COMPOSE_FILE" down --remove-orphans
        else
            echo "  [FAIL] docker compose up failed"
            docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
            FAILED=true
        fi
        echo ""
    elif $COMPOSE_ONLY; then
        echo "--- docker-compose test ---"
        echo "  [WARN] No compose file found. Pass --compose-file <path>"
        echo ""
    fi
fi

# ── Result ─────────────────────────────────────────────────────────────────
if $FAILED; then
    echo "=== docker-test FAILED ==="
    exit 1
else
    echo "=== docker-test PASSED ==="
fi
