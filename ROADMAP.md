# Roadmap

> Auto-generated overview of outstanding work across all public skill clusters.
> Run `bash scripts/roadmap-collect.sh` to regenerate, or `bash scripts/roadmap-collect.sh --json` for machine-readable output.

**Last updated:** 2025-07-14
**Open items:** 95 | **Completed:** 185

---

## Priority legend

Most open items fall into two categories:

| Category | Description | Action needed |
|----------|-------------|---------------|
| 🧪 **Requires real session** | Item can only be closed during actual usage | Wait for opportunity |
| 📝 **Worked example** | Needs a concrete before/after or step-by-step | Author when time allows |

Items marked "Ship: copy to ~/.claude/skills/..." are legacy — the install path is now automated via `install-all.sh`.

---

## Open items by cluster

### 01-meta

- **cwd-verification**: Add all known path pairs as they are encountered
- **github-authored-repos**: Test on one multi-repo session (requires real session)
- **github-authored-repos**: Document any new gotchas from real usage (requires real usage)
- **karpathy-environment**: Ship: copy to `~/.claude/skills/karpathy-environment/`
- **karpathy-framework**: Ship: copy to `~/.claude/skills/karpathy-framework/`
- **karpathy-spec**: Ship: copy to `~/.claude/skills/karpathy-spec/`
- **karpathy-verify**: Ship: copy to `~/.claude/skills/karpathy-verify/`
- **mid-task-checkin**: Consider a heuristic for detecting user typing mid-task (if tooling permits)
- **mid-task-checkin**: Add worked example: long 10-step refactor session with two check-in points shown
- **session-skill-extractor**: Multi-session aggregation (combine patterns across sessions)
- **session-skill-extractor**: Per-project pattern weighting
- **session-skill-extractor**: Confidence scoring improvements
- **skill-vetter**: Test on 3 real third-party skills (requires real sessions)
- **task-decomposer**: Add example: grimoire Cat 5 decomposed into 6 chunks (worked example)
- **task-decomposer**: Add `--resume` mode: reads existing run-book, skips completed chunks
- **task-handoff**: Add worked example: mid-session handoff from a real grimoire Cat 5 chunk
- **task-handoff**: Add `--auto` mode: triggered automatically when context exceeds a threshold
- **test-before-asking**: Add concrete examples of ask vs test for common session types
- **test-before-asking**: Test across 5 sessions to confirm the rule lands correctly
- **verify-code-version**: Test on DNSResolver and Slice-N-Dice sessions

### 02-comms

- **executive-translate**: Build 3 worked examples (finding → CISO brief, incident → board summary, risk → C-suite ask)
- **executive-translate**: Add worked examples for different audience tiers (CISO, C-suite, board)
- **executive-translate**: Test on 3 real findings
- **human-rewrite**: Build worked before/after examples for each style rule
- **human-rewrite**: Test on 5 real outputs from other skills
- **human-rewrite**: Add any further rules that emerge from real usage
- **tone-check**: Test on 5 real drafts across different audience tiers
- **tone-check**: Add worked examples of PASS vs FLAG vs borderline for each axis

### 03-incident

- **incident-appendix**: Test on 2 real investigation write-ups
- **incident-ask-builder**: Add worked example for common incident types
- **incident-ask-builder**: Test on 2 real incident scenarios
- **risk-to-action**: Test on 3 real risk items

### 04-security

- **ios-signing-risk**: Add Apple Developer Portal log retention window specifics
- **ios-signing-risk**: Test on a real IPA integrity scenario

### 05-technical

- **pe-binary-analysis**: Add syscall hook detection byte-pattern reference (clean stub patterns for common syscalls)
- **pe-binary-analysis**: Add worked example: full import table walk without WinAPI
- **pe-binary-analysis**: Add worked example: section table traversal with RVA/file-offset conversion
- **pe-binary-analysis**: Test on 2 real PE parsing sessions
- **ui-ux-product-audit**: Add worked example: full SaaS UI audit with implemented top-3 fixes
- **ui-ux-product-audit**: Add stack-specific checklist variants (React+Tailwind, Vue, Svelte)
- **ui-ux-product-audit**: Test on 3 real frontend repos and capture recurring anti-patterns

