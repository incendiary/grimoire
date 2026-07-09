# devops-practices

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional + enforcement

## Description
Establishes and enforces standardised devops practices on any repository. Acts as both
a reference (routing to existing grimoire skills) and an enforcement layer (portable
shell scripts that verify compliance). Invoke to bootstrap a repo with your standard
practices or to audit an existing repo against them.

Invoke when: setting up a new repo; onboarding a project to your standards; pre-release
audit; "establish my devops practices on this repo"; periodic health check.

## Context needed
- Repository root path (for script execution)
- Whether the repo uses GitHub releases (for version-sync checks)

---

## Practice categories

### 1. Versioning

**Standard:** Semantic versioning (major.minor.patch).

| Rule | Detail |
|------|--------|
| VERSION file is source of truth | Single file at repo root, one line: `X.Y.Z` |
| Git tag must match VERSION | Tag format: `vX.Y.Z` (with `v` prefix) |
| GitHub release must match tag | Release title includes version; tag is the release ref |
| Patch = related PR batch | Group several PRs on the same subject into one patch bump |
| Minor = feature batch | New capability added |
| Major = breaking change | API or interface contract broken |

**Enforcement:** `check-version-sync.sh`
**Existing skills:** `github-release-workflow`, `readme-version-pin`

---

### 2. PR discipline

**Standard:** Atomic, individually reviewable pull requests.

| Rule | Detail |
|------|--------|
| One logical change per PR | A PR should do one thing — not "fix bug and also refactor" |
| Conventional commit titles | `feat:`, `fix:`, `docs:`, `ci:`, `chore:` prefix |
| Squash merge to main | Never merge commits; history stays linear |
| Never rebase published branches | Use `git merge main` to catch up; rebase silently drops commits |
| Group PRs into point releases | 3 PRs improving CI → single patch bump after the batch |
| PR description references issue | Link the issue being addressed (if one exists) |

**Enforcement:** Rules only (human discipline). PR title checked by CI where available.
**Existing skills:** `project-delivery-workflow`

---

### 3. Testing standards

**Standard:** Every repo has CI with tests; baseline invariants are always tested.

| Rule | Detail |
|------|--------|
| CI workflow must include test step | No repo ships without automated tests |
| Baseline tests always present | Version-sync test, clone-ref test (see below) |
| Periodic test execution | Schedule CI runs (not just on PR) — catches env drift |
| Fix flaky tests immediately | Flaky test = production bug; never skip or retry-until-green |
| Add test for every production bug | If it broke once without a test, it will break again |

**Baseline tests to install in every repo:**

```bash
# Test: VERSION file matches latest git tag
test_version_sync() {
  version=$(cat VERSION)
  tag=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
  [ "$version" = "$tag" ] || fail "VERSION ($version) != tag ($tag)"
}

# Test: No @main/@master refs in user-facing docs
test_clone_refs_pinned() {
  violations=$(grep -rn '@main\|@master' README.md docs/ 2>/dev/null || true)
  [ -z "$violations" ] || fail "Unpinned refs found:\n$violations"
}
```

**Enforcement:** `check-test-baseline.sh`
**Existing skills:** `test-bootstrap` (05-technical)

---

### 4. Clone/install reference pinning

**Standard:** All clone instructions, install commands, and dependency refs specify a version.

| Rule | Detail |
|------|--------|
| No `@main` or `@master` in docs | Every ref must be `@vX.Y.Z` or a commit SHA |
| GitHub Actions refs pinned | `uses: owner/action@vX.Y.Z` not `@main` |
| Install commands versioned | `pip install pkg==X.Y.Z`, `npm install pkg@X.Y.Z` |
| Cross-check against VERSION | Pinned version must match current release |

**Enforcement:** `check-clone-refs.sh`
**Existing skills:** `readme-version-pin`

---

### 5. Continuous review

**Standard:** Tests are a living system, not a write-once artefact.

| Rule | Detail |
|------|--------|
| Review test failures weekly | Scheduled CI catches drift; review results |
| Never disable a failing test | Fix the code or fix the test — disabling hides rot |
| Coverage direction must be up | New code must have tests; coverage % never decreases |
| Post-incident test addition | Every incident gets a regression test within the fix PR |

**Enforcement:** Rules only (process discipline).
**Existing skills:** None — this is a practice, not automatable.

---

### 6. Documentation & roadmap management

**Standard:** Roadmap is broken out to a dedicated file; README links to it. Both stay in sync.

| Rule | Detail |
|------|--------|
| ROADMAP.md at repo root | Single source of truth for detailed roadmap; one item per line with checkbox |
| README has roadmap link | Brief overview in README with link to full ROADMAP.md, not duplication |
| Roadmap uses checkbox format | `- [ ]` uncompleted, `- [x]` completed; sortable and machine-parseable |
| Sync after PR merge or release | When work completes, update both README and ROADMAP.md in same commit |
| Archive completed roadmap sections | Completed items move to "Shipped" section at bottom of ROADMAP.md, not deleted |
| No stale items | Roadmap reflects current direction; remove items that are no longer planned |

