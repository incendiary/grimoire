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
| Always-on behavioural skills | Move to rules files, retire as skills |

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
(3) consolidation and the pathway-prefix rename, which cuts 57 skills to 42, grouped
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
JetBrains) is not covered, so zero here does not prove zero overall. That is why RA-6
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
a skill explicitly gets no grimoire help. Minimum fix: RA-2. Full fix: RA-1 to RA-5.

**PF-2 (risk 2): descriptions diverge per surface.** After the frontmatter lands, the
MCP registry and prompt files keep old text, so VS Code and JetBrains route
differently from Claude Code. Fix: RA-3.

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
push, and the loss is discovered only on a real repo. Fix: RA-21.

**PF-6 (risk 4): rules not reaching IDEs.** Rules moved to `~/.claude/rules` are
invisible to Copilot and JetBrains. Fix: RA-7 emits Copilot `.instructions.md` files
too. The JetBrains equivalent is unverified (see decisions).

## 6. Test coverage gaps

| Path | Why critical | Test type needed |
|---|---|---|
| Skill frontmatter | Discoverability depends on it | CI validator (RA-1) |
| Intent to skill routing | The key success criterion | Fixture-driven hit-rate test (RA-5) |
| `install-all.sh --update` with renamed skills | Stale skills on every machine | bats test with a temp skills dir (RA-15) |
| `github-history-wipe/*.sh` | Destructive, force-push adjacent | bats test against a local bare repo (RA-21) |
| `mcp-server` tool execution per skill | Only a smoke and registry test exist | Add one executor test per merged skill (RA-8 to RA-13) |

## 7. Dependency audit

- `mcp-server/package.json`: all versions exact-pinned. Good.
- `npm audit`: 9 advisories, all transitive, all "fix available via `npm audit fix`".
- No dependency scheduled drift detection (no Dependabot config). RA-19.

## 8. CI/CD gaps

| Check | State |
|---|---|
| Tests on every PR | Yes (`ci-mcp.yml` path-filtered, `validate.yml`) |
| Lint and format | Yes (shellcheck, eslint) |
| Secret scanning | Yes (gitleaks, TruffleHog, detect-secrets locally) |
| Action versions pinned | Tags only, not SHAs (RA-20) |
| Scheduled dependency drift | **No** (RA-19) |
| Frontmatter and discoverability | **No** (RA-1, RA-5) |

---

## Canonical rename map

This table is the specification for RA-8 to RA-18. 57 skills become 42 skills plus
6 rules files, under 13 prefixes: `orient`, `plan`, `roadmap`, `py`, `ci`, `deps`,
`release`, `publish`, `tf`, `write`, `incident`, `review`, `grimoire`. The bare prefix,
where it exists, is the pathway entry skill that lists its steps in order.

| Current | New | How |
|---|---|---|
| *(new)* | `orient` | New entry skill: cwd check, code-version check, push-protocol check, then `orient-repo-state` |
| `repo-compass` | `orient-repo-state` | Rename |
| `branch-surface-resolve` | `orient-branches` | Rename |
| `github-morning-run` | `orient-morning-run` | Rename |
| `github-authored-repos` | `orient-authored-repos` | Rename |
| `cwd-verification` | rule `grimoire-cwd` + script into `orient` | Retire skill |
| `verify-code-version` | rule `grimoire-code-version` + check into `orient` | Retire skill |
| `git-push-protocol-handler` | script into `orient` | Retire skill |
| `karpathy-framework` | `plan` | Rename (already a router) |
| `karpathy-spec` | `plan-spec` | Rename |
| `karpathy-verify` | `plan-verify` | Rename |
| `karpathy-environment` | `plan-environment` | Rename |
| `task-decomposer` | `plan-decompose` | Rename |
| `task-handoff` | `plan-handoff` | Rename |
| `model-selection-framework` | `plan-model-tier` | Rename |
| `test-before-asking` | rule `grimoire-test-before-asking` | Retire skill |
| `mid-task-checkin` | rule `grimoire-mid-task-checkin` | Retire skill |
| `roadmap-driver` + `grimoire-roadmap-status` | `roadmap` | Merge |
| `roadmap-sync` | `roadmap-sync` | Unchanged |
| `project-delivery-workflow` | `roadmap-deliver` | Rename |
| `python-lint-gate` + `format-before-commit` + `python-ci-lint-precheck` | `py-lint` | Merge |
| `python-black-ruff-authoring` | rule `grimoire-python-authoring` | Retire skill |
| `pre-commit-aware-commits` | rule `grimoire-pre-commit` | Retire skill |
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

