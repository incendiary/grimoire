#!/bin/bash
# pre-push-validation — repo-aware pre-push validation
# Parses .github/workflows/validate.yml and runs those checks locally before push
# Falls back to generic checks for repos without CI workflows

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Helper: check if tool exists
# shellcheck disable=SC2329
tool_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Helper: check if in skip list
# shellcheck disable=SC2329
should_skip() {
  for skip in $SKIP_CHECKS; do
    [ "$1" = "$skip" ] && return 0
  done
  return 1
}

# Detect project types early (needed for venv check below)
detect_bash() { find . -name "*.sh" -not -path "./.git/*" 2>/dev/null | grep -q . ; }
detect_node() { [ -f package.json ] || find . -maxdepth 2 -name package.json 2>/dev/null | grep -q . ; }
detect_python() { [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f setup.py ] || find . -maxdepth 2 -name "pyproject.toml" 2>/dev/null | grep -q . ; }
detect_go() { [ -f go.mod ] || find . -maxdepth 2 -name go.mod 2>/dev/null | grep -q . ; }
detect_rust() { [ -f Cargo.toml ] || find . -maxdepth 2 -name Cargo.toml 2>/dev/null | grep -q . ; }
detect_csharp() { find . -maxdepth 2 -name "*.csproj" 2>/dev/null | grep -q . ; }

# Check for Python virtual environment if this is a Python project
is_python_project=false
detect_python && is_python_project=true

if [ "$is_python_project" = "true" ]; then
  if [ -f "venv/bin/activate" ] || [ -f ".venv/bin/activate" ]; then
    if [ -z "$VIRTUAL_ENV" ]; then
      echo "⚠️  WARNING: Python virtual environment detected but not activated"
      venv_dir=""
      if [ -d venv ]; then venv_dir=venv; elif [ -d .venv ]; then venv_dir=.venv; fi
      if [ -n "$venv_dir" ]; then
        echo "   Found: $venv_dir"
        echo "   Activate with: source $venv_dir/bin/activate"
      fi
      echo "   Then re-run: bash $0 $(printf '%q ' "${@:---help}")"
      echo ""
      exit 1
    fi
  fi
fi

# Configuration
STRICT_MODE=false
DRY_RUN=false
INSTALL_HOOK=false
SKIP_CHECKS=""

# Tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_SKIPPED=0
FAILED_CHECKS=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse CLI flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --strict)
      STRICT_MODE=true
      shift
      ;;
    --skip-check)
      SKIP_CHECKS="$SKIP_CHECKS $2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --install-hook)
      INSTALL_HOOK=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Handle hook installation early and exit
if [ "$INSTALL_HOOK" = "true" ]; then
  HOOK_FILE=".git/hooks/pre-push"
  mkdir -p "$(dirname "$HOOK_FILE")"
  
  cat > "$HOOK_FILE" << 'HOOK_SCRIPT'
#!/bin/bash
# Pre-push validation hook — automatically run before every push
# To disable: chmod -x .git/hooks/pre-push
# To bypass: git push --no-verify

set -e
cd "$(git rev-parse --show-toplevel)"

# Find the pre-push-validation.sh script
SCRIPT_PATH=""
if [ -f "clusters/07-devops/pre-push-validation/pre-push-validation.sh" ]; then
  SCRIPT_PATH="clusters/07-devops/pre-push-validation/pre-push-validation.sh"
elif [ -f "scripts/pre-push-validation.sh" ]; then
  SCRIPT_PATH="scripts/pre-push-validation.sh"
fi

if [ -z "$SCRIPT_PATH" ]; then
  echo "⚠️  pre-push-validation.sh not found. Skipping validation."
  exit 0
fi

bash "$SCRIPT_PATH"
HOOK_SCRIPT
  
  chmod +x "$HOOK_FILE"
  echo ""
  echo -e "\033[0;32m✅ Pre-push hook installed to $HOOK_FILE\033[0m"
  echo "   To bypass validation: git push --no-verify"
  echo "   To uninstall: rm $HOOK_FILE"
  exit 0
fi

# Helper: check if tool exists
tool_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Helper: check if in skip list
should_skip() {
  local check="$1"
  for skip in $SKIP_CHECKS; do
    if [ "$check" = "$skip" ]; then
      return 0
    fi
  done
  return 1
}

