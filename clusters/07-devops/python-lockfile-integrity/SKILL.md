# python-lockfile-integrity

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Enforces content-hash-based dependency verification for Python projects. Version pinning
alone does not prevent a compromised or republished package at the same version number —
the `sha256` integrity hashes in your lockfile, enforced via the correct install command,
are the correct control. Covers four toolchains: pip-tools, poetry, pipenv, and uv.

Invoke when: setting up a Python project's CI pipeline; auditing an existing project
for supply chain hygiene; reviewing a dependency change after a supply chain incident
or suspicious package alert.

## Context needed
- Which Python lockfile toolchain the project uses (pip-tools, poetry, pipenv, uv)
- Whether a lockfile is present and committed
- CI platform (GitHub Actions, GitLab CI, etc.) for enforcement snippet

## What to do

### 1. Choose a hash-enforcing lockfile strategy

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

### 2. Mandate the enforcement command in CI — never bare `pip install`

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

### 3. Treat the lockfile as a reviewed, committed artefact

Every PR that modifies a lockfile should be reviewed with the same rigour as source code.
Audit these specific changes:

- **New package added**: inspect the sha256 hash; verify the package name is not a typo-squatting
  variant of a well-known package (e.g. `reqeusts` vs `requests`)
- **Version unchanged, hash changed**: a package was republished at the same version with
  different content. This is a red flag — treat as potentially compromised until confirmed otherwise
- **Version bumped, hash changed**: expected; verify the hash against the PyPI release page
- **Lockfile tool version change**: lockfile format may differ; verify the change was intentional

Add a PR description note whenever a lockfile changes:
> "requirements.txt updated: [describe what changed and why]"

### 4. Gate lockfile drift in CI

After the install step, assert the lockfile was not modified. A drift means the installed
packages do not match what was committed — fail the build.

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

### 5. Layer `pip-audit` as a complementary CVE check

`pip-audit` checks for known CVEs in installed packages. It is a separate concern from
hash integrity — audit checks vulnerability databases; integrity checks content authenticity.
Both are necessary.

```bash
pip install pip-audit
pip-audit -r requirements.txt
# or for poetry/pipenv/uv projects:
pip-audit
```

Gate CI on at minimum a high-severity threshold. Accept that some findings require
a separate triage process.

## Gotchas

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
  `[tool.poetry]` and a legacy `requirements.txt`). Check all of them — a project may
  be migrating between toolchains and the CI may still use the old one.

- **Hashes are only as trustworthy as when they were written.** If the lockfile was
  committed while a registry-level compromise was already in place, the hash enshrines
  the bad version. This is why lockfile PRs require human review, not just automated checking.

## Suggested scripts
- `check-python-lockfile-integrity.sh` — detects toolchain(s) in use, verifies hash coverage,
  audits CI pipelines for bare `pip install`, reports PASS/FAIL summary with remediation steps
