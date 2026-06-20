# Project Workflows

A guide to which grimoire skills to use, in what order, for common project types.

These are not absolute rules — they're patterns extracted from successful sessions.
Adjust based on your specific context.

---

## Foundational layer: Every project starts here

**Always** begin with these three skills, regardless of project type:

### 1. **karpathy-spec** (01-meta)

Convert vague requirements into precise, testable success criteria.

```
Prompt: "Build a CLI tool that processes CSV files"
                              ↓ karpathy-spec
Output: Spec with:
  - Success criteria (handles 10k+ rows, <1s overhead, strict error handling)
  - Scope boundaries (CSV only, no spreadsheet formats, no streaming)
  - Definition of done (unit tests, integration test, documented error codes)
```

→ This prevents 80% of "rebuild it" requests downstream.

### 2. **task-decomposer** (01-meta)

If this is multi-session or >100K lines of code, pre-split into independent chunks.

```
karpathy-spec output
            ↓
   task-decomposer    →   5 task files, each with:
            ↓                 - Self-contained scope
      [Task 1]              - Verifiable done criteria
      [Task 2]              - No cross-task context needed
      [Task 3]
      [Task 4]
      [Task 5]
```

→ Prevents context-window collisions mid-project.

### 3. **cwd-verification** (01-meta)

Confirm you're in the right directory before bulk operations.

---

## Project type: Node.js library or service

**Skill stack:** karpathy-spec → task-decomposer → [dev] → npm-lockfile-integrity → github-release-workflow → docker-ghcr-publish (optional)

### Pre-development

1. **karpathy-spec** — Define the API surface, success criteria, breaking-change boundaries
2. **task-decomposer** — Split into: (1) core API, (2) tests, (3) docs, (4) release prep
3. **cwd-verification** — Confirm you're in the right repo

### Development

1. **format-before-commit** — Auto-format + review hook changes before staging
2. **python-ci-lint-precheck** *or equivalent* — Lint before committing (ESLint for JS)

### Pre-release

1. **npm-lockfile-integrity** — Audit `package-lock.json` for integrity coverage
2. **github-release-workflow** — Version bump → PR → CI → merge → tag → release
3. **docker-ghcr-publish** (optional) — Build and push images to GHCR

### Post-release

1. **karpathy-verify** — Test the release against the original spec criteria

---

## Project type: Python CLI tool or library

**Skill stack:** karpathy-spec → task-decomposer → python-black-ruff-authoring → [dev] → python-lint-gate → python-ci-lint-precheck → format-before-commit → python-ci-template → github-release-workflow

### Pre-development

1. **karpathy-spec** — Define the CLI interface, success criteria, error handling model
2. **task-decomposer** — Split into: (1) core logic, (2) CLI wrapper, (3) tests, (4) docs
3. **cwd-verification** — Confirm directory

### Development

1. **python-black-ruff-authoring** — Write code in a style likely to pass Black + Ruff first pass
2. **python-lint-gate** — One-command Ruff + Black gate (`--check` or `--fix`)
3. **python-ci-lint-precheck** — Ruff + pylint before each commit
4. **format-before-commit** — Black + ruff auto-format with review

### Release prep

1. **python-ci-template** — Generate standardised CI (ruff, black, pytest, coverage matrix 3.9–3.12)
2. **github-release-workflow** — Version bump → PR → CI → merge → tag → release

### Post-release

1. **karpathy-verify** — Verify release against spec

---

## Project type: .NET / C# tool or library

**Skill stack:** karpathy-spec → task-decomposer → [dev] → dotnet-ci-template → github-release-workflow

### Pre-development

1. **karpathy-spec** — Define namespace structure, breaking-change boundaries, target frameworks
2. **task-decomposer** — Split into: (1) core logic, (2) unit tests, (3) integration tests, (4) docs
3. **cwd-verification** — Confirm directory

### Development

1. **dotnet-ci-template** — Generate standardised CI (build matrix Debug/Release, `dotnet format --verify-no-changes`, xUnit/NUnit coverage)

### Release prep

1. **github-release-workflow** — Version bump → PR → CI → merge → tag → release

### Post-release

1. **karpathy-verify** — Verify release against spec

---

## Project type: Terraform / IaC infrastructure

**Skill stack:** karpathy-spec → task-decomposer → [dev] → terraform-* skills → repo-security-bootstrap → github-release-workflow

### Pre-development

1. **karpathy-spec** — Define the target cloud state, success criteria, disaster-recovery assumptions
2. **task-decomposer** — Split into: (1) networking, (2) compute, (3) security, (4) monitoring, (5) docs
3. **cwd-verification** — Confirm directory

### Development

1. **terraform-version-compat** — Before adding/upgrading modules, check provider constraints
2. **terraform-aws-syntax** — Apply known AWS syntax patterns (VPN, spot, Cognito edge cases)
3. **terraform-checkov-skips** — Enforce justifications on every security skip

### Security

1. **repo-security-bootstrap** — Deploy `.gitleaks.toml` + `secret-scan.yml` workflow

### Release prep

1. **github-release-workflow** — Version bump → PR → CI → merge → tag → release

---

## Project type: Security tool / Exploit

