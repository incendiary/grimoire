#!/usr/bin/env bash
# check-python-lockfile-integrity.sh
# Audits a Python project for dependency content-hash enforcement.
# Supports pip-tools (requirements.txt --hash), poetry (poetry.lock),
# pipenv (Pipfile.lock), and uv (uv.lock).
#
# Checks performed:
#   1. Toolchain detection — which lockfile system(s) are present
#   2. Lockfile presence — lockfile exists for each detected tool
#   3. Hash coverage — hashes present in each lockfile (tool-specific)
#   4. CI pipeline audit — bare pip install usage without --require-hashes
#   5. pip version (pip-tools path only) — pip >= 8 required for hash enforcement
#
# Usage:
#   ./check-python-lockfile-integrity.sh                    # audit current directory
#   ./check-python-lockfile-integrity.sh /path/to/project   # audit specific project
#   ./check-python-lockfile-integrity.sh --strict           # exit 1 on warnings too

set -euo pipefail

# ── Arguments ────────────────────────────────────────────────────────────────
PROJECT_DIR="."
STRICT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict) STRICT=true; shift ;;
        -*)       echo "Unknown option: $1" >&2; exit 1 ;;
        *)        PROJECT_DIR="$1"; shift ;;
    esac
done

PASS=0
WARN=0
FAIL=0

echo "=== python-lockfile-integrity ==="
echo "  Project : $(realpath "$PROJECT_DIR")"
echo ""

# ── Helpers ──────────────────────────────────────────────────────────────────
pass() { echo "  [PASS] $1"; (( PASS++ )) || true; }
warn() { echo "  [WARN] $1"; (( WARN++ )) || true; }
fail() { echo "  [FAIL] $1"; (( FAIL++ )) || true; }
info() { echo "  [INFO] $1"; }

# ── 1. Toolchain detection ────────────────────────────────────────────────────
echo "--- Toolchain detection ---"
echo ""

HAS_UV=false
HAS_PIPENV=false
HAS_POETRY=false
HAS_PIPTOOLS=false

if [[ -f "$PROJECT_DIR/uv.lock" ]]; then
    HAS_UV=true
    info "Detected: uv (uv.lock found)"
fi

if [[ -f "$PROJECT_DIR/Pipfile.lock" ]] || [[ -f "$PROJECT_DIR/Pipfile" ]]; then
    HAS_PIPENV=true
    info "Detected: pipenv (Pipfile or Pipfile.lock found)"
fi

