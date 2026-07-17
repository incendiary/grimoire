# 07-devops — Dev workflow and repo management

Skills for CI/CD setup, repository publication, and bulk repo operations. Extracted
from sessions where the same procedures were repeated identically across multiple repos.
These skills eliminate that repetition — load one, get the full procedure with all
known gotchas baked in.

---

## Skills

### [repo-compass](repo-compass/) ✅ complete

Session-start orientation for any GitHub project. Combines `gh` CLI platform state
(PRs, issues, CI, releases, stale branches) with README roadmap state, cross-checks
each unchecked item against the codebase, and produces a "true state" summary.
Prevents "all clean" reports when README roadmap items are still outstanding.
→ [Full documentation](repo-compass/README.md)

### [repo-publication-prep](repo-publication-prep/) 📋 promoted

End-to-end checklist for publishing a private repo publicly: file-size audit (10MB
soft limit, 100MB hard block), history sanitisation decision (filter-repo vs fresh init
based on leak count and history value), and language-appropriate pre-commit hook
configuration. Merged from three separately extracted stubs.
→ [Full documentation](repo-publication-prep/README.md)

### [github-history-wipe](github-history-wipe/) 📋 promoted

Automates the fresh `git init` workflow for repos where history does not need to be
preserved: clone to `/tmp`, scan for sensitive strings, capture releases and tags to
JSON, user-confirm, wipe, force push, recreate releases. Extracted after this exact
procedure was repeated verbatim 16 times in a single session.
→ [Full documentation](github-history-wipe/README.md)

### [github-morning-run](github-morning-run/) ✅ complete

Routine GitHub repository maintenance. Audits open PRs, auto-merges simple dependabot
updates when CI passes, checks GitHub Actions status, and flags complex issues for review.
Supports single repo, multiple repos, or full portfolio audit. Scope is confirmed on invocation.
→ [Full documentation](github-morning-run/README.md)

### [local-ci](local-ci/) ✅ complete

Run your GitHub Actions workflows locally before pushing: real YAML parsing, exit-code
truth, stop-on-failure per job, and version-gated auto-fix (black/ruff) that only writes
when it matches CI's pinned version. Installs as a fast informational `pre-commit` hook or a
fail-closed `pre-push` gate — chaining any existing hook, never clobbering it.
→ [Full documentation](local-ci/README.md)

### [repo-security-bootstrap](repo-security-bootstrap/) 📋 promoted

Deploys standard secret-scanning infrastructure — a custom `.gitleaks.toml` with
corporate-reference rules and a GitHub Actions `secret-scan.yml` workflow — to repos
in bulk. Handles the archived-repo unarchive/re-archive dance. Extracted after the same
two files were committed to 16 repos identically.
→ [Full documentation](repo-security-bootstrap/README.md)

### [python-ci-template](python-ci-template/) 📋 promoted

Generates a standardised Python CI workflow: ruff lint, black format check, pytest with
coverage across a 3.9–3.12 matrix, and secret scanning. Handles Jython exceptions.
Extracted after the same workflow was written from scratch for 8 separate repos.
→ [Full documentation](python-ci-template/README.md)

### [dotnet-ci-template](dotnet-ci-template/) 📋 promoted

Generates a standardised .NET CI workflow: build and test matrix (Debug/Release),
`dotnet format --verify-no-changes`, and secret scanning. Covers both Windows-only
(WinAPI/BOF projects) and cross-platform variants. Extracted after the same workflow
was written from scratch for 5 separate repos.
→ [Full documentation](dotnet-ci-template/README.md)

### [python-ci-lint-precheck](python-ci-lint-precheck/) ✅ complete

Runs ruff and pylint before committing Python code, with rules for suppressing false
positives (W0621, E0401, R0914) at the correct scope — no broad file-level disables.
→ [Full documentation](python-ci-lint-precheck/README.md)

### [python-lint-gate](python-lint-gate/) ✅ complete

Unified pre-commit gate for Python repos using Ruff + Black. Provides one command for
check-only validation or safe auto-fix + re-check, and prints targeted guidance when
issues remain.
→ [Full documentation](python-lint-gate/README.md)

### [format-before-commit](format-before-commit/) ✅ complete

Enforces running black and ruff in check-mode first, then auto-fix mode, then
re-staging to review formatter changes before they go into the commit.
→ [Full documentation](format-before-commit/README.md)

### [portfolio-readme-generator](portfolio-readme-generator/) ✅ complete