### Model tier guide

- **Haiku:** mechanical work with an exact spec, where success is checkable by grep or
  CI (renames from a table, concatenations, version bumps).
- **Sonnet:** default. Writing descriptions, scripts, and skill prose where judgement is
  needed but the design is fixed.
- **Opus:** merges where capability could silently be lost, or cross-cutting changes
  touching install, CI, and MCP together. Also use Opus to review any Haiku output
  that touches more than 20 files.

### Standing instructions for every executing agent

1. Read `CLAUDE.md` (repo conventions: branch per item, conventional commits, never edit
   `VERSION`, add a `CHANGELOG.md` entry under `[Unreleased]`).
2. `git checkout -b <type>/<item-slug> main`. Pre-commit blocks commits on `main`.
3. Do not edit between the `ROADMAP-COLLECT` markers in `ROADMAP.md` by hand. Run
   `bash clusters/07-devops/devops-practices/check-roadmap-sync.sh . --fix` (path
   becomes `clusters/07-devops/ci-standards/...` after RA-12).
4. Before committing: `shellcheck` any changed `.sh`; `cd mcp-server && npm ci && npm test`
   if registry or MCP files changed.
5. When done, tick the item in `ROADMAP.md` ("Discoverability and consolidation
   programme" section).
6. British English, no em dashes in prose.

---

### Phase 1: make existing skills findable (no renames)

#### RA-1: Define the frontmatter spec and enforce it in CI

**Context:** No `SKILL.md` has YAML frontmatter, so Claude Code shows each skill's name
as its description. Claude Code reads `name` and `description` from a leading
`---` YAML block.

**Do:**
- Add `scripts/check-frontmatter.sh`: for every `clusters/*/*/SKILL.md`, assert line 1
  is `---`; a closing `---` exists within 10 lines; `name:` equals the directory name;
  `description:` is non-empty, at most 1024 characters, a single line, and contains
  `Use when`.
- Add a `frontmatter` job to `.github/workflows/validate.yml` running it.
- Keep the existing `> **Status/Cluster/Type**` blockquote below the frontmatter
  (other tooling parses it).

**Success criteria:** Script exits 1 on the current tree listing all 57 files, and 0
once RA-2 lands. Shellcheck clean.

**Files:** `scripts/check-frontmatter.sh`, `.github/workflows/validate.yml`

**Effort:** S. **Tier:** Sonnet.

#### RA-2: Add frontmatter to all 57 skills

**Context:** The key discoverability fix. Descriptions are what Claude matches intent
against, and what you see in `/` autocomplete.

**Do:** Prepend to each `SKILL.md`:
```yaml
---
name: <directory-name>
description: <What it does, one sentence>. Use when <3 to 5 trigger phrases from the existing "Invoke when" text>. Not for <nearest neighbour task> (use <other-skill>).
---
```
- Source the trigger phrases from the skill's own `## Description` / "Invoke when" text.
  Do not invent capabilities.
- The "Not for" clause is required wherever section 2.3 of `REVIEW.md` lists an
  overlap; it is what stops the wrong sibling firing.
- Work cluster by cluster, one commit per cluster.

**Success criteria:** `scripts/check-frontmatter.sh` exits 0. After
`bash install-all.sh --update`, a fresh Claude Code session lists every grimoire
skill with a real description. Spot check: in a fresh session, with no skill names,
ask "run my GitHub Actions locally before I push", "make this sound less like AI",
"what should I work on next in this repo" and confirm the matching skill is invoked.

**Files:** `clusters/*/*/SKILL.md` (57)

**Effort:** M. **Tier:** Sonnet (Haiku writes weak disambiguation clauses).

#### RA-3: Single-source descriptions for prompts and MCP

**Context:** `build.sh:49` scrapes `## Description`; `mcp-server/registry.json` has
hand-written descriptions. Both should read the frontmatter.

**Do:**
- `build.sh`: take `description` from frontmatter, and do not truncate at 200 chars.
- Registry: either generate `description` from frontmatter at MCP server load
  (`mcp-server/src/loader.ts` reads the `skill` path already) and drop the field from
  `registry.json`, or add a test in `mcp-server/src/__tests__/registry.test.ts` asserting
  equality. Prefer generation at load (one source, no drift).

**Success criteria:** Changing a frontmatter description changes the prompt file and
the MCP tool description with no other edit. `npm test` green.

**Files:** `build.sh`, `mcp-server/src/loader.ts`, `mcp-server/registry.json`,
`mcp-server/src/__tests__/registry.test.ts`

**Effort:** S. **Tier:** Sonnet.

#### RA-4: Generate the skills catalogue instead of hand-maintaining it

**Context:** `README.md` Skills Index is missing 10 skills.

**Do:** `scripts/gen-catalogue.sh` writes `SKILLS.md`: grouped by prefix (clusters
until RA-15), one row per skill: name, description, type. Replace the README Skills
Index with a link to `SKILLS.md`. Add a `--check` mode to `validate.yml` that fails if
`SKILLS.md` is stale.

**Success criteria:** `SKILLS.md` lists 57 skills; `--check` fails after a description
edit until regenerated.

**Files:** `scripts/gen-catalogue.sh`, `SKILLS.md`, `README.md`, `.github/workflows/validate.yml`

**Effort:** S. **Tier:** Haiku (after RA-2), Sonnet if RA-2 is incomplete.

#### RA-5: Make discoverability measurable

**Context:** "I can't find the right skill" needs a test, or regressions will return.

**Do:**
- `docs/discoverability-intents.tsv`: at least 30 rows of `<natural-language intent>\t<expected skill>`,
  phrased as the owner would type them, with no skill names inside. Cover every
  pathway and every overlap pair in `REVIEW.md` 2.3.
- Update `clusters/01-meta/skill-keyword-lookup/find-skill.sh` to weight frontmatter
  `description` above body text.
- `scripts/check-discoverability.sh`: runs `find-skill.sh --json --limit 3` per intent
  and reports hit@1 and hit@3. Wire into `validate.yml` with a gate of hit@3 at least 80%.

**Success criteria:** Report prints per-intent result. Gate passes after RA-2.
Re-run after RA-15 with the intents' expected names updated.

**Files:** `docs/discoverability-intents.tsv`, `find-skill.sh`, `scripts/check-discoverability.sh`, `validate.yml`

**Effort:** M. **Tier:** Sonnet. (The owner should review the intents file: it encodes
how they think.)

---

### Phase 2: evidence before pruning

#### RA-6: Cross-machine usage telemetry

**Context:** Usage data in `REVIEW.md` 2.2 covers one machine and Claude Code only.
The owner also uses VS Code and JetBrains on a second machine. Do not prune on
partial evidence.

**Do:**
- `scripts/hooks/log-skill-use.sh`: a Claude Code `PreToolUse` hook (matcher `Skill`)
  plus a `UserPromptSubmit` hook detecting `/<skill>` that appends
  `ISO-date<TAB>host<TAB>surface<TAB>skill` to `~/.claude/grimoire-usage.log`. No
  prompt text, no paths.
- `install-all.sh --with-telemetry`: merges the hooks into `~/.claude/settings.json`
  with a backup and `--dry-run`, same pattern as `install-vscode.sh`.
- Confirm `mcp-server/src/logger.ts` logs each tool call with the tool name; add a
  `surface=mcp` field if absent.
- `scripts/usage-report.sh <log>...`: merges logs from both machines, prints per-skill
  counts and last-used date, and lists never-used skills.

**Success criteria:** Invoking a skill by `/name`, by model routing, and by MCP each
produce one log line. Report runs on two concatenated logs.

**Files:** `scripts/hooks/log-skill-use.sh`, `install-all.sh`, `mcp-server/src/logger.ts`, `scripts/usage-report.sh`

**Effort:** M. **Tier:** Sonnet.

---

### Phase 3: rules, not skills

#### RA-7: Move always-on behaviour into rules files for every surface

**Context:** Six skills describe standing behaviour (see rename map). Skills load
only on trigger, so they are never "always active".

**Do:**
- Create `rules/` at repo root with `grimoire-test-before-asking.md`,
  `grimoire-mid-task-checkin.md`, `grimoire-cwd.md`, `grimoire-code-version.md`,
  `grimoire-pre-commit.md`, `grimoire-python-authoring.md`. Each at most 40 lines:
  the rule, why, and how to apply. Condense; do not paste the skill.
- `install-all.sh`: copy `rules/*.md` to `~/.claude/rules/`; `uninstall-all.sh` removes them.
- `build.sh`: emit each rule as `prompts/<name>.instructions.md` with
  `applyTo: "**"` frontmatter (Copilot custom instructions; `python-authoring` uses
  `applyTo: "**/*.py"`).
- Delete the six skill directories. Move scripts: `cwd-verification`'s script and
  `verify-code-version`'s check go to `orient` (RA-14); if RA-14 is not yet done, park
  them under `rules/scripts/`.
- Update `mcp-server/registry.json` to drop retired action skills.

**Success criteria:** Rules appear in `~/.claude/rules` after install and in
`prompts/*.instructions.md` after `build.sh`. No skill directory for the six remains.
CI green.

**Files:** `rules/*`, `install-all.sh`, `uninstall-all.sh`, `build.sh`, six skill dirs, `mcp-server/registry.json`

**Effort:** M. **Tier:** Sonnet.

---

### Phase 4: consolidation (create merged skills directly under their new names)

Every merge item must start by writing a feature-parity checklist (every capability,
flag, script, and gotcha in each source skill) into the PR description, and end by
ticking each line or noting a deliberate drop. Source skills are deleted in the same PR.

#### RA-8: `ci-local` (merge `pre-push-validation` into `local-ci`)

**Context:** Both parse `.github/workflows/*.yml` and run `run:` steps locally.
`local-ci` adds hook install, version-matched auto-fix, and `--sync`.
`pre-push-validation` has an explicit CI-only skip-reason list and fail-closed default.

**Do:** Diff `pre-push-validation/pre-push-validation.sh` against `local-ci/local-ci.sh`
feature by feature. Port anything missing into `local-ci.sh`. Move `local-ci` to
`clusters/07-devops/ci-local/`, script name `local-ci.sh` unchanged (the owner's global
`~/.claude/rules/git-ci.md` calls `bash local-ci.sh`). Delete `pre-push-validation`.
Update registry, `devops-practices` references, and `PROJECT-WORKFLOWS.md`.

**Success criteria:** Parity checklist complete. `local-ci.sh --list` and `--dry-run`
on this repo show every step `pre-push-validation.sh` would have run or skipped, with
the same skip reasons.

**Effort:** M. **Tier:** Opus.

#### RA-9: `py-lint` (merge three Python lint skills)

**Context:** `python-lint-gate` (`lint-gate.sh`), `format-before-commit` (Black/Ruff
`pyproject.toml` template), `python-ci-lint-precheck` (pylint and pytest disable
comments). Authoring guidance goes to the RA-7 rule.

**Do:** New `clusters/07-devops/py-lint/` with `lint-gate.sh`, `pyproject.toml`
template, sections: gate, config template, pylint exceptions. Link to the
`grimoire-python-authoring` rule and to `ci-local` for full-workflow runs. Delete the
three sources.

**Success criteria:** Parity checklist complete; `lint-gate.sh --check` behaves as before.

**Effort:** S. **Tier:** Sonnet.

#### RA-10: `deps-integrity` (merge lockfile and provenance skills)

**Do:** New `clusters/07-devops/deps-integrity/` keeping all three scripts
(`check-lockfile-integrity.sh`, `check-python-lockfile-integrity.sh`,
`check-provenance.sh`). SKILL.md sections: Node lockfile, Python lockfile, npm
provenance. Check how `mcp-server/src/executor.ts` selects a script: if one tool per
skill, expose three registry entries `deps-integrity-npm`, `deps-integrity-python`,
`deps-integrity-provenance` pointing at the same SKILL.md, or add an ecosystem argument.

**Success criteria:** Parity checklist complete; each script runs from the new path;
MCP tests green.

**Effort:** M. **Tier:** Sonnet.

#### RA-11: `tf-guardrails` (merge three terraform skills)

**Do:** Concatenate the three SKILL.md bodies into sections (provider version compat,
AWS syntax, checkov skip placement), dedupe shared intro, keep both scripts
(`check-provider-compat.sh`, `validate-checkov-skip-placement.sh`). Move each
source's `## Roadmap` items into the merged README.

**Success criteria:** No content lost (line-by-line check of the three sources);
shellcheck clean.

**Effort:** S. **Tier:** Haiku.

#### RA-12: `ci-standards` (fold the updater into `devops-practices`)

**Do:** Move `devops-practices-updater`'s procedure into a "Evolving this standard"
section of `devops-practices`, rename the directory to `ci-standards`. **Update every
path reference** to its `check-*.sh` scripts: `.pre-commit-config.yaml`,
`.github/workflows/devops-check.yml`, `ROADMAP.md` header text, `CLAUDE.md`.

**Success criteria:** `grep -rn 'devops-practices' --exclude=CHANGELOG.md .` returns
nothing outside `scripts/renamed-skills.txt`. `devops-check.yml` green.

**Effort:** S. **Tier:** Sonnet.

#### RA-13: `roadmap` (merge `grimoire-roadmap-status` into `roadmap-driver`)

**Do:** `roadmap-driver` gains a "status only" mode that does what
`grimoire-roadmap-status` does (counts, top clusters, infra progress). Rename to
`roadmap`; rename `project-delivery-workflow` to `roadmap-deliver` in RA-15.

**Success criteria:** "show roadmap status" and "what should I work on next" both
route to `roadmap`. MCP tool for status still works.

**Effort:** S. **Tier:** Sonnet.

#### RA-14: `orient` entry skill

**Context:** Observed chain always begins with orientation. Folds three small checks.

**Do:** New `clusters/01-meta/orient/` (action type) with `orient.sh` that runs in
order: cwd check (from `cwd-verification`), code-version check (from
`verify-code-version`), SSH push check (`check_push_protocol.sh` from
`git-push-protocol-handler`), then prints the `orient-*` skills with one-line purposes
and suggests `orient-repo-state`. Delete `git-push-protocol-handler`.

**Success criteria:** `bash orient.sh` in this repo prints all three check results and
exits 0. Registry entry added.

**Effort:** M. **Tier:** Sonnet.

---

### Phase 5: rename and pathway entries

#### RA-15: Execute the canonical rename

**Context:** Pure renames per the table in `REVIEW.md`. Merges must already be done.
This is a breaking change for anyone invoking by the old names.

**Do:**
- `scripts/renamed-skills.txt`: `old<TAB>new` for every row, including merged and
  retired names (new column `-` for retired).
- `scripts/apply-renames.sh`: `git mv` each directory; update the `# heading`, the
  frontmatter `name:`, and every textual reference across `clusters/`, `rules/`,
  `README.md`, `PROJECT-WORKFLOWS.md`, `CLAUDE.md`, `SKILLS.md`, `mcp-server/registry.json`,
  `mcp-server/src/__tests__/*`, `.github/workflows/*`, `.pre-commit-config.yaml`,
  `scripts/*`. Use word-boundary matches (`task-handoff` must not hit
  `plan-handoff` twice). Do not touch `CHANGELOG.md` history.
- `install-all.sh --update` and `uninstall-all.sh`: read `renamed-skills.txt` and
  remove old installed directories (with the existing backup behaviour).
- Fix `registry.test.ts`, which hard-codes `clusters/01-meta` and `clusters/07-devops`.
- Commit with `feat!:` and a `BREAKING CHANGE:` footer (release-please major bump).

**Success criteria:** For every old name, `grep -rnw <old> . --exclude=CHANGELOG.md
--exclude=renamed-skills.txt --exclude-dir=node_modules` returns nothing. CI green.
bats test: temp skills dir with old names, run `install-all.sh --update --skills-dir`,
old names gone and backed up. `check-discoverability.sh` still passes with updated
intents.

**Effort:** L. **Tier:** Sonnet to write the scripts; Opus to review the final diff.

#### RA-16: Pathway entry skills list their steps

**Do:** In `plan`, `release`, `publish`, and `orient`, add a `## Pathway` section at the
top: numbered steps with skill names and one-line purpose, e.g. `publish`:
`publish` (audit) → `publish-history-wipe` (if history is dirty) →
`publish-secret-scan` → `ci-local --sync` → `publish-readme`. Each step skill gets a
one-line "Part of the <prefix> pathway, step N" under its frontmatter.

**Success criteria:** Typing `/publish` in Claude Code shows the pathway in autocomplete
order; entry skill output names the next step.

**Effort:** S. **Tier:** Sonnet.

#### RA-17: Rewrite `PROJECT-WORKFLOWS.md` and cluster READMEs in pathway terms

**Do:** Replace per-project-type stacks with per-pathway sections, using new names.
Remove lint-skill chains made obsolete by RA-9. Keep it under 150 lines.

**Success criteria:** No retired names; every pathway prefix has a section.

**Effort:** S. **Tier:** Haiku, given the rename map.

#### RA-18: Cross-repo and global-config follow-up (owner approval required)

**Context:** Outside this repo: `grimoire-private` and `grimoire-offsec` may reference
public skill names; `~/.claude/CLAUDE.md` names `github-authored-repos`;
`~/.claude/rules/git-ci.md` names `pre-push-validation` and `local-ci`.

**Do:** Grep each location for every old name in `renamed-skills.txt` and produce a
diff for the owner. Apply only with explicit approval.

**Effort:** S. **Tier:** Haiku.

---

### Phase 6: hygiene

#### RA-19: Clear npm advisories and add scheduled drift detection

**Do:** `cd mcp-server && npm audit fix` (no `--force`); confirm `npm test` and
`npm run build`. Add `.github/dependabot.yml` for `npm` (`/mcp-server`) and
`github-actions` (`/`), weekly.

**Success criteria:** `npm audit --omit=dev` shows 0 high. Dependabot config valid.

**Effort:** XS. **Tier:** Haiku.

#### RA-20: Align scanner versions and pin actions by SHA

**Do:** Bump TruffleHog in `.pre-commit-config.yaml` to match CI (`v3.97.6`). Replace
tag pins in `.github/workflows/*.yml` with full commit SHAs plus a `# vX` comment.

**Effort:** XS. **Tier:** Haiku.

#### RA-21: Tests for destructive scripts

**Do:** Add `tests/` with bats tests for `github-history-wipe/capture-releases.sh`
and `recreate-releases.sh` (against a local bare repo, `gh` stubbed on `PATH`), and for
`install-all.sh` / `uninstall-all.sh` with `--skills-dir` in a temp directory. Run in
`validate.yml`.

**Effort:** M. **Tier:** Sonnet.

#### RA-22: Separate validation items from actionable roadmap work

**Context:** About 30 of 49 open items are "Test on N real X". They cannot be worked,
only observed, and they hide the actionable backlog.

**Do:** In each skill README, move such items under `## Validation` (not `## Roadmap`).
Teach `scripts/roadmap-collect.sh` to count them separately, and render them in their own
`ROADMAP.md` subsection inside the generated block. When merges happen (RA-8 to RA-13),
carry validation items to the merged skill.

**Success criteria:** `ROADMAP.md` header shows actionable and validation counts
separately. `check-roadmap-sync.sh --check` green.

**Effort:** S. **Tier:** Sonnet.

#### RA-23: Evidence-based prune (60 days after RA-6 ships on both machines)

**Do:** Run `scripts/usage-report.sh` over both machines' logs. List skills with zero
use. For each, propose keep, merge, or archive (move to `archive/`, excluded from
install). **The owner decides**; do not delete.

**Effort:** S. **Tier:** Sonnet for the report.

---

## Needs owner decision

1. **`~/.claude/rules/git-ci.md`** is a seven-phase publish procedure loaded into every
   session (including this one). Recommend moving it into the `publish` entry skill and
   leaving a two-line rule pointing at it. Saves context in every unrelated session.
2. **Directory layout.** Numbered clusters (`07-devops`) now compete with prefixes
   (`release-`, `publish-`, `ci-`). Recommend deferring: the prefix carries the grouping
   for users, and moving directories touches CI, install scripts, and the private repos.
   Revisit after RA-15 if it still grates.
3. **JetBrains rules channel.** RA-7 covers Claude Code and Copilot. The equivalent for
   JetBrains AI Assistant rules is unverified; confirm which JetBrains assistant the
   second machine uses before extending RA-7.
4. **Prefix refinements** listed under the rename map.