if [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
    if grep -q "\[tool\.poetry\]" "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
        HAS_POETRY=true
        info "Detected: poetry ([tool.poetry] in pyproject.toml)"
    fi
fi

# requirements*.txt — check for any matching files
REQ_FILES=()
while IFS= read -r f; do
    REQ_FILES+=("$f")
done < <(find "$PROJECT_DIR" -maxdepth 2 -name "requirements*.txt" 2>/dev/null | sort)

if [[ ${#REQ_FILES[@]} -gt 0 ]]; then
    HAS_PIPTOOLS=true
    info "Detected: pip/pip-tools (${#REQ_FILES[@]} requirements*.txt file(s))"
fi

echo ""

if ! $HAS_UV && ! $HAS_PIPENV && ! $HAS_POETRY && ! $HAS_PIPTOOLS; then
    fail "No Python lockfile toolchain detected in $PROJECT_DIR"
    echo ""
    echo "  Expected one or more of:"
    echo "    uv.lock               → uv"
    echo "    Pipfile / Pipfile.lock → pipenv"
    echo "    pyproject.toml with [tool.poetry] → poetry"
    echo "    requirements*.txt     → pip-tools"
    echo ""
    echo "=== python-lockfile-integrity — FAILED ==="
    exit 1
fi

# ── 2 & 3. Per-toolchain lockfile presence and hash coverage ─────────────────

# ── uv ───────────────────────────────────────────────────────────────────────
if $HAS_UV; then
    echo "--- uv ---"
    echo ""

    pass "uv.lock found"

    # uv.lock uses TOML-like format; hashes appear as:
    #   wheels = [{ url = "...", hash = "sha256:..." }]
    # or in sdist blocks. Use grep to spot-check.
    HASH_COUNT=$(grep -c 'hash = "sha256:' "$PROJECT_DIR/uv.lock" 2>/dev/null || echo "0")
    info "sha256 hash entries in uv.lock: $HASH_COUNT"

    if [[ "$HASH_COUNT" -eq 0 ]]; then
        warn "No sha256 hashes found in uv.lock — unexpected for a standard uv project"
        echo "         uv generates hashes by default. This may indicate an unusual lockfile."
        echo "         Regenerate: uv lock"
    else
        pass "uv.lock contains sha256 hashes ($HASH_COUNT entries)"
    fi

    echo "  Enforcement command: uv sync --frozen"
    echo "  (uv sync without --frozen may update the lockfile in CI)"
    echo ""
fi

# ── pipenv ───────────────────────────────────────────────────────────────────
if $HAS_PIPENV; then
    echo "--- pipenv ---"
    echo ""

    if [[ ! -f "$PROJECT_DIR/Pipfile.lock" ]]; then
        fail "Pipfile found but Pipfile.lock is missing"
        echo "         Remediation: pipenv lock"
        echo "         Then commit: git add Pipfile.lock"
        echo ""
    else
        pass "Pipfile.lock found"

        if ! command -v python3 &>/dev/null; then
            warn "python3 not found — skipping Pipfile.lock hash coverage check"
        else
            PIPENV_REPORT=$(python3 - "$PROJECT_DIR/Pipfile.lock" <<'PYEOF'
import json, sys

lockfile_path = sys.argv[1]
try:
    data = json.load(open(lockfile_path))
except Exception as e:
    print(f"ERROR={e}")
    sys.exit(0)

missing = []
total = 0

# Pipfile.lock has "default" and "develop" sections
for section in ("default", "develop"):
    packages = data.get(section, {})
    for name, info in packages.items():
        total += 1
        hashes = info.get("hashes", [])
        if not hashes:
            missing.append(f"{section}/{name}")

print(f"TOTAL={total}")
print(f"MISSING={len(missing)}")
for m in missing[:20]:
    print(f"PKG={m}")
if len(missing) > 20:
    print(f"TRUNCATED={len(missing) - 20}")
PYEOF
)

            if echo "$PIPENV_REPORT" | grep -q "^ERROR="; then
                fail "Could not parse Pipfile.lock — file may be malformed"
            else
                TOTAL=$(echo "$PIPENV_REPORT" | grep "^TOTAL=" | cut -d= -f2)
                MISSING_COUNT=$(echo "$PIPENV_REPORT" | grep "^MISSING=" | cut -d= -f2)
                TRUNCATED=$(echo "$PIPENV_REPORT" | grep "^TRUNCATED=" | cut -d= -f2 || echo "0")

                info "Total packages in Pipfile.lock: $TOTAL"

                if [[ "$MISSING_COUNT" -eq 0 ]]; then
                    pass "All $TOTAL packages have hashes in Pipfile.lock"
                else
                    fail "$MISSING_COUNT of $TOTAL packages are missing hashes in Pipfile.lock"
                    while IFS= read -r line; do
                        if [[ "$line" == PKG=* ]]; then
                            echo "    ${line#PKG=}"
                        fi
                    done <<< "$PIPENV_REPORT"
                    if [[ "$TRUNCATED" -gt 0 ]]; then
                        echo "    ... and $TRUNCATED more"
                    fi
                    echo ""
                    echo "  Remediation: pipenv lock (regenerates all hashes)"
                fi
            fi
        fi

        echo "  Enforcement command: pipenv install --deploy"
        echo "  (pipenv install without --deploy may ignore the lockfile)"
        echo ""
    fi
fi

# ── poetry ───────────────────────────────────────────────────────────────────
if $HAS_POETRY; then
    echo "--- poetry ---"
    echo ""

    if [[ ! -f "$PROJECT_DIR/poetry.lock" ]]; then
        fail "pyproject.toml has [tool.poetry] but poetry.lock is missing"
        echo "         Remediation: poetry lock"
        echo "         Then commit: git add poetry.lock"
        echo ""
    else
        pass "poetry.lock found"

        # poetry.lock is TOML; each package has a [[package]] section and a
        # [package.source] or files list with hash = "sha256:..." entries.
        # git/path dependencies won't have registry hashes — acceptable, flag as info.
        HASH_COUNT=$(grep -c 'hash = "sha256:' "$PROJECT_DIR/poetry.lock" 2>/dev/null || echo "0")
        PKG_COUNT=$(grep -c '^\[\[package\]\]' "$PROJECT_DIR/poetry.lock" 2>/dev/null || echo "0")

        info "Packages in poetry.lock: $PKG_COUNT"
        info "sha256 hash entries: $HASH_COUNT"

        if [[ "$HASH_COUNT" -eq 0 ]]; then
            warn "No sha256 hashes found in poetry.lock"
            echo "         This is unexpected for a standard poetry project."
            echo "         Possible causes: all deps are git/path deps, or old poetry version."
            echo "         Regenerate: poetry lock --no-update"
        else
            pass "poetry.lock contains sha256 hashes ($HASH_COUNT entries across $PKG_COUNT packages)"
            if [[ "$PKG_COUNT" -gt 0 ]] && [[ "$HASH_COUNT" -lt "$PKG_COUNT" ]]; then
                info "Some packages have fewer hash entries than others — normal for git/path deps"
            fi
        fi

        echo "  Enforcement command: poetry install"
        echo "  (poetry install verifies hashes automatically)"
        echo ""
    fi
fi

# ── pip-tools ────────────────────────────────────────────────────────────────
if $HAS_PIPTOOLS; then
    echo "--- pip-tools (requirements.txt) ---"
    echo ""

    if [[ ${#REQ_FILES[@]} -eq 0 ]]; then
        fail "No requirements*.txt files found"
        echo ""
    else
        info "${#REQ_FILES[@]} requirements file(s) found:"
        for f in "${REQ_FILES[@]}"; do
            echo "    $f"
        done
        echo ""

        FILES_WITH_HASHES=0
        FILES_WITHOUT_HASHES=0

        for req_file in "${REQ_FILES[@]}"; do
            # Count package lines (non-empty, non-comment, non-option lines)
            # and hash-annotated lines
            if ! command -v python3 &>/dev/null; then
                warn "python3 not found — skipping hash coverage check for $req_file"
                continue
            fi

            REQ_REPORT=$(python3 - "$req_file" <<'PYEOF'
import sys, re

req_file = sys.argv[1]
lines = open(req_file).readlines()

total_pkgs = 0
pkgs_with_hash = 0
current_pkg_has_hash = False
current_pkg = None

for line in lines:
    stripped = line.strip()
    # Skip comments and blank lines
    if not stripped or stripped.startswith('#'):
        continue
    # Hash continuation line
    if stripped.startswith('--hash='):
        current_pkg_has_hash = True
        continue
    # Option lines (-r, -c, --index-url, etc.) — not packages
    if stripped.startswith('-'):
        continue
    # New package line (may have \ continuation)
    if current_pkg is not None:
        total_pkgs += 1
        if current_pkg_has_hash:
            pkgs_with_hash += 1
    current_pkg = stripped.rstrip('\\').strip()
    current_pkg_has_hash = False

# Last package
if current_pkg is not None:
    total_pkgs += 1
    if current_pkg_has_hash:
        pkgs_with_hash += 1

print(f"TOTAL={total_pkgs}")
print(f"WITH_HASH={pkgs_with_hash}")
PYEOF
)

            TOTAL=$(echo "$REQ_REPORT" | grep "^TOTAL=" | cut -d= -f2)
            WITH_HASH=$(echo "$REQ_REPORT" | grep "^WITH_HASH=" | cut -d= -f2)

            REL_PATH="${req_file#"$PROJECT_DIR/"}"
            info "$REL_PATH: $WITH_HASH/$TOTAL packages have --hash annotations"

            if [[ "$TOTAL" -eq 0 ]]; then
                warn "$REL_PATH: no packages found — file may be empty or all comments"
            elif [[ "$WITH_HASH" -eq 0 ]]; then
                fail "$REL_PATH: no --hash annotations found — bare version pinning only"
                echo "         Remediation:"
                echo "           pip-compile --generate-hashes ${REL_PATH%.txt}.in"
                echo "           (or regenerate: pip-compile --generate-hashes $REL_PATH)"
                echo "         Enforcement: pip install --require-hashes -r $REL_PATH"
                (( FILES_WITHOUT_HASHES++ )) || true
            elif [[ "$WITH_HASH" -lt "$TOTAL" ]]; then
                warn "$REL_PATH: $((TOTAL - WITH_HASH)) package(s) missing --hash annotations"
                echo "         Regenerate with: pip-compile --generate-hashes"
                (( FILES_WITHOUT_HASHES++ )) || true
            else
                pass "$REL_PATH: all $TOTAL packages have --hash annotations"
                (( FILES_WITH_HASHES++ )) || true
            fi
        done

        echo ""
        echo "  Enforcement command: pip install --require-hashes -r requirements.txt"
        echo "  WARNING: pip install -r requirements.txt does NOT verify hashes even"
        echo "  if --hash annotations are present. The --require-hashes flag is mandatory."
        echo ""

        # pip version check
        if command -v pip &>/dev/null; then
            PIP_VERSION=$(pip --version 2>/dev/null | grep -o '[0-9]*\.[0-9]*' | head -1 || echo "0.0")
            PIP_MAJOR=$(echo "$PIP_VERSION" | cut -d. -f1)
            info "pip version: $(pip --version 2>/dev/null | head -1)"

            if [[ "$PIP_MAJOR" -lt 8 ]]; then
                fail "pip $PIP_VERSION is below 8.0 — --require-hashes is not supported"
                echo "         Upgrade: pip install --upgrade pip"
            elif [[ "$PIP_MAJOR" -lt 22 ]]; then
                warn "pip $PIP_VERSION — upgrade to pip >= 22 for improved hash verification"
                echo "         Upgrade: pip install --upgrade pip"
            else
                pass "pip $PIP_VERSION supports --require-hashes"
            fi
        else
            warn "pip not found on PATH — cannot verify pip version"
        fi
        echo ""
    fi
fi

# ── 4. CI enforcement audit ───────────────────────────────────────────────────
echo "--- CI pipeline audit ---"
echo ""

CI_FILES=()
while IFS= read -r f; do
    CI_FILES+=("$f")
done < <(find "$PROJECT_DIR" \
    \( -name "*.yml" -o -name "*.yaml" \) \
    | grep -E "(\.github/workflows|\.gitlab-ci|\.circleci)" \
    | head -20 2>/dev/null || true)

if [[ ${#CI_FILES[@]} -eq 0 ]]; then
    info "No CI workflow files found — skipping"
else
    info "${#CI_FILES[@]} CI file(s) found"
    echo ""

    BARE_PIP_FILES=()
    UV_NO_FROZEN_FILES=()

    for f in "${CI_FILES[@]}"; do
        # Check for bare pip install without --require-hashes
        # Use grep -n to get context; look for pip install lines that lack --require-hashes
        if grep -q "pip install" "$f" 2>/dev/null; then
            # Check if any pip install line lacks --require-hashes
            while IFS= read -r line; do
                if echo "$line" | grep -q "pip install" && \
                   ! echo "$line" | grep -q "\-\-require-hashes" && \
                   ! echo "$line" | grep -q "pip install pip" && \
                   ! echo "$line" | grep -q "pip install pip-" && \
                   ! echo "$line" | grep -q "pip install --upgrade pip"; then
                    BARE_PIP_FILES+=("$f")
                    break
                fi
            done < <(grep "pip install" "$f" 2>/dev/null)
        fi

        # Check for uv sync without --frozen or --locked
        if grep -q "uv sync" "$f" 2>/dev/null; then
            while IFS= read -r line; do
                if echo "$line" | grep -q "uv sync" && \
                   ! echo "$line" | grep -q "\-\-frozen" && \
                   ! echo "$line" | grep -q "\-\-locked"; then
                    UV_NO_FROZEN_FILES+=("$f")
                    break
                fi
            done < <(grep "uv sync" "$f" 2>/dev/null)
        fi
    done

    if [[ ${#BARE_PIP_FILES[@]} -gt 0 ]]; then
        fail "${#BARE_PIP_FILES[@]} CI file(s) use 'pip install' without --require-hashes:"
        for f in "${BARE_PIP_FILES[@]}"; do
            echo "    $f"
        done
        echo ""
        echo "  Remediation: replace 'pip install -r requirements.txt' with"
        echo "    'pip install --require-hashes -r requirements.txt'"
        echo "  Or switch to poetry install / pipenv install --deploy / uv sync --frozen"
    else
        pass "No CI files use bare 'pip install' without --require-hashes"
    fi
    echo ""

    if [[ ${#UV_NO_FROZEN_FILES[@]} -gt 0 ]]; then
        warn "${#UV_NO_FROZEN_FILES[@]} CI file(s) use 'uv sync' without --frozen/--locked:"
        for f in "${UV_NO_FROZEN_FILES[@]}"; do
            echo "    $f"
        done
        echo "         'uv sync' without --frozen may update uv.lock in CI."
        echo "         Use: uv sync --frozen"
    fi
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "--- Summary ---"
echo ""
echo "  Passed:   $PASS"
echo "  Warnings: $WARN"
echo "  Failed:   $FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo "=== python-lockfile-integrity — FAILED ($FAIL check(s)) ==="
    exit 1
elif $STRICT && [[ "$WARN" -gt 0 ]]; then
    echo "=== python-lockfile-integrity — FAILED in --strict mode ($WARN warning(s)) ==="
    exit 1
else
    echo "=== python-lockfile-integrity complete ==="
fi
