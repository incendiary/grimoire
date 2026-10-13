# grimoire

A private library of structured skills for AI coding assistants. Each skill is a
composable `SKILL.md` folder encoding context, constraints, and scripts for a
recurring workflow. Skills are atomic and chainable — not monolithic prompt dumps.

Grimoire is **platform-agnostic at source** with three delivery targets:

| Platform | Mechanism | Install |
|----------|-----------|---------|
| Claude Code | `~/.claude/skills/` auto-loading | `bash install-all.sh` |
| VS Code (Copilot Chat) | `.prompt.md` files + MCP tools | `bash install-vscode.sh` |
| JetBrains MCP clients | MCP tool registration | `bash install-jetbrains.sh` |
| Any MCP client | Standalone MCP server (stdio) | `cd mcp-server && npm ci && npm run build` |

The canonical source is always `SKILL.md`. Everything else is a build output.

---

## Quick Start

### Claude Code

```bash
bash install-all.sh
```

Update existing installs safely:

```bash
bash install-all.sh --update
```

Force overwrite without backup:

```bash
bash install-all.sh --force
```

Copies every skill folder into `~/.claude/skills/`. Skills activate automatically
when Claude recognises their trigger conditions. See [clusters/README.md](clusters/README.md)
for how Claude Code skill invocation works.

Remove installed grimoire-managed skills:

```bash
bash uninstall-all.sh --dry-run
bash uninstall-all.sh
bash uninstall-all.sh --skills-dir /path/to/skills
```

### VS Code (full setup)

```bash
bash install-vscode.sh
```

Builds the MCP server, generates prompt files, and offers to merge the required
settings into your `settings.json`. Supports `--apply` (non-interactive) and
`--dry-run`. Requires Node.js 22+.

Remove VS Code integration:

```bash
bash uninstall-vscode.sh --dry-run
bash uninstall-vscode.sh
```

### VS Code (prompt files only)

```bash
bash build.sh
```

Generates `.prompt.md` files to `prompts/`. Reference skills in Copilot Chat
with `#skill-name`. Add to VS Code settings:

```json
"chat.promptFilesLocations": [{"path": "/absolute/path/to/grimoire/prompts"}]
```

### JetBrains MCP setup

```bash
bash install-jetbrains.sh
```

Builds the MCP server and merges a `grimoire` entry into JetBrains MCP config.
Supports `--apply`, `--dry-run`, and explicit `--mcp-path /absolute/path/to/mcp.json`
for environments where config location differs.

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
action skills as callable tools. Each tool runs exactly one script named in
`registry.json` (via `execFile`, no shell), with the caller's arguments. Action skills whose
scripts push, merge, or delete are listed under `excluded` with a reason and are not exposed.

- Runtime: Node 22+, TypeScript, ESM
- Transport: stdio (compatible with VS Code, Cursor, any MCP client)
- CI: `ci-mcp.yml` — build, lint, test on every push to `mcp-server/`

### Known limitation: corporate-managed VS Code

If your organisation manages Copilot via GitHub Enterprise policy, the setting
`chat.mcp.access` may be locked to `none` ("Managed by organization"). This
blocks **all** MCP servers — including local ones — from loading in VS Code.

**Symptom:** `MCP: List Servers` shows empty despite correct `mcp.json` config.

**Workaround:** Use prompt files only (`#skill-name` in Copilot Chat). Prompt files
are unaffected by MCP policy — they load as context text, not as tool calls.
Skills still work but Copilot interprets them as guidance rather than executing
commands directly. For full action-skill execution, use Claude Code or an
unmanaged VS Code profile.

---

## Workflow: session → new skill

```
Claude Code session
       ↓
grimoire-extract fires at session end
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

## Project Workflows

Skills are named by pathway: the prefix says when you need it. Type a prefix (for
example `/release`) in Claude Code, or `#release` in Copilot Chat, to see the pathway.
The entry skills `orient`, `plan`, `release` and `publish` list their steps in order.
Full list: [SKILLS.md](SKILLS.md).

| Project type | Pathways, in order |
|---|---|
| Python tool | `orient`, `plan`, `py-lint`, `ci-python`, `release` |
| .NET tool | `orient`, `plan`, `ci-dotnet`, `release` |
| Node service | `orient`, `plan`, `deps-integrity`, `release`, `release-docker-ghcr` |
| Terraform | `orient`, `plan`, `tf-guardrails`, `publish-secret-scan`, `release` |
| Security tool | `orient`, `plan-spec`, `publish-secret-scan`, `publish-readme`, `release` |
| Going public | `publish` (follow its pathway table) |

---

## Clusters

Seven public clusters + two private (via submodule). See [clusters/README.md](clusters/README.md).

| # | Cluster | Location | Purpose |
|---|---------|----------|---------||
| 01 | [meta](clusters/01-meta/) | public | Skill management, session extraction, task decomposition |
| 02 | [comms](clusters/02-comms/) | public | Tone review, style rewriting, executive translation |
| 03 | [incident](clusters/03-incident/) | public | Evidence collection, incident docs, risk action plans |
| 04 | [security](clusters/04-security/) | public | iOS signing risk analysis |
| 05 | [technical](clusters/05-technical/) | public | Test bootstrapping |
| 06 | study | **private** | Burst study sessions, material triage, YouTube curation |
| 07 | [devops](clusters/07-devops/) | public | CI templates, repo publication, history wiping, secrets |
| 08 | offsec | **private** | Shellcode, BOFs, process injection, EDR, C2 |
| 09 | odpc | **private** | WKL ODPC: syscalls, ETW evasion, call-stack spoofing |

> **Private clusters** live in separate repos ([grimoire-private](https://github.com/incendiary/grimoire-private),
> [grimoire-offsec](https://github.com/incendiary/grimoire-offsec)) mounted as git submodules at
> `clusters-private/` and `clusters-offsec/`. See [Private submodule](#private-submodule) below.

---

## Skills Index

The full, generated list of skills with descriptions is in [SKILLS.md](SKILLS.md).
In Claude Code, type `/` and start typing to filter; in Copilot Chat use `#skill-name`.

---

## Private submodule

Personal, team-specific, or offensive-security clusters that don't belong in the shared
public repo live in separate private repositories, each mounted as a git submodule under
`clusters-<name>/` (e.g. `clusters-private/`, `clusters-offsec/`).

### Using the existing private submodules

```bash
git submodule init && git submodule update
```

Or clone with `--recurse-submodules`. The install scripts (`install-all.sh`,
`build.sh`, `install-vscode.sh`) automatically detect and include skills from any
mounted `clusters-*/clusters/` submodule.

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
