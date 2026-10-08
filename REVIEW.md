# Holistic review: discoverability and consolidation (2026-09-29)

Scope: public `clusters/` (57 skills), install and build scripts, MCP server, CI.
`clusters-private/` and `clusters-offsec/` are out of scope (empty in this checkout;
the real private and offsec clusters live in separate repos).

Decisions already taken with the owner (do not re-open them while executing this plan):

| Decision | Outcome |
|---|---|
| Delivery surfaces in use | All four: Claude Code (this Mac), VS Code/Copilot prompt files, JetBrains MCP, and VS Code plus JetBrains on a second machine |
| Renaming appetite | Hard rename in one planned batch, no alias stubs |
| Naming scheme | Pathway prefix (see [Canonical rename map](#canonical-rename-map)) |
| Always-on behavioural skills | Delete (revised in the 2026-10-04 audit: three duplicate Claude Code built-ins, two become global CLAUDE.md lines, Python authoring folds into `py-lint`) |

---

## 1. Executive summary

The main discoverability failure is a metadata failure, not a naming one. **None of the
57 `SKILL.md` files has YAML frontmatter**, so Claude Code lists every grimoire skill
with its own name as its description (for example `branch-surface-resolve:
branch-surface-resolve`). Claude cannot select a skill from intent, and the human
cannot browse by purpose. Descriptions also come from three unsynchronised sources
(none for Claude Code, a 200-character scrape in `build.sh`, and hand-written text in
`mcp-server/registry.json`). On this Mac, across 151 sessions from July to September
2026, only about 15 of the 57 skills were ever invoked, and each invocation was
explicit, by name. The fix order is: (1) frontmatter as the single description
source, with a measurable discoverability test; (2) cross-machine usage telemetry;
(3) consolidation and the pathway-prefix rename, which cuts 57 skills to 41, grouped
under 13 prefixes. Other health is good: CI is comprehensive and secrets scanning is
layered. The only material hygiene items are transitive npm advisories in the MCP
server and a roadmap dominated by validation items that cannot close.

---

## 2. Evidence

### 2.1 Frontmatter and description sources

| Surface | Where the description comes from | State |
|---|---|---|
| Claude Code (`~/.claude/skills`) | `SKILL.md` YAML frontmatter `description:` | **Missing in 57/57 files.** Falls back to the skill name. |
| VS Code prompt files | `build.sh:49`, first 5 lines of `## Description`, truncated to 200 chars | Works, but truncates mid-sentence and drops the "Invoke when" triggers |
| MCP tools (VS Code, JetBrains) | Hand-written `description` in `mcp-server/registry.json` | 24 entries, drifts independently of `SKILL.md` |

### 2.2 Usage (Claude Code transcripts, this Mac only, 2026-07-09 to 2026-09-29)

Method: parsed `~/.claude/projects/*/*.jsonl` for `Skill` tool calls, `mcp__grimoire__*`
tool calls, and slash-command tags. **Limitation:** the second machine (VS Code and
JetBrains) is not covered, so zero here does not prove zero overall. That is why RA-06
(telemetry) comes before any pruning.

- Invoked at least once: `codebase-holistic-review`, `devops-practices`,
  `github-morning-run`, `repo-compass`, `karpathy-framework`, `pre-push-validation`,
  `github-release-workflow`, `model-selection-framework`, `skill-keyword-lookup`,
  `karpathy-spec`, `devops-practices-updater`, `format-before-commit`,
  `python-black-ruff-authoring`, `task-decomposer`, `ui-ux-product-audit`,
  `mid-task-checkin`, `roadmap-driver`.
- Zero recorded invocations: every 02-comms, 03-incident, 04-security and terraform
  skill; all three supply-chain skills; the whole publish pathway; `local-ci`;
  `roadmap-sync`; `task-handoff`; `karpathy-verify`; and the rest.
- MCP tool calls recorded on this Mac: zero.
- Most common observed chain: `repo-compass → devops-practices → github-morning-run /
  github-release-workflow → codebase-holistic-review`. `skill-keyword-lookup` appears
  mid-chain twice, which shows the owner hunting for a name.

### 2.3 Fragmentation (functional overlap)

| Overlap | Skills | Verdict |
|---|---|---|
| Run CI workflows locally | `local-ci`, `pre-push-validation` | Duplicate. Both parse `.github/workflows/*.yml` and run `run:` steps. `local-ci` is the superset (hooks, auto-fix, `--sync`). |
| Make Python pass Black/Ruff | `python-lint-gate`, `format-before-commit`, `python-ci-lint-precheck`, `python-black-ruff-authoring`, plus `pre-commit-aware-commits` | Five skills, one outcome. Merge into one task skill plus one rule. |
| Dependency integrity | `npm-lockfile-integrity`, `python-lockfile-integrity`, `npm-provenance-attestation` | Same control family, different ecosystems. Merge, keep scripts. |
| Terraform authoring | `terraform-aws-syntax`, `terraform-checkov-skips`, `terraform-version-compat` | Three small (61 to 69 lines) guardrail notes. Merge. |
| Roadmap | `roadmap-driver`, `grimoire-roadmap-status`, `roadmap-sync`, `project-delivery-workflow` | `grimoire-roadmap-status` is a subset of `roadmap-driver`. |
| DevOps standard | `devops-practices`, `devops-practices-updater` | Updater is a section, not a skill. |
| "Always active" rules | `test-before-asking`, `cwd-verification`, `verify-code-version`, `mid-task-checkin`, `pre-commit-aware-commits`, `python-black-ruff-authoring` | Skills load on trigger, so "always active" never happens. Should be rules. |

### 2.4 Documentation drift

- `README.md` Skills Index is hand-maintained and missing 10 skills:
  `grimoire-roadmap-status`, `model-selection-framework`, `roadmap-driver`,
  `ui-ux-product-audit`, `branch-surface-resolve`, `devops-practices-updater`,
  `devops-practices`, `github-morning-run`, `local-ci`, `pre-push-validation`.
- `README.md` cluster table describes 05-technical as "Test bootstrapping" only.
- `PROJECT-WORKFLOWS.md` is the only place pathways are described, and it recommends
  the overlapping lint skills in sequence (e.g. `python-lint-gate → python-ci-lint-precheck
  → format-before-commit`).
- `ROADMAP.md`: 49 open items, of which about 30 are "Test on N real X" validation
  items. These cannot close while the skills never fire, which inflates the open count.

---

## 3. Architecture map

| Module / Path | Responsibility | Concerns |
|---|---|---|
| `clusters/<NN-name>/<skill>/SKILL.md` | Canonical skill source | No frontmatter. Metadata lives in a `> **Status/Cluster/Type**` blockquote that only grimoire tooling parses. |
| `clusters/*/README.md` | Cluster index and workflow notes | Hand-maintained, drifts |
| `install-all.sh` / `uninstall-all.sh` | Copy skills to `~/.claude/skills` | No knowledge of renamed skills; a rename leaves old copies installed |
| `build.sh` | Generate `prompts/*.prompt.md` for Copilot | Own description scraper (see 2.1) |
| `install-vscode.sh`, `install-jetbrains.sh` | Build MCP server, merge IDE config | Fine |
| `mcp-server/` (`registry.json`, `src/`) | Expose `Type: action` skills as MCP tools | Registry descriptions hand-written; `registry.test.ts` hard-codes `clusters/01-meta` and `clusters/07-devops` |
| `scripts/` | Roadmap collection/close, dependency graph, release backfill | Fine |
| `clusters/07-devops/devops-practices/check-*.sh` | Repo enforcement scripts used by `devops-check.yml` and pre-commit | Paths are referenced by CI and `.pre-commit-config.yaml`; a rename must update both |
| `.github/workflows/` | validate, ci-mcp, secret-scan, devops-check, release-please | Comprehensive |

Data flow: `SKILL.md` → (`install-all.sh` copy | `build.sh` render | `registry.json` →
MCP server) → assistant. The single-source principle in `README.md` holds for content
but not for descriptions.

---

## 4. Risk inventory

| # | Category | Finding | Score | Location |
|---|---|---|---|---|
| 1 | Maintainability | No frontmatter: Claude Code cannot route to any skill by intent | 5 | `clusters/*/*/SKILL.md` |
| 2 | Maintainability | Three unsynchronised description sources | 4 | `build.sh:49`, `mcp-server/registry.json` |
| 3 | Maintainability | Duplicate and overlapping skills (section 2.3) | 4 | `clusters/07-devops/*` |
| 4 | Maintainability | "Always active" behaviour encoded as lazily loaded skills | 3 | six skills in 2.3 |
| 5 | Maintainability | Hand-maintained indexes drift (README Skills Index missing 10) | 3 | `README.md` |
| 6 | Reliability | Rename without an old-name list leaves stale skills installed on every machine | 3 | `install-all.sh`, `uninstall-all.sh` |
| 7 | Reliability | Destructive scripts (history wipe, release recreate, installers) have no tests beyond shellcheck | 3 | `clusters/07-devops/github-history-wipe/*.sh`, `install-all.sh` |
| 8 | Dependency | 3 high, 5 moderate, 1 low npm advisories (transitive via `@modelcontextprotocol/sdk`: `fast-uri`, `hono`, `@hono/node-server`, `body-parser`). Server uses stdio, so exposure is low. | 2 | `mcp-server/package-lock.json` |
| 9 | Dependency | TruffleHog pre-commit `v3.95.2` vs CI `v3.97.6` | 1 | `.pre-commit-config.yaml` |
| 10 | Security | Actions pinned to tags, not SHAs | 2 | `.github/workflows/*.yml` |
| 11 | Maintainability | Global `~/.claude/rules/git-ci.md` is a publish procedure loaded into every session, and names `pre-push-validation` (to be retired) | 2 | outside repo |

## 5. Predicted failure scenarios (score 3 and above)

**PF-1 (risk 1): skills never fire.** Happening today. Any session that does not name
a skill explicitly gets no grimoire help. Minimum fix: RA-02. Full fix: RA-01 to RA-04, checked by the RA-05 spot-check.

**PF-2 (risk 2): descriptions diverge per surface.** After the frontmatter lands, the
MCP registry and prompt files keep old text, so VS Code and JetBrains route
differently from Claude Code. Fix: RA-03.

**PF-3 (risk 3): consolidation loses capability.** Merging `local-ci` and
`pre-push-validation` or the lint skills without a feature diff silently drops a
behaviour (for example `pre-push-validation`'s explicit skip-reason list). Fix: every
merge item requires a written feature-parity checklist.

**PF-4 (risk 6): rename strands old skills.** On the second machine, `install-all.sh
--update` installs the new names but leaves the old directories, doubling the listing.
Trigger: first install after RA-15. Fix: `scripts/renamed-skills.txt` consumed by
install and uninstall (RA-15).

**PF-5 (risk 7): history-wipe regression.** A future edit to
`capture-releases.sh`/`recreate-releases.sh` breaks release recreation after a force
push, and the loss is discovered only on a real repo. Accepted risk: the skill has no recorded use, so the 2026-10-04 audit dropped the planned test harness (RA-21).

## 6. Test coverage gaps

| Path | Why critical | Test type needed |
|---|---|---|
| Skill frontmatter | Discoverability depends on it | CI validator (RA-01) |
| Intent to skill routing | The key success criterion | Manual spot-check in a fresh session (RA-05); a keyword scorer would measure the wrong thing |
| `install-all.sh --update` with renamed skills | Stale skills on every machine | bats test with a temp skills dir (RA-15) |
| `mcp-server` tool execution per skill | Only a smoke and registry test exist | Add one executor test per merged skill (RA-08 to RA-13) |

## 7. Dependency audit

- `mcp-server/package.json`: all versions exact-pinned. Good.
- `npm audit`: 9 advisories, all transitive, all "fix available via `npm audit fix`".
- Dependabot is configured (`.github/dependabot.yml`, since #39) for scheduled drift detection. (Corrected 2026-10-08; the original review missed it.)

## 8. CI/CD gaps

| Check | State |
|---|---|
| Tests on every PR | Yes (`ci-mcp.yml` path-filtered, `validate.yml`) |
| Lint and format | Yes (shellcheck, eslint) |
| Secret scanning | Yes (gitleaks, TruffleHog, detect-secrets locally) |
| Action versions pinned | Tags only, not SHAs (RA-20) |
| Scheduled dependency drift | Yes (Dependabot) |
| Frontmatter | **No** (RA-01, RA-03) |

---

## Canonical rename map

This table is the specification for RA-07 to RA-18 (revised 2026-10-04). 57 skills become
41 skills, under 13 prefixes: `orient`, `plan`, `roadmap`, `py`, `ci`, `deps`,
`release`, `publish`, `tf`, `write`, `incident`, `review`, `grimoire`. The bare prefix,
where it exists, is the pathway entry skill that lists its steps in order.

| Current | New | How |
|---|---|---|
| `repo-compass` | `orient` | Rename, becomes entry (RA-14) |
| `branch-surface-resolve` | `orient-branches` | Rename |
| `github-morning-run` | `orient-morning-run` | Rename |
| `github-authored-repos` | `orient-authored-repos` | Rename |
| `cwd-verification` | one line in global `~/.claude/CLAUDE.md` | Delete (RA-07) |
| `verify-code-version` | one line in global `~/.claude/CLAUDE.md` | Delete (RA-07) |
| `git-push-protocol-handler` | section and script in `orient` | Merge (RA-14) |
| `karpathy-framework` | `plan` | Rename (already a router) |
| `karpathy-spec` | `plan-spec` | Rename |
| `karpathy-verify` | `plan-verify` | Rename |
| `karpathy-environment` | `plan-environment` | Rename |
| `task-decomposer` | `plan-decompose` | Rename |
| `task-handoff` | `plan-handoff` | Rename |
| `model-selection-framework` | `plan-model-tier` | Rename |
| `test-before-asking` | Claude Code auto mode | Delete (RA-07) |
| `mid-task-checkin` | Claude Code queued messages | Delete (RA-07) |
| `roadmap-driver` (+ delete `grimoire-roadmap-status`) | `roadmap` | Rename (RA-13) |
| `roadmap-sync` | `roadmap-sync` | Unchanged |
| `project-delivery-workflow` | `roadmap-deliver` | Rename |
| `python-lint-gate` + `format-before-commit` + `python-ci-lint-precheck` + `python-black-ruff-authoring` | `py-lint` | Merge (RA-09) |
| `pre-commit-aware-commits` | Claude Code system prompt | Delete (RA-07) |
| `local-ci` + `pre-push-validation` | `ci-local` | Merge (`local-ci` is the base) |
| `python-ci-template` | `ci-python` | Rename |
| `dotnet-ci-template` | `ci-dotnet` | Rename |
| `devops-practices` + `devops-practices-updater` | `ci-standards` | Merge |
| `test-bootstrap` | `ci-tests` | Rename |
| `npm-lockfile-integrity` + `python-lockfile-integrity` + `npm-provenance-attestation` | `deps-integrity` | Merge |
| `github-release-workflow` | `release` | Rename, becomes entry |
| `readme-version-pin` | `release-readme-pin` | Rename |
| `docker-ghcr-publish` | `release-docker-ghcr` | Rename |
| `repo-publication-prep` | `publish` | Rename, becomes entry |
| `github-history-wipe` | `publish-history-wipe` | Rename |
| `repo-security-bootstrap` | `publish-secret-scan` | Rename |
| `portfolio-readme-generator` | `publish-readme` | Rename |
| `terraform-aws-syntax` + `terraform-checkov-skips` + `terraform-version-compat` | `tf-guardrails` | Merge |
| `tone-check` | `write-tone` | Rename |
| `human-rewrite` | `write-human` | Rename |
| `executive-translate` | `write-exec` | Rename |
| `incident-ask-builder` | `incident-asks` | Rename |
| `incident-appendix` | `incident-appendix` | Unchanged |
| `risk-to-action` | `incident-risk-plan` | Rename |
| `codebase-holistic-review` | `review-codebase` | Rename |
| `ui-ux-product-audit` | `review-ui` | Rename |
| `skill-vetter` | `review-skill` | Rename |
| `ios-signing-risk` | `review-ios-signing` | Rename |
| `skill-keyword-lookup` | `grimoire-find` | Rename |
| `session-skill-extractor` | `grimoire-extract` | Rename |

Refinements beyond the preview the owner approved: added `roadmap-*` and `grimoire-*`
prefixes, `orient-authored-repos`, `plan-environment`, `plan-model-tier`, `ci-tests`,
and `review-ios-signing`. Change them in this table before RA-15 runs if unwanted.

---

## Action roadmap

The 23 work items (RA-01 to RA-23) are executable task briefs in
[`docs/tasks/discoverability/`](docs/tasks/discoverability/), one file per item, in the
`task-decomposer` format. Each brief is written for an agent with no context, and gives
the model tier, fallback, dependencies, files touched, exact steps, and verification
commands. A master agent starts at
[`00-runbook.md`](docs/tasks/discoverability/00-runbook.md), which sets dispatch waves,
the prompt template, verification, escalation, and integration order. `ROADMAP.md` tracks
completion.

---

## Over-engineering audit (2026-10-04)

A `ponytail-audit` pass over the repo, cross-checked against this plan. Owner approved all
changes below.

**Repo findings added as tasks:**

| Finding | Task |
|---|---|
| `## Installation` copied into 57 skill READMEs (about 1,170 lines), plus a CI job forcing it | RA-24 |
| `model-select.sh` (interactive, agents cannot drive it), `roadmap-close.sh`, `skill-dependency-graph.sh` (no callers) | RA-25 |
| VERSION/tag drift checks in this repo's CI, superseded by release-please | RA-26 |
| 93 duplicated lines between the VS Code and JetBrains installers | RA-27 |

**Plan changes:**

| Task | Change | Reason |
|---|---|---|
| RA-01/03 | No non-blocking CI phase; RA-03 adds the check once all skills pass | Removes a two-step CI dance |
| RA-05 | Manual spot-check list, no scorer or CI gate | `find-skill.sh` hit-rate does not measure how Claude routes |
| RA-06 | Report over existing transcripts and MCP logs | Both already record every invocation; no hooks or settings edits |
| RA-07 | Delete five skills; no rules files or install plumbing | Three duplicate Claude Code behaviour; two are one-line global rules |
| RA-13 | Delete `grimoire-roadmap-status` | It has no script; `roadmap-collect.sh` is the status |
| RA-14 | Rename `repo-compass` to `orient` instead of building an orchestrator | Already the de facto session-start skill |
| RA-16 | Entry tables only, no per-step back-references | The prefix already says it |
| RA-17 | Delete `PROJECT-WORKFLOWS.md` | Pathway tables and `SKILLS.md` cover it |
| RA-21 | Dropped | Test harness for an unused skill; one install assertion moves into RA-15 |
| RA-22 | Delete validation items instead of tracking them separately | They are never scheduled |

Correction to 2.2: `session-skill-extractor` runs from a Stop hook, so it is in use even
though no transcript records an invocation.

---

## Needs owner decision

1. **`~/.claude/rules/git-ci.md`** is a seven-phase publish procedure loaded into every
   session (including this one). Recommend moving it into the `publish` entry skill and
   leaving a two-line rule pointing at it. Saves context in every unrelated session.
2. **Directory layout.** Numbered clusters (`07-devops`) now compete with prefixes
   (`release-`, `publish-`, `ci-`). Recommend deferring: the prefix carries the grouping
   for users, and moving directories touches CI, install scripts, and the private repos.
   Revisit after RA-15 if it still grates.
3. ~~JetBrains rules channel~~: moot, no rules files are created (2026-10-04 audit).
4. **Prefix refinements** listed under the rename map.
