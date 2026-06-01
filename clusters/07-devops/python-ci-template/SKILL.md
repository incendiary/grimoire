# python-ci-template

> **Status:** promoted
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

## Gotchas
- `burps` is Jython-only — do not add ruff/black; use a manual lint step or skip
- Coverage upload requires `CODECOV_TOKEN` set as a GitHub Actions secret
- Some projects use `requirements.txt` rather than a `pyproject.toml` — adjust the install step accordingly
- Pylint `too-many-locals` and unused import errors will fail CI if not pre-fixed — run locally before pushing

## Suggested scripts
- `check-ci-ready.sh` — runs ruff and black locally, reports any failures before push
