---
name: deps-integrity
description: "Checks dependency supply-chain integrity: npm and Python lockfile hashes (pip-tools, poetry, pipenv, uv) and npm Sigstore provenance attestations. Use when setting up CI for a Node or Python project, auditing dependencies after a supply-chain alert, or vetting a new package before adding it."
---
# deps-integrity

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Dependency identity by content hash or signed provenance, across three checks that share
one control family: Node lockfile integrity (`sha512`), Python lockfile integrity
(`sha256`; pip-tools, poetry, pipenv, uv), and npm provenance attestation (Sigstore).
Version pinning alone does not stop a compromised or republished package at the same
version number.

Invoke when: setting up CI for a Node or Python project; auditing a project for supply
chain hygiene; reviewing a dependency change after a supply chain incident or suspicious
package alert; vetting a new package before adding it.

## Which check when

| Situation | Section | Script |
|-----------|---------|--------|
| Node project, CI setup or audit | Node lockfile integrity | `check-lockfile-integrity.sh` |
| Python project, CI setup or audit | Python lockfile integrity | `check-python-lockfile-integrity.sh` |
| New npm dependency, or checking where packages were built | npm provenance attestation | `check-provenance.sh` |
| Mixed Node and Python repo | Run both lockfile checks | both lockfile scripts |

Run the provenance check after `npm ci`; it is complementary to the lockfile check
(hashes prove content is unchanged since the lockfile was written, provenance proves
where it came from). If npm is older than 9.5.0, fall back to the Node lockfile check.

## Node lockfile integrity

### Context needed
- Presence and lockfile version of `package-lock.json` (v1/v2/v3)
- npm version in use locally and in CI
- CI platform (GitHub Actions, GitLab CI, etc.) for enforcement snippet
- Whether the project uses workspaces or a monorepo layout

### What to do
1. **Mandate `npm ci` over `npm install` in all CI pipelines.**

   `npm ci` verifies every package against the `integrity` hash in `package-lock.json`
   before installing. If any hash doesn't match, it exits non-zero and the install fails.
   `npm install` may silently rewrite the lockfile and does not enforce hashes.

   GitHub Actions snippet:
   ```yaml
   - name: Install dependencies
     run: npm ci
   ```

   Never use `npm install` in CI. Treat any pipeline using it as unverified.

