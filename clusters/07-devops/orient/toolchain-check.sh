#!/usr/bin/env bash
# toolchain-check.sh — read-only check that the local toolchain can run this repo.
# Usage: bash toolchain-check.sh [repo-dir]   (always exits 0; prints PASS / WARN lines)
set -uo pipefail

cd "${1:-.}" || exit 0
pass() { echo "PASS  $*"; }
warn() { echo "WARN  $*"; }

# bash: macOS ships 3.2; bash 4 builtins in repo scripts will fail there.
bash_major="${BASH_VERSINFO[0]}"
# Character classes keep this pattern from matching itself.
bash4_hits=$(grep -rlE '^\s*(mapfil[e]|readarra[y])\b|declar[e] -A' --include='*.sh' . \
    --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.claude 2>/dev/null | head -3)
if [[ -n "${bash4_hits}" && "${bash_major}" -lt 4 ]]; then
    warn "bash ${BASH_VERSION}: these scripts need bash 4+: $(echo "${bash4_hits}" | tr '\n' ' ')"
else
    pass "bash ${BASH_VERSION}"
fi

# node: compare the running major version with engines.node and .nvmrc.
pkgs=$(find . -maxdepth 2 -name package.json -not -path '*/node_modules/*' 2>/dev/null)
if [[ -n "${pkgs}" || -f .nvmrc ]]; then
    if ! command -v node >/dev/null 2>&1; then
        warn "node not found, but the repo has package.json or .nvmrc"
    else
        have=$(node -v | sed 's/^v//; s/\..*//')
        for p in ${pkgs}; do
            want=$(sed -n 's/.*"node": *"[^0-9]*\([0-9][0-9]*\).*/\1/p' "${p}" | head -1)
            if [[ -n "${want}" && "${have}" -lt "${want}" ]]; then
                warn "node v${have} is below engines.node ${want} in ${p} (try: nvm use ${want})"
            elif [[ -n "${want}" ]]; then
                pass "node v${have} meets engines.node ${want} in ${p}"
            fi
        done
        if [[ -f .nvmrc ]]; then
            want=$(sed 's/^v//; s/\..*//' .nvmrc)
            if [[ "${have}" == "${want}" ]]; then
                pass "node v${have} matches .nvmrc"
            else
                warn "node v${have} differs from .nvmrc (${want})"
            fi
        fi
    fi
fi

# python: ci-local needs PyYAML to parse workflows; also catch broken pyenv shims.
py=$(command -v python3 || true)
if [[ -z "${py}" ]]; then
    warn "python3 not found"
elif ! python3 --version >/dev/null 2>&1; then
    warn "python3 at ${py} fails to run (broken shim? check pyenv)"
else
    pass "$(python3 --version 2>&1) at ${py}"
    if [[ -d .github/workflows ]] && ! python3 -c 'import yaml' 2>/dev/null; then
        warn "PyYAML missing for ${py}; ci-local cannot parse workflows (use a project venv)"
    fi
fi
if [[ -x "${HOME}/.pyenv/shims/python3" ]] && ! "${HOME}/.pyenv/shims/python3" --version >/dev/null 2>&1; then
    warn "pyenv shim ${HOME}/.pyenv/shims/python3 is broken (pyenv binary missing?)"
fi
exit 0
