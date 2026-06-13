# npm-lockfile-integrity

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-08

Enforces content-hash-based dependency verification for Node.js projects. Version pinning
alone does not prevent a compromised or republished package at the same version number —
the `sha512` integrity hashes in `package-lock.json`, enforced via `npm ci`, are the
correct control. Extracted from a supply chain attack discussion around SBOM pinning
strategies and the event-stream/xz-utils threat model.

---

## What this skill does

Establishes three concrete controls:

1. **`npm ci` mandate** — replaces `npm install` in CI with the hash-enforcing alternative
2. **Lockfile review discipline** — treats `package-lock.json` as a first-class reviewed
   artefact, with a specific checklist for what to look for in lockfile PRs
3. **Integrity gap detection** — `check-lockfile-integrity.sh` finds packages missing
   `integrity` fields (common in older lockfiles) and flags v1/sha1 lockfiles for upgrade

Pairs with `npm-provenance-attestation` — run both for full supply chain coverage.

---

## When to use it

- Setting up CI for any Node.js project
- Auditing an existing project's dependency verification posture
- Post-incident review after a supply chain alert involving an npm package
- Reviewing a PR that modifies `package-lock.json`

---

## Installation

### Claude Code

```bash
cp -r clusters/07-devops/npm-lockfile-integrity ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#npm-lockfile-integrity
```

### MCP client

Register the grimoire MCP server — this skill is exposed as tool `npm_lockfile_integrity`.

> **Note:** This is an `action` type skill — available as MCP tool, prompt file, and Claude Code.


---

## Quick reference

```bash
# Check lockfile integrity coverage
bash check-lockfile-integrity.sh

# Enforce in CI (replace npm install with)
npm ci

# Gate on lockfile drift after install
npm ci && git diff --exit-code package-lock.json

# Check lockfile version (want v2 or v3 for sha512)
node -e "const l=require('./package-lock.json'); console.log(l.lockfileVersion)"

# Regenerate lockfile with current npm (sha512 hashes)
rm -rf node_modules package-lock.json && npm install
```

---

## Workflow

```
Audit: check-lockfile-integrity.sh
        ↓
Fix gaps (lockfile version, missing hashes)
        ↓
Replace npm install → npm ci in all CI pipelines
        ↓
Add lockfile drift check (git diff --exit-code after npm ci)
        ↓
Add npm audit --audit-level=high gate
        ↓
Enforce lockfile PR review discipline
```

---

## What it won't do

- Verify publisher identity — use `npm-provenance-attestation` for that
- Detect known CVEs — use `npm audit` for that (separate concern)
- Auto-resolve integrity gaps — regeneration requires human review of the diff

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `check-lockfile-integrity.sh` — lockfile version, integrity coverage, PASS/FAIL summary
- [ ] Add GitHub Actions workflow snippet for lockfile drift gating
- [ ] Test on 3 Node.js repos
- [ ] Ship: copy to `~/.claude/skills/npm-lockfile-integrity/`
