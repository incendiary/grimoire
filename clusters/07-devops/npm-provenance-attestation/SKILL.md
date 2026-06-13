# npm-provenance-attestation

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional

## Description
Verifies npm package provenance attestations — Sigstore-backed build transparency records
that link a published package to its source repository, CI workflow, and commit SHA.
Flags packages with invalid, missing, or suspicious provenance, and distinguishes between
"no provenance" (published before npm 9.5.0 support) and "provenance verification failed"
(potentially compromised).

Invoke when: evaluating a new dependency before adding it; performing a supply chain security
review of an existing project; investigating a suspicious package or maintainer account
compromise; enforcing a policy that critical dependencies must have provenance attestations.

## Context needed
- npm version (provenance verification requires ≥ 9.5.0)
- `node_modules` must be installed (`npm ci` first — provenance checks against installed packages)
- A list of high-criticality packages to prioritise, if any
- Whether the project uses a private registry (Sigstore attestations are registry-specific)

## What to do

1. **Verify npm version supports provenance.**

   ```bash
   npm --version   # need ≥ 9.5.0
   ```

   If below 9.5.0, provenance verification is unavailable. Fall back to `npm-lockfile-integrity`
   as the primary control — lockfile `sha512` hashes remain valid regardless of npm version.

   If above 9.5.0, continue.

2. **Run `npm audit signatures` — verifies all installed packages.**

   ```bash
   npm audit signatures
   ```

   This command fetches the npm registry's public keys and verifies the cryptographic
   signature on every package in `node_modules`. It reports:
   - **Verified**: signature valid
   - **Missing**: package was published without a signature (common for pre-2023 packages)
   - **Invalid**: signature verification failed — treat as potentially compromised

   A clean run shows no output. Any finding is printed with the package name and version.

3. **Check provenance for critical dependencies.**

   For each high-value dependency (auth libraries, crypto, infrastructure SDKs):

   ```bash
   npm view <package>@<version> dist.attestations --json
   ```

   From the output, verify:
   - `predicateType` contains `slsa-provenance` or `npm-publish-provenance`
   - `sourceRepositoryURI` matches the expected GitHub/GitLab repository URL
   - `buildTrigger` is `push` or a CI event — not `manual` (manual local publishes are
     a red flag for packages that claim to be CI-built)
   - `runInvocationURI` points to a real CI run URL that matches the repository

   If `dist.attestations` is null or absent: the package has no provenance attestation.
   This is expected for packages published before npm 9.5.0 introduced provenance (2023).
   It is not suspicious for established packages; it is a yellow flag for anything newly
   published or recently updated under new maintainership.

4. **Classify findings and decide next action.**

   | State | Meaning | Action |
   |-------|---------|--------|
   | Signed + provenance, all fields match | Best case | Accept |
   | Signed, no provenance | Published before provenance support | Accept for established packages; flag for new/updated |
   | Signature present but provenance `sourceRepositoryURI` doesn't match claimed repo | Mismatch | Investigate before installing |
   | Signature verification failed | Content or signature tampered | Do not install; raise with team |
   | No signature at all on a recently-published package | Unusual publish path | Flag for review |

## Gotchas

- **`npm audit signatures` only checks `node_modules`.** Run `npm ci` first. An empty
  `node_modules` will produce no output — not a clean result.

- **Absence of provenance is expected for pre-2023 packages.** lodash, express, moment,
  and most established packages were published before npm provenance support. Absence alone
  is not suspicious. Compare the package's publish date against 2023-04 (when npm 9.5.0
  shipped) to contextualise missing provenance.

- **Provenance attestations are opt-in for publishers.** Even post-2023, publishers must
  explicitly pass `--provenance` to `npm publish`. Many legitimate publishers haven't
  adopted it yet. Use provenance as a signal, not a binary gate, unless your policy requires it.

- **Private registries (Verdaccio, Artifactory, GitHub Packages private) do not forward
  Sigstore attestations.** If your project proxies through a private registry, `npm audit
  signatures` may report missing signatures for all packages — even ones that have public
  attestations. Verify directly against the public registry for those packages.

- **`npm audit signatures` and `npm audit` are separate commands.**
  - `npm audit` → known CVEs (advisory database)
  - `npm audit signatures` → cryptographic signature verification
  Run both; neither replaces the other.

- **Sigstore's Rekor transparency log is append-only.** A valid attestation today was
  valid at publish time and will remain verifiable indefinitely. A package with an
  attestation claiming a `sourceRepositoryURI` that doesn't exist or doesn't contain
  that package's code is a strong indicator of a compromised publish.

## Suggested scripts
- `check-provenance.sh` — runs `npm audit signatures`, parses results by category
  (verified/missing/failed), checks provenance details for named critical packages,
  and reports PASS/FAIL with actionable findings
