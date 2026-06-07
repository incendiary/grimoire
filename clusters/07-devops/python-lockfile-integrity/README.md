# python-lockfile-integrity

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-08

Enforces content-hash-based dependency verification for Python projects. Version pinning
alone does not prevent a compromised or republished package at the same version number —
the `sha256` integrity hashes in your lockfile, enforced via the correct install command,
are the correct control. Mirrors the same control as `npm-lockfile-integrity` for Node.js
projects. Covers four toolchains: pip-tools, poetry, pipenv, and uv.

---

## What this skill does

Establishes three concrete controls:

1. **Hash-enforcing install mandate** — replaces bare `pip install` in CI with the toolchain's
   hash-verifying equivalent (`--require-hashes`, `poetry install`, `pipenv install --deploy`,
   `uv sync --frozen`)
2. **Lockfile review discipline** — treats lockfiles as first-class reviewed artefacts, with
   a specific checklist for what to look for (version-unchanged/hash-changed = red flag)
3. **Coverage gap detection** — `check-python-lockfile-integrity.sh` detects which toolchain
   is in use, verifies hash annotations are present, and audits CI files for enforcement gaps

Pairs with `npm-lockfile-integrity` if the project has both Python and Node.js components.

---

## When to use it

- Setting up CI for any Python project
- Auditing an existing project's dependency verification posture
- Post-incident review after a supply chain alert involving a PyPI package
- Reviewing a PR that modifies a lockfile

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/python-lockfile-integrity ~/.claude/skills/
```

---

## Quick reference

```bash
# Audit a project for hash enforcement gaps
bash check-python-lockfile-integrity.sh

# Audit a specific directory
bash check-python-lockfile-integrity.sh /path/to/project

# Exit 1 on warnings as well as failures
bash check-python-lockfile-integrity.sh --strict

# pip-tools: generate hashes
pip-compile --generate-hashes requirements.in

# pip-tools: enforce in CI
pip install --require-hashes -r requirements.txt

# poetry: enforce in CI
poetry install

# pipenv: enforce in CI
pipenv install --deploy

# uv: enforce in CI
uv sync --frozen

# Gate lockfile drift (pip-tools)
pip install --require-hashes -r requirements.txt && git diff --exit-code requirements.txt
```

---

## Toolchain comparison

| Toolchain | Lockfile | Hashes built-in? | Enforcement command |
|-----------|----------|-----------------|---------------------|
| pip-tools | `requirements.txt` (needs `--generate-hashes`) | No — must opt in | `pip install --require-hashes -r requirements.txt` |
| poetry | `poetry.lock` | Yes | `poetry install` |
| pipenv | `Pipfile.lock` | Yes | `pipenv install --deploy` |
| uv | `uv.lock` | Yes | `uv sync --frozen` |

---

## What it won't do

- Verify publisher identity — PyPI provenance attestations (PEP 740) are too nascent
  to be actionable; check back when pip gains `pip audit signatures` support
- Detect known CVEs — use `pip-audit` for that (separate concern)
- Auto-remediate hash gaps — regeneration requires human review of the diff

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `check-python-lockfile-integrity.sh` — toolchain detection, hash coverage, CI audit, PASS/FAIL summary
- [ ] Test on 3 Python repos (pip-tools, poetry, uv variants)
- [ ] Ship: copy to `~/.claude/skills/python-lockfile-integrity/`
