# python-ci-template

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Source:** archive session (pattern detected 8x)

## Description
Generates a standardised Python CI workflow: ruff + black lint, pytest with coverage,
and secret scanning. Used across htb-canvas, Slice-N-Dice, bgp_rogue, DNSResolver, and others.

Invoke when: adding CI to a Python repo, or when asked to create a GitHub Actions workflow
for a Python project.

## Context needed
- Python version support (default matrix: 3.9, 3.10, 3.11, 3.12)
- Whether the project has a test suite (`tests/` dir or `pytest` in dependencies)
- Whether coverage upload is needed (requires `CODECOV_TOKEN` secret)
- Whether the project is Jython-only (skip modern linters)

## What to do

Write `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install ruff black
      - run: ruff check .
      - run: black --check .

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -e ".[dev]"
      - run: pytest --cov --cov-report=xml
      - uses: codecov/codecov-action@v4
        if: matrix.python-version == '3.12'
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

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

Adjust the version matrix and omit `codecov` if not needed.

## Variant selection

Three templates are available — pick the one that matches the project:

| Template | When to use |
|----------|-------------|
| `ci.yml` (above) | Project has `pyproject.toml` with `[project.optional-dependencies]` dev group; test suite exists |
| `ci-requirements-only.yml` | Dependencies in `requirements.txt`; test suite exists |
| `ci-no-tests.yml` | No test suite yet — lint + secret scan only |

Copy the chosen template to `.github/workflows/ci.yml` in the target project.

## Jython exception

Jython projects (e.g. Burp Suite extensions compiled against Jython) must **not** use
ruff or black. Neither tool supports Jython-compatible Python syntax, and ruff will
raise `SyntaxError` on Jython-only constructs. For Jython projects:

1. Skip the lint job entirely, or replace it with `pycodestyle` or a manual review note
2. Keep the secret-scan job — gitleaks is language-agnostic
3. For the test job: Jython projects typically can't run under CPython; omit pytest
4. A minimal Jython CI is just secret-scan:

```yaml
# .github/workflows/ci.yml (Jython — no lint, no pytest)
name: CI
on: [push, pull_request]
jobs:
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

## Gotchas
- `burps` (Jython Burp extension) — do not add ruff/black; use Jython-only config above
- Coverage upload requires `CODECOV_TOKEN` set as a GitHub Actions secret
- Some projects use `requirements.txt` rather than `pyproject.toml` — use `ci-requirements-only.yml`
- Pylint `too-many-locals` and unused import errors will fail CI if not pre-fixed — run `check-ci-ready.sh` locally before pushing

## Suggested scripts
- `check-ci-ready.sh` — runs ruff and black locally, mirrors the lint job exactly
- `ci-no-tests.yml` — variant for projects without a test suite
- `ci-requirements-only.yml` — variant for `requirements.txt`-only projects
