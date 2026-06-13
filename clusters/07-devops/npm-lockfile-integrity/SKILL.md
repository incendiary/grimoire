# npm-lockfile-integrity

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Enforces content-hash-based dependency verification for Node.js projects. Treats
`package-lock.json` as the authoritative identity of every dependency via `sha512`
integrity fields — not the version string. Prevents a compromised or republished
package at a "correct" version number from reaching CI or production builds.

Invoke when: setting up a Node.js project's CI pipeline; auditing an existing project
for supply chain hygiene; reviewing a dependency chain after a supply chain incident
or suspicious package alert.

## Context needed
- Presence and lockfile version of `package-lock.json` (v1/v2/v3)
- npm version in use locally and in CI
- CI platform (GitHub Actions, GitLab CI, etc.) for enforcement snippet
- Whether the project uses workspaces or a monorepo layout

## What to do

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

2. **Treat `package-lock.json` as a reviewed, committed artefact — not a generated file.**

   Every PR that modifies `package-lock.json` should be reviewed with the same rigour
   as source code changes. The changes to audit:
   - New packages added (inspect the `resolved` URL and `integrity` hash)
   - Existing packages with changed `integrity` values (version unchanged but hash changed
     = the package was republished with different content — treat as a red flag)
   - `lockfileVersion` changes (v1 → v2 is expected on npm upgrade; verify it's intentional)

   Add a PR description note whenever `package-lock.json` changes:
   > "package-lock.json updated: [describe what changed and why]"

3. **Verify all dependencies have `integrity` fields.**

   Packages added with npm < 5 may be missing `integrity` fields entirely. Without them,
   `npm ci` cannot verify content. Run `check-lockfile-integrity.sh` to detect any gaps.

   Packages missing integrity — remediation:
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

5. **Layer `npm audit` as a complementary control — it is a different concern.**

   `npm audit` checks for known CVEs in the dependency graph. `npm ci` + integrity hashes
   check content authenticity. Both are necessary; neither replaces the other.

   ```bash
   npm audit --audit-level=high
   ```
   Gate CI on `--audit-level=high` as a minimum. Accept that some lower-severity findings
   may require a separate triage process.

## Gotchas

- **`npm install` in CI silently breaks integrity enforcement.** Any pipeline step using
  `npm install` is not verifying hashes. Audit all CI workflow files for `npm install`
  and replace with `npm ci`.

- **Integrity hashes are only as trustworthy as when they were written.** If `package-lock.json`
  was committed while a registry-level compromise was already in place, the hash enshrines
  the bad version. This is why lockfile PRs require careful review, not just automated
  `npm audit`.

- **Lockfile v1 uses `sha1` hashes — insufficient.** npm < 7 generates v1 lockfiles with
  `sha1` integrity. Upgrade to npm ≥ 7 to get v2/v3 lockfiles with `sha512`. Verify with:
  ```bash
  node -e "const l=require('./package-lock.json'); console.log('lockfileVersion:', l.lockfileVersion)"
  ```

- **Monorepos with workspaces have separate lockfile sections.** Check integrity coverage
  across all workspace entries, not just the root `dependencies` block.

- **`npm ci` deletes `node_modules` before installing.** This is intentional — it ensures
  a clean install from the lockfile. Do not work around this in CI by caching `node_modules`
  between runs without also verifying the lockfile hash hasn't changed.

- **`resolved` URL changes without hash change = CDN migration, usually safe.** Hash change
  without version change = content change, always investigate.

## Suggested scripts
- `check-lockfile-integrity.sh` — verifies lockfile exists, checks lockfile version,
  detects packages missing integrity fields, and reports a PASS/FAIL summary with
  actionable remediation steps