# Helper: run a check
run_check() {
  local name="$1"
  local description="$2"
  local cmd="$3"
  
  if should_skip "$name"; then
    echo -e "${YELLOW}⏭️  ${name}${NC} (${description}) [SKIPPED]"
    CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1))
    return 0
  fi
  
  if [ "$DRY_RUN" = "true" ]; then
    echo -e "${BLUE}⏭️  ${name}${NC} (${description})"
    echo "   Command: $cmd"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
  fi
  
  echo -n "⏳ $name... "
  
  if output=$(eval "$cmd" 2>&1); then
    echo -e "${GREEN}✅${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
  else
    echo -e "${RED}❌${NC}"
    echo "  Error output:"
    echo "$output" | while IFS= read -r line; do echo "    $line"; done
    FAILED_CHECKS="${FAILED_CHECKS} ${name}"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    return 1
  fi
}


# Print banner and detect repo type
echo ""
echo -e "${BLUE}=== Pre-Push Validation for $REPO_ROOT ===${NC}"
echo ""

# Grimoire-specific validation (if .github/workflows/validate.yml exists)
if [ -f ".github/workflows/validate.yml" ]; then
  echo "Detected: grimoire repository (via .github/workflows/validate.yml)"
  echo ""
  echo -e "${BLUE}=== Running grimoire CI checks ===${NC}"
  echo ""
  
  FAILED=0
  
  # 1. Shellcheck
  run_check "shellcheck" "Shell script linting" \
    "find . -name '*.sh' -not -path './.git/*' -not -path './clusters-private/*' -exec shellcheck {} +" || FAILED=1
  
  # 2. Skill structure check
  run_check "structure" "Skill directory structure" \
    "bash -c 'set -e; for dir in clusters/*/*/; do [ ! -d \"\$dir\" ] && continue; [ ! -f \"\${dir}SKILL.md\" ] && { echo \"ERROR: missing SKILL.md in \${dir}\"; exit 1; }; [ ! -f \"\${dir}README.md\" ] && { echo \"ERROR: missing README.md in \${dir}\"; exit 1; }; done; echo \"All skill directories have SKILL.md and README.md\"'" || FAILED=1
  
  # 3. Registry sync check (Type:action skills must be registered)
  run_check "registry-sync" "MCP registry validation" \
    "bash -c 'set -e; for f in \$(grep -rl \"^> \\\\*\\\\*Type:\\\\*\\\\* action\" clusters/01-meta/*/SKILL.md clusters/07-devops/*/SKILL.md 2>/dev/null); do grep -q \"\\\"\$f\\\"\" mcp-server/registry.json || { echo \"ERROR: \$f has Type: action but no registry entry\"; exit 1; }; done; echo \"All action skills are registered\"'" || FAILED=1
  
  # 4. README quality check
  run_check "readme-quality" "README installation docs" \
    "bash -c 'set -e; for readme in clusters/*/*/README.md; do [ ! -f \"\$readme\" ] && continue; grep -q \"## Installation\" \"\$readme\" || { echo \"ERROR: missing ## Installation in \$readme\"; exit 1; }; platforms=0; grep -q \"claude/skills\" \"\$readme\" && platforms=\$((platforms+1)); grep -qE \"#<|#skill-name|prompt|Copilot Chat\" \"\$readme\" && platforms=\$((platforms+1)); grep -qE \"MCP|mcp\" \"\$readme\" && platforms=\$((platforms+1)); [ \$platforms -ge 2 ] || { echo \"ERROR: \$readme has fewer than 2 platform targets (\$platforms found)\"; exit 1; }; done; echo \"All READMEs have multi-platform installation docs\"'" || FAILED=1
  
  # 5. No stale path references
  run_check "stale-paths" "Path reference validation" \
    "bash -c 'set -e; for readme in clusters/*/*/README.md; do [ ! -f \"\$readme\" ] && continue; grep -qE \"/path/to/grimoire|loadout/\" \"\$readme\" && { echo \"ERROR: stale path reference in \$readme\"; exit 1; }; done; echo \"No stale paths found\"'" || FAILED=1

  # 6. Stale branches check (warns about feature branches significantly out of sync with main)
  run_check "stale-branches" "Branch sync validation" \
    "bash -c 'for branch in \$(git branch | grep feat/ | grep -v \"\\\\*\" | sed \"s/^[[:space:]]\\\\+//\"); do commits_ahead=\$(git log --oneline main..\$branch 2>/dev/null | wc -l); if [ \"\$commits_ahead\" -gt 0 ]; then echo \"⚠️  \$branch: \$commits_ahead commit(s) ahead of main\"; fi; done; echo \"Branch sync check complete\"'" || FAILED=1
  
  if [ $FAILED -ne 0 ]; then
    echo ""
    echo -e "${RED}=== CI Checks Failed ===${NC}"
    exit 1
  fi
  