2. **Treat `package-lock.json` as a reviewed, committed artefact, not a generated file.**

   Every PR that modifies `package-lock.json` should be reviewed with the same rigour
   as source code changes. The changes to audit:
   - New packages added (inspect the `resolved` URL and `integrity` hash)
   - Existing packages with changed `integrity` values (version unchanged but hash changed
     = the package was republished with different content, treat as a red flag)
   - `lockfileVersion` changes (v1 → v2 is expected on npm upgrade; verify it's intentional)

   Add a PR description note whenever `package-lock.json` changes:
   > "package-lock.json updated: [describe what changed and why]"

3. **Verify all dependencies have `integrity` fields.**

   Packages added with npm < 5 may be missing `integrity` fields entirely. Without them,
   `npm ci` cannot verify content. Run `check-lockfile-integrity.sh` to detect any gaps.

   Packages missing integrity, remediation:
   ```bash
   # Remove node_modules and lockfile, reinstall with current npm to regenerate hashes
   rm -rf node_modules package-lock.json
   npm install
   git diff package-lock.json   # review new hashes before committing
   ```

4. **Gate lockfile drift in CI.**

   After `npm ci`, verify the lockfile was not modified:
   ```bash
   npm ci
   git diff --exit-code package-lock.json
   ```
   If this exits non-zero, the installed packages do not match the committed lockfile —
   investigate before allowing the build to proceed.

5. **Layer `npm audit` as a complementary control, it is a different concern.**

   `npm audit` checks for known CVEs in the dependency graph. `npm ci` + integrity hashes
   check content authenticity. Both are necessary; neither replaces the other.

   ```bash
   npm audit --audit-level=high
   ```
   Gate CI on `--audit-level=high` as a minimum. Accept that some lower-severity findings
   may require a separate triage process.

### Gotchas
- **`npm install` in CI silently breaks integrity enforcement.** Any pipeline step using
  `npm install` is not verifying hashes. Audit all CI workflow files for `npm install`
  and replace with `npm ci`.

- **Integrity hashes are only as trustworthy as when they were written.** If `package-lock.json`
  was committed while a registry-level compromise was already in place, the hash enshrines
  the bad version. This is why lockfile PRs require careful review, not just automated
  `npm audit`.

- **Lockfile v1 uses `sha1` hashes, insufficient.** npm < 7 generates v1 lockfiles with
  `sha1` integrity. Upgrade to npm ≥ 7 to get v2/v3 lockfiles with `sha512`. Verify with:
  ```bash
  node -e "const l=require('./package-lock.json'); console.log('lockfileVersion:', l.lockfileVersion)"
  ```

- **Monorepos with workspaces have separate lockfile sections.** Check integrity coverage
  across all workspace entries, not just the root `dependencies` block.

- **`npm ci` deletes `node_modules` before installing.** This is intentional, it ensures
  a clean install from the lockfile. Do not work around this in CI by caching `node_modules`
  between runs without also verifying the lockfile hash hasn't changed.

- **`resolved` URL changes without hash change = CDN migration, usually safe.** Hash change
  without version change = content change, always investigate.

### Script
- `check-lockfile-integrity.sh`: verifies lockfile exists, checks lockfile version,
  detects packages missing integrity fields, and reports a PASS/FAIL summary with
  actionable remediation steps

## Python lockfile integrity

### Context needed
- Which Python lockfile toolchain the project uses (pip-tools, poetry, pipenv, uv)
- Whether a lockfile is present and committed
- CI platform (GitHub Actions, GitLab CI, etc.) for enforcement snippet

### What to do
#### 1. Choose a hash-enforcing lockfile strategy

Pick one. All four are acceptable; the critical requirement is that content hashes are
present and the enforcement command verifies them on install.

| Toolchain | Lockfile | Hash format | Enforcement command |
|-----------|----------|-------------|---------------------|
| pip-tools | `requirements.txt` (with `--generate-hashes`) | sha256 | `pip install --require-hashes -r requirements.txt` |
| poetry | `poetry.lock` | sha256 (built-in) | `poetry install` |
| pipenv | `Pipfile.lock` | sha256 (built-in) | `pipenv install --deploy` |
| uv | `uv.lock` | sha256 (built-in) | `uv sync --frozen` |

**pip-tools note:** `requirements.txt` without `--generate-hashes` contains only version
pins, not content hashes. Generating a bare requirements file is not equivalent to a
lockfile. Always use `pip-compile --generate-hashes`.

#### 2. Mandate the enforcement command in CI, never bare `pip install`

Replace the anti-pattern with the toolchain-appropriate enforcement command:

**pip-tools:**
```yaml
# WRONG
- run: pip install -r requirements.txt

# RIGHT
- run: pip install --require-hashes -r requirements.txt
```

**poetry:**
```yaml
# WRONG
- run: pip install -r requirements.txt

# RIGHT
- run: poetry install
```

**pipenv:**
```yaml
# WRONG
- run: pipenv install

# RIGHT
- run: pipenv install --deploy
```

**uv:**
```yaml
# WRONG
- run: uv sync

# RIGHT
- run: uv sync --frozen
```

`pip install -r requirements.txt` without `--require-hashes` does NOT verify hashes even
if they are present in the file. The flag is mandatory.

#### 3. Treat the lockfile as a reviewed, committed artefact

Every PR that modifies a lockfile should be reviewed with the same rigour as source code.
Audit these specific changes:

- **New package added**: inspect the sha256 hash; verify the package name is not a typo-squatting
  variant of a well-known package (e.g. `reqeusts` vs `requests`)
- **Version unchanged, hash changed**: a package was republished at the same version with
  different content. This is a red flag, treat as potentially compromised until confirmed otherwise
- **Version bumped, hash changed**: expected; verify the hash against the PyPI release page
- **Lockfile tool version change**: lockfile format may differ; verify the change was intentional

Add a PR description note whenever a lockfile changes:
> "requirements.txt updated: [describe what changed and why]"

#### 4. Gate lockfile drift in CI

After the install step, assert the lockfile was not modified. A drift means the installed
packages do not match what was committed, fail the build.

**pip-tools:**
```yaml
- run: pip install --require-hashes -r requirements.txt
- run: git diff --exit-code requirements.txt
```

**poetry:**
```yaml
- run: poetry install
- run: git diff --exit-code poetry.lock
```

**pipenv:**
```yaml
- run: pipenv install --deploy
# --deploy already fails if Pipfile.lock is out of date
```

**uv:**
```yaml
- run: uv sync --frozen
# --frozen already fails if uv.lock would change
```

#### 5. Layer `pip-audit` as a complementary CVE check

`pip-audit` checks for known CVEs in installed packages. It is a separate concern from
hash integrity, audit checks vulnerability databases; integrity checks content authenticity.
Both are necessary.

```bash
pip install pip-audit
pip-audit -r requirements.txt
# or for poetry/pipenv/uv projects:
pip-audit
```

Gate CI on at minimum a high-severity threshold. Accept that some findings require
a separate triage process.

### Gotchas
- **`pip install -r requirements.txt` does NOT verify hashes** even if hashes are
  present in the file. The `--require-hashes` flag is mandatory. This is the single most
  common misconfiguration.

- **pip-tools `requirements.txt` without `--generate-hashes` has no hashes at all.**
  A version-pinned requirements file (`requests==2.28.0`) is not equivalent to a hash-pinned
  one. Generate with: `pip-compile --generate-hashes requirements.in`

- **Poetry git and path dependencies do not have PyPI hashes.** These are expected to lack
  registry hashes and are not suspicious. The script flags them as informational only.

- **`uv sync` without `--frozen` may silently update `uv.lock` in CI.** Always use
  `--frozen` (or the alias `--locked`) in CI pipelines.

- **`pipenv install` without `--deploy` can ignore the lockfile** in some pipenv versions
  and fall back to resolving from `Pipfile`. Always use `--deploy`.

- **Multiple lockfile systems can coexist in one repo** (e.g. `pyproject.toml` with
  `[tool.poetry]` and a legacy `requirements.txt`). Check all of them, a project may
  be migrating between toolchains and the CI may still use the old one.

- **Hashes are only as trustworthy as when they were written.** If the lockfile was
  committed while a registry-level compromise was already in place, the hash enshrines
  the bad version. This is why lockfile PRs require human review, not just automated checking.

### Script
- `check-python-lockfile-integrity.sh`: detects toolchain(s) in use, verifies hash coverage,
  audits CI pipelines for bare `pip install`, reports PASS/FAIL summary with remediation steps

## npm provenance attestation

### Context needed
- npm version (provenance verification requires ≥ 9.5.0)
- `node_modules` must be installed (`npm ci` first, provenance checks against installed packages)
- A list of high-criticality packages to prioritise, if any
- Whether the project uses a private registry (Sigstore attestations are registry-specific)

### What to do
1. **Verify npm version supports provenance.**

   ```bash
   npm --version   # need ≥ 9.5.0
   ```

   If below 9.5.0, provenance verification is unavailable. Fall back to the Node lockfile check
   as the primary control, lockfile `sha512` hashes remain valid regardless of npm version.

   If above 9.5.0, continue.

2. **Run `npm audit signatures`, verifies all installed packages.**

   ```bash
   npm audit signatures
   ```

   This command fetches the npm registry's public keys and verifies the cryptographic
   signature on every package in `node_modules`. It reports:
   - **Verified**: signature valid
   - **Missing**: package was published without a signature (common for pre-2023 packages)
   - **Invalid**: signature verification failed, treat as potentially compromised

   A clean run shows no output. Any finding is printed with the package name and version.

3. **Check provenance for critical dependencies.**

   For each high-value dependency (auth libraries, crypto, infrastructure SDKs):

   ```bash
   npm view <package>@<version> dist.attestations --json
   ```

   From the output, verify:
   - `predicateType` contains `slsa-provenance` or `npm-publish-provenance`
   - `sourceRepositoryURI` matches the expected GitHub/GitLab repository URL
   - `buildTrigger` is `push` or a CI event, not `manual` (manual local publishes are
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

### Gotchas
- **`npm audit signatures` only checks `node_modules`.** Run `npm ci` first. An empty
  `node_modules` will produce no output, not a clean result.

- **Absence of provenance is expected for pre-2023 packages.** lodash, express, moment,
  and most established packages were published before npm provenance support. Absence alone
  is not suspicious. Compare the package's publish date against 2023-04 (when npm 9.5.0
  shipped) to contextualise missing provenance.

- **Provenance attestations are opt-in for publishers.** Even post-2023, publishers must
  explicitly pass `--provenance` to `npm publish`. Many legitimate publishers haven't
  adopted it yet. Use provenance as a signal, not a binary gate, unless your policy requires it.

- **Private registries (Verdaccio, Artifactory, GitHub Packages private) do not forward
  Sigstore attestations.** If your project proxies through a private registry, `npm audit
  signatures` may report missing signatures for all packages, even ones that have public
  attestations. Verify directly against the public registry for those packages.

- **`npm audit signatures` and `npm audit` are separate commands.**
  - `npm audit` → known CVEs (advisory database)
  - `npm audit signatures` → cryptographic signature verification
  Run both; neither replaces the other.

- **Sigstore's Rekor transparency log is append-only.** A valid attestation today was
  valid at publish time and will remain verifiable indefinitely. A package with an
  attestation claiming a `sourceRepositoryURI` that doesn't exist or doesn't contain
  that package's code is a strong indicator of a compromised publish.

### Script
- `check-provenance.sh`: runs `npm audit signatures`, parses results by category
  (verified/missing/failed), checks provenance details for named critical packages,
  and reports PASS/FAIL with actionable findings