### 07-devops

- **docker-ghcr-publish**: Add `--platform linux/amd64,linux/arm64` multi-arch build support
- **docker-ghcr-publish**: Add GitHub Actions workflow snippet for automated GHCR publish on tag push
- **docker-ghcr-publish**: Test on pdf2john-docker and bgp_rogue
- **dotnet-ci-template**: Test on one new repo (requires real session)
- **dotnet-ci-template**: Document any new gotchas from real usage (requires real session)
- **format-before-commit**: Test on 3 Python repos
- **git-push-protocol-handler**: Add SSH agent start/add sequence for when agent is simply not running
- **git-push-protocol-handler**: Test on a representative set of repos
- **github-history-wipe**: Test on one repo end-to-end (requires real session)
- **github-history-wipe**: Document any new gotchas from real usage (requires real session)
- **github-release-workflow**: Add CHANGELOG generation step
- **github-release-workflow**: Add variant for repos without a release branch (direct tag on main)
- **github-release-workflow**: Test on DNSResolver v2 release
- **npm-lockfile-integrity**: Add GitHub Actions workflow snippet for lockfile drift gating
- **npm-lockfile-integrity**: Test on 3 Node.js repos
- **npm-lockfile-integrity**: Ship: copy to `~/.claude/skills/npm-lockfile-integrity/`
- **npm-provenance-attestation**: Add GitHub Actions workflow snippet for provenance gating
- **npm-provenance-attestation**: Test on 3 Node.js repos with mixed provenance coverage
- **npm-provenance-attestation**: Ship: copy to `~/.claude/skills/npm-provenance-attestation/`
- **devops-practices**: Add CI workflow snippet that runs all three check scripts on PR
- **devops-practices**: Add `--fix` mode to `check-clone-refs.sh` (auto-update refs to current VERSION)
- **devops-practices**: Add GitHub Actions version-pinning check (workflow files, not just docs)
- **devops-practices**: Add scheduled CI template for periodic test execution
- **devops-practices**: Test all three check scripts on 3 repos (grimoire, DNSResolver, Slice-N-Dice)
- **devops-practices-updater**: Add automatic detection via session-skill-extractor routing
- **portfolio-readme-generator**: Add README linter to check structure compliance post-generation
- **portfolio-readme-generator**: Add per-language examples (Python CLI, C# Windows tool, C++ BOF)
- **portfolio-readme-generator**: Test on 5 repos
- **pre-commit-aware-commits**: Add gitleaks false-positive allowlist template
- **pre-commit-aware-commits**: Test on DNSResolver and Slice-N-Dice
- **python-ci-lint-precheck**: Test on Slice-N-Dice and DNSResolver
- **python-ci-template**: Test on one new repo (requires real session)
- **python-ci-template**: Document any new gotchas from real usage (requires real session)
- **python-lockfile-integrity**: Test on 3 Python repos (pip-tools, poetry, uv variants)
- **python-lockfile-integrity**: Ship: copy to `~/.claude/skills/python-lockfile-integrity/`
- **readme-version-pin**: Add `--pattern` flag to `pin_readme_version.sh` for custom install line formats
- **readme-version-pin**: Test on DNSResolver and Slice-N-Dice release cuts
- ~~**repo-compass**: Test on 3 repos with varying states (tidy, lagged, genuinely outstanding)~~ ✅ tested on grimoire (101 unchecked items, genuinely outstanding), grimoire-private (14 unchecked, genuinely outstanding) — 2026-06-14
- **repo-publication-prep**: Test end-to-end on one new repo (requires real session)
- **repo-publication-prep**: Document any new gotchas from real usage (requires real usage)
- **repo-security-bootstrap**: Test on one repo end-to-end (requires real session)
- **repo-security-bootstrap**: Document any new gotchas from real usage (requires real session)
- **roadmap-sync**: Test on DNSResolver and Slice-N-Dice
- **terraform-aws-syntax**: Add resource type gotchas as they are encountered
- **terraform-aws-syntax**: Add provider version matrix for known argument type changes
- **terraform-checkov-skips**: Add common skip patterns and their justifications
- **terraform-version-compat**: Add known-good version matrix for frequently used module combinations

### 08-offsec

- **api-hashing-conventions**: Add worked end-to-end example pairing with `shellcode-dev-conventions`
- **bof-dev-conventions**: Add Havoc demon module API comparison
- **bof-dev-conventions**: Add fork-and-run vs inline guidance with OPSEC notes
- **bof-dev-conventions**: Add Makefile template
- **c2-integration-checklist**: Add Havoc-specific demon module integration details
- **c2-integration-checklist**: Add DNS listener OPSEC checklist (TTL, NS delegation, authoritative zone config)
- **c2-integration-checklist**: Add post-engagement cleanup checklist (artifact removal, implant termination confirmation)
- **edr-test-loop**: Add AMSI bypass sub-loop
- **edr-test-loop**: Add ETW patching considerations and risk notes
- **edr-test-loop**: Add memory-at-rest (sleep mask) test sub-loop
- **process-injection-taxonomy**: Add Cobalt Strike-specific guidance (BOF vs post-ex DLL vs fork-and-run)
- **process-injection-taxonomy**: Add table row for thread pool injection (TpAllocWork)
- **process-injection-taxonomy**: Add table row for kernel-mode techniques (driver-based)
- **process-injection-taxonomy**: Link edr-test-loop workflow for validation phase
- **shellcode-dev-conventions**: Add x86 `fs:[0x30]` PEB walk variant with concrete offsets
- **shellcode-dev-conventions**: Add worked example: minimal `MessageBoxA` shellcode (x64) end-to-end

---

## Infrastructure roadmap

These are repo-level improvements not tied to individual skills:

- [x] Add grimoire-private cluster README standardisation (mirror public format)
- [x] Add `scripts/roadmap-close.sh` — marks items done by skill name + index
- [x] Add MCP tool for roadmap query (`grimoire-roadmap-status`)
- [x] Investigate semantic search across SKILL.md content for skill discovery
- [x] Add skill dependency graph generation (which skills reference others)
- [x] Add `uninstall-vscode.sh` — removes grimoire entry from mcp.json, removes prompt path from settings.json, deletes prompts/ build output
- [x] Add `uninstall-all.sh` — removes grimoire-managed skills from a target skills directory (default: `~/.claude/skills`)
- [x] Timestamped versioned backups for `install-all.sh` (Claude Code) — same pattern as install-vscode.sh (date-stamped, keep last 5)
- [x] Add `--update` mode to `install-all.sh` — backs up existing skill to `.backups/<skill>-YYYYMMDD-HHMMSS/`, overwrites with latest, prunes to 5 backups. `--force` to overwrite without backup. Default remains skip-if-exists for safety.
- [x] Add `roadmap-driver` skill (01-meta) — reads outstanding roadmap items, selects next work item, invokes karpathy-framework to plan and execute. Chains: repo-compass (assess) → task-decomposer (break down) → karpathy-framework (plan) → karpathy-verify (confirm). Trigger: "what should I work on next?" / "pick up from the roadmap"
- [x] Cluster README "when to use" enhancement — each cluster README gains a workflow section explaining when/how each skill should be invoked, with trigger phrases and ideal sequencing. ~~Start with 07-devops as template, then roll out to all clusters (01-meta through 09-odpc)~~ completed for public clusters (2026-06-15); private clusters were handled in `grimoire-private` (06-study and 09-odpc).
- [x] Add MCP server logging — file-based + stderr, structured format with timestamps, context, and metadata (`mcp-server/src/logger.ts`)
- [x] Add fail-open error handling — tool failures return error content instead of crashing the server; registry load failure starts with 0 tools; global uncaught exception/rejection handlers keep server alive
- [x] Add MCP server health-check tool — a no-op `grimoire_health` tool that returns server uptime, tool count, and log file path for diagnostics
- [x] Add MCP server log rotation — prevent unbounded log growth (rotate at 10MB, keep 3)
- [x] Add `install-jetbrains.sh` — JetBrains MCP support (bypasses corporate VS Code MCP policy). Includes path auto-detection, `--mcp-path` override, backup support, and dry-run/apply modes.
- [ ] Post-merge changelog tidy pass — sync `CHANGELOG.md` with latest merged PRs and release notes after each infrastructure batch.