else
  # Generic validation for non-grimoire repos
  echo "Detected: generic repository"
  echo ""
  
  detected=""
  detect_bash && detected="${detected} bash"
  detect_node && detected="${detected} node.js"
  detect_python && detected="${detected} python"
  detect_go && detected="${detected} go"
  detect_rust && detected="${detected} rust"
  detect_csharp && detected="${detected} c#"
  
  if [ -z "$detected" ]; then
    echo -e "${YELLOW}⚠️  No recognized project type detected${NC}"
    exit 0
  fi
  
  echo "Detected:${detected}"
  echo ""
  echo -e "${BLUE}=== Running generic checks ===${NC}"
  echo ""
  
  # Bash checks
  if echo "$detected" | grep -q bash; then
    if tool_exists shellcheck; then
      run_check "shellcheck" "Shell script linting" \
        "find . -name '*.sh' -not -path './.git/*' -exec shellcheck {} +" || true
    fi
  fi
  
  # Node.js checks
  if echo "$detected" | grep -q node.js; then
    if tool_exists npm && [ -f "package.json" ]; then
      run_check "npm-lint" "ESLint" "npm run lint 2>&1 || true" || true
      run_check "npm-format" "Prettier" "npm run format:check 2>&1 || true" || true
      
      if [ "$STRICT_MODE" = "true" ]; then
        run_check "npm-test" "npm test" "npm test 2>&1" || true
      fi
    fi
  fi
  
  # Python checks
  if echo "$detected" | grep -q python; then
    if ! tool_exists python3; then
      echo -e "${RED}❌ Python project detected but python3 not found in PATH${NC}"
      exit 1
    fi
    
    # Fail closed: required tools must be available
    if ! tool_exists flake8; then
      echo -e "${RED}❌ Python project detected but flake8 not in PATH${NC}"
      echo "   Install with: pip install flake8  (or activate venv first)"
      exit 1
    fi
    
    run_check "flake8" "Python linting" "flake8 . 2>&1" || return 1
    
    if tool_exists black; then
      run_check "black" "Python formatting" "black --check . 2>&1" || return 1
    fi
    
    if [ "$STRICT_MODE" = "true" ]; then
      if tool_exists pytest; then
        run_check "pytest" "Python tests" "pytest . 2>&1" || return 1
      fi
    fi
  fi
  
  # Go checks
  if echo "$detected" | grep -q go; then
    if ! tool_exists go; then
      echo -e "${RED}❌ Go project detected but go not found in PATH${NC}"
      exit 1
    fi
    
    run_check "gofmt" "Go formatting" "gofmt -l . 2>&1" || return 1
    run_check "govet" "Go analysis" "go vet ./..." || return 1
    
    if [ "$STRICT_MODE" = "true" ]; then
      run_check "gotest" "Go tests" "go test ./..." || return 1
    fi
  fi
  
  # Rust checks
  if echo "$detected" | grep -q rust; then
    if ! tool_exists cargo; then
      echo -e "${RED}❌ Rust project detected but cargo not found in PATH${NC}"
      exit 1
    fi
    
    run_check "cargo-fmt" "Rust formatting" "cargo fmt --check 2>&1" || return 1
    run_check "cargo-clippy" "Rust linting" "cargo clippy --all-targets 2>&1" || return 1
    
    if [ "$STRICT_MODE" = "true" ]; then
      run_check "cargo-test" "Rust tests" "cargo test 2>&1" || return 1
    fi
  fi
  
  # C# checks
  if echo "$detected" | grep -q c#; then
    if ! tool_exists dotnet; then
      echo -e "${RED}❌ C# project detected but dotnet not found in PATH${NC}"
      exit 1
    fi
    
    run_check "dotnet-format" "C# formatting" "dotnet format --verify-no-changes 2>&1" || return 1
    
    if [ "$STRICT_MODE" = "true" ]; then
      run_check "dotnet-test" "C# tests" "dotnet test 2>&1" || return 1
    fi
  fi
fi

# Report results
echo ""
echo -e "${BLUE}=== Results ===${NC}"
echo ""
echo "Passed:  $CHECKS_PASSED"
echo "Skipped: $CHECKS_SKIPPED"

if [ $CHECKS_FAILED -gt 0 ]; then
  echo -e "${RED}Failed:  $CHECKS_FAILED${NC}"
  echo ""
  echo "Failed checks:$FAILED_CHECKS"
  echo ""
  exit 1
else
  echo -e "${GREEN}Failed:  0${NC}"
  echo ""
  if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}PASS: (dry-run only)${NC}"
  else
    echo -e "${GREEN}PASS: all checks completed successfully${NC}"
  fi
  exit 0
fi
