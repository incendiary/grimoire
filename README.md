# grimoire

A private library of structured skills for AI coding assistants. Each skill is a
composable `SKILL.md` folder encoding context, constraints, and scripts for a
recurring workflow. Skills are atomic and chainable — not monolithic prompt dumps.

Grimoire is **platform-agnostic at source** with three delivery targets:

| Platform | Mechanism | Install |
|----------|-----------|---------|
| Claude Code | `~/.claude/skills/` auto-loading | `bash install-all.sh` |
| VS Code (Copilot Chat) | `.prompt.md` files + MCP tools | `bash install-vscode.sh` |
| Any MCP client | Standalone MCP server (stdio) | `cd mcp-server && npm ci && npm run build` |

The canonical source is always `SKILL.md`. Everything else is a build output.

---

## Quick Start

### Claude Code

```bash
bash install-all.sh
```

Copies every skill folder into `~/.claude/skills/`. Skills activate automatically
when Claude recognises their trigger conditions. See [clusters/README.md](clusters/README.md)
for how Claude Code skill invocation works.

### VS Code (full setup)

```bash
bash install-vscode.sh
```

Builds the MCP server, generates prompt files, and offers to merge the required
settings into your `settings.json`. Supports `--apply` (non-interactive) and
`--dry-run`. Requires Node.js 22+.

### VS Code (prompt files only)

```bash
bash build.sh
```

Generates `.prompt.md` files to `prompts/`. Reference skills in Copilot Chat
with `#skill-name`. Add to VS Code settings:

```json
"chat.promptFilesLocations": [{"path": "/absolute/path/to/grimoire/prompts"}]
```

---

## Architecture

### Skill types

Every `SKILL.md` declares a `Type:` field:

| Type | Prompt file | MCP tool | Use case |
|------|-------------|----------|----------|
| `instructional` | ✅ | — | Thinking frameworks, conventions, checklists |
| `action` | ✅ | ✅ | Skills that execute shell commands or scripts |

### Source of truth

```
SKILL.md (canonical)
   ├── build.sh ──→ prompts/*.prompt.md (gitignored)
   ├── registry.json ──→ MCP server tools
   └── install-all.sh ──→ ~/.claude/skills/
```

### MCP server

The `mcp-server/` directory contains a TypeScript MCP server that exposes
action skills as callable tools. It reads `registry.json` at startup and
resolves each skill's shell scripts for execution.

- Runtime: Node 22+, TypeScript, ESM
- Transport: stdio (compatible with VS Code, Cursor, any MCP client)
- CI: `ci-mcp.yml` — build, lint, test on every push to `mcp-server/`

---

## Workflow: session → new skill

```
Claude Code session
       ↓
session-skill-extractor fires at session end
       ↓
Transcript analysed for repeated patterns
       ↓
Proposed stubs → ~/.claude/proposed-skills/
       ↓
Review → promote into grimoire cluster
       ↓
Update Skills Index (below) + git commit + push
       ↓
bash install-all.sh (or install-vscode.sh)
```

---

## Clusters

Seven public clusters + two private (via submodule). See [clusters/README.md](clusters/README.md).

| # | Cluster | Location | Purpose |
|---|---------|----------|---------||
| 01 | [meta](clusters/01-meta/) | public | Skill management, session extraction, task decomposition |
| 02 | [comms](clusters/02-comms/) | public | Tone review, style rewriting, executive translation |
| 03 | [incident](clusters/03-incident/) | public | Evidence collection, incident docs, risk action plans |
| 04 | [security](clusters/04-security/) | public | iOS signing risk analysis |
| 05 | [technical](clusters/05-technical/) | public | PE binary parsing, test bootstrapping |
| 06 | study | **private** | Burst study sessions, material triage, YouTube curation |
| 07 | [devops](clusters/07-devops/) | public | CI templates, repo publication, history wiping, secrets |
| 08 | [offsec](clusters/08-offsec/) | public | Shellcode, BOFs, process injection, EDR, C2 |
| 09 | odpc | **private** | WKL ODPC: syscalls, ETW evasion, call-stack spoofing |

