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

---

## Typical chain

```
Repo ready for publication
        ↓
repo-publication-prep     (file audit + history decision + pre-commit setup)
        ↓
github-history-wipe       (if fresh init chosen)
        ↓
repo-security-bootstrap   (gitleaks config + GH Actions secret scan)
        ↓
python-ci-template        (if Python project)
  or dotnet-ci-template   (if .NET project)
        ↓
Repo published
```