**Skill stack:** karpathy-spec → [07-devops security bootstrap] → [05-technical conventions] → [08-offsec conventions] → portfolio-readme-generator → github-release-workflow

### Pre-development

1. **karpathy-spec** — Define the attack surface, success criteria, OPSEC constraints
2. **repo-security-bootstrap** — Deploy secret scanning upfront (credentials leak risk)
3. **cwd-verification** — Confirm directory

### Development

1. **[08-offsec specific skill]** — Load the relevant offsec convention (shellcode, BOF, EDR iteration, etc.)
2. **format-before-commit** — Code review before staging

### Pre-release

1. **portfolio-readme-generator** — Write portfolio-quality README with authorised-use disclaimer
2. **github-release-workflow** — Version bump → PR → CI → merge → tag → release

---

## Project type: Prompt / AI skill (for grimoire)

**Skill stack:** session-skill-extractor → karpathy-spec → [01-meta README standards] → skill-vetter → github-release-workflow

### Extraction

1. **session-skill-extractor** — Proposed SKILL.md stub auto-generated from session transcript
2. **karpathy-spec** — Define when the skill activates, what it outputs, success criteria

### Vetting

1. **skill-vetter** — Safety audit (repo health, script calls, prompt injection)

### Integration

1. Update grimoire cluster README with skill entry
2. Add to `registry.json` if action-type
3. **github-release-workflow** — Create PR → CI → merge → tag → release

---

## Workflow: Multi-repo bulk operations

**Skill stack:** cwd-verification → github-authored-repos → [bulk task] → roadmap-sync → github-release-workflow

### Setup

1. **cwd-verification** — Confirm you're in the right parent directory
2. **github-authored-repos** — Filter to authored repos only (prevent forks from being processed)

### Bulk task

1. Apply the operation (e.g., `repo-security-bootstrap` on 16 repos, or `python-ci-template` on 12 repos)

### Cleanup

1. **roadmap-sync** — Tick completed items in each repo's README
2. **github-release-workflow** — Batch version bumps across all repos

---

## Workflow: Repository assessment

**Skill stack:** repo-compass → [identify outstanding work] → roadmap-driver

### Assessment

1. **repo-compass** — Session-start orientation
   - GitHub platform state: PRs, issues, CI status, stale branches
   - README roadmap state: cross-check each unchecked item against codebase
   - Output: "true state" summary (catches "all clean" when roadmap items are pending)

### Next steps

1. If you need the roadmap broken down into executable chunks:
   - **roadmap-driver** → selects next implementation-ready item and chains to:
     - `repo-compass` (full state)
     - `task-decomposer` (break into chunks)
     - `karpathy-framework` (decide which Karpathy layer)
     - `karpathy-verify` (evaluate output)

---

## Workflow: Mid-session context pressure

**Trigger:** "Context is getting full" / session sluggish / about to hit limits

```
mid-task-checkin  →  pause, check for new instructions, confirm direction
        ↓
task-handoff      →  package state for a fresh session to continue
        ↓
[new session loads handoff document]
```

---

## Workflow: Review and verification

**Skill stack:** karpathy-verify → test-before-asking

### After development

1. **karpathy-verify** — Second-opinion evaluation against your original spec criteria
   - Different model or role review
   - External signal testing (run it, check output)
   - Feedback loops improve quality 2–3× per invocation

### Before accepting AI output

1. **test-before-asking** — Try the reasonable interpretation rather than clarifying
   - Defined decision threshold: try first, ask only for destructive/expensive/preference-dependent actions
   - Indexed by action type

---

## Workflow: Session start (any project)

Always load these three before diving into project-specific work:

```
cwd-verification       →  "Am I in the right directory?"
        ↓
verify-code-version    →  "Is my working tree current?"
        ↓
github-authored-repos  →  (multi-repo only) "Scope to authored repos"
```

---

## Why these orderings?

1. **Spec first** — Prevents rebuilding mid-project when requirements clarify
2. **Decompose early** — Prevents context-window collisions on large projects
3. **Verify last** — Catches hidden quality issues before release
4. **Security early** — Repos are immutable after pushing — secret scan upfront, not retroactively
5. **Release late** — Version bumps and tags only once code is stable

---

## How to invoke a skill

Once installed (via `bash install-all.sh` or `bash install-vscode.sh`), invoke a skill:

**Explicit:** Reference by name

```
/karpathy-spec
Build a CLI tool that converts Markdown to Word documents, with embedded images.
```

**Implicit:** Describe your task, Claude recognises the trigger

```
I'm starting a Python project. What should I build first?
```

Skill names follow the folder names: `[cluster]/[skill-name]/` → invoke as `#skill-name` in Copilot Chat or `/skill-name` in Claude Code.

---

## Roadmap items

Many grimoire skills have open roadmap items. See [ROADMAP.md](ROADMAP.md) for:

- Worked examples (e.g., "full SaaS UI audit with top-3 fixes implemented")
- Stack-specific variants (e.g., "React+Tailwind vs Vue vs Svelte checklists")
- Real-world validation from live sessions

If you complete one of these items, open a PR to update the skill's README and move the item to "complete".