> **Private clusters** live in a separate repo ([grimoire-private](https://github.com/incendiary/grimoire-private))
> mounted as a git submodule at `clusters-private/`. See [Private submodule](#private-submodule) below.

---

## Skills Index

> **Status:** ✅ complete · 📋 promoted (needs expansion) · 🔲 stub

| Cluster | Skill | Status |
|---------|-------|--------|
| 01-meta | `session-skill-extractor` | ✅ |
| 01-meta | `skill-vetter` | ✅ |
| 01-meta | `github-authored-repos` | ✅ |
| 01-meta | `test-before-asking` | ✅ |
| 01-meta | `cwd-verification` | ✅ |
| 01-meta | `verify-code-version` | ✅ |
| 01-meta | `mid-task-checkin` | ✅ |
| 01-meta | `task-decomposer` | ✅ |
| 01-meta | `task-handoff` | ✅ |
| 01-meta | `karpathy-environment` | ✅ |
| 01-meta | `karpathy-framework` | ✅ |
| 01-meta | `karpathy-spec` | ✅ |
| 01-meta | `karpathy-verify` | ✅ |
| 02-comms | `tone-check` | ✅ |
| 02-comms | `human-rewrite` | ✅ |
| 02-comms | `executive-translate` | ✅ |
| 03-incident | `incident-ask-builder` | ✅ |
| 03-incident | `incident-appendix` | ✅ |
| 03-incident | `risk-to-action` | ✅ |
| 04-security | `ios-signing-risk` | ✅ |
| 05-technical | `pe-binary-analysis` | ✅ |
| 05-technical | `test-bootstrap` | ✅ |
| 06-study | *(private submodule)* | — |
| 07-devops | `repo-compass` | ✅ |
| 07-devops | `repo-publication-prep` | ✅ |
| 07-devops | `github-history-wipe` | ✅ |
| 07-devops | `repo-security-bootstrap` | ✅ |
| 07-devops | `python-ci-template` | ✅ |
| 07-devops | `dotnet-ci-template` | ✅ |
| 07-devops | `python-ci-lint-precheck` | ✅ |
| 07-devops | `format-before-commit` | ✅ |
| 07-devops | `portfolio-readme-generator` | ✅ |
| 07-devops | `pre-commit-aware-commits` | ✅ |
| 07-devops | `github-release-workflow` | ✅ |
| 07-devops | `git-push-protocol-handler` | ✅ |
| 07-devops | `roadmap-sync` | ✅ |
| 07-devops | `terraform-checkov-skips` | ✅ |
| 07-devops | `terraform-aws-syntax` | ✅ |
| 07-devops | `terraform-version-compat` | ✅ |
| 07-devops | `project-delivery-workflow` | ✅ |
| 07-devops | `docker-ghcr-publish` | ✅ |
| 07-devops | `npm-lockfile-integrity` | ✅ |
| 07-devops | `npm-provenance-attestation` | ✅ |
| 07-devops | `python-lockfile-integrity` | ✅ |
| 07-devops | `readme-version-pin` | ✅ |
| 08-offsec | `shellcode-dev-conventions` | ✅ |
| 08-offsec | `api-hashing-conventions` | ✅ |
| 08-offsec | `process-injection-taxonomy` | ✅ |
| 08-offsec | `edr-test-loop` | ✅ |
| 08-offsec | `bof-dev-conventions` | ✅ |
| 08-offsec | `c2-integration-checklist` | ✅ |
| 09-odpc | *(private submodule)* | — |

---

## Private submodule

Personal or team-specific clusters that don't belong in the shared repo live in a
separate private repository, mounted as a git submodule at `clusters-private/`.

### Using the existing private submodule

```bash
git submodule init && git submodule update
```

Or clone with `--recurse-submodules`. The install scripts (`install-all.sh`,
`build.sh`, `install-vscode.sh`) automatically detect and include skills from
`clusters-private/clusters/` when the submodule is initialised.

### Creating your own private submodule

If you're forking grimoire and want your own private clusters:

```bash
bash scripts/init-private-submodule.sh
```

This creates a new private GitHub repo, scaffolds the correct directory structure,
and wires it as a submodule. See the script's `--help` for options.

---

## Note

This repository is **private**.
