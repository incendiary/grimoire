# 07-devops — Dev workflow and repo management

Skills for CI/CD setup, repository publication, and bulk repo operations. Extracted
from sessions where the same procedures were repeated identically across multiple repos.
These skills eliminate that repetition — load one, get the full procedure with all
known gotchas baked in.

---

## Skills

### [orient](orient/) ✅ complete

Session-start orientation for any GitHub project. Combines `gh` CLI platform state
(PRs, issues, CI, releases, stale branches) with README roadmap state, cross-checks
each unchecked item against the codebase, and produces a "true state" summary.
Prevents "all clean" reports when README roadmap items are still outstanding.
Also runs the SSH push check, with HTTPS fallback when SSH is unavailable.
→ [Full documentation](orient/README.md)

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

### [ci-local](ci-local/) ✅ complete
Runs this repo's GitHub Actions workflow steps locally before pushing, auto-fixes Black/Ruff
only when tool versions match CI, and installs a fast informational `pre-commit` hook or a
fail-closed `pre-push` gate, chaining any existing hook rather than clobbering it.
→ [Full documentation](ci-local/README.md)

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

### [py-lint](py-lint/) ✅ complete

Python-only lint and format gate: Ruff and Black check with optional safe auto-fix and
re-check, a standard `pyproject.toml` / pre-commit / pylintrc config template, writing-time
patterns that pass first time, and scoped pylint exceptions (W0621, E0401, R0914).
→ [Full documentation](py-lint/README.md)

### [portfolio-readme-generator](portfolio-readme-generator/) ✅ complete

Generates a portfolio-quality README from code — reads first, then writes with a
fixed 6-section structure. Mandates an authorised-use disclaimer for any security tool.
Applies human-rewrite style rules.
→ [Full documentation](portfolio-readme-generator/README.md)

### [github-release-workflow](github-release-workflow/) ✅ complete

End-to-end release workflow: issue → branch → version bump → PR → CI wait → merge →
tag → GitHub release. Includes SSH authentication check before tag push.
→ [Full documentation](github-release-workflow/README.md)

### [roadmap-sync](roadmap-sync/) ✅ complete

Keeps README roadmaps in sync after code changes: reads the current state first,
ticks completed items, adds new ones, removes stale items. Always a standalone commit.
→ [Full documentation](roadmap-sync/README.md)

### [tf-guardrails](tf-guardrails/) ✅ complete
Terraform guardrails: provider version compatibility, AWS provider syntax, and checkov skip placement.
→ [Full documentation](tf-guardrails/README.md)

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

### [deps-integrity](deps-integrity/) ✅ complete

Checks dependency supply-chain integrity: `sha512` npm lockfile hashes, `sha256` Python lockfile
hashes (pip-tools, poetry, pipenv, uv) and npm Sigstore provenance attestations. Version pinning
alone does not stop a republished package; hashes enforced at install, plus signed provenance, do.
`check-lockfile-integrity.sh`, `check-python-lockfile-integrity.sh` and `check-provenance.sh` cover the three checks.
→ [Full documentation](deps-integrity/README.md)

### [ci-standards](ci-standards/) ✅ complete

Applies and audits standardised devops practices: semver versioning, atomic PR discipline,
testing standards, clone-ref pinning, and continuous review. Routes to existing skills for
implementation; provides shell scripts (`check-version-sync.sh`, `check-clone-refs.sh`,
`check-test-baseline.sh`, `check-roadmap-sync.sh`) for enforcement and auditing, and a
section for recording new practices as sessions reveal them.
→ [Full documentation](ci-standards/README.md)

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
orient              → assess current state (PRs, CI, stale branches)
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
py-lint                   → ensure code is formatted before final commit
        ↓
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
py-lint                   → ruff + black check/fix gate, pylint exceptions, re-stage
        ↓
        ↓
orient → (if SSH fails) switch to HTTPS, push, restore
```

### Workflow 4: Session start / orientation

**Trigger:** "What's the state of this repo?" / starting a new session on any project

```
orient              → platform state + README roadmap cross-check
        ↓
roadmap-sync              → (if items completed) tick and commit
```

### Workflow 5: Infrastructure / IaC changes

**Trigger:** "Adding a Terraform module" / "Upgrading provider" / IaC work

```
tf-guardrails → pre-flight: provider constraints, AWS syntax gotchas, checkov skip placement
```

### Workflow 6: Supply chain security audit

**Trigger:** "Check dependencies" / "Audit lockfile" / dependency review

```
deps-integrity   → Node.js lockfile sha512 coverage, Sigstore provenance on packages,
                   Python hash-based pinning across toolchains
```

### Workflow 7: Establish devops practices on a repo

**Trigger:** "Establish my devops practices" / "Is this repo compliant?" / onboarding a new project

```
ci-standards                 → audit repo against all practice categories
        ↓
check-version-sync.sh        → VERSION == tag == release?
check-clone-refs.sh          → no @main/@master in docs?
check-test-baseline.sh       → CI + baseline tests present?
        ↓
[address violations using routed skills]
        ↓
github-release-workflow      → (if version drift) align release
readme-version-pin           → (if unpinned refs) pin all
        ↓
ci-standards                 → (if new practice discovered) "Evolving this standard"
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
orient                  → verify final clean repo state
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|---------------|
| `orient` | Starting a session; need ground truth on repo state; before planning work |
| `repo-publication-prep` | Moving private → public; need file-size audit and history decision |
| `github-history-wipe` | Repo has sensitive history that cannot be filtered surgically |
| `repo-security-bootstrap` | New repo needs gitleaks + secret-scan workflow; bulk deploying to many repos |
| `python-ci-template` | Python repo has no CI or needs standardised CI from scratch |
| `dotnet-ci-template` | .NET repo has no CI or needs standardised CI from scratch |
| `py-lint` | About to commit Python code; need Ruff + Black checks (or safe auto-fixes), formatter setup, or pylint exceptions |
| `portfolio-readme-generator` | Repo needs a portfolio-quality README; publishing or updating docs |
| `github-morning-run` | Daily/weekly repo hygiene; checking PRs, auto-merging dependabots, checking CI status |
| `github-release-workflow` | Cutting a version: branch → PR → CI → merge → tag → release |
| `roadmap-sync` | Code changes completed; README roadmap needs ticking; pre-release state check |
| `docker-ghcr-publish` | Release tagged; need to build and push Docker images to GHCR |
| `readme-version-pin` | Release tagged; README install instructions reference old version |
| `deps-integrity` | Auditing Node.js or Python deps; lockfile hashes enforced, packages have Sigstore provenance |
| `tf-guardrails` | Writing or reviewing Terraform; adding modules, AWS resources, or checkov skips |
| `project-delivery-workflow` | Full delivery loop: clone → roadmap → feature branches → PRs → release |
| `ci-standards` | Establishing standards on a repo; auditing compliance; onboarding a project; capturing a newly discovered practice |
| `branch-surface-resolve` | Branches have accumulated across sessions; need to audit, surface conflicts, and land work via PRs |}
