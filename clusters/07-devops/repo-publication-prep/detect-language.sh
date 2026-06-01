#!/usr/bin/env bash
# detect-language.sh
# Infers the primary programming language of a repo from file extensions
# and outputs the appropriate pre-commit hook recommendations.
#
# Outputs one of: python | dotnet | go | shell | c | mixed | unknown
#
# Usage: bash detect-language.sh [repo_path]
#   repo_path  (optional) path to repo; defaults to current directory

set -euo pipefail

REPO="${1:-.}"

cd "$REPO"

# Count files by language group (exclude .git and common non-code dirs)
py=$(find . -not -path "*/.git/*" -not -path "*/node_modules/*" -name "*.py" | wc -l | tr -d ' ')
cs=$(find . -not -path "*/.git/*" -name "*.cs" | wc -l | tr -d ' ')
fsproj=$(find . -not -path "*/.git/*" \( -name "*.csproj" -o -name "*.sln" -o -name "*.fsproj" \) | wc -l | tr -d ' ')
go=$(find . -not -path "*/.git/*" -name "*.go" | wc -l | tr -d ' ')
sh=$(find . -not -path "*/.git/*" \( -name "*.sh" -o -name "*.bash" \) | wc -l | tr -d ' ')
c_cpp=$(find . -not -path "*/.git/*" \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) | wc -l | tr -d ' ')
tf=$(find . -not -path "*/.git/*" -name "*.tf" | wc -l | tr -d ' ')

dotnet=$(( cs + fsproj ))

# Determine primary language
candidates=0
primary="unknown"

[ "$py" -gt 0 ]     && candidates=$(( candidates + 1 )) && primary="python"
[ "$dotnet" -gt 0 ] && candidates=$(( candidates + 1 )) && primary="dotnet"
[ "$go" -gt 0 ]     && candidates=$(( candidates + 1 )) && primary="go"
[ "$sh" -gt 0 ]     && candidates=$(( candidates + 1 )) && primary="shell"
[ "$c_cpp" -gt 0 ]  && candidates=$(( candidates + 1 )) && primary="c"
[ "$tf" -gt 0 ]     && candidates=$(( candidates + 1 )) && primary="terraform"

[ "$candidates" -ge 2 ] && primary="mixed"

echo "=== Language detection: $REPO ==="
echo ""
echo "  .py files   : $py"
echo "  .cs/.sln    : $dotnet"
echo "  .go files   : $go"
echo "  .sh files   : $sh"
echo "  .c/.cpp/.h  : $c_cpp"
echo "  .tf files   : $tf"
echo ""
echo "  Primary language: $primary"
echo ""

echo "=== Recommended .pre-commit-config.yaml hooks ==="
echo ""

# Always include gitleaks
cat <<'YAML'
repos:
  # Secret scanning — always include
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.24.3
    hooks:
      - id: gitleaks
YAML

case "$primary" in
  python)
    cat <<'YAML'

  # Python linting and formatting
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.10
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/psf/black
    rev: 25.1.0
    hooks:
      - id: black
YAML
    ;;
  dotnet)
    cat <<'YAML'

  # .NET formatting (local hook — requires dotnet SDK)
  - repo: local
    hooks:
      - id: dotnet-format
        name: dotnet format
        language: system
        entry: dotnet format --verify-no-changes
        pass_filenames: false
        types_or: [c#, file]
YAML
    ;;
  go)
    cat <<'YAML'

  # Go formatting and vetting
  - repo: https://github.com/dnephin/pre-commit-golang
    rev: v0.5.1
    hooks:
      - id: go-fmt
      - id: go-vet
YAML
    ;;
  shell)
    cat <<'YAML'

  # Shell script linting
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.10.0.1
    hooks:
      - id: shellcheck
YAML
    ;;
  c)
    cat <<'YAML'

  # C/C++ formatting
  - repo: https://github.com/pocc/pre-commit-clang-tools
    rev: v1.4.5
    hooks:
      - id: clang-format
        args: [--style=Microsoft]
YAML
    ;;
  terraform)
    cat <<'YAML'

  # Terraform formatting and validation
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.99.4
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
YAML
    ;;
  mixed)
    echo "  # Mixed language project — combine hooks from relevant language sections above."
    ;;
  unknown)
    echo "  # Language unknown — add language-appropriate hooks manually."
    ;;
esac

echo ""
echo "NOTE: Pin hook versions explicitly. Run 'pre-commit autoupdate' to refresh."
if [ "$py" -gt 0 ]; then
  echo "NOTE: For Jython projects, skip ruff/black — use only gitleaks."
fi
