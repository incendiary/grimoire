# npm-provenance-attestation

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-08

Verifies npm package provenance: Sigstore-backed attestations that link each published
package to its source repository, CI workflow, and commit SHA. Complements
`npm-lockfile-integrity` — integrity hashes confirm a package's content hasn't changed
since the lockfile was written; provenance confirms where the package came from and who
built it. Extracted from a supply chain attack discussion covering the xz-utils and
event-stream threat models.

---

## What this skill does

Establishes a two-layer verification workflow:

1. **`npm audit signatures`** — batch verification of cryptographic signatures for all
   installed packages; reports missing vs. invalid vs. verified
2. **`npm view dist.attestations`** — per-package provenance check for critical dependencies;
   validates `sourceRepositoryURI`, `buildTrigger`, and `runInvocationURI`

`check-provenance.sh` automates the batch check, classifies results, and optionally runs
deep provenance inspection for a named list of critical packages.

---

## When to use it

- Adding a new dependency to a project — run before committing the lockfile change
- Security review of an existing Node.js project
- Post-incident triage after a supply chain alert involving an npm package
- Enforcing a policy requiring provenance on critical dependencies

---

## Requirements

- npm ≥ 9.5.0 (provenance verification unavailable below this)
- `node_modules` installed (`npm ci` first)
- Public npm registry access (private registries may not forward Sigstore attestations)

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/npm-provenance-attestation ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#npm-provenance-attestation
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Quick reference

```bash
# Verify signatures for all installed packages
npm audit signatures

# Check provenance for a specific package
npm view <package>@<version> dist.attestations --json

# Run the full check (all packages + critical list)
bash check-provenance.sh

# Check specific critical packages
bash check-provenance.sh --critical express,jsonwebtoken,axios

# Strict mode: exit 1 on missing signatures as well as failures
bash check-provenance.sh --strict
```

---

## Provenance classification

| Finding | Meaning | Action |
|---------|---------|--------|
| Signed + provenance, repo matches | Best case | Accept |
| Signed, no provenance | Pre-2023 publish | Accept for established packages |
| Provenance repo mismatch | Suspicious | Investigate |
| Signature verification failed | Potentially compromised | Do not install |
| No signature, recent package | Unusual publish path | Flag for review |

---

## Pairs with

`npm-lockfile-integrity` — run both for full supply chain coverage:
- Lockfile integrity: content hasn't changed since the lockfile was written
- Provenance attestation: content came from the claimed source

---

## CI integration

Add to `.github/workflows/npm-provenance-gate.yml`:

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

**`.npm-critical-packages`** (optional, one package per line):
```
# Packages to deep-check for provenance
express
jsonwebtoken
axios
```

**What each step catches:**
- `npm audit signatures` — fails on invalid/missing signatures; exit 0 with a summary for unsigned packages
- Critical package check — logs provenance chain for packages you've flagged as high-risk dependencies

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `check-provenance.sh` — batch signature audit + critical package provenance check
- [x] Add GitHub Actions workflow snippet for provenance gating
- [ ] Test on 3 Node.js repos with mixed provenance coverage
- [x] Ship: copy to `~/.claude/skills/npm-provenance-attestation/`