**File structure example:**
```
ROADMAP.md (root)
├─ ## Features (upcoming)
│  ├─ - [ ] Feature X (Priority: HIGH)
│  └─ - [ ] Feature Y
├─ ## In Progress
│  └─ - [ ] Feature Z (tracked in PR #123)
└─ ## Shipped (v1.0 - v1.3)
   ├─ - [x] Feature A
   └─ - [x] Feature B

README.md
└─ ## Roadmap
   Brief summary + "See [full roadmap](ROADMAP.md)"
```

**Enforcement:** No automated script; managed via `roadmap-sync` skill on each PR merge.
**Existing skills:** `roadmap-sync` (keep README and ROADMAP.md in sync after changes)

---

### 10. Code quality / formatting

**Standard:** Every repo has a formatter and linter configured; both gate CI.

| Language | Formatter | Linter | Notes |
|----------|-----------|--------|-------|
| Python | `black` | `ruff` | ruff replaces flake8+isort+pyupgrade |
| TypeScript/JavaScript | `prettier` | `eslint` | eslint flat config (v9+) |
| Go | `gofmt` / `goimports` | `golangci-lint` | gofmt is canonical |
| Rust | `rustfmt` | `clippy` | Both ship with toolchain |
| C#/.NET | `dotnet format` | Roslyn analysers | Built into SDK |
| C/C++ | `clang-format` | `clang-tidy` | `.clang-format` in repo root |
| Shell/Bash | `shfmt` | `shellcheck` | Already enforced in grimoire CI |
| Terraform | `terraform fmt` | `tflint` + `checkov` | Covered by terraform skills |
| YAML | `prettier` | `yamllint` | CI configs, docker-compose |
| Markdown | `prettier` | `markdownlint` | Docs/READMEs |

| Rule | Detail |
|------|--------|
| Format on save + before commit | Editor config + CI gate; no unformatted code merges |
| Lint must pass in CI | No warnings-as-non-blocking; lint failures are build failures |
| Config lives in repo root | Not user-global; checked into source control |
| Pin formatter/linter versions | In lockfile or CI config; prevents drift between devs |
| No broad file-level disables | Suppress per-line with justification; never blanket-ignore |

**Enforcement:** `format-before-commit` skill handles Python; language-specific CI templates handle others.
**Existing skills:** `format-before-commit`, `python-ci-lint-precheck`, `pre-commit-aware-commits`

---

## Enforcement scripts

All scripts are portable POSIX-compatible shell, runnable in any repo:

| Script | What it checks | Exit code |
|--------|---------------|-----------|
| `check-version-sync.sh` | VERSION == git tag == GH release | 0 = synced, 1 = drift |
| `check-clone-refs.sh` | No `@main`/`@master` in docs | 0 = clean, 1 = violations |
| `check-test-baseline.sh` | CI exists, baseline tests present | 0 = compliant, 1 = gaps |

Run all three for a full audit:
```bash
for script in check-version-sync.sh check-clone-refs.sh check-test-baseline.sh; do
  bash "path/to/devops-practices/$script" || echo "FAIL: $script"
done
```

---

## Routing to existing skills

When a practice needs more than enforcement — it needs *implementation* — route to:

| Need | Skill to invoke |
|------|----------------|
| Cut a release with proper tagging | `github-release-workflow` |
| Pin README install refs to version | `readme-version-pin` |
| Sync roadmap after PR merge or release | `roadmap-sync` |
| Full delivery loop (branch → PR → release) | `project-delivery-workflow` |
| Bootstrap test framework in a new repo | `test-bootstrap` (05-technical) |
| Set up pre-commit hooks | `pre-commit-aware-commits` |
| Verify code version matches HEAD | `verify-code-version` (01-meta) |
| Deploy secret scanning | `repo-security-bootstrap` |

---

## Self-update protocol

When a session reveals a new repeating practice:
1. Invoke `devops-practices-updater`
2. It reads this SKILL.md, identifies the correct category
3. Appends the new rule to the category table
4. If enforceable, updates or creates a check script
5. Commits as a standalone change

---

## Roadmap

- [ ] Add CI workflow snippet that runs all three check scripts on PR
- [ ] Add `--fix` mode to `check-clone-refs.sh` (auto-update refs to current VERSION)
- [ ] Add GitHub Actions version-pinning check (not just docs, also workflow files)
- [x] Add scheduled CI template for periodic test execution — `validate.yml` now runs weekly (`schedule: cron`) in addition to push/PR