Generates a portfolio-quality README from code — reads first, then writes with a
fixed 6-section structure. Mandates an authorised-use disclaimer for any security tool.
Applies human-rewrite style rules.
→ [Full documentation](portfolio-readme-generator/README.md)

### [pre-commit-aware-commits](pre-commit-aware-commits/) ✅ complete

Prevents commits where pre-commit hooks have silently modified files. Enforces a
hook dry-run before staging, re-review of hook changes, and a gitleaks-finding
review before adding to allowlist.
→ [Full documentation](pre-commit-aware-commits/README.md)

### [pre-push-validation](pre-push-validation/) ✅ complete

Shift-left validation: runs all feasible local checks (linting, formatting, type checking,
tests, security scans) before pushing to GitHub. Auto-detects project type (Node.js, Python,
Go, Rust, C#, bash) and chains appropriate validators. Optionally installs a pre-push git
hook for automatic enforcement, preventing avoidable CI failures.
→ [Full documentation](pre-push-validation/README.md)

### [github-release-workflow](github-release-workflow/) ✅ complete

End-to-end release workflow: issue → branch → version bump → PR → CI wait → merge →
tag → GitHub release. Includes SSH authentication check before tag push.
→ [Full documentation](github-release-workflow/README.md)

### [git-push-protocol-handler](git-push-protocol-handler/) ✅ complete

Handles SSH push failures by switching to HTTPS, pushing, then restoring the SSH
remote after the session. Prevents broken remote state.
→ [Full documentation](git-push-protocol-handler/README.md)

### [roadmap-sync](roadmap-sync/) ✅ complete

Keeps README roadmaps in sync after code changes: reads the current state first,
ticks completed items, adds new ones, removes stale items. Always a standalone commit.
→ [Full documentation](roadmap-sync/README.md)

### [terraform-checkov-skips](terraform-checkov-skips/) ✅ complete

Enforces `#checkov:skip` placement inside resource blocks (not before them) and
requires a justification on every skip line. Includes grep command to find misplaced
annotations before pushing.
→ [Full documentation](terraform-checkov-skips/README.md)

### [terraform-aws-syntax](terraform-aws-syntax/) ✅ complete

Known block-vs-attribute syntax patterns for AWS provider resources: VPN endpoints,
spot instances, Cognito token validity. Enforces `terraform validate` after every
resource block change.
→ [Full documentation](terraform-aws-syntax/README.md)

### [terraform-version-compat](terraform-version-compat/) ✅ complete

Pre-flight check before adding or upgrading a Terraform module: reads module
`required_providers`, checks constraint conflicts, checks for breaking syntax changes,
and locks the provider lock file for linux and darwin.
→ [Full documentation](terraform-version-compat/README.md)

### [project-delivery-workflow](project-delivery-workflow/) ✅ complete

End-to-end delivery loop for a GitHub project: cold clone, read all nested READMEs
to extract the roadmap, work each item as a feature branch → PR → CI check → merge,
tick READMEs and bump versions throughout, close with a major version bump and release.
→ [Full documentation](project-delivery-workflow/README.md)

### [readme-version-pin](readme-version-pin/) ✅ complete

Keeps README install instructions pinned to the latest tagged release. `pin_readme_version.sh`
rewrites `@main`/`@master`/old tag refs across all READMEs to the current version;
`check_readme_version.sh` asserts correctness and gates commits as a pre-commit hook.
→ [Full documentation](readme-version-pin/README.md)

### [docker-ghcr-publish](docker-ghcr-publish/) ✅ complete

Builds and pushes CPU and GPU Docker images to GHCR pinned to the current release version.
`docker-publish.sh` builds/tags/pushes and updates README deployment instructions;
`docker-test.sh` smoke-tests each variant (CPU, GPU, docker-compose) before pushing.
→ [Full documentation](docker-ghcr-publish/README.md)

### [npm-lockfile-integrity](npm-lockfile-integrity/) ✅ complete

Enforces content-hash-based dependency verification for Node.js projects. Version pinning
alone does not prevent a republished package at the same version — `sha512` integrity hashes
in `package-lock.json`, enforced via `npm ci`, are the correct control.
`check-lockfile-integrity.sh` audits lockfile version, integrity coverage, and CI pipeline usage.
→ [Full documentation](npm-lockfile-integrity/README.md)

### [npm-provenance-attestation](npm-provenance-attestation/) ✅ complete

Verifies npm package provenance: Sigstore-backed attestations linking each published package
to its source repository, CI workflow, and commit SHA. Complements `npm-lockfile-integrity` —
integrity hashes confirm content hasn't changed; provenance confirms where it came from.
`check-provenance.sh` runs `npm audit signatures` and inspects critical package attestations.
→ [Full documentation](npm-provenance-attestation/README.md)

### [python-lockfile-integrity](python-lockfile-integrity/) ✅ complete

Enforces content-hash-based dependency verification for Python projects. Covers four toolchains:
pip-tools (`--require-hashes`), poetry (`poetry install`), pipenv (`--deploy`), and uv (`--frozen`).
`check-python-lockfile-integrity.sh` detects the toolchain in use, verifies sha256 hash coverage,
and audits CI pipelines for bare `pip install` usage. Mirrors `npm-lockfile-integrity` for Python.
→ [Full documentation](python-lockfile-integrity/README.md)

### [devops-practices](devops-practices/) ✅ complete

Umbrella skill establishing standardised devops practices: semver versioning, atomic PR
discipline, testing standards, clone-ref pinning, and continuous review. Routes to existing
skills for implementation; provides portable shell scripts (`check-version-sync.sh`,
`check-clone-refs.sh`, `check-test-baseline.sh`) for enforcement and auditing.
→ [Full documentation](devops-practices/README.md)

### [devops-practices-updater](devops-practices-updater/) ✅ complete

Self-update mechanism for `devops-practices`. Invoked when a session reveals a new repeating
practice. Reads the current skill, classifies the practice, appends to the correct category,
and updates enforcement scripts if automatable. Ensures practices grow without becoming disorganised.
→ [Full documentation](devops-practices-updater/README.md)

### [branch-surface-resolve](branch-surface-resolve/) ✅ complete

Audits every local and remote branch, categorises each as READY / LOCAL-ONLY / HAS-PR /
CONFLICT / STALE, and resolves what can be resolved automatically via PRs. Conflicts are
surfaced with commit list, diff summary, and resolution options — never auto-merged.
Invoke to clean up scattered branches and land all work on `main` via proper PRs.
→ [Full documentation](branch-surface-resolve/README.md)

---

## When to invoke — workflow guide

### Workflow 1: New repo publication

**Trigger:** "I want to publish this repo" / "Make this repo public" / starting a new open-source release

```
repo-compass              → assess current state (PRs, CI, stale branches)
        ↓
repo-publication-prep     → file audit + history decision + pre-commit setup
        ↓
github-history-wipe       → (if fresh init chosen) wipe and force push
        ↓
repo-security-bootstrap   → gitleaks config + GH Actions secret scan
        ↓
python-ci-template        → (if Python) standardised CI workflow
  or dotnet-ci-template   → (if .NET) standardised CI workflow
        ↓
portfolio-readme-generator → generate portfolio-quality README
        ↓
readme-version-pin        → pin install instructions to tagged version
        ↓
github-release-workflow   → cut first release (tag + GH release)
```

### Workflow 2: Cutting a release

**Trigger:** "Ship a new version" / "Tag and release" / version bump needed

```
roadmap-sync              → tick completed items, confirm state is clean
        ↓
format-before-commit      → ensure code is formatted before final commit
        ↓
pre-commit-aware-commits  → verify hooks haven't silently modified files
        ↓
github-release-workflow   → branch → version bump → PR → CI → merge → tag → release
        ↓
readme-version-pin        → update install refs to new tag
        ↓
docker-ghcr-publish       → (if containerised) build + push images
```

### Workflow 3: Daily commit workflow

**Trigger:** "Ready to commit" / making changes to any repo with CI

```
format-before-commit      → run black + ruff check, then auto-fix, re-stage
        ↓
python-lint-gate          → unified check/fix gate for ruff + black
        ↓
python-ci-lint-precheck   → ruff + pylint with correct suppression rules
        ↓
pre-commit-aware-commits  → dry-run hooks, review changes, gitleaks check
        ↓
git-push-protocol-handler → (if SSH fails) switch to HTTPS, push, restore
```

### Workflow 4: Session start / orientation

**Trigger:** "What's the state of this repo?" / starting a new session on any project

```
repo-compass              → platform state + README roadmap cross-check
        ↓
roadmap-sync              → (if items completed) tick and commit
```

### Workflow 5: Infrastructure / IaC changes

**Trigger:** "Adding a Terraform module" / "Upgrading provider" / IaC work

```
terraform-version-compat  → pre-flight: constraint conflicts, breaking changes
        ↓
terraform-aws-syntax      → known block-vs-attribute gotchas for AWS resources
        ↓
terraform-checkov-skips   → ensure #checkov:skip is inside blocks with justification
```

### Workflow 6: Supply chain security audit

**Trigger:** "Check dependencies" / "Audit lockfile" / dependency review

```
npm-lockfile-integrity       → (Node.js) verify sha512 hash coverage in lockfile
        ↓
npm-provenance-attestation   → (Node.js) verify Sigstore attestations on packages
        ↓
python-lockfile-integrity    → (Python) verify hash-based pinning across toolchains
```

### Workflow 7: Establish devops practices on a repo

**Trigger:** "Establish my devops practices" / "Is this repo compliant?" / onboarding a new project

```
devops-practices             → audit repo against all practice categories
        ↓
check-version-sync.sh        → VERSION == tag == release?
check-clone-refs.sh          → no @main/@master in docs?
check-test-baseline.sh       → CI + baseline tests present?
        ↓
[address violations using routed skills]
        ↓
github-release-workflow      → (if version drift) align release
readme-version-pin           → (if unpinned refs) pin all
pre-commit-aware-commits     → (if no hooks) install
        ↓
devops-practices-updater     → (if new practice discovered) capture it
```

### Workflow 8: Surface and resolve scattered branches

**Trigger:** "I have branches everywhere" / "Clean up my branches" / returning to a repo after a break

```
branch-surface-resolve        → audit all branches; see READY/LOCAL-ONLY/HAS-PR/CONFLICT/STALE
        ↓
branch-surface-resolve --resolve
                              → auto-push and create PRs for READY and LOCAL-ONLY
        ↓
[manual resolution]           → for any CONFLICT branches (diff surfaced by script)
        ↓
repo-compass                  → verify final clean repo state
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|---------------|
| `repo-compass` | Starting a session; need ground truth on repo state; before planning work |
| `repo-publication-prep` | Moving private → public; need file-size audit and history decision |
| `github-history-wipe` | Repo has sensitive history that cannot be filtered surgically |
| `repo-security-bootstrap` | New repo needs gitleaks + secret-scan workflow; bulk deploying to many repos |
| `python-ci-template` | Python repo has no CI or needs standardised CI from scratch |
| `dotnet-ci-template` | .NET repo has no CI or needs standardised CI from scratch |
| `python-ci-lint-precheck` | About to commit Python code; want to catch lint issues pre-push |
| `python-lint-gate` | Need one command to run Ruff + Black checks (or safe auto-fixes) before commit |
| `format-before-commit` | About to commit Python code; need to run formatters first |
| `pre-commit-aware-commits` | Repo has pre-commit hooks; need to verify they haven't silently modified staged files |
| `portfolio-readme-generator` | Repo needs a portfolio-quality README; publishing or updating docs |
| `github-morning-run` | Daily/weekly repo hygiene; checking PRs, auto-merging dependabots, checking CI status |
| `github-release-workflow` | Cutting a version: branch → PR → CI → merge → tag → release |
| `git-push-protocol-handler` | SSH push just failed; need HTTPS fallback without breaking remote config |
| `roadmap-sync` | Code changes completed; README roadmap needs ticking; pre-release state check |
| `docker-ghcr-publish` | Release tagged; need to build and push Docker images to GHCR |
| `readme-version-pin` | Release tagged; README install instructions reference old version |
| `npm-lockfile-integrity` | Auditing Node.js project; checking lockfile has integrity hashes |
| `npm-provenance-attestation` | Auditing Node.js deps; verifying packages have Sigstore provenance |
| `python-lockfile-integrity` | Auditing Python project; checking hash-based pinning is enforced |
| `terraform-version-compat` | Adding/upgrading a Terraform module; need constraint pre-flight |
| `terraform-aws-syntax` | Writing AWS Terraform resources; need to avoid known block/attribute traps |
| `terraform-checkov-skips` | Adding checkov skip annotations; need correct placement and justification |
| `project-delivery-workflow` | Full delivery loop: clone → roadmap → feature branches → PRs → release |
| `devops-practices` | Establishing standards on a repo; auditing compliance; onboarding a project |
| `devops-practices-updater` | Session revealed a new practice; need to capture it in the devops-practices skill |
| `branch-surface-resolve` | Branches have accumulated across sessions; need to audit, surface conflicts, and land work via PRs |}
