# Task RA-19: Clear MCP server npm advisories

> Status: done
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: XS
> Touches: `mcp-server/package-lock.json`, `CHANGELOG.md`

## Objective
Remove the known npm advisories in the MCP server's dependency tree without changing
direct dependency versions. Dependabot is already configured (`.github/dependabot.yml`); do not touch it.

## Background
- `npm audit` (2026-09-29) reported 9 advisories (3 high, 5 moderate, 1 low), all in
  transitive dependencies of `@modelcontextprotocol/sdk` (`fast-uri`, `hono`,
  `@hono/node-server`, `body-parser`). All are marked "fix available via `npm audit fix`".
- Merged Dependabot PRs may already have cleared some advisories; if `npm audit --omit=dev --audit-level=high` already exits 0 after `npm ci`, stop with `CHUNK COMPLETE: RA-19 nothing to fix`.
- Direct dependencies in `mcp-server/package.json` are exact-pinned deliberately. Do not
  change `package.json`.
- The server uses stdio transport, so exposure is low; this is hygiene.

## Steps
1. Run, from the repo root:
   ```bash
   cd mcp-server
   npm ci
   npm audit --omit=dev
   npm audit fix
   ```
   Do **not** use `npm audit fix --force`.
2. Confirm `git diff --stat` shows only `mcp-server/package-lock.json`. If
   `package.json` changed, run `git checkout -- package.json` and stop with
   `CHUNK BLOCKED: RA-19 audit fix wanted to change package.json`.
3. Run `npm run build && npm run lint && npm test`. All must pass. Then `cd ..`.
4. `CHANGELOG.md` → `### Security` (create the subsection under `## [Unreleased]` if
   absent): `- Resolved transitive npm advisories in mcp-server (npm audit fix).`

## Constraints
- Lockfile-only change in `mcp-server/`.

## Done when
- [ ] `cd mcp-server && npm audit --omit=dev --audit-level=high` exits 0.
- [ ] `npm run build && npm run lint && npm test` pass.
- [ ] `git diff --stat main` lists only `mcp-server/package-lock.json`, `CHANGELOG.md`, `ROADMAP.md`, and this task file.

## Return signal
Commit message: `fix: resolve mcp-server npm advisories`
Then follow Shared conventions step 7.
