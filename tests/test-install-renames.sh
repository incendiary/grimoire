#!/usr/bin/env bash
# test-install-renames.sh — install-all.sh --update removes renamed/retired skills and backs them up.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "${TMP_HOME}"' EXIT
SKILLS="${TMP_HOME}/.claude/skills"

# Pre-seed: one renamed, one merged, one retired skill, plus the hook-driven skill
# (present already, so its install.sh hook wiring is not triggered in this sandbox).
for old in karpathy-spec local-ci test-before-asking session-skill-extractor; do
    mkdir -p "${SKILLS}/${old}" && echo "old" > "${SKILLS}/${old}/SKILL.md"
done

HOME="${TMP_HOME}" bash "${REPO}/install-all.sh" --update >/dev/null

fail() { echo "FAIL: $*"; exit 1; }
for old in karpathy-spec local-ci test-before-asking; do
    [[ ! -d "${SKILLS}/${old}" ]] || fail "${old} still installed"
    [[ -n "$(ls -A "${SKILLS}/.backups/${old}" 2>/dev/null)" ]] || fail "${old} not backed up"
done
for new in plan-spec ci-local session-skill-extractor; do
    [[ -f "${SKILLS}/${new}/SKILL.md" ]] || fail "${new} not installed"
done
grep -q '^name: plan-spec$' "${SKILLS}/plan-spec/SKILL.md" || fail "plan-spec has wrong frontmatter name"
echo "PASS: renamed and retired skills removed with backups; new names installed"
