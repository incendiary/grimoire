# test-bootstrap

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 05-technical

## Description
Adds a unit test layer to a project that has none, or fills gaps in one that has partial
coverage. Detects the language and existing test infrastructure, recommends a framework
if none is present, generates failing test stubs for the target code, and wires the
runner into CI.

Invoke when: asked to "add tests", "write unit tests for X", "set up testing", or
"what tests should this have" — or proactively when reviewing a PR that touches
logic with no test coverage.

## Context needed
- Language / runtime (Python, C#, TypeScript, Go, Bash)
- The file, module, class, or function to test — or "the whole project"
- Whether a test framework is already present (check `pyproject.toml`, `*.csproj`,
  `package.json`, `go.mod`, `.bats` files before asking)
- Whether CI already has a test stage

## Framework selection table

| Language | Default framework | Runner command | Coverage tool | When to deviate |
|---|---|---|---|---|
| Python | `pytest` | `pytest` | `pytest-cov` | `unittest` if already present and working |
| C# | `xUnit` | `dotnet test` | `coverlet` (built-in with SDK) | `NUnit`/`MSTest` if already in solution |
| TypeScript / JS | `Vitest` | `vitest run` | built-in (`--coverage`) | `Jest` if already configured |
| Go | stdlib `testing` | `go test ./...` | `go test -cover` | No deviation — stdlib is always right |
| Bash | `bats-core` | `bats tests/` | N/A | Only if scripts are complex enough to warrant it |

Never introduce a second framework alongside an existing one. Detect first, then match.

## Workflow

```
1. Audit existing test infrastructure
        ↓
2. Choose / confirm framework (document choice in a comment or README note)
        ↓
3. Install framework if missing (pyproject.toml / *.csproj / package.json)
        ↓
4. Generate test stubs — failing red tests first
        ↓
5. Run tests → confirm they fail for the right reason (not import errors)
        ↓
6. Implement tests properly — cover: happy path, boundary, error/exception cases
        ↓
7. Run tests → confirm green
        ↓
8. Wire runner into CI if not already present
        ↓
9. Report coverage summary
```

## Step 1 — Audit existing test infrastructure

```bash
# Python
find . -name "pytest.ini" -o -name "pyproject.toml" | xargs grep -l "pytest" 2>/dev/null
find . -name "test_*.py" -o -name "*_test.py" | head -5

# C#
find . -name "*.csproj" | xargs grep -l "xUnit\|NUnit\|MSTest" 2>/dev/null

# TypeScript / JS
cat package.json | grep -E '"test"|vitest|jest' 2>/dev/null

# Go
find . -name "*_test.go" | head -5

# Bash
find . -name "*.bats" | head -5
```

## Step 2 — Install framework (if missing)

**Python (pytest):**
```toml
# pyproject.toml — add to [tool.pytest.ini_options] and [project.optional-dependencies]
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"

[project.optional-dependencies]
test = ["pytest", "pytest-cov"]
```
```bash
pip install -e ".[test]"   # or: uv add --dev pytest pytest-cov
```

**C# (xUnit):**
```bash
dotnet new xunit -n ProjectName.Tests -o tests/ProjectName.Tests
dotnet sln add tests/ProjectName.Tests/ProjectName.Tests.csproj
# Add project reference in the test .csproj:
# <ProjectReference Include="../../src/ProjectName/ProjectName.csproj" />
```

**TypeScript (Vitest):**
```bash
npm install --save-dev vitest @vitest/coverage-v8
# Add to package.json:
# "test": "vitest run",
# "test:coverage": "vitest run --coverage"
```

**Go:** No install needed — `testing` is in the stdlib.

**Bash (bats-core):**
```bash
# Via git submodule (preferred for portability):
git submodule add https://github.com/bats-core/bats-core tests/bats
mkdir -p tests
```

## Step 3 — Generate test stubs

Write the minimal failing test first. This proves the test harness is wired correctly
before investing in real assertions.

**Python stub:**
```python
# tests/test_<module>.py
import pytest
from mypackage.module import MyClass, my_function

class TestMyFunction:
    def test_happy_path(self):
        result = my_function("valid_input")
        assert result == "expected_output"   # TODO: fill in

    def test_returns_none_on_empty_input(self):
        assert my_function("") is None

    def test_raises_on_invalid_type(self):
        with pytest.raises(TypeError):
            my_function(123)
```

**C# stub (xUnit):**
```csharp
// tests/ProjectName.Tests/MyClassTests.cs
using Xunit;
using ProjectName;

public class MyClassTests
{
    [Fact]
    public void HappyPath_ReturnsExpected()
    {
        var sut = new MyClass();
        var result = sut.MyMethod("valid");
        Assert.Equal("expected", result);
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void EmptyOrNull_ThrowsArgumentException(string input)
    {
        var sut = new MyClass();
        Assert.Throws<ArgumentException>(() => sut.MyMethod(input));
    }
}
```

**TypeScript stub (Vitest):**
```typescript
// tests/myModule.test.ts
import { describe, it, expect } from "vitest";
import { myFunction } from "../src/myModule";

describe("myFunction", () => {
    it("returns expected value for valid input", () => {
        expect(myFunction("valid")).toBe("expected");
    });

    it("returns null for empty string", () => {
        expect(myFunction("")).toBeNull();
    });

    it("throws on non-string input", () => {
        expect(() => myFunction(123 as any)).toThrow(TypeError);
    });
});
```

**Go stub:**
```go
// pkg/mypackage/myfunction_test.go
package mypackage_test

import (
    "testing"
    "myproject/pkg/mypackage"
)

func TestMyFunction_HappyPath(t *testing.T) {
    got := mypackage.MyFunction("valid")
    want := "expected"
    if got != want {
        t.Errorf("MyFunction(%q) = %q; want %q", "valid", got, want)
    }
}

func TestMyFunction_EmptyInput(t *testing.T) {
    got := mypackage.MyFunction("")
    if got != "" {
        t.Errorf("expected empty string, got %q", got)
    }
}
```

**Bash stub (bats):**
```bash
#!/usr/bin/env bats
# tests/my_script.bats

setup() {
    load "bats/load"
    source ./my_script.sh
}

@test "my_function returns 0 on valid input" {
    run my_function "valid"
    [ "$status" -eq 0 ]
}

@test "my_function prints expected output" {
    run my_function "hello"
    [ "$output" = "hello world" ]
}

@test "my_function fails on missing arg" {
    run my_function
    [ "$status" -ne 0 ]
}
```

## Step 4 — What cases to cover

For every function/method, cover these categories:

| Category | Description | Example |
|---|---|---|
| Happy path | Valid input, expected output | `add(2, 3) == 5` |
| Boundary | Edge values, empty, zero, max | `add(0, 0) == 0` |
| Error / exception | Invalid input raises the right error | `add("x", 1) raises TypeError` |
| State | Object state before/after mutating call | `list.add(x)` → `len == 1` |
| Integration | Two components working together | Only when unit tests are insufficient |

**Aim for:** every public function/method has at minimum a happy path and one error case.
Coverage % is a proxy — 80% is a reasonable floor, not a goal.

## Step 5 — Wire into CI

**GitHub Actions (Python):**
```yaml
# .github/workflows/test.yml
- name: Run tests
  run: |
    pip install -e ".[test]"
    pytest
```

**GitHub Actions (C#):**
```yaml
- name: Run tests
  run: dotnet test --no-build --verbosity normal
```

**GitHub Actions (TypeScript):**
```yaml
- name: Run tests
  run: npm ci && npm test
```

**GitHub Actions (Go):**
```yaml
- name: Run tests
  run: go test ./... -coverprofile=coverage.out
```

If a CI workflow already exists, add the test step before the build/publish step —
tests must gate the pipeline.

## Gotchas

- **Don't test private internals.** Test the public API; refactor internals freely without
  breaking tests.
- **One assertion per test** (ideally). A test that checks 5 things tells you something
  failed but not what.
- **Test file location convention matters.** Python: `tests/` at root. Go: same package,
  `_test.go` suffix. C#: separate project in `tests/`. Vitest: `src/` or `tests/` — pick
  one and configure in `vitest.config.ts`.
- **Mocking external dependencies.** Don't let unit tests hit real databases, APIs, or
  filesystems. Use `pytest-mock` / `unittest.mock` (Python), `Moq` (C#), `vi.mock` (Vitest).
- **Virtual environments.** Always install test deps in a venv / `uv` env — never system-wide.
- **C# test discovery.** Test classes must be `public` and test methods decorated with
  `[Fact]` or `[Theory]`. Forgetting `public` causes silent test skipping.
- **Go table tests.** For multiple input cases in Go, use table-driven tests rather than
  writing a separate function per case.

## Related skills

- `python-ci-template` — full Python CI pipeline including test stage
- `dotnet-ci-template` — full C# CI pipeline including `dotnet test`
- `test-before-asking` — workflow: run existing tests before raising questions
- `format-before-commit` — pair with test-bootstrap to enforce formatting + tests pre-commit
- `pre-commit-aware-commits` — add a test-run hook to `.pre-commit-config.yaml`
