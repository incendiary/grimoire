# deps-integrity

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-10-09

Checks dependency supply-chain integrity: npm and Python lockfile hashes (pip-tools, poetry,
pipenv, uv) and npm Sigstore provenance attestations. Version pinning alone does not prevent
a compromised or republished package at the same version number; content hashes enforced by
the right install command, plus signed provenance, are the correct controls. Merges three former
npm lockfile, Python lockfile and npm provenance skills.

---

## What this skill does

Three checks, one script each:

1. **Node lockfile** (`check-lockfile-integrity.sh`): `npm ci` mandate, `sha512` integrity
   coverage, lockfile version (v1/sha1 flagged), drift gate, `npm audit --audit-level=high`.
2. **Python lockfile** (`check-python-lockfile-integrity.sh`): detects the toolchain, verifies
   hash coverage, audits CI for bare `pip install`. Covers pip-tools (`--require-hashes`),
   poetry (`poetry install`), pipenv (`--deploy`) and uv (`--frozen`).
3. **npm provenance** (`check-provenance.sh`): `npm audit signatures` over installed packages
   and `dist.attestations` inspection for named critical packages.

Lockfile PRs are treated as reviewed artefacts: version unchanged with hash changed is a red flag.

---

## When to use it

- Setting up CI for a Node or Python project
- Auditing an existing project's dependency verification posture
- Post-incident review after a supply chain alert involving an npm or PyPI package
- Reviewing a PR that modifies a lockfile
- Vetting a new npm dependency before adding it

---

## Quick reference

```bash
# Node lockfile coverage
bash check-lockfile-integrity.sh

# Python lockfile coverage (optional path, --strict exits 1 on warnings)
bash check-python-lockfile-integrity.sh [/path/to/project] [--strict]

# npm provenance (run npm ci first; npm >= 9.5.0)
bash check-provenance.sh [--critical express,jsonwebtoken,axios] [--strict]

# Enforcement commands for CI
npm ci && git diff --exit-code package-lock.json
pip install --require-hashes -r requirements.txt
poetry install
pipenv install --deploy
uv sync --frozen
```

| Toolchain | Lockfile | Hashes built-in? | Enforcement command |
|-----------|----------|-----------------|---------------------|
| npm | `package-lock.json` | Yes (sha512, lockfile v2/v3) | `npm ci` |
| pip-tools | `requirements.txt` (needs `--generate-hashes`) | No, must opt in | `pip install --require-hashes -r requirements.txt` |
| poetry | `poetry.lock` | Yes | `poetry install` |
| pipenv | `Pipfile.lock` | Yes | `pipenv install --deploy` |
| uv | `uv.lock` | Yes | `uv sync --frozen` |

| Provenance finding | Meaning | Action |
|---------|---------|--------|
| Signed + provenance, repo matches | Best case | Accept |
| Signed, no provenance | Pre-2023 publish | Accept for established packages |
| Provenance repo mismatch | Suspicious | Investigate |
| Signature verification failed | Potentially compromised | Do not install |
| No signature, recent package | Unusual publish path | Flag for review |

---

## Workflow

```
Node project:   check-lockfile-integrity.sh -> fix gaps -> npm ci in CI -> drift gate -> npm audit
Python project: check-python-lockfile-integrity.sh -> fix gaps -> hash-enforcing install in CI -> drift gate -> pip-audit
New npm dep:    npm ci -> check-provenance.sh -> classify findings
```

---

## CI integration

Node lockfile (`.github/workflows/npm-lockfile-audit.yml`):

```yaml
name: npm lockfile integrity
on:
  push:
    paths: ["package-lock.json", "package.json"]
  pull_request:
    paths: ["package-lock.json", "package.json"]

jobs:
  lockfile-integrity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install with integrity enforcement
        run: npm ci

      - name: Audit for known vulnerabilities
        run: npm audit --audit-level=high

      - name: Check lockfile is not dirty after install
        run: git diff --exit-code package-lock.json
```

Provenance gate (`.github/workflows/npm-provenance-gate.yml`):

```yaml
name: npm provenance attestation
on:
  push:
    paths: ["package-lock.json", "package.json"]
  pull_request:
    paths: ["package-lock.json", "package.json"]

jobs:
  provenance-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Audit package signatures
        run: npm audit signatures

      - name: Check provenance for critical packages
        if: hashFiles('.npm-critical-packages') != ''
        run: |
          while IFS= read -r pkg; do
            [[ -z "$pkg" || "$pkg" == "#"* ]] && continue
            echo "--- $pkg ---"
            npm view "$pkg" dist.attestations --json 2>/dev/null || echo "No attestation data"
          done < .npm-critical-packages
```

`.npm-critical-packages` (optional, one package per line, `#` for comments) lists packages
to deep-check, for example `express`, `jsonwebtoken`, `axios`.

---

## Requirements

- Provenance: npm >= 9.5.0, `node_modules` installed (`npm ci` first), public registry
  access (private registries may not forward Sigstore attestations)

---

## What it won't do

- Verify PyPI publisher identity (PEP 740 attestations are too nascent to be actionable)
- Detect known CVEs: use `npm audit` or `pip-audit` for that (separate concern)
- Auto-remediate hash gaps: regeneration requires human review of the diff

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] `check-lockfile-integrity.sh`, `check-python-lockfile-integrity.sh` and `check-provenance.sh` shipped
