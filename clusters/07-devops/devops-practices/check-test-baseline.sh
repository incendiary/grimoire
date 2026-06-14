#!/bin/sh
# check-test-baseline.sh — Verifies a repo meets minimum testing standards.
# Usage: bash check-test-baseline.sh [repo-root]
# Exit: 0 = compliant, 1 = gaps found
set -e

REPO_ROOT="${1:-.}"
cd "$REPO_ROOT"

PASS=0
FAIL=0

check_pass() {
  echo "✓ $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo "✗ $1"
  FAIL=$((FAIL + 1))
}

echo "Checking test baseline for: $(basename "$(pwd)")"
echo ""

# --- 1. CI workflow exists ---
if [ -d .github/workflows ]; then
  CI_FILES=$(find .github/workflows -name '*.yml' -o -name '*.yaml' 2>/dev/null)
  if [ -n "$CI_FILES" ]; then
    # Check if any workflow has a test step
    if grep -rlq 'test\|pytest\|vitest\|jest\|dotnet test\|go test\|cargo test' .github/workflows/ 2>/dev/null; then
      check_pass "CI workflow with test step found"
    else
      check_fail "CI workflows exist but no test step detected"
    fi
  else
    check_fail "No CI workflow files found in .github/workflows/"
  fi
else
  check_fail "No .github/workflows/ directory"
fi

# --- 2. VERSION file exists ---
if [ -f VERSION ]; then
  check_pass "VERSION file present"
else
  check_fail "No VERSION file at repo root"
fi

# --- 3. Version-sync test exists ---
# Look for a test that compares VERSION to git tag
VERSION_TEST_FOUND=false
for pattern in 'VERSION.*tag\|tag.*VERSION' 'version.*sync\|sync.*version' 'describe.*tags.*VERSION\|VERSION.*describe.*tags'; do
  if grep -rlq "$pattern" tests/ test/ spec/ __tests__/ .github/workflows/ 2>/dev/null; then
    VERSION_TEST_FOUND=true
    break
  fi
done
if [ "$VERSION_TEST_FOUND" = true ]; then
  check_pass "Version-sync test found"
else
  check_fail "No version-sync test found (VERSION == git tag)"
fi

# --- 4. Clone-ref pinning test or enforcement ---
CLONE_TEST_FOUND=false
if grep -rlq '@main\|@master\|clone.*ref\|pin.*version' tests/ test/ .github/workflows/ 2>/dev/null; then
  CLONE_TEST_FOUND=true
fi
# Also check if readme-version-pin scripts are present
if [ -f scripts/check_readme_version.sh ] || find .github/workflows/ -name '*version-pin*' -print -quit 2>/dev/null | grep -q .; then
  CLONE_TEST_FOUND=true
fi
if [ "$CLONE_TEST_FOUND" = true ]; then
  check_pass "Clone-ref pinning check found"
else
  check_fail "No clone-ref pinning test found (no @main in docs)"
fi

# --- 5. Scheduled CI (periodic test runs) ---
if grep -rlq 'schedule:\|cron:' .github/workflows/ 2>/dev/null; then
  check_pass "Scheduled CI found (periodic test runs)"
else
  check_fail "No scheduled CI — tests only run on PR/push"
fi

# --- Summary ---
echo ""
echo "Result: $PASS passed, $FAIL failed"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "Run 'devops-practices' skill to address gaps."
  exit 1
fi

exit 0
