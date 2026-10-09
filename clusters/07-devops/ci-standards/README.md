# ci-standards

> Standardised devops practices — umbrella skill with enforcement scripts.

## Purpose

Establishes and enforces a consistent set of devops practices across all repositories.
Combines routing to existing grimoire skills (for implementation) with portable shell
scripts (for enforcement/auditing).

## When to invoke

- Setting up a new repository ("establish my devops practices")
- Pre-release audit ("is this repo compliant?")
- Onboarding a project to your standards
- Periodic health check on an existing repo
- After discovering a practice gap in a session

## Practice categories

1. **Versioning** — semver, VERSION file as source of truth, tag + release sync
2. **PR discipline** — atomic PRs, conventional commits, squash merge, batch into point releases
3. **Testing standards** — CI required, baseline tests (version-sync, clone-ref), periodic runs
4. **Clone-ref pinning** — no `@main`/`@master` in docs, all refs versioned
5. **Continuous review** — fix flaky tests, never disable, coverage direction up

## Enforcement scripts

### check-version-sync.sh

Verifies VERSION file, latest git tag, and GitHub release are in agreement.

```
$ bash check-version-sync.sh
✓ VERSION file:    1.6.2
✓ Latest git tag:  v1.6.2
✓ GitHub release:  v1.6.2
All in sync.
```

Failure output:

```
$ bash check-version-sync.sh
✗ VERSION file:    1.6.3
✗ Latest git tag:  v1.6.2
✗ GitHub release:  v1.6.2
DRIFT DETECTED: VERSION (1.6.3) != tag (1.6.2) != release (1.6.2)
```

### check-clone-refs.sh

Scans documentation for unpinned clone/install references.

```
$ bash check-clone-refs.sh
Scanning: README.md docs/ .github/workflows/
✗ README.md:14: git clone https://github.com/user/repo.git@main
✗ .github/workflows/ci.yml:23: uses: actions/checkout@main
2 violations found. Pin to specific versions.
```

### check-test-baseline.sh

Checks whether a repo meets minimum testing standards.

```
$ bash check-test-baseline.sh
✓ CI workflow found: .github/workflows/ci.yml
✗ No version-sync test found
✗ No clone-ref test found
2 baseline tests missing. Run ci-standards to install them.
```

### check-roadmap-sync.sh

> **Not portable like the three above.** This one is grimoire-repo-specific — it
> depends on `scripts/roadmap-collect.sh` and grimoire's own `ROADMAP.md` marker
> convention. It lives here to reuse the established check-script convention and
> wiring (`devops-check.yml`, the local pre-push hook), not because it works in an
> arbitrary downstream repo.

Verifies `ROADMAP.md`'s generated block matches the `## Roadmap` sections of every
skill's own README (the source of truth).

```
$ bash check-roadmap-sync.sh . --check
✗ DRIFT DETECTED — ROADMAP.md does not match the per-skill README sources.
...
Run: bash clusters/07-devops/ci-standards/check-roadmap-sync.sh . --fix
```

```
$ bash check-roadmap-sync.sh . --fix
✓ ROADMAP.md regenerated (57 open, 222 completed).
```

## Workflow

### Full setup (new repo)

```
ci-standards                  → audit current state
        ↓
[review violations]
        ↓
github-release-workflow       → set up proper release process
readme-version-pin            → pin all refs
        ↓
check-version-sync.sh         → verify version sync
check-clone-refs.sh           → verify ref pinning
check-test-baseline.sh        → verify test baseline
        ↓
All green → repo is compliant
```

### Periodic audit (existing repo)

```bash
cd your-repo-root
bash clusters/07-devops/ci-standards/check-version-sync.sh
bash clusters/07-devops/ci-standards/check-clone-refs.sh
bash clusters/07-devops/ci-standards/check-test-baseline.sh
```

## Related skills

| Skill | Relationship |
|-------|-------------|
| `github-release-workflow` | Implements the versioning practice |
| `readme-version-pin` | Implements clone-ref pinning |
| `project-delivery-workflow` | Implements PR discipline |
| `test-bootstrap` (05-technical) | Implements test framework setup |

## Evolving this standard

When a session reveals a new repeating practice, follow "Evolving this standard" in
`SKILL.md`: classify the practice, add the rule to the correct category, and update
enforcement scripts if it is automatable. Related: `session-skill-extractor` (01-meta)
discovers patterns; `karpathy-environment` (01-meta) captures broader workspace-level ones.

---
