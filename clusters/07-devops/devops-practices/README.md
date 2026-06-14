# devops-practices

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
2 baseline tests missing. Run devops-practices to install them.
```

## Workflow

### Full setup (new repo)

```
devops-practices              → audit current state
        ↓
[review violations]
        ↓
github-release-workflow       → set up proper release process
readme-version-pin            → pin all refs
pre-commit-aware-commits      → install hooks
        ↓
check-version-sync.sh         → verify version sync
check-clone-refs.sh           → verify ref pinning
check-test-baseline.sh        → verify test baseline
        ↓
All green → repo is compliant
```

### Periodic audit (existing repo)

```bash
cd /path/to/repo
bash path/to/devops-practices/check-version-sync.sh
bash path/to/devops-practices/check-clone-refs.sh
bash path/to/devops-practices/check-test-baseline.sh
```

## Related skills

| Skill | Relationship |
|-------|-------------|
| `github-release-workflow` | Implements the versioning practice |
| `readme-version-pin` | Implements clone-ref pinning |
| `project-delivery-workflow` | Implements PR discipline |
| `pre-commit-aware-commits` | Implements hook-based enforcement |
| `test-bootstrap` (05-technical) | Implements test framework setup |
| `verify-code-version` (01-meta) | Verifies code matches HEAD |
| `devops-practices-updater` | Evolves this skill with new practices |

## Companion skill

**`devops-practices-updater`** — invoke when a session reveals a new practice that should
be standardised. It reads this skill, appends the new rule to the correct category, and
updates enforcement scripts if applicable.
