# Project Workflows

A guide to which grimoire skills to use, in what order, for common project types.

These are not absolute rules — they're patterns extracted from successful sessions.
Adjust based on your specific context.

---

## Foundational layer: Every project starts here

**Always** begin with these three skills, regardless of project type:

### 1. **plan-spec** (01-meta)

Convert vague requirements into precise, testable success criteria.

```
Prompt: "Build a CLI tool that processes CSV files"
                              ↓ plan-spec
Output: Spec with:
  - Success criteria (handles 10k+ rows, <1s overhead, strict error handling)
  - Scope boundaries (CSV only, no spreadsheet formats, no streaming)
  - Definition of done (unit tests, integration test, documented error codes)
```

→ This prevents 80% of "rebuild it" requests downstream.

### 2. **plan-decompose** (01-meta)

If this is multi-session or >100K lines of code, pre-split into independent chunks.

```
plan-spec output
            ↓
   plan-decompose    →   5 task files, each with:
            ↓                 - Self-contained scope
      [Task 1]              - Verifiable done criteria
      [Task 2]              - No cross-task context needed
      [Task 3]
      [Task 4]
      [Task 5]
```

→ Prevents context-window collisions mid-project.

---

## Project type: Node.js library or service

**Skill stack:** plan-spec → plan-decompose → [dev] → deps-integrity → release → release-docker-ghcr (optional)

### Pre-development

1. **plan-spec** — Define the API surface, success criteria, breaking-change boundaries
2. **plan-decompose** — Split into: (1) core API, (2) tests, (3) docs, (4) release prep

### Development

1. **py-lint** *or equivalent* — Format and lint before committing (ESLint for JS)

### Pre-release

1. **deps-integrity** — Audit `package-lock.json` for integrity coverage
2. **release** — Version bump → PR → CI → merge → tag → release
3. **release-docker-ghcr** (optional) — Build and push images to GHCR

### Post-release

1. **plan-verify** — Test the release against the original spec criteria

---

## Project type: Python CLI tool or library

**Skill stack:** plan-spec → plan-decompose → [dev] → py-lint → ci-python → release

### Pre-development

1. **plan-spec** — Define the CLI interface, success criteria, error handling model
2. **plan-decompose** — Split into: (1) core logic, (2) CLI wrapper, (3) tests, (4) docs

### Development

1. **py-lint** — Write code in a Black + Ruff-stable style, then run the one-command gate (`--check` or `--fix`) with pylint exceptions before each commit

### Release prep

1. **ci-python** — Generate standardised CI (ruff, black, pytest, coverage matrix 3.9–3.12)
2. **release** — Version bump → PR → CI → merge → tag → release

### Post-release

1. **plan-verify** — Verify release against spec

---

## Project type: .NET / C# tool or library

**Skill stack:** plan-spec → plan-decompose → [dev] → ci-dotnet → release

### Pre-development

1. **plan-spec** — Define namespace structure, breaking-change boundaries, target frameworks
2. **plan-decompose** — Split into: (1) core logic, (2) unit tests, (3) integration tests, (4) docs

### Development

1. **ci-dotnet** — Generate standardised CI (build matrix Debug/Release, `dotnet format --verify-no-changes`, xUnit/NUnit coverage)

### Release prep

1. **release** — Version bump → PR → CI → merge → tag → release

### Post-release

1. **plan-verify** — Verify release against spec

---

## Project type: Terraform / IaC infrastructure

**Skill stack:** plan-spec → plan-decompose → [dev] → terraform-* skills → publish-secret-scan → release

### Pre-development

1. **plan-spec** — Define the target cloud state, success criteria, disaster-recovery assumptions
2. **plan-decompose** — Split into: (1) networking, (2) compute, (3) security, (4) monitoring, (5) docs

### Development

1. **tf-guardrails** — Before adding/upgrading modules, check provider constraints, apply known AWS syntax patterns (VPN, spot, Cognito edge cases), and enforce justifications on every security skip

### Security

1. **publish-secret-scan** — Deploy `.gitleaks.toml` + `secret-scan.yml` workflow

### Release prep

1. **release** — Version bump → PR → CI → merge → tag → release

---

## Project type: Security tool / Exploit

**Skill stack:** plan-spec → [07-devops security bootstrap] → [05-technical conventions] → [08-offsec conventions] → publish-readme → release

### Pre-development

1. **plan-spec** — Define the attack surface, success criteria, OPSEC constraints
2. **publish-secret-scan** — Deploy secret scanning upfront (credentials leak risk)

### Development

1. **[08-offsec specific skill]** — Load the relevant offsec convention (shellcode, BOF, EDR iteration, etc.)
2. **py-lint** — Format and lint before staging

### Pre-release

1. **publish-readme** — Write portfolio-quality README with authorised-use disclaimer
2. **release** — Version bump → PR → CI → merge → tag → release

---

## Project type: Prompt / AI skill (for grimoire)

**Skill stack:** session-skill-extractor → plan-spec → [01-meta README standards] → review-skill → release

### Extraction

1. **session-skill-extractor** — Proposed SKILL.md stub auto-generated from session transcript
2. **plan-spec** — Define when the skill activates, what it outputs, success criteria

### Vetting

1. **review-skill** — Safety audit (repo health, script calls, prompt injection)

### Integration

1. Update grimoire cluster README with skill entry
2. Add to `registry.json` if action-type
3. **release** — Create PR → CI → merge → tag → release

---

## Workflow: Multi-repo bulk operations

**Skill stack:** orient-authored-repos → [bulk task] → roadmap-sync → release

### Setup

1. **orient-authored-repos** — Filter to authored repos only (prevent forks from being processed)

### Bulk task

1. Apply the operation (e.g., `publish-secret-scan` on 16 repos, or `ci-python` on 12 repos)

### Cleanup

1. **roadmap-sync** — Tick completed items in each repo's README
2. **release** — Batch version bumps across all repos

---

## Workflow: Repository assessment

**Skill stack:** orient → [identify outstanding work] → roadmap

### Assessment

1. **orient** — Session-start orientation
   - GitHub platform state: PRs, issues, CI status, stale branches
   - README roadmap state: cross-check each unchecked item against codebase
   - Output: "true state" summary (catches "all clean" when roadmap items are pending)

### Next steps

1. If you need the roadmap broken down into executable chunks:
   - **roadmap** → selects next implementation-ready item and chains to:
     - `orient` (full state)
     - `plan-decompose` (break into chunks)
     - `plan` (decide which Karpathy layer)
     - `plan-verify` (evaluate output)

---

## Workflow: Mid-session context pressure

**Trigger:** "Context is getting full" / session sluggish / about to hit limits

```
        ↓
plan-handoff      →  package state for a fresh session to continue
        ↓
[new session loads handoff document]
```

---

## Workflow: Review and verification

**Skill stack:** plan-verify

### After development

1. **plan-verify** — Second-opinion evaluation against your original spec criteria
   - Different model or role review
   - External signal testing (run it, check output)
   - Feedback loops improve quality 2–3× per invocation

---

## Workflow: Session start (any project)

Load this before diving into project-specific work:

```
orient-authored-repos  →  (multi-repo only) "Scope to authored repos"
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
/plan-spec
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
