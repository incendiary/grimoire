# dotnet-ci-template

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Source:** archive session (pattern detected 5x)

## Description
Generates a standardised .NET CI workflow: build, test, format check, and secret scanning.
Used across WindowsServiceTemplate, QueuserAPC, IncendiaryService, EarlyWorm, csharp-shellcode-runner.

Invoke when: adding CI to a C# or .NET repo, or when asked to create a GitHub Actions
workflow for a .NET project.

## Context needed
- Target framework (`net6.0`, `net8.0`, or multi-target)
- Whether the project has a test project (look for `*.Tests.csproj` or `xunit`/`nunit` references)
- Whether the build is Windows-only (some BOF/WinAPI projects must use `windows-latest`)

## What to do

Write `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: windows-latest   # change to ubuntu-latest for cross-platform projects
    strategy:
      matrix:
        configuration: [Debug, Release]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: "8.0.x"   # adjust to target framework
      - run: dotnet restore
      - run: dotnet build --configuration ${{ matrix.configuration }} --no-restore
      - run: dotnet test --configuration ${{ matrix.configuration }} --no-build
        if: hashFiles('**/*.Tests.csproj') != ''
      - run: dotnet format --verify-no-changes
        if: matrix.configuration == 'Debug'

  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

For projects without a test suite, omit the `dotnet test` step rather than failing CI.

## Variant selection

| Template | When to use |
|----------|-------------|
| `ci-windows-only.yml` | WinAPI, BOF, P-Invoke, shellcode projects — must compile on Windows |
| `ci-cross-platform.yml` | Class libraries, CLI tools — no Windows-specific namespaces |

Copy the chosen template to `.github/workflows/ci.yml` in the target project.

## net6.0 → net8.0 upgrade path

`net6.0` reached end-of-life in November 2024. When adding CI to a project still targeting
`net6.0`, flag it for upgrade before the CI workflow is merged:

1. **Update `TargetFramework` in `.csproj`:**
   ```xml
   <!-- Before -->
   <TargetFramework>net6.0</TargetFramework>
   <!-- After -->
   <TargetFramework>net8.0</TargetFramework>
   ```

2. **Update `global.json` if present:**
   ```json
   { "sdk": { "version": "8.0.x", "rollForward": "latestMinor" } }
   ```

3. **Pin .NET version in CI template:**
   ```yaml
   - uses: actions/setup-dotnet@v4
     with:
       dotnet-version: "8.0.x"
   ```

4. **Check NuGet package compatibility:** some packages have separate net6/net8 releases.
   Run `dotnet restore` and verify no `NU1201` incompatibility warnings.

5. **Run tests locally on net8.0 before pushing the CI change.**

For multi-target projects (`net6.0;net8.0`), keep both targets temporarily and remove
`net6.0` once the net8.0 build and tests are confirmed green.

## Gotchas
- SDK glob patterns (`**/*.csproj`) can accidentally sweep test project files into the main project — check `.csproj` includes explicitly
- `xUnit` packages may need explicit restore if not in the solution file
- `dotnet format --verify-no-changes` will fail if the code was not formatted locally first — run `format-check.sh` before committing
- BOF templates and WinAPI-heavy projects require `windows-latest`; cross-platform libraries can use `ubuntu-latest`
- `net6.0` is EOL — flag any projects still targeting it for upgrade to `net8.0` (see upgrade path above)

## Suggested scripts
- `format-check.sh` — runs `dotnet format --verify-no-changes` locally; auto-detects `.sln` or `.csproj`
- `ci-windows-only.yml` — template for WinAPI/BOF projects
- `ci-cross-platform.yml` — template for library/cross-platform projects
